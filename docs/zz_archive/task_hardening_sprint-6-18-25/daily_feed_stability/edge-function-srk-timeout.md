# 🛠️ Edge Function SRK Timeout – Handoff (Sprint 6-18-25)

## Context

- **Project ref:** `okptsizouuanwnpqjfui` (plan: Pro)
- **Function(s):** `daily-content-generator` → cloned as `daily-gen` → cloned as
  `tile-job`
- **Problem:** Any POST that includes the **Service-Role JWT (SRK)** hangs for
  ~150 s then returns **504**. Calls _without_ an `Authorization` header (or
  with anon-key) reach the runtime and respond in ~700 ms (401 as expected).
- **What this means:** The request is blocked **before** the Edge Runtime boots
  – likely Cloudflare WAF / JWT pre-validation.

## Work done so far

1. **CLI upgraded** to v2.28.1; functions re-deployed with `--use-api`.
2. Added `verify_jwt = false` in both `supabase/config.toml` and `deno.json`.
3. Confirmed behaviour via cURL tests + `--max-time 15`.
4. Explored new Dashboard UI – "Debug headers" toggle no longer exposed (removed
   May 2025).
5. Located **edge_logs** via _Logs & Analytics → Edge Functions_; captured two
   key entries:
   - 504 example `7d7d9655-981f-40b8-a2b0-217613873a9b` – `execution_id:null`,
     150 s, JWT present, no `x_served_by`.
   - 401 example `74613f54-7558-4956-9c79-067a2421b898` – runtime headers
     present, exec time 0.7 s.
6. Verified no performance issue: runtime boots fine when reached.
7. Drafted support ticket template (see below). User is about to raise it.

## Support ticket template (already provided to user)

```
Area: Issues with APIs / client libraries
Severity: High
Library: Javascript (curl)
Services: Edge Functions
Subject: Edge-Function call with Service-Role JWT returns 504 before runtime executes
Message: <see full block in chat – includes log IDs + repro>
```

## Recommended next steps

1. **User action:** Submit the ticket (template above). Attach failing log JSON.
2. **While waiting:**
   - Use anon-key or a custom header (`x-cron-auth`) in prod jobs.
   - Set up **Log Drain** → _Supabase Logs_ → source `edge_logs` for easier SQL
     queries.
3. **Once Supabase replies:**
   - They will either whitelist the WAF rule or flip the internal debug flag so
     we can see rule IDs.
   - Re-test with SRK header; ensure `execution_id` now populates and runtime
     logs appear.
4. **If fixed:** Remove temporary anon / cron header workaround and re-enable
   SRK.

## Open items / questions

- Are other functions affected or only this route? (Suggest run one
  SRK-authenticated request against another simple function.)
- Long-term: consider moving SRK usage to server-side jobs via
  `supabase.functions.invoke()` so header never crosses CF edge.

–– End of hand-off ––
