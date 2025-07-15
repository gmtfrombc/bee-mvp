import os
import uuid

import pytest

from tests.db.db_utils import _psql, _conn

# Ordered list of migration files needed for Action Steps + helper view
MIGRATION_FILES = [
    # auth stub migration replaced by inline SQL below for speed
    # creates _shared.audit_log & function
    "supabase/migrations/20240722115000_shared_audit_function.sql",
    "supabase/migrations/20250714140000_init_action_steps.sql",
    "supabase/migrations/20250714141000_action_step_logs.sql",
    "supabase/migrations/20250714142000_action_step_triggers.sql",
    "supabase/migrations/20250714143000_action_step_rls.sql",
    "supabase/migrations/20250714145000_current_week_action_steps_view.sql",
]


@pytest.mark.integration
@pytest.mark.skipif(os.getenv("ACT") == "true", reason="Skip heavy DB test in ACT mode")
def test_current_week_action_steps_view():
    """Happy-path + RLS enforcement for current_week_action_steps view."""

    # 1️⃣  Apply migrations in order (idempotent)
    # Inline minimal Supabase auth stub so later migrations referencing auth.users/auth.uid() succeed.
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

    # Ensure dedicated non-superuser role exists for RLS assertions
    _psql(
        """
        DO $$
        BEGIN
          IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rls_test_user') THEN
            CREATE ROLE rls_test_user LOGIN PASSWORD 'postgres';
          END IF;
          GRANT USAGE ON SCHEMA public, auth TO rls_test_user;
          GRANT SELECT ON ALL TABLES IN SCHEMA public TO rls_test_user;
        END$$;
        """
    )

    # 2️⃣  Prepare sample data (bypass RLS using superuser)
    user_a = uuid.uuid4()
    user_b = uuid.uuid4()

    # Insert stub users to satisfy FK constraints
    _psql(f"INSERT INTO auth.users (id) VALUES ('{user_a}'), ('{user_b}');")

    # Insert current-week action steps
    for category, desc, freq, weeks_delta, u in [
        ("Nutrition", "Eat 5 veggies", 5, 0, user_a),
        ("Sleep", "7h sleep", 7, 0, user_a),
        ("Movement", "10k steps", 5, 0, user_b),
        ("Yoga", "Sun salutations", 3, -7, user_a),  # previous week
    ]:
        _psql(
            f"""
            INSERT INTO public.action_steps (id, user_id, category, description, frequency, week_start)
            VALUES (
              '{uuid.uuid4()}',
              '{u}',
              '{category}',
              '{desc}',
              {freq},
              (date_trunc('week', timezone('utc', current_date)) + INTERVAL '{weeks_delta} days')::date
            );
            """
        )

    # Fetch one of user_a's current-week step ids to attach logs
    conn_super = _conn(None, superuser=True)
    with conn_super.cursor() as cur:
        cur.execute(
            """
            SELECT id FROM public.action_steps
            WHERE user_id = %s
              AND week_start = date_trunc('week', timezone('utc', current_date))::date
            LIMIT 1;
            """,
            (str(user_a),),
        )
        step_id = cur.fetchone()[0]
    conn_super.close()

    # Insert two completion logs for that step
    _psql(
        f"""
        INSERT INTO public.action_step_logs (id, action_step_id, completed_on)
        VALUES
          ('{uuid.uuid4()}', '{step_id}', current_date),
          ('{uuid.uuid4()}', '{step_id}', current_date + INTERVAL '1 day');
        """
    )

    # 3️⃣  Query as user_a (RLS applied via jwt.claims)
    conn_a = _conn(user_a)
    with conn_a.cursor() as cur:
        cur.execute(
            "SELECT id, completed_count FROM public.current_week_action_steps ORDER BY id;"
        )
        rows = cur.fetchall()
        assert (
            len(rows) == 2
        ), "Expected exactly 2 action steps for user_a in current week"
        # Find row with completed_count = 2
        counts = [r[1] for r in rows]
        assert 2 in counts and 0 in counts, "completed_count aggregation incorrect"
    conn_a.close()

    # 4️⃣  Query as user_b – should see only their own one row, count 0
    conn_b = _conn(user_b)
    with conn_b.cursor() as cur:
        cur.execute("SELECT count(*) FROM public.current_week_action_steps;")
        visible = cur.fetchone()[0]
        assert visible == 1, "RLS leak: user_b sees other users' steps"
    conn_b.close()

    # 5️⃣  Cleanup: drop helper view to keep DB clean (optional)
    _psql("DROP VIEW IF EXISTS public.current_week_action_steps;")
