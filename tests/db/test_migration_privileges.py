# pytest integration test to ensure migrations succeed under non-superuser that lacks CREATE privilege on auth schema

import os
import subprocess

import psycopg2 as _real_psycopg2
import pytest

DB_CFG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": os.getenv("DB_PORT", "54322"),
    "database": os.getenv("DB_NAME", "test"),
    "user": "postgres",  # superuser for setup only
    "password": os.getenv("DB_SUPER_PASSWORD", "postgres"),
}

RESTRICTED_ROLE = "migration_runner"
RESTRICTED_PW = os.getenv("TEST_ROLE_PASSWORD", "postgres")

MIGRATION_STUB = "supabase/migrations/20240101000000_init_supabase_auth.sql"


def _psql(sql: str, *, user: str, password: str) -> None:
    subprocess.run(
        [
            "psql",
            f"-h{DB_CFG['host']}",
            f"-p{DB_CFG['port']}",
            f"-U{user}",
            "-d",
            DB_CFG["database"],
            "-v",
            "ON_ERROR_STOP=1",
            "-q",
            "-c",
            sql,
        ],
        check=True,
        text=True,
        env={**os.environ, "PGPASSWORD": password},
    )


@pytest.mark.integration
@pytest.mark.skipif(os.getenv("ACT") == "true", reason="Skip heavy DB test in ACT mode")
def test_migration_stub_runs_with_restricted_role(tmp_path):
    """Attempt to apply auth stub migration with a role that cannot CREATE in auth schema."""

    # 1️⃣  Ensure restricted role exists & lacks CREATE on auth schema
    _psql(
        f"""
        DO $$
        BEGIN
          IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '{RESTRICTED_ROLE}') THEN
            CREATE ROLE {RESTRICTED_ROLE} LOGIN PASSWORD '{RESTRICTED_PW}';
          END IF;
          GRANT USAGE ON SCHEMA auth TO {RESTRICTED_ROLE};
          REVOKE CREATE ON SCHEMA auth FROM {RESTRICTED_ROLE};
          GRANT CONNECT ON DATABASE {DB_CFG['database']} TO {RESTRICTED_ROLE};
          GRANT CREATE ON DATABASE {DB_CFG['database']} TO {RESTRICTED_ROLE};
        END$$;
        """,
        user="postgres",
        password=DB_CFG["password"],
    )

    # Ensure stub auth.users exists to mimic Supabase cloud
    _psql(
        "CREATE TABLE IF NOT EXISTS auth.users(id UUID PRIMARY KEY);",
        user="postgres",
        password=DB_CFG["password"],
    )

    # 2️⃣  Apply migration as restricted role – should succeed (skip table creation)
    subprocess.run(
        [
            "psql",
            f"-h{DB_CFG['host']}",
            f"-p{DB_CFG['port']}",
            f"-U{RESTRICTED_ROLE}",
            "-d",
            DB_CFG["database"],
            "-v",
            "ON_ERROR_STOP=1",
            "-q",
            "-f",
            MIGRATION_STUB,
        ],
        check=True,
        text=True,
        env={**os.environ, "PGPASSWORD": RESTRICTED_PW},
    )

    # 3️⃣  Sanity – table exists (created earlier by superuser or Supabase), migration did not fail
    conn = _real_psycopg2.connect(
        host=DB_CFG["host"],
        port=DB_CFG["port"],
        dbname=DB_CFG["database"],
        user="postgres",
        password=DB_CFG["password"],
    )
    conn.autocommit = True
    cur = conn.cursor()
    cur.execute(
        "SELECT 1 FROM information_schema.tables WHERE table_schema='auth' AND table_name='users';"
    )
    assert cur.fetchone(), "auth.users should exist after migration"
    cur.close()
    conn.close()
