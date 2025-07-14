import os
import subprocess
import uuid
import json

import psycopg2 as _real_psycopg2
import pytest

# Database connection configuration – mirrors other DB tests
DB_CFG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": os.getenv("DB_PORT", "54322"),
    "database": os.getenv("DB_NAME", "test"),
    "user": os.getenv("DB_USER", "postgres"),  # superuser for setup
    "password": os.getenv("DB_PASSWORD", "postgres"),
}

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


def _psql(sql: str) -> None:
    """Execute raw *sql* against the configured database via `psql` CLI."""

    subprocess.run(
        [
            "psql",
            f"-h{DB_CFG['host']}",
            f"-p{DB_CFG['port']}",
            f"-U{DB_CFG['user']}",
            "-d",
            DB_CFG["database"],
            "-v",
            "ON_ERROR_STOP=1",
            "-q",
            "-f",
            "-",  # read SQL from stdin
        ],
        input=sql,
        check=True,
        text=True,
        env={**os.environ, "PGPASSWORD": DB_CFG["password"]},
    )


def _conn(user_id: uuid.UUID | None = None):
    """Return psycopg2 connection; if *user_id* provided sets `auth.uid()`."""
    conn = _real_psycopg2.connect(
        host=DB_CFG["host"],
        port=DB_CFG["port"],
        dbname=DB_CFG["database"],
        user=DB_CFG["user"],  # superuser but we simulate RLS via jwt.claims
        password=DB_CFG["password"],
    )
    # Keep autocommit disabled so that `set_config` with `is_local = true`
    # remains visible for subsequent statements executed within the same
    # connection (otherwise the setting is cleared after each autocommitted
    # statement and `auth.uid()` would return NULL).
    #
    # NOTE: We intentionally *do not* call `conn.autocommit = True` here.
    # Psycopg2 defaults to a transaction-scoped connection which is exactly
    # what we need for the RLS tests below.
    #
    # If you need autocommit semantics for a specific operation, create a
    # dedicated cursor/connection instead of toggling this flag globally.
    #
    # See https://www.postgresql.org/docs/current/functions-admin.html#FUNCTIONS-ADMIN-SET for details.

    if user_id:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT set_config('request.jwt.claims', %s, true)",
                (json.dumps({"sub": str(user_id)}),),
            )
    return conn


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
    conn_super = _conn(None)
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
