import os
import subprocess
from pathlib import Path

# Import real module to bypass conftest patching
import psycopg2 as _real_psycopg2
import pytest

import uuid
from psycopg2 import errors

# Database connection configuration – default values target the Supabase local emulator.
DB_CFG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": os.getenv("DB_PORT", "54322"),
    "database": os.getenv("DB_NAME", "test"),
    "user": os.getenv("DB_USER", "postgres"),
    "password": os.getenv("DB_PASSWORD", "postgres"),
}

# Ordered list of onboarding-related migration files to apply in this test suite
MIGRATION_FILES = [
    "supabase/migrations/20250708120000_onboarding_schema.sql",  # base tables + enum
    "supabase/migrations/20250708121000_onboarding_responses.sql",  # onboarding_responses
    "supabase/migrations/20250708122000_onboarding_responses_rls.sql",  # RLS policies
    "supabase/migrations/20250708123000_onboarding_responses_audit_trigger.sql",  # audit trigger
]


def _psql(sql: str) -> None:  # helper to execute raw SQL via psql CLI for ease
    """Execute *sql* against the configured database using the psql CLI."""

    subprocess.run(
        [
            "psql",
            f"-h{DB_CFG['host']}",
            f"-p{DB_CFG['port']}",
            f"-U{DB_CFG['user']}",
            "-d",
            DB_CFG["database"],
            "-v",
            "ON_ERROR_STOP=1",  # fail fast on any SQL error
            "-q",
            "-c",
            sql,
        ],
        check=True,
        text=True,
        env={**os.environ, "PGPASSWORD": DB_CFG["password"]},
    )


@pytest.mark.integration
@pytest.mark.skipif(os.getenv("ACT") == "true", reason="Skip heavy DB test in ACT mode")
def test_onboarding_schema_and_security(tmp_path):
    """Apply onboarding migrations then verify schema, RLS, and audit trigger."""

    # 1️⃣  Apply migrations in order
    for path in MIGRATION_FILES:
        with open(path, "r", encoding="utf-8") as sql_file:
            _psql(sql_file.read())

    # 2️⃣  Connect via real psycopg2 for assertions
    conn = _real_psycopg2.connect(
        host=DB_CFG["host"],
        port=DB_CFG["port"],
        dbname=DB_CFG["database"],
        user=DB_CFG["user"],
        password=DB_CFG["password"],
    )
    conn.autocommit = True
    cur = conn.cursor()

    # 3️⃣  Tables & enum exist
    cur.execute(
        """
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'onboarding_responses';
        """
    )
    assert cur.fetchone(), "onboarding_responses table missing"

    cur.execute(
        """
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'medical_history';
        """
    )
    assert cur.fetchone(), "medical_history table missing"

    cur.execute(
        """
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'biometrics';
        """
    )
    assert cur.fetchone(), "biometrics table missing"

    cur.execute(
        """
        SELECT 1 FROM pg_type WHERE typname = 'energy_rating_schedule';
        """
    )
    assert cur.fetchone(), "energy_rating_schedule enum missing"

    # 4️⃣  RLS enabled & policies present on onboarding_responses
    cur.execute(
        "SELECT relrowsecurity FROM pg_class WHERE relname = 'onboarding_responses';"
    )
    relrowsecurity = cur.fetchone()
    assert (
        relrowsecurity and relrowsecurity[0]
    ), "RLS not enabled on onboarding_responses"

    cur.execute(
        "SELECT COUNT(*) FROM pg_policies WHERE tablename = 'onboarding_responses';"
    )
    policy_count = cur.fetchone()[0]
    assert policy_count >= 2, "Expected at least 2 RLS policies on onboarding_responses"

    # 5️⃣  Audit trigger attached
    cur.execute("SELECT 1 FROM pg_trigger WHERE tgname = 'audit_onboarding_responses';")
    assert cur.fetchone(), "Audit trigger not found on onboarding_responses"

    cur.close()
    conn.close()

    # 6️⃣  Simple rollback to keep DB tidy (optional)
    rollback_sql = Path("tests/db/rollback_onboarding.sql")
    rollback_sql.write_text(
        """
        DROP TRIGGER IF EXISTS audit_onboarding_responses ON public.onboarding_responses CASCADE;

        DROP TABLE IF EXISTS public.onboarding_responses CASCADE;
        DROP TABLE IF EXISTS public.medical_history CASCADE;
        DROP TABLE IF EXISTS public.biometrics CASCADE;
        DROP TABLE IF EXISTS public.energy_rating_schedules CASCADE;

        DROP TYPE IF EXISTS public.energy_rating_schedule CASCADE;
        """,
        encoding="utf-8",
    )
    _psql(rollback_sql.read_text())


@pytest.mark.integration
@pytest.mark.skipif(os.getenv("ACT") == "true", reason="Skip heavy DB test in ACT mode")
def test_rls_denies_cross_user_access(tmp_path):
    """Verify RLS prevents another role from inserting/selecting other users' data."""

    # Apply migrations (idempotent if already applied)
    for path in MIGRATION_FILES:
        with open(path, "r", encoding="utf-8") as sql_file:
            _psql(sql_file.read())

    # Prepare a row belonging to user_a (superuser bypasses RLS for setup)
    user_a = uuid.uuid4()
    _psql(
        f"INSERT INTO public.onboarding_responses (user_id, answers) VALUES ('{user_a}', '{{}}');"
    )

    # Ensure a non-superuser role exists
    _psql(
        """
        DO $$
        BEGIN
          IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'rls_tester') THEN
            CREATE ROLE rls_tester LOGIN PASSWORD 'test';
          END IF;
        END$$;

        GRANT USAGE ON SCHEMA public TO rls_tester;
        GRANT SELECT, INSERT ON ALL TABLES IN SCHEMA public TO rls_tester;
        """
    )

    # Connect as rls_tester (subject to RLS)
    conn = _real_psycopg2.connect(
        host=DB_CFG["host"],
        port=DB_CFG["port"],
        dbname=DB_CFG["database"],
        user="rls_tester",
        password="test",
    )
    conn.autocommit = True
    cur = conn.cursor()

    # Attempt to SELECT rows (should return 0 due to RLS)
    cur.execute("SELECT * FROM public.onboarding_responses;")
    rows = cur.fetchall()
    assert rows == [], "RLS leak: non-owner role can see rows"  # expecting empty list

    # Attempt to INSERT row for different user → expect RLS violation
    user_b = uuid.uuid4()
    with pytest.raises(errors.InsufficientPrivilege):
        cur.execute(
            "INSERT INTO public.onboarding_responses (user_id, answers) VALUES (%s, '{}'::jsonb);",
            (str(user_b),),
        )

    cur.close()
    conn.close()


@pytest.mark.integration
@pytest.mark.skipif(os.getenv("ACT") == "true", reason="Skip heavy DB test in ACT mode")
def test_audit_trigger_logs_changes(tmp_path):
    """Ensure audit trigger records INSERT/UPDATE events in _shared.audit_log."""

    # Ensure migrations applied (idempotent)
    for path in MIGRATION_FILES:
        with open(path, "r", encoding="utf-8") as sql_file:
            _psql(sql_file.read())

    # Establish superuser connection to bypass RLS for setup/testing
    conn = _real_psycopg2.connect(
        host=DB_CFG["host"],
        port=DB_CFG["port"],
        dbname=DB_CFG["database"],
        user=DB_CFG["user"],
        password=DB_CFG["password"],
    )
    conn.autocommit = True
    cur = conn.cursor()

    # Baseline audit log count (only for onboarding_responses table)
    cur.execute(
        "SELECT COUNT(*) FROM _shared.audit_log WHERE table_name = 'onboarding_responses';"
    )
    before_count = cur.fetchone()[0]

    # Insert new row
    user_id = uuid.uuid4()
    cur.execute(
        "INSERT INTO public.onboarding_responses (user_id, answers) VALUES (%s, '{}'::jsonb) RETURNING id;",
        (str(user_id),),
    )
    inserted_id = cur.fetchone()[0]

    # Update the same row
    cur.execute(
        "UPDATE public.onboarding_responses SET answers = '{\"step\":1}'::jsonb WHERE id = %s;",
        (inserted_id,),
    )

    # Count after
    cur.execute(
        "SELECT COUNT(*) FROM _shared.audit_log WHERE table_name = 'onboarding_responses';"
    )
    after_count = cur.fetchone()[0]

    assert after_count >= before_count + 2, "Audit log did not record expected events"

    cur.close()
    conn.close()
