#!/usr/bin/env python3
"""Back-fill default 0-score rows in daily_engagement_scores for users missing a record on a given day.

Usage
-----
python scripts/backfill_momentum_rows.py --days 30 [--dry-run] [--endpoint https://XYZ.supabase.co]

Key Features
------------
1. Connects to Supabase using the SERVICE_ROLE_KEY (full DB access).
2. Iterates backwards N days from today, inserting a default momentum row for
   every *active* user that lacks a row for that date.
3. Uses batched INSERT … ON CONFLICT DO NOTHING queries to avoid locking –
   configurable via --batch-size (default 500).
4. "Dry-run" mode prints how many rows *would* be inserted without mutating the
   database.

Environment Variables
---------------------
SUPABASE_URL               – https://<project>.supabase.co  (or pass --endpoint)
SERVICE_ROLE_KEY | SUPABASE_SERVICE_ROLE_KEY – service-role JWT key
"""
from __future__ import annotations

import argparse
import datetime as dt
import os
import sys
from typing import Optional

try:
    # supabase-py ≥2
    from supabase import Client, create_client  # type: ignore
except ModuleNotFoundError:  # pragma: no cover – handled in unit tests via monkey-patch
    Client = object  # type: ignore

    def create_client(*_args, **_kwargs):  # type: ignore
        raise RuntimeError(
            "supabase-py not installed; install with `pip install supabase`"
        )


BATCH_SIZE_DEFAULT = 500


def _sql_insert_statement(date_iso: str, batch_size: int, offset: int) -> str:
    """Generate SQL that inserts up to *batch_size* rows for *date_iso*.

    The query works in two steps via a CTE:
    1. Identify *missing* user/date pairs.
    2. Insert default rows using INSERT … ON CONFLICT DO NOTHING.
    """
    return f"""
WITH missing AS (
    SELECT u.id AS user_id
    FROM auth.users u
    LEFT JOIN public.daily_engagement_scores d
        ON d.user_id = u.id AND d.score_date = '{date_iso}'::DATE
    WHERE d.user_id IS NULL
    LIMIT {batch_size} OFFSET {offset}
)
INSERT INTO public.daily_engagement_scores (user_id, score_date, final_score, momentum_state)
SELECT user_id, '{date_iso}'::DATE, 0.0, 'NeedsCare'
FROM missing
ON CONFLICT (user_id, score_date) DO NOTHING
RETURNING 1;"""


def _sql_count_missing(date_iso: str) -> str:
    """SQL that counts how many rows are missing for *date_iso*."""
    return f"""
SELECT COUNT(*) AS missing
FROM auth.users u
LEFT JOIN public.daily_engagement_scores d
    ON d.user_id = u.id AND d.score_date = '{date_iso}'::DATE
WHERE d.user_id IS NULL;"""


def _ensure_env(var_name: str) -> str:
    value = os.getenv(var_name)
    if not value:
        sys.exit(f"Environment variable {var_name} is required")
    return value


def process_day(
    client: Client, target_date: dt.date, dry_run: bool, batch_size: int
) -> int:
    """Insert default rows for *target_date*; returns number of rows inserted (or counted in dry-run)."""
    date_iso = target_date.isoformat()

    if dry_run:
        sql = _sql_count_missing(date_iso)
        res = client.sql(sql)
        count = int(res[0]["missing"]) if res else 0  # type: ignore[index]
        print(f"[{date_iso}] would insert {count} rows")
        return count

    # perform batched inserts until < batch_size returned
    total_inserted = 0
    offset = 0
    while True:
        sql = _sql_insert_statement(date_iso, batch_size, offset)
        res = client.sql(sql)
        inserted = len(res) if res else 0  # type: ignore[arg-type]
        total_inserted += inserted
        if inserted < batch_size:
            break
        offset += batch_size
    print(f"[{date_iso}] inserted {total_inserted} rows")
    return total_inserted


def run(
    days: int,
    endpoint: Optional[str] = None,
    dry_run: bool = False,
    batch_size: int = BATCH_SIZE_DEFAULT,
):
    base_url = endpoint or os.getenv("SUPABASE_URL")
    if not base_url:
        sys.exit("SUPABASE_URL env var or --endpoint required")

    key = os.getenv("SERVICE_ROLE_KEY") or os.getenv("SUPABASE_SERVICE_ROLE_KEY")
    if not key:
        sys.exit("SERVICE_ROLE_KEY or SUPABASE_SERVICE_ROLE_KEY env var required")

    client: Client = create_client(base_url, key)

    today = dt.date.today()
    overall_inserted = 0
    for i in range(1, days + 1):
        target_date = today - dt.timedelta(days=i)
        overall_inserted += process_day(client, target_date, dry_run, batch_size)

    action = "would be inserted" if dry_run else "inserted"
    print(f"Backfill complete: {overall_inserted} rows {action} across {days} days")


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Backfill daily_engagement_scores with default rows"
    )
    parser.add_argument(
        "--days",
        type=int,
        default=30,
        help="Number of previous days to backfill (default: 30)",
    )
    parser.add_argument(
        "--endpoint",
        help="Optional Supabase project URL (defaults to SUPABASE_URL env var)",
    )
    parser.add_argument(
        "--dry-run", action="store_true", help="Only count missing rows; do not insert"
    )
    parser.add_argument(
        "--batch-size",
        type=int,
        default=BATCH_SIZE_DEFAULT,
        help="Insert batch size (default: 500)",
    )
    return parser.parse_args()


if __name__ == "__main__":
    args = _parse_args()
    run(args.days, args.endpoint, args.dry_run, args.batch_size)
