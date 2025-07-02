import os
import uuid
import psycopg2
import json

DB_CFG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": os.getenv("DB_PORT", "54322"),
    "database": os.getenv("DB_NAME", "postgres"),
    "user": os.getenv("DB_USER", "postgres"),
    "password": os.getenv("DB_PASSWORD", "postgres"),
}


def _get_conn(user_id: str | None = None):
    conn = psycopg2.connect(**DB_CFG)
    conn.autocommit = True
    if user_id:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT set_config('request.jwt.claims', %s, true)",
                (json.dumps({"sub": user_id}),),
            )
    return conn


def test_owner_can_insert_and_select_profile():
    user_id = str(uuid.uuid4())
    conn = _get_conn(user_id)

    try:
        with conn.cursor() as cur:
            # Insert own profile row
            cur.execute(
                "INSERT INTO public.profiles(id, onboarding_complete) VALUES (%s, false) ON CONFLICT DO NOTHING",
                (user_id,),
            )
            # Select back
            cur.execute(
                "SELECT onboarding_complete FROM public.profiles WHERE id = %s",
                (user_id,),
            )
            row = cur.fetchone()
            assert row is not None and row[0] is False
    finally:
        conn.close()


def test_stranger_cannot_select_others_profile():
    owner_id = str(uuid.uuid4())
    stranger_id = str(uuid.uuid4())
    owner_conn = _get_conn(owner_id)
    with owner_conn.cursor() as cur:
        cur.execute(
            "INSERT INTO public.profiles(id, onboarding_complete) VALUES (%s, true) ON CONFLICT DO NOTHING",
            (owner_id,),
        )
    owner_conn.close()

    stranger_conn = _get_conn(stranger_id)
    try:
        with stranger_conn.cursor() as cur:
            cur.execute(
                "SELECT * FROM public.profiles WHERE id = %s",
                (owner_id,),
            )
            data = cur.fetchall()
            assert len(data) == 0
    finally:
        stranger_conn.close()
