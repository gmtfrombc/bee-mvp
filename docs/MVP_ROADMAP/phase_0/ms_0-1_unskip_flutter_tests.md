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

#### Skipped Tests Tracker

| Skipped Test (file)                       | Description                                                  | Status     |
| ----------------------------------------- | ------------------------------------------------------------ | ---------- |
| onboarding_flow_test.dart                 | Onboarding happy-path flow – heavy dependencies              | ⚪ Pending |
| launch_controller_flow_test.dart          | LaunchController shows AppWrapper when onboarding complete   | ⚪ Pending |
| onboarding_pages_golden_test.dart         | PreferencesPage golden – flaky baseline                      | ⚪ Pending |
| medical_history_performance_test.dart     | MedicalHistoryPage performance benchmark (CI unreliable)     | ⚪ Pending |
| navigation_integration_test.dart          | Achievements navigation scenario – timer conflicts           | ⚪ Pending |
| adaptive_polling_toggle_test.dart         | AdaptivePollingToggle SharedPreferences interaction          | ⚪ Pending |
| accessibility_test.dart                   | MomentumCard comprehensive accessibility semantics           | ⚪ Pending |
| minimal_performance_test.dart             | Minimal performance tests group – platform channel flakiness | ⚪ Pending |
| momentum_performance_essentials_test.dart | Momentum performance essentials (AI coach benchmarks)        | ⚪ Pending |
