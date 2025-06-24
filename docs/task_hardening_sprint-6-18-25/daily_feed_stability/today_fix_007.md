# Daily-Feed Stability Fix 007 – 2025-06-21

## What we attempted today

1. **Verified pg_net reachability** – confirmed `daily-content-generator`
   returns `202` to pg_net.
2. **Extended background timeout** in the generator to 90 s and added
   diagnostics.
3. **Captured downstream errors** and surfaced them into
   `content_generation_jobs.error_message`.
4. **Iterated on Edge-Function URL configuration**
   - Moved from legacy `…/functions/v1/…` path to new `…functions.supabase.co`
     domain.
   - Discovered Sub-route stripping on the new domain ➜ reverted to v1 path.
5. **Secret management** – stored `SERVICE_ROLE_KEY` and
   `AI_COACHING_ENGINE_URL` as Supabase secrets.
6. **Redeployed** `daily-content-generator` multiple times after each change.
7. **Observed downstream 400 error** →
   `Missing required fields: user_id, message` coming from
   **ai-coaching-engine** root path → indicates incorrect sub-route.

## Current status (end-of-session)

| Component                     | Status                               |
| ----------------------------- | ------------------------------------ |
| pg_net ➜ daily-content-gen    | ✅ 202 Accepted                      |
| daily-content-gen ➜ ai-engine | ❌ 400 (wrong endpoint)              |
| Job row update                | Stuck at `failed` with error message |
| `daily_feed_content` row      | **Not yet inserted**                 |

Latest `error_message` example:

```
Downstream status 400: {"error":"Missing required fields: user_id, message"}
```

## Root cause identified

Supabase strips path segments **after** the first slash when calling a function
via the `…functions.supabase.co` domain. Our request therefore hits the AI
engine **root** path (conversation), not the `/generate-daily-content`
controller.

**Correct call syntax:**

```
https://<proj>.supabase.co/functions/v1/ai-coaching-engine:generate-daily-content
```

(note the `:` before the sub-route).

## Next steps (handoff)

1. **Set secret to full v1 path with colon syntax**
   ```bash
   supabase secrets set \
     --project-ref okptsizouuanwnpqjfui \
     AI_COACHING_ENGINE_URL=https://okptsizouuanwnpqjfui.supabase.co/functions/v1/ai-coaching-engine:generate-daily-content
   ```
2. **Edit generator fetch** – change
   ```ts
   fetch(`${aiCoachingEngineUrl}/generate-daily-content`, …)
   ```
   to simply
   ```ts
   fetch(aiCoachingEngineUrl, …)
   ```
   (the route is already included).
3. **Redeploy** `supabase/functions/daily-content-generator`.
4. **Trigger manual run**:
   ```sql
   SELECT trigger_daily_content_generation(current_date, FALSE, 'manual_colon_path');
   ```
5. Expect job row ➜ `completed` and new row in `daily_feed_content`.
6. Delete obsolete `queued`/`failed` rows once confirmed.

---

## Technical hand-off for next AI assistant

- File touched today: `supabase/functions/daily-content-generator/index.ts` –
  diagnostics & 90 s timeout already in place.
- Secrets currently present:
  - `SERVICE_ROLE_KEY` ✅
  - `AI_COACHING_ENGINE_URL` ⚠️ **needs colon-path value** as above.
- No database schema changes pending.
- All troubleshooting is now inside Supabase; no Flutter app changes needed.

Focus on applying the colon-path secret, redeploying the generator, and
confirming the pipeline end-to-end. Once a `completed` job and a fresh
`daily_feed_content` row appear, clean up the logs and close this ticket.
