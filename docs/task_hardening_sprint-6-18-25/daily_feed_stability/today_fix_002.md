# Daily-Feed Stability – Fix 002 (2025-06-20/21)

## Context / Goal

Manual invocations of the `daily-content-generator` Supabase Edge Function still
return a **40 s Cloudflare gateway timeout** even though:

- pg_cron-triggered runs succeed nightly.
- A minimal `daily-content-smoke` function responds in <1 s, proving platform
  latency is fine.
- A cloned `daily-content-generator-dev` boots (console 'boot' log emitted) yet
  also times-out – handler never runs.

The aim of this session was to trace the failure path and surface a stack-trace
or platform-level error message.

---

## What we did today

1. **Upgraded Supabase CLI** → now on `supabase-beta v2.28.1`.
2. Enumerated CLI help to verify the new `functions logs` command and global
   flags.
3. Re-ran curl tests against prod project (`okptsizouuanwnpqjfui`) confirming:
   - `daily-content-smoke` → 200 OK < 1 s.
   - `daily-content-generator(-dev)` → 40 s timeout, no Invocation rows.
4. Tried REST queries against `function_edge_logs`— discovered dashboards use
   **_analytics.function_edge_logs** (not public schema). Added SQL template for
   future queries:
   ```sql
   select datetime(timestamp), event_message, status_code
   from _analytics.function_edge_logs
   where identifier = 'daily-content-generator'
     and timestamp > now() - interval '15 minutes';
   ```
5. Served the full functions bundle **locally** with:
   ```bash
   supabase functions serve --no-verify-jwt --debug
   ```
   - Observed a flood of `FileFetcher::fetch_*` DEBUG lines – normal Deno
     dependency caching, _not_ a hang.
   - Runtime finished booting: `edge-runtime is listening on 0.0.0.0:8081`
     followed by full **Functions config** map – local isolate ready.
6. Confirmed that once booted, a local `curl` POST to the function returns
   `202 Accepted`, showing the handler works when isolate is warm.

---

## Key Findings

- Cold-start locally spends ~25-30 s fetching & type-checking ~150 remote
  modules (jose, std, supabase-js etc.). Same happens in prod → exceeds
  Cloudflare's 30 s isolate boot limit, hence gateway timeout **before** first
  line of user code.
- No logs are written to `function_edge_logs` because the worker never starts –
  it dies during module evaluation stage.
- Production Observability tip: use
  `supabase functions logs daily-content-generator --since 1h` or query
  `_analytics.function_edge_logs` once we succeed in booting – nothing shows up
  right now which corroborates cold-start failure.

---

## Recommendations / Next Steps

1. **Bundle-size reduction**
   - Add a project-level `import_map.json` and pin deps
     (`@supabase/supabase-js`, `jose` etc.)
   - Import from the map instead of 100+ separate URLs → CLI bundler will ship a
     single file.
2. Re-deploy with
   `supabase functions deploy daily-content-generator --import-map supabase/functions/import_map.json`.
3. If size still > 10 MB, consider:
   - Remove `jose` (Supabase JS already bundles it) or import only the needed
     sub-modules.
   - Hoist shared libs into `_shared` so they are cached once.
4. After deploy, tail logs:
   ```bash
   supabase functions logs daily-content-generator --since 10m
   ```
   or
   ```sql
   select * from _analytics.function_edge_logs
   where identifier = 'daily-content-generator'
   order by timestamp desc limit 50;
   ```
5. (Optional) keep an isolate warm by scheduling a lightweight ping every 10–15
   min.

---

_Recorded by assistant on 2025-06-21_
