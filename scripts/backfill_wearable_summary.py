#!/usr/bin/env python3
"""Back-fill steps_total & hrv_avg columns in wearable_daily_summary.

Usage:
    python scripts/backfill_wearable_summary.py --days 90 [--endpoint https://XYZ.supabase.co]

The script iterates backwards from today (exclusive) for N days and calls the
`wearable-daily-summarizer` Edge Function with the `date` query param.  It
requires env vars SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY (or SERVICE_ROLE_KEY).

Example:
    SUPABASE_URL=https://abc.supabase.co \
    SERVICE_ROLE_KEY=ey... \
    python scripts/backfill_wearable_summary.py --days 30
"""
from __future__ import annotations

import argparse
import datetime as dt
import os
import sys
from typing import Optional

import requests  # type: ignore


def call_summarizer(base_url: str, key: str, date: str) -> bool:
    url = f"{base_url}/functions/v1/wearable-daily-summarizer?date={date}"
    headers = {
        "apikey": key,
        "Authorization": f"Bearer {key}",
    }
    try:
        res = requests.get(url, headers=headers, timeout=30)
        res.raise_for_status()
        print(
            f"[{date}] status={res.status_code} processed={res.json().get('processed')}")
        return True
    except Exception as err:  # pylint: disable=broad-except
        print(f"[{date}] FAILED → {err}", file=sys.stderr)
        return False


def run(days: int, endpoint: Optional[str] = None):
    base_url = endpoint or os.getenv("SUPABASE_URL")
    if not base_url:
        sys.exit("SUPABASE_URL env var or --endpoint required")
    key = os.getenv("SERVICE_ROLE_KEY") or os.getenv(
        "SUPABASE_SERVICE_ROLE_KEY")
    if not key:
        sys.exit("SERVICE_ROLE_KEY or SUPABASE_SERVICE_ROLE_KEY env var required")

    today = dt.date.today()
    success, total = 0, 0
    for i in range(1, days + 1):
        target_date = today - dt.timedelta(days=i)
        ok = call_summarizer(base_url, key, target_date.isoformat())
        success += int(ok)
        total += 1
    print(f"Backfill complete: {success}/{total} days succeeded")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Backfill wearable_daily_summary via edge function calls")
    parser.add_argument("--days", type=int, default=30,
                        help="Number of previous days to backfill (default: 30)")
    parser.add_argument(
        "--endpoint", help="Optional Supabase project URL (defaults to SUPABASE_URL env var)")
    args = parser.parse_args()

    run(args.days, args.endpoint)
