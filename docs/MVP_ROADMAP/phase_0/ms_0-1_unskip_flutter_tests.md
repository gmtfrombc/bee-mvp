### Mini-Sprint 0-1 · Un-skip Flutter Tests

**Goal:** Remove all `skip:` flags from Flutter tests, fix any resulting
failures, and raise CI coverage gate to 45 %.

**Duration:** 2 days (2025-07-20 → 2025-07-21)

| Task | Description                                                      | Est    | Status |
| ---- | ---------------------------------------------------------------- | ------ | ------ |
| T0   | List all lines containing `skip:` via grep; paste into checklist | 0.5 h  | ✅     |
| T1   | Remove `skip:` from test group #1; fix failures                  | 1 h    | ✅     |
| T2   | Repeat for remaining tests (#2-#12)                              | 3 h    | ⬜     |
| T3   | Update or regenerate golden images if diff errors arise          | 1 h    | ⬜     |
| T4   | Run `make ci-fast` locally until green                           | —      | ⬜     |
| T5   | Bump coverage gate in CI config to 45 %                          | 0.5 h  | ⬜     |
| T6   | Push branch + open PR                                            | 0.25 h | ⬜     |

**Acceptance Criteria**

1. No remaining `skip:` in `app/test/**` (verified by grep).
2. `make ci-fast` passes locally and in GitHub Actions.
3. Coverage report ≥ 45 %.

**Rollback Plan** Re-add `skip:` on any test that blocks CI and open backlog
ticket referencing failure log.

---

_Last updated: 2025-07-19_
