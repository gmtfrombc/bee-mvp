import os
import uuid

import psycopg2 as _real_psycopg2
import pytest

from tests.db.db_utils import _psql, _conn

# Ordered list of migration files required for action_steps feature
MIGRATION_FILES = [
    "supabase/migrations/20240722115000_shared_audit_function.sql",
    "supabase/migrations/20250714140000_init_action_steps.sql",
    "supabase/migrations/20250714141000_action_step_logs.sql",
    "supabase/migrations/20250714142000_action_step_triggers.sql",
    "supabase/migrations/20250714143000_action_step_rls.sql",
]


@pytest.fixture(scope="module", autouse=True)
def _prepare_db():
    """Apply schema migrations once per test module."""

    # Minimal auth schema + helpers (same as other DB tests)
    _psql(
        """
        CREATE SCHEMA IF NOT EXISTS auth;
        CREATE TABLE IF NOT EXISTS auth.users (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid()
        );

        CREATE OR REPLACE FUNCTION auth.uid() RETURNS UUID AS $$
        BEGIN
          RETURN NULLIF(current_setting('request.jwt.claims', true)::jsonb->>'sub', '')::UUID;
        EXCEPTION WHEN others THEN
          RETURN NULL;
        END;
        $$ LANGUAGE plpgsql SECURITY DEFINER;

        CREATE EXTENSION IF NOT EXISTS pgcrypto;
        """
    )

    for path in MIGRATION_FILES:
        with open(path, "r", encoding="utf-8") as sql_file:
            _psql(sql_file.read())

    # Tables dropped; keep role for other tests to avoid dependency issues

    # Inside _prepare_db fixture, (re)create non-superuser role with a known
    # password.  We **always** set/overwrite the PASSWORD so that an existing
    # role from earlier tests (with a different password) does not break the
    # authentication flow in CI.
    _psql(
        """
        DO $$
        BEGIN
          IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rls_test_user') THEN
            ALTER ROLE rls_test_user WITH LOGIN NOSUPERUSER PASSWORD 'postgres';
          ELSE
            CREATE ROLE rls_test_user LOGIN NOSUPERUSER PASSWORD 'postgres';
          END IF;
        END$$;

        GRANT USAGE ON SCHEMA public, auth TO rls_test_user;
        GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO rls_test_user;
        GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO rls_test_user;
        """
    )

    yield

    # Module-level cleanup – drop created tables to keep DB tidy (optional)
    _psql(
        """
        DROP TABLE IF EXISTS public.action_step_logs CASCADE;
        DROP TABLE IF EXISTS public.action_steps CASCADE;
        """
    )


# -------------------------
#        Test Cases
# -------------------------


@pytest.mark.integration
@pytest.mark.skipif(os.getenv("ACT") == "true", reason="Skip heavy DB test in ACT mode")
def test_happy_path_insert_select():
    """User can insert & select their own action step (RLS happy path)."""

    user_id = uuid.uuid4()
    _psql(f"INSERT INTO auth.users (id) VALUES ('{user_id}');")

    conn = _conn(user_id)
    with conn, conn.cursor() as cur:
        # Insert a valid action step for *this* user
        cur.execute(
            """
            INSERT INTO public.action_steps (user_id, category, description, frequency, week_start)
            VALUES (%s, 'Sleep', '7h sleep', 7,
                    date_trunc('week', timezone('utc', current_date))::date)
            RETURNING id;
            """,
            (str(user_id),),
        )
        step_id = cur.fetchone()[0]

    # Re-query to make sure row is visible
    with conn, conn.cursor() as cur:
        cur.execute("SELECT id FROM public.action_steps WHERE id = %s", (step_id,))
        assert cur.fetchone() is not None, "Inserted row not found for same user"
    conn.close()


@pytest.mark.integration
@pytest.mark.skipif(os.getenv("ACT") == "true", reason="Skip heavy DB test in ACT mode")
def test_insert_other_user_denied():
    """RLS blocks insert when user_id ≠ auth.uid()."""

    user_a = uuid.uuid4()
    user_b = uuid.uuid4()
    _psql(f"INSERT INTO auth.users (id) VALUES ('{user_a}'), ('{user_b}');")

    conn_b = _conn(user_b)
    with conn_b, conn_b.cursor() as cur:
        with pytest.raises(_real_psycopg2.errors.InsufficientPrivilege):
            cur.execute(
                """
                INSERT INTO public.action_steps (user_id, category, description, frequency, week_start)
                VALUES (%s, 'Nutrition', 'Eat veggies', 5,
                        date_trunc('week', timezone('utc', current_date))::date);
                """,
                (str(user_a),),
            )
    conn_b.close()


@pytest.mark.integration
@pytest.mark.skipif(os.getenv("ACT") == "true", reason="Skip heavy DB test in ACT mode")
def test_select_other_user_denied():
    """User should not see other users' rows."""

    user_a = uuid.uuid4()
    user_b = uuid.uuid4()
    _psql(f"INSERT INTO auth.users (id) VALUES ('{user_a}'), ('{user_b}');")

    # Insert row for user_a via superuser (bypass RLS)
    _psql(
        f"""
        INSERT INTO public.action_steps (user_id, category, description, frequency, week_start)
        VALUES ('{user_a}', 'Movement', '10k steps', 5,
                date_trunc('week', timezone('utc', current_date))::date);
        """
    )

    conn_b = _conn(user_b)
    with conn_b, conn_b.cursor() as cur:
        cur.execute("SELECT count(*) FROM public.action_steps;")
        visible = cur.fetchone()[0]
        assert visible == 0, "RLS leak: user_b sees other users' action steps"
    conn_b.close()


@pytest.mark.integration
@pytest.mark.skipif(os.getenv("ACT") == "true", reason="Skip heavy DB test in ACT mode")
def test_action_step_logs_rls():
    """RLS enforcement on action_step_logs via join to owner action_step."""

    user_a = uuid.uuid4()
    user_b = uuid.uuid4()
    _psql(f"INSERT INTO auth.users (id) VALUES ('{user_a}'), ('{user_b}');")

    # Insert action step for user_a (superuser bypass)
    insert_step_sql = f"""
        INSERT INTO public.action_steps (id, user_id, category, description, frequency, week_start)
        VALUES ('{uuid.uuid4()}', '{user_a}', 'Yoga', 'Sun salutations', 3,
                date_trunc('week', timezone('utc', current_date))::date)
        RETURNING id;
    """
    conn_super = _conn(None, superuser=True)
    with conn_super, conn_super.cursor() as cur:
        cur.execute(insert_step_sql)
        step_id = cur.fetchone()[0]
    conn_super.close()

    # ▶ Attempt insert log as *other* user – expect permission error
    conn_b = _conn(user_b)
    with conn_b, conn_b.cursor() as cur:
        with pytest.raises(_real_psycopg2.errors.InsufficientPrivilege):
            cur.execute(
                """
                INSERT INTO public.action_step_logs (action_step_id, completed_on)
                VALUES (%s, current_date);
                """,
                (str(step_id),),
            )
    conn_b.close()

    # ▶ Happy-path insert & select for owner
    conn_a = _conn(user_a)
    with conn_a, conn_a.cursor() as cur:
        cur.execute(
            """
            INSERT INTO public.action_step_logs (action_step_id, completed_on)
            VALUES (%s, current_date)
            RETURNING id;
            """,
            (str(step_id),),
        )
        log_id = cur.fetchone()[0]

    with conn_a, conn_a.cursor() as cur:
        cur.execute("SELECT id FROM public.action_step_logs WHERE id = %s;", (log_id,))
        assert cur.fetchone() is not None, "Owner cannot see their own log"
    conn_a.close()
