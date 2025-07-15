import os
import json
import subprocess
import uuid

import psycopg2 as _real_psycopg2

__all__ = ["_psql", "_conn"]

# ---------------------------------------------------------------------------
# Environment helpers
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Auto-bootstrap local Postgres container (see scripts/start_test_db.sh)
# ---------------------------------------------------------------------------

# Lazily populate DB_HOST / DB_PORT by invoking the helper script once.  This
# prevents the frequent "role \"postgres\" does not exist" error when the dev
# Postgres on 5432 belongs to Supabase instead of vanilla Postgres.


def _ensure_local_db():
    if os.getenv("DB_HOST") and os.getenv("DB_PORT"):
        return

    script_path = os.path.join(
        os.path.dirname(os.path.dirname(__file__)), "..", "scripts", "start_test_db.sh"
    )
    if not os.path.exists(script_path):
        # Fallback – nothing we can do automatically
        return

    try:
        import subprocess
        import re

        result = subprocess.run(
            ["bash", script_path], capture_output=True, text=True, check=True
        )
        for line in result.stdout.splitlines():
            m = re.match(r"export (DB_HOST|DB_PORT)=(.+)", line.strip())
            if m:
                os.environ[m.group(1)] = m.group(2)
    except Exception:
        # Silent fail – tests will attempt connection and raise meaningful error
        pass


_ensure_local_db()

# Use (possibly) updated environment variables
_PG_HOST = os.getenv("DB_HOST", "localhost")
_PG_PORT = os.getenv("DB_PORT", "5432")
_PG_DB = os.getenv("DB_NAME", "test")
_PG_SUPER_PW = os.getenv("DB_SUPER_PASSWORD", "postgres")

# Non-superuser test role used in RLS tests
_RLS_USER = os.getenv("RLS_TEST_USER", "rls_test_user")
_RLS_PW = os.getenv("RLS_TEST_PASSWORD", "postgres")


def _base_env() -> dict[str, str]:
    """Return a copy of *os.environ* with libpq variables populated."""

    env = dict(os.environ)
    env.setdefault("PGHOST", _PG_HOST)
    env.setdefault("PGPORT", _PG_PORT)
    env.setdefault("PGDATABASE", _PG_DB)
    return env


# ---------------------------------------------------------------------------
# Public helpers
# ---------------------------------------------------------------------------


def _psql(sql: str) -> None:
    """Execute *sql* via the *psql* CLI with **ON_ERROR_STOP**.

    Relies exclusively on libpq environment variables for connection details, so
    callers only need to make sure `DB_HOST/DB_PORT/...` are exported.
    """

    subprocess.run(
        ["psql", "-v", "ON_ERROR_STOP=1", "-q", "-f", "-"],
        input=sql,
        check=True,
        text=True,
        env={**_base_env(), "PGUSER": "postgres", "PGPASSWORD": _PG_SUPER_PW},
    )


def _conn(user_id: uuid.UUID | None = None, *, superuser: bool = False):
    """Return a psycopg2 connection.

    If *superuser* is *True*, connect as *postgres*; otherwise connect as the
    dedicated non-superuser role used for RLS tests.  If *user_id* is supplied,
    set `request.jwt.claims` so that `auth.uid()` returns that UUID within the
    session.
    """

    if superuser:
        creds = {"user": "postgres", "password": _PG_SUPER_PW}
    else:
        creds = {"user": _RLS_USER, "password": _RLS_PW}

    conn = _real_psycopg2.connect(
        host=_PG_HOST,
        port=_PG_PORT,
        dbname=_PG_DB,
        **creds,
    )

    if user_id:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT set_config('request.jwt.claims', %s, false)",
                (json.dumps({"sub": str(user_id)}),),
            )
    return conn
