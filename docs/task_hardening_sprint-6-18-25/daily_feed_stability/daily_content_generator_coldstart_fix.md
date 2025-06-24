# Daily-Content Generator – cold-start fix (2025-06-21)

The function no longer relies on `deno.land/std/*` imports and now starts the
HTTP server with `Deno.serve()`.

## Invoke manually

```
curl -i -X POST https://srarhcjhjjgbdgfiazje.functions.supabase.co/daily-content-generator \
     -H 'Content-Type: application/json' \
     -d '{}'
```

Expected response (cold-start < 1 s):

```http
HTTP/2 202
{"success":true,"queued":true,"content_date":"<yyyy-mm-dd>"}
```

## Deploy command used

```
supabase functions deploy daily-content-generator \
  --project-ref srarhcjhjjgbdgfiazje \
  --no-verify-jwt \
  --import-map supabase/functions/daily-content-generator/import_map.json \
  --use-api
```

The bundle reported by the CLI is ~11 kB and contains **no remote dependencies**
(verified with `deno info`).

## Next steps

1. Update any helper scripts or Cloud Scheduler jobs that call the manual
   endpoint to use the URL above.
2. (Separate task) wire this lightweight version back into the nightly cron once
   validated in staging.
