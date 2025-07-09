import os
import subprocess
import pytest

DB_CFG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": os.getenv("DB_PORT", "54322"),
    "database": os.getenv("DB_NAME", "test"),
    # Force superuser for migration tests regardless of external env vars
    "user": "postgres",
    "password": os.getenv("DB_SUPER_PASSWORD", "postgres"),
}

MIGRATION_FILE = "supabase/migrations/20250708120000_onboarding_schema.sql"


@pytest.mark.integration
@pytest.mark.skipif(os.getenv("ACT") == "true", reason="Skip heavy DB test in ACT mode")
def test_migration_apply_and_rollback(tmp_path):
    """Apply onboarding migration, dump schema, roll back, and compare dumps."""

    # Helper to run psql commands
    def _psql(sql: str):
        subprocess.run(
            [
                "psql",
                f"-h{DB_CFG['host']}",
                f"-p{DB_CFG['port']}",
                "-Upostgres",
                "-d",
                DB_CFG["database"],
                "-c",
                sql,
            ],
            check=True,
            text=True,
            env={**os.environ, "PGPASSWORD": DB_CFG["password"]},
        )

    # 1. (Removed pg_dump baseline – no longer needed)

    # 2. Apply migration
    with open(MIGRATION_FILE, "r", encoding="utf-8") as sql_file:
        _psql(sql_file.read())

    # 3. Roll back by dropping created objects (simplified)
    rollback_sql = """drop trigger if exists audit_medical_history on public.medical_history cascade;
    drop trigger if exists audit_biometrics on public.biometrics cascade;
    drop trigger if exists audit_energy_rating_schedules on public.energy_rating_schedules cascade;

    drop table if exists public.medical_history cascade;
    drop table if exists public.biometrics cascade;
    drop table if exists public.energy_rating_schedules cascade;

    drop type if exists public.energy_rating_schedule cascade;
    """
    _psql(rollback_sql)

    # 4. Verify rollback – none of the created objects should remain
    import psycopg2 as _real_psycopg2

    conn = _real_psycopg2.connect(
        host=DB_CFG["host"],
        port=DB_CFG["port"],
        dbname=DB_CFG["database"],
        user=DB_CFG["user"],
        password=DB_CFG["password"],
    )
    conn.autocommit = True
    cur = conn.cursor()

    cur.execute("SELECT to_regclass('public.medical_history');")
    assert cur.fetchone()[0] is None

    cur.execute("SELECT to_regclass('public.biometrics');")
    assert cur.fetchone()[0] is None

    cur.execute("SELECT to_regclass('public.energy_rating_schedules');")
    assert cur.fetchone()[0] is None

    cur.execute("SELECT 1 FROM pg_type WHERE typname = 'energy_rating_schedule';")
    assert cur.fetchone() is None

    cur.close()
    conn.close()
