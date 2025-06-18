
# 🛠️ Supabase Edge Function – Root‑Cause Analysis & Action Plan

## 1. 🧩 Problem Summary

- **504 Gateway Timeout**, but only “booted” / “shutdown” logs appear → the function isn't starting fast enough to reach your handler.
- Local emulation (`supabase functions serve…`) logs:
  ```
  WorkerRequestCancelled: request has been cancelled by supervisor
  wall clock duration reached … (in_flight_req_exists = true)
  ```
  → Cold‑start compile time exceeds the 30 s runtime limit.

## 2. ✅ Diagnosis

| Observation                                | Meaning                               |
|-------------------------------------------|----------------------------------------|
| No handler logs appearing before 30 s     | Deno runtime aborted startup           |
| Local 30–45 s compile time                | Large dependencies delaying cold start |
| Removing heavy imports didn’t fix it      | Bundled dependencies still heavy       |

This aligns with known behavior: large imports cause early timeouts.

## 3. 🎯 Fix Strategy

### A. Strip heavy dependencies
- Fully remove `supabase-js` imports.
- Use raw `fetch(...)` to call your Postgres RPC via REST.

### B. Keep the bundle minimal
- Stick to Deno core and fetch APIs only (compile in <1 s).

### C. Validate locally
```bash
supabase functions serve daily-content-generator --debug
curl -i -X POST -H "Content-Type: application/json" \
  -d '{"target_date":"2025-06-17"}' \
  http://localhost:54321/functions/v1/daily-content-generator
```
Expect `202 Accepted` within <1 s and logs:
```
🌅 Starting daily content generation for …
🚀 Queuing downstream generation …
```

### D. Deploy & retest
- Confirm fast `202` in production.
- Verify you see the queue logs and no more 504.

### E. Optional: add warm‑up ping
Implement scheduled pings to reduce cold-starts.

## 4. 🔀 Alternate Strategies

1. **Dynamic import `supabase-js` on error paths** (still delayed).
2. **Pre-bundle dependencies via `deno.json`** and deploy with CLI v1.215+.
3. **Stick with `fetch`** — fastest and simplest solution.

## 5. ✅ Immediate Steps

1. Remove all `supabase-js` imports.
2. Refactor RPC logic to use `fetch(...)`.
3. Test locally for fast startup.
4. Deploy to production and validate.
5. (Optional) Add scheduled warm-ups.

---

**Bottom line**: Cold‑start timeouts stem from heavy compile-time dependencies. Stripping them will keep startup under 30 s. I can prepare the code diff next for swift implementation.
