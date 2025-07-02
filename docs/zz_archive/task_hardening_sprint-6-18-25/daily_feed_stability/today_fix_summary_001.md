# Daily-Feed Stability – Consolidated Summary (as of 2025-06-21)

## 1. Context

The `daily-content-generator` Supabase Edge Function is responsible for
preparing the personalised _Today Feed_ each night (scheduled via
`pg_cron/pg_net`) and on-demand when triggered manually. Throughout 20–21 June
the function suffered from severe cold-start delays (> 30 s) that resulted in
Cloudflare gateway time-outs, leaving both automated and manual runs in an error
state.

---

## 2. Work Completed to Date

| Step | Date          | Key Actions                                                                                                                                                                                              | Outcome                                                                                                                |
| ---- | ------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| 001  | 2025-06-20    | • Extended `pg_net` timeout to 30 s.<br/>• Deployed smoke test function → confirmed platform latency OK.<br/>• Discovered worker boots but **handler never executes**; suspected module evaluation hang. | Identified cold-start module evaluation as the root cause.                                                             |
| 002  | 2025-06-20/21 | • Upgraded Supabase CLI.<br/>• Local `supabase functions serve --debug` traces showed massive remote dependency fetch (> 150 modules).                                                                   | Proved that external module graph exceeded Cloudflare's 30 s isolate boot limit.                                       |
| 003  | 2025-06-21    | • Removed heavy deps (`@supabase/supabase-js`, `jose`).<br/>• Added shared `import_map.json`.<br/>• Implemented early `202` response via `EdgeRuntime.waitUntil()`.                                      | Bundle shrank **699 kB → 9 kB**; still observed time-outs in production, pointing to remaining remote `std/*` imports. |
| 004  | 2025-06-21    | • Deployed the slim bundle into a fresh, single-function project (`srarhcjhjjgbdgfiazje`).                                                                                                               | Confirmed remaining latency caused by dynamic `std/http` & `std/async` imports.                                        |
| 005  | 2025-06-21    | • Eliminated **all** remote `std/*` imports.<br/>• Wrapped handler in `Deno.serve()` and set `maxDuration = 10 s`.<br/>• Deployed with fully pinned `import_map.json`.                                   | Cold-start latency **≈ 0.8 s**; manual POST now returns `202 Accepted` reliably.                                       |

---

## 3. Current Status

1. **Manual triggers:** Stable — respond in < 1 s with early 202 and background
   processing.
2. **Scheduled nightly cron job:** **❌ Failed** during the most recent
   overnight run; no Invocation logs recorded. The failure path and error
   details still need root-cause analysis.
3. **Codebase health:** Multiple experimental clones (`*-dev`, `*-smoke`,
   standalone project copies) and helper scripts now exist, increasing
   maintenance overhead.

---

## 4. Outstanding Issues

• Root-cause the overnight cron failure (environment variables, auth, or
cold-start race?).<br/>• Ensure both cron-triggered and manual runs share
identical, minimal cold-start paths.<br/>• Consolidate duplicate functions /
projects to avoid bundle bloat and long compile times.<br/>• Establish
guard-rails (CI lint, bundle-size check, import-map enforcement) to prevent
regression.

---

## 5. Recommended Next Steps (to be refined with human developer)

1. **Systematic diagnostic plan** for the cron path: a. Re-run scheduled job
   manually with `supabase functions invoke` while tailing
   `_analytics.function_edge_logs`.<br/> b. Capture full request / response /
   header set used by `pg_cron`.
2. **Decide on delivery mechanism:** • **Option A – Keep Edge Functions** and
   finish performance hardening.<br/> • **Option B – Move generation to a
   long-running Cloud Run / Kubernetes job** that can exceed 30 s without CF
   limits.
3. **Codebase clean-up strategy:** • Deprecate or delete
   `daily-content-generator-dev`, `*-smoke`, and ad-hoc helper functions once
   production path is stable.<br/> • Standardise shared utilities in `_shared/`
   and enforce import-map usage.<br/> • Introduce automated bundle-size CI gate
   (< 100 kB) for all Edge Functions.

---

> **Action Item:** Collaborate on the above plan to ensure both scheduled and
> manual content generation paths are resilient, or pivot to an alternative
> architecture if Edge Function constraints remain prohibitive.
