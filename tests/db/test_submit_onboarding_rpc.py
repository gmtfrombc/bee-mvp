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
    # Use superuser for migrations to avoid privilege errors
    "user": "postgres",
    "password": os.getenv("DB_SUPER_PASSWORD", "postgres"),
}

# Ordered list of migrations needed for this suite
MIGRATION_FILES = [
    "supabase/migrations/20250708120000_onboarding_schema.sql",  # base tables + enum
    "supabase/migrations/20250708121000_onboarding_responses.sql",  # onboarding_responses
    "supabase/migrations/20250708122000_onboarding_responses_rls.sql",  # RLS policies
    "supabase/migrations/20250708123000_onboarding_responses_audit_trigger.sql",  # audit trigger
    "supabase/migrations/20240722120000_v1.6.1_profiles.sql",  # profiles table
    "supabase/migrations/20240722130000_coach_memory_table.sql",  # coach_memory
    "supabase/migrations/20250722140000_submit_onboarding_rpc.sql",  # RPC under test
]


def _psql(sql: str) -> None:
    """Utility wrapper to execute raw SQL via the psql CLI (fail-fast)."""
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
            "-c",
            sql,
        ],
        check=True,
        text=True,
        env={**os.environ, "PGPASSWORD": DB_CFG["password"]},
    )


@pytest.mark.integration
@pytest.mark.skipif(os.getenv("ACT") == "true", reason="Skip heavy DB test in ACT mode")
def test_submit_onboarding_happy_path(tmp_path):
    """Happy-path: inserts responses, updates coach_memory, and flips flag."""

    # 1️⃣  Apply all required migrations (idempotent)
    for path in MIGRATION_FILES:
        with open(path, "r", encoding="utf-8") as sql_file:
            _psql(sql_file.read())

    # 2️⃣  Prepare user & profile rows
    user_id = uuid.uuid4()
    _psql(f"INSERT INTO auth.users(id) VALUES ('{user_id}');")
    # onboarding_complete defaults false
    _psql(f"INSERT INTO public.profiles(id) VALUES ('{user_id}');")

    # 3️⃣  Call RPC
    answers = {"q1": "foo", "q2": 42}
    conn = _real_psycopg2.connect(
        host=DB_CFG["host"],
        port=DB_CFG["port"],
        dbname=DB_CFG["database"],
        user=DB_CFG["user"],
        password=DB_CFG["password"],
    )
    conn.autocommit = True
    cur = conn.cursor()

    cur.execute(
        "SELECT public.submit_onboarding(%s, %s::jsonb, %s, %s, %s);",
        (
            str(user_id),
            json.dumps(answers),
            "intrinsic",
            "ready",
            "supportive",
        ),
    )
    result = cur.fetchone()[0]
    assert "success" in str(result), "RPC did not return success JSON"

    # 4️⃣  Assertions – data persisted & flags updated
    cur.execute(
        "SELECT 1 FROM public.onboarding_responses WHERE user_id = %s;", (str(user_id),)
    )
    assert cur.fetchone(), "onboarding_responses insert failed"

    cur.execute(
        "SELECT onboarding_complete FROM public.profiles WHERE id = %s;",
        (str(user_id),),
    )
    assert cur.fetchone()[0] is True, "profiles.onboarding_complete not set"

    cur.execute(
        "SELECT motivation_type FROM public.coach_memory WHERE user_id = %s;",
        (str(user_id),),
    )
    coach_row = cur.fetchone()
    assert coach_row and coach_row[0] == "intrinsic", "coach_memory upsert failed"

    cur.close()
    conn.close()


@pytest.mark.integration
@pytest.mark.skipif(os.getenv("ACT") == "true", reason="Skip heavy DB test in ACT mode")
def test_submit_onboarding_rollback(tmp_path):
    """Passing NULL answers triggers rollback – no side-effects expected."""

    # Apply migrations (idempotent)
    for path in MIGRATION_FILES:
        with open(path, "r", encoding="utf-8") as sql_file:
            _psql(sql_file.read())

    user_id = uuid.uuid4()
    _psql(f"INSERT INTO auth.users(id) VALUES ('{user_id}');")
    _psql(f"INSERT INTO public.profiles(id) VALUES ('{user_id}');")

    conn = _real_psycopg2.connect(
        host=DB_CFG["host"],
        port=DB_CFG["port"],
        dbname=DB_CFG["database"],
        user=DB_CFG["user"],
        password=DB_CFG["password"],
    )
    conn.autocommit = True
    cur = conn.cursor()

    with pytest.raises(Exception):
        cur.execute(
            "SELECT public.submit_onboarding(%s, NULL::jsonb, %s, %s, %s);",
            (str(user_id), "intrinsic", "ready", "supportive"),
        )

    # Verify no rows inserted / updated
    cur.execute(
        "SELECT COUNT(*) FROM public.onboarding_responses WHERE user_id = %s;",
        (str(user_id),),
    )
    assert (
        cur.fetchone()[0] == 0
    ), "onboarding_responses should remain empty after rollback"

    cur.execute(
        "SELECT onboarding_complete FROM public.profiles WHERE id = %s;",
        (str(user_id),),
    )
    assert (
        cur.fetchone()[0] is False
    ), "profiles.onboarding_complete should remain false after rollback"

    cur.execute(
        "SELECT COUNT(*) FROM public.coach_memory WHERE user_id = %s;", (str(user_id),)
    )
    assert cur.fetchone()[0] == 0, "coach_memory should remain empty after rollback"

    cur.close()
    conn.close()
