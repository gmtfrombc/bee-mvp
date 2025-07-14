#!/usr/bin/env python3
"""RLS Smoke-Test for _shared.audit_log

Verifies that row-level security is enabled and that regular application roles
cannot read the audit table. The test is skipped in GitHub Actions until a
non-superuser fixture is provisioned.
"""
import os
import psycopg2
import pytest
import json

pytestmark = pytest.mark.skip(
    reason="Audit-log RLS smoke-test needs dedicated DB fixture; skipped in CI"
)

DB_CFG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": os.getenv("DB_PORT", "54322"),
    "database": os.getenv("DB_NAME", "postgres"),
    "user": os.getenv("DB_USER", "postgres"),
    "password": os.getenv("DB_PASSWORD", "postgres"),
}


def _conn(user_id: str | None = None):
    conn = psycopg2.connect(**DB_CFG)
    conn.autocommit = True
    if user_id:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT set_config('request.jwt.claims', %s, true)",
                (json.dumps({"sub": user_id}),),
            )
    return conn


def test_rls_enabled_and_blocking():
    """Ensure audit_log has RLS and anonymous/regular roles cannot read."""
    anonymous_conn = _conn(None)
    with anonymous_conn.cursor() as cur:
        # Check RLS flag
        cur.execute(
            "SELECT relrowsecurity FROM pg_class WHERE relname = '_shared.audit_log'::regclass::text.split('.')[-1] LIMIT 1"
        )
        rls_enabled = cur.fetchone()[0]
        assert rls_enabled, "RLS should be enabled on _shared.audit_log"

        # Attempt to read as anonymous (should fail)
        with pytest.raises(Exception):
            cur.execute("SELECT * FROM _shared.audit_log LIMIT 1")
    anonymous_conn.close()
