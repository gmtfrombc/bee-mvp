# Today-Feed – Daily Content Generator Troubleshooting Log

_Last updated: 2025-06-20_

## Goal

Allow manual invocations of `daily-content-generator` from Postgres (pg_net) to
finish < 30 s. Nightly cron jobs are already safe because they fire-and-forget.

## Timeline of Tests

| Date/Time UTC | Action                                                                            | Result                                                        |
| ------------- | --------------------------------------------------------------------------------- | ------------------------------------------------------------- |
| 23:00         | Bumped `trigger_daily_content_generation` pg_net timeout to **30 000 ms**         | Manual run still timed-out (30 s)                             |
| 23:10         | Deployed smoke function `daily-content-smoke` (always returns 200)                | GET w/ 5 s timeout → **401** (no JWT). Confirms route is fast |
| 23:15         | Disabled JWT, pinged smoke again                                                  | **200** within < 1 s ✔︎                                        |
| 23:20         | Copied repo code → `daily-content-generator-dev`, deployed with `--no-verify-jwt` | pg_net POST time-outs at 5 s and 20 s                         |
| 23:30         | Added top-level boot log; redeployed                                              | Boot log appears → worker starts                              |
| 23:35         | pg_net POST 60 s timeout                                                          | Still times-out. No invocation rows generated                 |

## Findings so far

1. Worker boots but **never receives the request** (no Invocation record).
   Cloudflare waits full client timeout.
2. Therefore failure occurs **before** the handler's first line:
   - Worker may exit during module evaluation _after_ boot log.
   - Dashboard needs `function_edge_logs` query to reveal exact error.

## Next Diagnostic Step

Run this in Logs Explorer:

```sql
select datetime(timestamp),
       metadata.response.status_code,
       metadata.response.origin_time,
       event_message,
       metadata.reason
from   function_edge_logs
where  metadata.request.path like '%daily-content-generator-dev%'
  and  datetime(timestamp) > datetime_sub(current_datetime, interval 10 minute)
limit 50;
```

Find any rows with error / reason and capture stack-trace.

---

_Log maintained under
`/docs/task_hardening_sprint-6-18-25/daily_feed_stability/`_
