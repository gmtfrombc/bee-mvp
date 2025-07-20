### Mini-Sprint 0-2 · TODO Triage & Action

**Goal:** Review every `TODO` in Dart code; convert to actionable tickets or
implement quick fixes. Reduce outstanding TODOs by ≥ 70 %.

**Duration:** 2 days (2025-07-22 → 2025-07-23)

| Task | Description                                                 | Est    | Status |
| ---- | ----------------------------------------------------------- | ------ | ------ |
| T0   | Run grep for `TODO(` or `TODO:` and export list             | 0.5 h  | ✅     |
| T1   | Categorise: A) Needed now, B) Defer, C) Obsolete            | 1 h    | ✅     |
| T2   | Implement all category A items (quick fixes ≤ 30 min each)  | 4 h    | ⬜     |
| T3   | Create GitHub issues for category B with labels & estimates | 1 h    | ⬜     |
| T4   | Delete/clean obsolete comments                              | 0.5 h  | ⬜     |
| T5   | Update docs & close mini-sprint                             | 0.25 h | ⬜     |

**Acceptance Criteria**

1. TODO grep count reduced by ≥ 70 %.
2. All remaining TODOs have matching GitHub issues.
3. CI green after fixes.

**Rollback Plan** Revert individual commits if a quick-fix introduces a
regression; the GitHub issue list preserves context.

---

_Last updated: 2025-07-19_
