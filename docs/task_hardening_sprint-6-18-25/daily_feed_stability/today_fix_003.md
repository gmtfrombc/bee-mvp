# Daily-Feed Stability – Debug Session 003

Date: 2025-06-21\
Engineer: o3-AI session

## What was done this round ✅

1. **Stripped heavy deps** – removed `@supabase/supabase-js` from
   `daily-content-generator` (+ `-dev`) and replaced with a lightweight
   PostgREST `fetch` on the error-path. Bundle size dropped **699 kB → 9 kB**.
2. **Added import map** – `supabase/functions/import_map.json` now pins shared
   deps for all Edge Functions.
3. **Background execution** – wrapped downstream call to `ai-coaching-engine` in
   `EdgeRuntime.waitUntil()` so the handler returns a `202` immediately while
   the long job runs in the background.
4. **Resilience tweaks** • Provided LOCAL fallbacks for `SUPABASE_URL` /
   `SERVICE_ROLE_KEY` so `supabase functions serve` works even without
   `supabase start`.\
   • Extra console logs (`📝`, `✅`) to trace handler reach & early response.
5. **Deployed** the slim bundle to production (`daily-content-generator`).
6. **Local investigation** – discovered `functions serve` transpires **all 25
   functions** → first compile ≈ 2 min; curl requests hang during that compile.

## Key findings 🕵️‍♂️

- The handler itself never logs (no `🌅` banner) when curl hangs → request
  doesn't reach user code yet.
- Local stall is purely the massive first-time TypeScript compile. Once cached,
  requests should be instant.
- In production we still see Cloudflare 30 s gateway timeout, but Edge-platform
  _boot_ log is 21 ms (bundle is tiny). No **Invoke** log appears → suggests the
  request is never completed (likely still awaiting module graph analysis due to
  many cross-function imports, or downstream `fetch` waits >30 s).

## Recommendations / Next steps ➡️

1. **Isolate compile scope locally** for faster iteration:
   ```bash
   SUPABASE_FUNCTIONS_PATH=supabase/functions/daily-content-generator \
     supabase functions serve daily-content-generator --no-verify-jwt
   ```
2. Let the first compile finish (≈2 min), verify you now get:
   ```
   🌅 Starting daily content generation …
   ✅ Responding 202 early
   ```
   and curl shows `202`.
3. If local OK, _redeploy_ (bundle unchanged) and tail runtime logs:
   ```bash
   supabase functions logs daily-content-generator --since 10m
   ```
   Look for **Invoke** log and our custom banners.
4. If prod still times out with no Invoke log:
   - Check CF routing / auth header length.
   - Confirm `ai-coaching-engine` reachable from Edge (try short `fetch` to
     `/health`).
5. Longer-term: split "monster" functions into separate project repo or use
   per-function folder to keep compile times low.

---

Refer to **today_fix_001.md** and **today_fix_002.md** for earlier context.
