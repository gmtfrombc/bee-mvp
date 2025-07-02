# Daily-Content Generator – Debug & Smoke-Test Log

_Last updated: 2025-06-20_

## Context

The Edge Function `daily-content-generator` sometimes exceeds pg_net/post-gRPC
time-outs when called manually from Postgres. Nightly cron jobs are safe because
the helper only **queues** the HTTP request, but for manual runs we need the
function to respond in < 30 s.

## What we verified so far

1. pg_cron jobs `daily-content-generation` (03:00 UTC) and backup (04:00 UTC)
   exist and call `trigger_daily_content_generation()`.
2. Helper inserts job row and queues an HTTP POST via `net.http_post()`.
3. pg_net 30 000 ms timeout still fires – function does **not** answer within 30
   s.
4. Hitting the route **without** an Authorization header returns 401 in < 1 s
   (so Cloudflare + routing are fine).
5. A separate minimal `health-ping` Edge Function (`/health-ping`) returns
   `200 pong` instantly.

## Current hypothesis

The deployed `daily-content-generator` is doing heavy GPT work before it
returns. We need to confirm by deploying a **smoke-test copy** that replies
immediately; if the copy is fast, the delay is definitely inside our handler.

## Next planned steps

| Step | Who            | Action                                                                                               |
| ---- | -------------- | ---------------------------------------------------------------------------------------------------- |
| 1    | Assistant      | Create new Edge Function `daily-content-smoke` that just returns 200 pong                            |
| 2    | Assistant      | Deploy `daily-content-smoke` via Supabase CLI                                                        |
| 3    | User           | Run one pg_net call with 5 s timeout → expect status 202/200                                         |
| 4    | Assistant+User | If fast → refactor original handler to respond 202 then use `EdgeRuntime.waitUntil()` for heavy work |
| 5    | Assistant      | Deploy refactored function to production slot                                                        |

If step 3 shows another pg_net timeout, the delay is outside our code path
(network or platform) and we will escalate accordingly.
