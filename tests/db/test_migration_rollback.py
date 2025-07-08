import os
import subprocess
import pytest

DB_CFG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": os.getenv("DB_PORT", "54322"),
    "database": os.getenv("DB_NAME", "test"),
    "user": os.getenv("DB_USER", "postgres"),
    "password": os.getenv("DB_PASSWORD", "postgres"),
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
                f"-U{DB_CFG['user']}",
                "-d",
                DB_CFG["database"],
                "-c",
                sql,
            ],
            check=True,
            text=True,
            env={**os.environ, "PGPASSWORD": DB_CFG["password"]},
        )

    dump_before = tmp_path / "before.sql"
    dump_after = tmp_path / "after.sql"

    # 1. Capture baseline dump
    with open(dump_before, "w") as f:
        subprocess.run(
            [
                "pg_dump",
                f"--host={DB_CFG['host']}",
                f"--port={DB_CFG['port']}",
                "--schema-only",
                "--dbname",
                DB_CFG["database"],
            ],
            check=True,
            stdout=f,
            env={**os.environ, "PGPASSWORD": DB_CFG["password"]},
        )

    # 2. Apply migration
    with open(MIGRATION_FILE, "r", encoding="utf-8") as sql_file:
        _psql(sql_file.read())

    # 3. Roll back by dropping created objects (simplified)
    rollback_sql = """
    drop trigger if exists audit_medical_history on public.medical_history cascade;
    drop trigger if exists audit_biometrics on public.biometrics cascade;
    drop trigger if exists audit_energy_rating_schedules on public.energy_rating_schedules cascade;

    drop table if exists public.medical_history cascade;
    drop table if exists public.biometrics cascade;
    drop table if exists public.energy_rating_schedules cascade;

    drop type if exists public.energy_rating_schedule cascade;
    """
    _psql(rollback_sql)

    # 4. Capture dump after rollback
    with open(dump_after, "w") as f:
        subprocess.run(
            [
                "pg_dump",
                f"--host={DB_CFG['host']}",
                f"--port={DB_CFG['port']}",
                "--schema-only",
                "--dbname",
                DB_CFG["database"],
            ],
            check=True,
            stdout=f,
            env={**os.environ, "PGPASSWORD": DB_CFG["password"]},
        )

    # 5. Assert dumps are equal
    with open(dump_before, "r", encoding="utf-8") as f1, open(
        dump_after, "r", encoding="utf-8"
    ) as f2:
        assert f1.read() == f2.read()
