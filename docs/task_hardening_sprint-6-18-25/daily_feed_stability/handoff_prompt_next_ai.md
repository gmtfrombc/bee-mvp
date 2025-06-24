# Handoff – Daily-Feed Stability (Session 004 → 005)

## Current state

- Main prod project: heavy `daily-content-generator` still times-out; nightly
  cron untouched.
- New project `srarhcjhjjgbdgfiazje` contains only:
  - `daily-content-generator` (9 kB bundle, early 202, **but cold-start still
    > 60 s**).
  - `health-ping` (tiny, returns 401 < 1 s → proves platform fine).
- Root cause: remaining remote `std/*` imports pulled at _runtime_ by
  `daily-content-generator` during first evaluation.

## Your mission

1. Open `supabase/functions/daily-content-generator/index.ts`.
2. Remove dynamic imports that reference `https://deno.land/std@...`.
   - Use plain `fetch` for the RPC in `updateJobStatus`.
   - Avoid `std/http/server.ts` completely – it is _not_ needed for outbound
     HTTP.
3. Confirm `deno info` (or CLI bundle log) shows **no external files
   downloaded** except the entry script.
4. Deploy to `srarhcjhjjgbdgfiazje` with `--no-verify-jwt`.
5. Test cold-start:
   ```bash
   curl -i -X POST https://srarhcjhjjgbdgfiazje.functions.supabase.co/daily-content-generator -d '{}'
   ```
   • Expect `202` in <1 s, and logs: `🌅 Starting…`, `✅ Responding 202 early`.
6. If OK, update helper script & docs with new URL; hand instructions back to
   human dev.

## Credentials available in shell

```bash
export SUPABASE_ACCESS_TOKEN=sbp_fbd2fa6bf6e6891328d9b8e6a0123d4cd95d9c30
export SERVICE_ROLE_JWT=<already exported above>
```

## Hard guard-rails

- Do **not** change nightly cron logic yet – only manual path.
- Keep bundle minimal (<15 kB). No supabase-js!
- Commit doc edits under
  `docs/task_hardening_sprint-6-18-25/daily_feed_stability/`.

Good luck! 🐝
