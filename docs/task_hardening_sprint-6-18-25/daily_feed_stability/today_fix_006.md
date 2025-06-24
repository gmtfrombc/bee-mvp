# Daily-Feed Stability – Fix 006 (2025-07-04)

## 1. Objectives for the session

- Eliminate remaining failures in nightly **daily-content-generator** pipeline.
- Ensure scheduled pg_cron job successfully queues work, Edge Function executes,
  and new row is written to `daily_feed_content`.

## 2. What was accomplished today

1. **Cold-start issue confirmed solved** – Edge Function bundle < 10 kB, ~0.8 s
   boot.
2. **Database fixes**
   - Added `request_id bigint` column to `public.content_generation_jobs`.
   - Extended pg_net TTL to 24 h to keep response logs.
   - Re-wrote `trigger_daily_content_generation()`:
     - Async `pg_net.http_post` → status `queued`.
     - Removed obsolete `content` column reference.
     - Added robust error handling.
3. **URL resolution hardening**
   - Created helper table `app_settings` with key `daily_content_generator_url`
     → project-specific Edge-Function endpoint.
   - Function now reads URL from that table and no longer defaults to
     `localhost`.
4. **Migration files committed & applied**
   - `20250704221500_fix_content_generation_function.sql`
   - `20250704223000_fix_url_fallback.sql`
5. **Manual test runs**
   - New job `b95c48d1-…` inserted with `status = queued`, `request_id = 23`.
   - `_http_response` previously showed ❌ "Couldn't connect to server"
     (pre-fix).

## 3. Current status / remaining problem

- Latest job stays **queued**; no row yet in `daily_feed_content`.
- `_http_response` table has only the earlier failed row (id 22). No entry for
  id 23 within 6 h window → indicates pg_net didn't finish or worker hasn't
  processed id 23 yet.
- `daily_feed_content` still last updated **2025-06-12**.

## 4. Hypothesis

Connection now reaches correct host, but Edge Function may be:

- Rejecting request (missing `service_role` auth header), or
- Returning >30 s, causing pg_net timeout (would appear with `timed_out = t`).

## 5. Next-step checklist

1. Query pg_net response for request id 23:
   ```sql
   select * from net._http_response where id = 23;
   ```
2. If no row → pg_net worker backlog; restart worker:
   ```sql
   select net.worker_restart();
   ```
3. If status_code >=400 → inspect Edge Function logs around timestamp.
4. Ensure **Authorization: Bearer <SERVICE_ROLE_SECRET>** header is passed.
5. Once response `202` received, verify job status flips to `completed`:
   ```sql
   select * from public.content_generation_jobs where id = 'b95c48d1-…';
   ```
6. Confirm insert into `daily_feed_content`.
7. Clean up old `running` rows (those before Fix 006) as needed.
