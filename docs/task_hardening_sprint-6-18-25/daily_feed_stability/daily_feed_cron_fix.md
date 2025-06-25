# Daily Feed – Cron Pipeline Hardening

**Date:** 2025-06-24

## Context

The Momentum "Today Feed" relies on the Supabase Edge Function
`daily-content-generator` which is triggered automatically every night by
`pg_cron` (03:00 UTC primary / 04:00 UTC backup). For two days no automatic
content rows were produced, although manual invocations continued to work.

## Root-Cause Analysis

1. The PL/pgSQL helper `trigger_daily_content_generation()` resolved the
   function URL from the custom GUC `app.daily_content_generator_url`.
2. After a Postgres restart the GUC was **unset**, causing the fallback URL
   (`http://localhost:54321/...`) to be used.
3. Cron jobs still executed but received an HTTP 404 → no rows in
   `daily_feed_content` → empty Today Feed.
4. Subsequent Supabase linter scans also reported:
   - `security_definer_view` on `public.daily_feed_content_current`
   - `rls_disabled_in_public` for `public.app_settings`

## Fix Implementation

| Timestamp                                                      | Change                                                 | Notes |
| -------------------------------------------------------------- | ------------------------------------------------------ | ----- |
| `20250624000500`                                               | **Migration** `use_app_settings_for_generator_url.sql` |       |
| • Created `public.app_settings` table (key/value)              |                                                        |       |
| • Upserted the _public_ Edge Function URL                      |                                                        |       |
| • Re-implemented `trigger_daily_content_generation()` to read: |                                                        |       |

    1. custom GUC  
    2. `app_settings` fallback  
    3. localhost (dev) |

| `supabase db push` | Applied the migration through CLI using project secrets |
Non-interactive (`printf 'Y\n'`) | | Smoke test |
`curl -X POST https://<proj>.functions.supabase.co/daily-content-generator …` |
Returned `202 Accepted`, confirmed row in `content_generation_jobs` | |
`20250624190000` | **Migration** `security_fixes.sql` |\
• Dropped & recreated helper view without `SECURITY DEFINER`\
• Enabled RLS on `app_settings` + deny-all policy | | `20250624191500` |
**Migration** `fix_view_security_invoker_option.sql` | Recreated the view with
`WITH (security_invoker=true)` (PG15 syntax) |

## Outcome

✔ Nightly cron jobs will now fetch the correct Cloud Function URL even after a
restart.\
✔ Supabase linter reports **no remaining security errors**.\
✔ Manual trigger script (`scripts/manual_trigger_daily_content.sh`) untouched.

## Verification Steps

```sql
-- verify URL persists
a) select * from public.app_settings where key = 'daily_content_generator_url';
-- should return cloud URL

-- force-run generator (service-role JWT)
POST /daily-content-generator {"target_date":"YYYY-MM-DD","force_regenerate":true}

-- check latest row
select * from public.daily_feed_content order by generated_at desc limit 1;
```

## Operational Notes

- Upcoming nightly run @ 03:00 UTC will exercise the full path.
- Rollback: set GUC manually →
  `alter database ... set app.daily_content_generator_url = '...'`.
- Future migrations should prefer `app_settings` for non-secret runtime config.

---

_Author: BEE-MVP AI Pair-Programmer — Task Hardening Sprint 2025-06_
