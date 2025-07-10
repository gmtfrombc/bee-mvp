### Epic: Local Supabase Mini-Stack Hardening (Option B)

**Context** We currently rely exclusively on the cloud Supabase project. A
previous local stack drifted and was abandoned. Contract tests for
`/sync-ai-tags` now run with an in-memory stub (Option C). To gain full RLS +
trigger coverage offline, we plan to re-establish a minimal Dockerised Supabase
stack.

---

## 🎯 Goal

Provide a reproducible local Supabase instance (Postgres + edge-runtime only)
that:

1. Boots in < 30 s via `supabase start` (Docker).
2. Applies a slim migration set ( `coach_memory` table + shared audit function
   ).
3. Lets CI run contract tests offline with p95 latency < 500 ms.

## 📋 Task Breakdown

| ID | Description                                                                     | Est. hrs | Owner | Status  |
| -- | ------------------------------------------------------------------------------- | -------- | ----- | ------- |
| L1 | Add minimal `supabase/config.toml` limiting services to Postgres & edge-runtime | 2h       |       | pending |
| L2 | Isolate migrations for contract tests into `migrations/contract_subset/`        | 1h       |       | pending |
| L3 | Create GitHub Action service container using `supabase/cli:latest`              | 3h       |       | pending |
| L4 | Update Deno test runner to target `localhost:54322` when `USE_LOCAL_SB=true`    | 2h       |       | pending |
| L5 | Document start/stop scripts in `scripts/local_supabase.sh`                      | 1h       |       | pending |
| L6 | Add CI workflow caching Docker layers for faster boot                           | 2h       |       | pending |
| L7 | Remove `SKIP_SUPABASE` bypass from contract tests (guarded by env flag)         | 1h       |       | pending |

_Total est. effort: 12 h (1.5 dev days)_

## ✅ Acceptance Criteria

- `deno test` passes against local stack inside CI.
- RLS policies & audit trigger verified by tests.
- CI time increase ≤ 3 min.

## Risks / Mitigations

- **Docker-in-Docker instability** on GitHub runners → use service containers,
  not DinD.
- **Schema drift** between subset & prod → nightly GitHub Action compares diffs.

## Timeline Proposal

| Day | Focus                           |
| --- | ------------------------------- |
| 1   | L1-L3 setup & verify manual run |
| 2   | L4-L5 integrate tests           |
| 3   | L6-L7 CI integration & polish   |

## Stakeholders

• Backend lead, DevOps, QA
