# Manual trigger for `daily-content-generator`

Use this when you want to run the daily content generation on-demand (e.g. after
patching prompts or fixing data).

## 1 – CLI helper script (fastest)

```bash
# From repo root
./scripts/manual_trigger_daily_content.sh <project-ref> '{"force_regenerate": true}'
```

Flags explained:

- `<project-ref>` – your Supabase project id (found in dashboard URL).
- Optional JSON body – defaults to `{}`.
- The script calls `supabase functions invoke` with `--no-verify-jwt` so you
  don't need to craft a Service-Role JWT.

## 2 – Supabase Dashboard

1. Open **Edge Functions → daily-content-generator**.
2. Click **"Stub Request"**.
3. Choose `POST`, paste `{}` (or a custom body) and hit **Send**. You'll get a
   `202 Accepted` if the worker boots within 30 s.

## 3 – Direct cURL (if you really need it)

```bash
curl -X POST https://<project-ref>.functions.supabase.co/daily-content-generator \
     -H "Authorization: Bearer $SERVICE_ROLE_JWT" \
     -H "Content-Type: application/json" \
     -d '{}'
```

Replace `$SERVICE_ROLE_JWT` with an actual service-role key from your project
settings.

---

**Note on cold starts**\
The function is now slim (<10 kB) and returns early (`202`) while the heavy work
runs in a background task, so manual calls should complete well under the 30 s
front-door limit. If you still hit a timeout after long periods of inactivity,
ping the health-check function or run the trigger once to warm the isolate
before the real call.
