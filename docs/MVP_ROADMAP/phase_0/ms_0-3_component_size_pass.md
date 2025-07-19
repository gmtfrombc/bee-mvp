### Mini-Sprint 0-3 · Component Size Governance – Pass 1

**Goal:** Refactor any Dart/TS files exceeding 300 LOC into smaller,
domain-focused modules per architecture rules.

**Duration:** 2 days (2025-07-24 → 2025-07-25)

| Task | Description                                                   | Est   | Status |
| ---- | ------------------------------------------------------------- | ----- | ------ |
| T0   | Run `scripts/check_component_sizes.sh` → export oversize list | 0.5 h | ⬜     |
| T1   | Prioritise top 10 largest files for refactor                  | 0.5 h | ⬜     |
| T2   | Refactor UI widgets (split view + logic)                      | 4 h   | ⬜     |
| T3   | Refactor services / utils (extract helpers)                   | 4 h   | ⬜     |
| T4   | Update imports & unit tests                                   | 1 h   | ⬜     |
| T5   | Re-run size script; aim for 0 files > 300 LOC                 | 0.5 h | ⬜     |

**Acceptance Criteria**

1. `scripts/check_component_sizes.sh` exits 0 (no violators).
2. All refactored files pass `flutter analyze` with no warnings.
3. No test regressions.

**Rollback Plan** Keep each refactor in its own commit; revert offending commit
if regression detected.

---

_Last updated: 2025-07-19_
