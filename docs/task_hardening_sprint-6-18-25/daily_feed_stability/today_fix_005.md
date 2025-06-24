# Today Fix 005 – Daily-Feed Stability (2025-06-21)

## Context

Edge Function `daily-content-generator` was experiencing 60 s+ cold-start delays
on a slim staging project (`srarhcjhjjgbdgfiazje`) because it fetched
`deno.land/std/*` modules at runtime.

## What we found

- Import graph still included dynamic calls to `std/http/server.ts` via
  `Deno.serve` default polyfill.
- No HTTP server was started, so the request hung until the edge supervisor
  killed the worker (~150 s).

## Fix applied

1. **Removed all remote `std/*` imports** and verified `deno info` shows _0
   external files_.
2. Wrapped the handler in `Deno.serve(handler)` and exported the handler so
   tests continue to pass.
3. Set `maxDuration` → `10` s (defensive cap, not 0 which can cause force-kill
   before respond).
4. Deployed with:
   ```bash
   supabase functions deploy daily-content-generator \
     --project-ref srarhcjhjjgbdgfiazje \
     --no-verify-jwt \
     --import-map supabase/functions/daily-content-generator/import_map.json \
     --use-api
   ```

## Outcome

- Cold-start latency: **~0.8 s** (measured with `curl -i -X POST …`).
- Response: `202` + JSON `{success:true, queued:true …}`.
- Bundle size: **≈ 11 kB**.

## Next steps

- Update helper scripts / manual triggers to use the new URL:
  `https://srarhcjhjjgbdgfiazje.functions.supabase.co/daily-content-generator`.
- Monitor the function for 24 h (Cloudflare + Supabase logs) to confirm no
  regressions.
- Once validated, re-enable nightly cron job to hit this slim project or migrate
  fix back to prod project.
- Optional: clean up local `serve` tasks
  (`pkill -f 'supabase functions serve'`).
