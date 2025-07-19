### Mini-Sprint 0-4 · Coverage Gate & LCOV Cleanup

**Goal:** Delete committed `lcov.info`, add to `.gitignore`, and bump CI
coverage threshold from 40 % → 45 %.

**Duration:** 1 day (2025-07-26)

| Task | Description                                                       | Est    | Status |
| ---- | ----------------------------------------------------------------- | ------ | ------ |
| T0   | Remove `app/coverage/lcov.info` from repo history (single commit) | 0.5 h  | ⬜     |
| T1   | Add `coverage/*.info` to root `.gitignore`                        | 0.25 h | ⬜     |
| T2   | Update `make ci-fast` coverage check to 45 %                      | 0.5 h  | ⬜     |
| T3   | Update README badge & docs                                        | 0.25 h | ⬜     |
| T4   | Run full CI to confirm new gate passes                            | —      | ⬜     |

**Acceptance Criteria**

1. No `.info` files tracked by Git.
2. CI fails if coverage < 45 %.
3. README shows new threshold.

**Rollback Plan** Revert commit that bumps coverage gate if pipeline blocks;
keep lcov ignored.

---

_Last updated: 2025-07-19_
