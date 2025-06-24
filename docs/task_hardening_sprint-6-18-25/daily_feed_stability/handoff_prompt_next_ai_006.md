## Handoff – Daily-Feed Stability (2025-07-04)

### Context / Goal

Nightly **daily-content-generator** pipeline must write a new row into
`daily_feed_content` via Edge Functions + pg_net. Cold-start fixed; DB side
largely refactored, but latest manual job (`b95c48d1-…`, req-id 23) remains
**queued** and content table still shows 2025-06-12.

### What was done today

1. Added `request_id` column; extended pg_net TTL to 24 h.
2. Reworked `trigger_daily_content_generation()` → async call, status `queued`.
3. Added `app_settings` table; stored correct `daily_content_generator_url`.
4. Patched function to read URL from settings.
5. Applied migrations `…_fix_content_generation_function.sql` and
   `…_fix_url_fallback.sql`.
6. Manual trigger now inserts job row with status `queued`, request_id = 23.
7. `_http_response` still only shows old failed entry (id 22 → localhost). id 23
   not yet present.

### Current symptoms

- Job row stays `queued`; no update to `daily_feed_content`.
- pg_net worker exists (pid shows).
- No `_http_response` row for id 23 within > 2 min window.

### Likely cause

Edge Function call not reaching runtime (DNS / firewall) **or** pg_net worker
backlog. URL is correct; next check is worker + response row.

### Immediate next steps

1. Query specific response id:
   ```sql
   select * from net._http_response where id = 23;
   ```
2. If NULL → restart pg_net worker and watch queue:
   ```sql
   select net.worker_restart();
   select * from net._http_response order by created desc limit 5;
   ```
3. If response appears with 4xx/5xx → open Edge Function logs ~timestamp; look
   for auth failure.
4. Ensure header `Authorization: Bearer <SERVICE_ROLE_SECRET>` is passed; else
   modify function headers.
5. Once status `202` is returned, job should auto-update to `completed`
   (function `update_job_status` is called by Edge Function).
6. Verify insert into `daily_feed_content`.

### Longer-term

- Add cron watchdog to alert if no row inserted by 04:00 UTC.
- Implement CI test that fires trigger against staging and asserts feed row.

Good luck!
