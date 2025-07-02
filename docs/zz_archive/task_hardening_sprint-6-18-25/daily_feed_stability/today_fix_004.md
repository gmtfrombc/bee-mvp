# Daily-Feed Stability – Fix 004 (2025-06-21)

## Context / Goal

Manual invocations of `daily-content-generator` continued to hit Cloudflare's 30
s front-door timeout. Previous sessions proved the delay came from **cold-start
module evaluation** rather than user code.

## What we did today ✅

1. **Generated helper script** `scripts/manual_trigger_daily_content.sh` for
   one-click POSTs.
2. Created a **fresh Supabase project** `daily-content-generator`
   (`ref: srarhcjhjjgbdgfiazje`) containing only the target Edge Function.
3. Deployed the current 9 kB bundle (`--no-verify-jwt`).
4. Deployed a lightweight `health-ping` Edge Function to the same project →
   returns `401` in < 1 s, proving platform health.
5. Re-tested `daily-content-generator` → still hangs ~60 s then CF cancels.

## Findings 🕵️‍♀️

- Even in an otherwise empty project the first request stalls, so the
  **remaining latency sits inside the function's own evaluation phase**.
- Deno downloads & type-checks a deep tree from `std/http` & `std/async` pulled
  in via dynamic imports (e.g. `updateJobStatus`'s fallback `fetch` helpers).
  This overshoots the 30 s limit before user code runs.

## Recommended next steps ▶️

1. **Remove remote std imports** – rewrite helper paths to use native `fetch` +
   minimal JSON handling.
2. Re-deploy to project `srarhcjhjjgbdgfiazje`; cold-start should then be < 500
   ms.
3. Verify with:
   ```bash
   curl -i -X POST https://srarhcjhjjgbdgfiazje.functions.supabase.co/daily-content-generator -d '{}'
   ```
   Expect `202 Accepted` + custom `✅ Responding 202 early` log.
4. Once manual trigger is stable, update pg_cron/pg_net URL and retire the heavy
   function in the main project.

---

_Recorded by assistant 04 – 2025-06-21_
