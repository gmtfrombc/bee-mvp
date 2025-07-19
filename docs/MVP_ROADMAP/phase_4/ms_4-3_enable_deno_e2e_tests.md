### Mini-Sprint 4-3 · Enable Deno End-to-End Tests

**Goal:** Un-ignore `supabase/functions/tests/*.ts` that currently have
`ignore: true`, by running them against the Local Supabase mini-stack V2
(Realtime + Storage) and ensuring they pass both locally and in CI.

**Duration:** 2 days (scheduled during Phase 4, exact dates TBD)

| Task | Description                                                                      | Est    | Status |
| ---- | -------------------------------------------------------------------------------- | ------ | ------ |
| T0   | Confirm mini-stack V2 containers running locally (`docker-compose.emulator.yml`) | 0.25 h | ⬜     |
| T1   | Remove `ignore: true` from `interaction-e2e.test.ts`                             | 0.25 h | ⬜     |
| T2   | Remove `ignore: true` from `auth_enforcement.test.ts`                            | 0.25 h | ⬜     |
| T3   | Remove `ignore: true` from `daily_content_pipeline.test.ts`                      | 0.25 h | ⬜     |
| T4   | Update `.github/workflows/ci.yml` to spin up mini-stack for Deno job             | 1 h    | ⬜     |
| T5   | Fix any failing assertions / outdated mocks                                      | 3 h    | ⬜     |
| T6   | Ensure `deno test --coverage` integrates with coverage summary                   | 0.5 h  | ⬜     |
| T7   | Push branch & open PR; CI green                                                  | —      | ⬜     |

**Acceptance Criteria**

1. All Deno E2E tests pass locally and in GitHub CI.
2. `ignore:` flags fully removed.
3. Coverage report includes Deno tests.

**Rollback Plan** Re-add `ignore: true` to failing test and open ticket if
mini-stack instability blocks CI.

---

_Last updated: 2025-07-19_
