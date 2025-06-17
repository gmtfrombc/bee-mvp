# Interaction Performance Benchmarks

This document tracks performance testing for the Coaching Interaction pipeline
(Epic 2.3).

## Bench harness

```bash
deno run -A supabase/functions/ai-coaching-engine/bench/jitai-load.bench.ts https://<project>.functions.supabase.co
```

- 100 RPS for 30 s against `/evaluate-jitai`
- Reports p95 latency & error‐rate

## Target SLO

| Metric                     | SLO                    |
| -------------------------- | ---------------------- |
| p95 latency (AI endpoints) | < 900 ms               |
| Error rate                 | < 2 %                  |
| Bench pass criteria        | 0 errors, p95 < 800 ms |

## Latest run (2025-06-16)

```
Requests: 3000
Errors: 0 (0.00%)
p95 latency: 623 ms
```

SLO compliant ✅
