### Sprint PRD – Component Size Governance Compliance (Generated 2025-07-??)

> **Goal** — Bring oversized Dart files back within the limits defined in
> `docs/architecture/component_governance.md` (v2.0). Improve maintainability
> and unblock future feature work.
>
> **Scope** — `app/lib/**` Dart source only. Tests and generated files excluded.

---

## 1 📊 Current Audit Summary

| Metric                            | Count |
| --------------------------------- | ----- |
| Total Dart files scanned          | 311   |
| Files over any limit              | ~45   |
| Services > 500 LOC                | 21    |
| Widgets (presentation/) > 300 LOC | 14    |
| Screen components > 400 LOC       | 6     |
| Modal widgets > 250 LOC           | 4     |

### 1.1 Top 15 Offenders

| Lines | Path                                                                        | Component Type    | Limit | ∆ Over                                             |
| ----- | --------------------------------------------------------------------------- | ----------------- | ----- | -------------------------------------------------- |
| 1083  | `core/services/wearable_data_repository.dart`                               | Service           | 500   | +583                                               |
| 836   | `core/notifications/testing/notification_test_framework.dart`               | Service/Test util | 500   | +336                                               |
| 819   | `features/today_feed/domain/models/today_feed_content.dart`                 | Model*            | n/a   | _Large enum/JSON mapping – consider partial split_ |
| 816   | `features/today_feed/data/services/today_feed_sharing_service.dart`         | Service           | 500   | +316                                               |
| 795   | `features/today_feed/data/services/session_duration_tracking_service.dart`  | Service           | 500   | +295                                               |
| 788   | `features/today_feed/presentation/widgets/states/offline_state_widget.dart` | Widget            | 300   | +488                                               |
| 778   | `features/gamification/ui/achievements_screen.dart`                         | Screen            | 400   | +378                                               |
| 725   | `features/today_feed/data/services/today_feed_human_review_service.dart`    | Service           | 500   | +225                                               |
| 712   | `core/notifications/domain/models/notification_models.dart`                 | Model             | n/a   | _Could be split into sub-models_                   |
| 677   | `core/services/health_permission_manager.dart`                              | Service           | 500   | +177                                               |
| 656   | `features/ai_coach/ui/coach_chat_screen.dart`                               | Screen            | 400   | +256                                               |
| 602   | `core/services/android_garmin_feature_flag_service.dart`                    | Service           | 500   | +102                                               |
| 590   | `core/services/notification_test_validator.dart`                            | Service/Test util | 500   | +90                                                |
| 575   | `features/momentum/data/services/momentum_api_service.dart`                 | Service           | 500   | +75                                                |
| 541   | `features/today_feed/presentation/widgets/states/error_state_widget.dart`   | Widget            | 300   | +241                                               |

_*Model files have no hard limit but sizes near 800 LOC hurt readability;
propose logical split._

---

## 2 🎯 Objectives

1. Reduce every **Service** to ≤ 500 LOC.
2. Reduce every **Widget/Screen** file to ≤ 300/400 LOC respectively.
3. Maintain behaviour & public APIs (no functional regressions).
4. Add/adjust tests where code is extracted.

## 1.2 Top TypeScript Offenders (supabase/functions)

| Lines | Path                                                            | Component Type      | Limit | ∆ Over |
| ----- | --------------------------------------------------------------- | ------------------- | ----- | ------ |
| 870   | `supabase/functions/ai-coaching-engine/mod.ts`                  | Edge-function entry | 500   | +370   |
| 801   | `supabase/functions/momentum-score-calculator/index.ts`         | Edge-function entry | 500   | +301   |
| 728   | `supabase/functions/push-notification-triggers/index.ts`        | Edge-function entry | 500   | +228   |
| 547   | `supabase/functions/momentum-score-calculator/error-handler.ts` | Utility             | 500   | +47    |

_Approx. 4 TypeScript files currently exceed 500 LOC._

## 1.3 Top Python Offenders (project-root `tests/`)

| Lines | Path                                                | File Role     | Limit | ∆ Over |
| ----- | --------------------------------------------------- | ------------- | ----- | ------ |
| 929   | `tests/db/test_rls.py`                              | DB test suite | 500*  | +429   |
| 893   | `tests/api/test_data_validation_error_handling.py`  | API tests     | 500*  | +393   |
| 778   | `tests/db/test_performance_optimization.py`         | Perf tests    | 500*  | +278   |
| 718   | `tests/api/test_momentum_calculation_unit_tests.py` | Unit tests    | 500*  | +218   |

_*We do not enforce strict size on test modules, but >900 LOC makes triage slow;
consider logical split when convenient._

---

## 3 🗂️ Task Breakdown

| ID  | Description                                                                                                             | Target File(s)                       | Type            | Est. hrs      | Owner   | Status  |
| --- | ----------------------------------------------------------------------------------------------------------------------- | ------------------------------------ | --------------- | ------------- | ------- | ------- |
| G1  | Extract data-access helpers & mappers into `wearable_data_adapter.dart`; keep repository focused on public API          | `wearable_data_repository.dart`      | Service split   | 4             | backend | pending |
| G2  | Split state classes & JSON mapping into separate model files (`today_feed_item.dart`, etc.)                             | `today_feed_content.dart`            | Model tidy-up   | 3             | mobile  | pending |
| G3  | Break `offline_state_widget.dart` into small stateless widgets (`OfflineBanner`, `RetryCTA`…)                           | Widget refactor                      | 3               | mobile        | pending |         |
| G4  | Decompose `achievements_screen.dart` into screen + controller + sub-widgets                                             | Screen refactor                      | 4               | gamification  | pending |         |
| G5  | Extract permissions util + platform-specific helpers from `health_permission_manager.dart`                              | Service split                        | 3               | core          | pending |         |
| G6  | Refactor `coach_chat_screen.dart` – move message-bubble, input-bar to separate widgets                                  | Screen refactor                      | 4               | ai-coach      | pending |         |
| G7  | Factor out analytics helpers from `today_feed_sharing_service.dart`                                                     | Service split                        | 3               | today_feed    | pending |         |
| G8  | Reduce size of `notification_*` services by moving test fixtures & builders into `testing/`                             | Service tidy-up                      | 3               | notifications | pending |         |
| G9  | Add CI step: `scripts/check_component_sizes.sh` – fail if any limit exceeded (already exists, but ensure workflow call) | CI                                   | 1               | dev-infra     | pending |         |
| G10 | Update architecture docs with new file structure where needed                                                           | Docs                                 | 1               | docs          | pending |         |
| G11 | Split monolithic edge-function file into `mod.ts` (router), `services/`, `handlers/`                                    | `ai-coaching-engine/mod.ts`          | TS refactor     | 4             | backend | pending |
| G12 | Decompose score calculator into `index.ts` (entry) + `calculator.service.ts`                                            | `momentum-score-calculator/index.ts` | TS refactor     | 3             | backend | pending |
| G13 | Extract notification logic modules from `push-notification-triggers/index.ts`                                           | TS refactor                          | 3               | backend       | pending |         |
| G14 | Split oversized Python RLS tests into focused test modules (`test_rls_read.py`, etc.)                                   | `tests/db/test_rls.py`               | Py test tidy-up | 2             | QA      | pending |
| G15 | Add size-check logic to `scripts/check_component_sizes.sh` for *.ts and *.py (ignore venv/, node_modules/)              | CI                                   | 2               | dev-infra     | pending |         |

_Total effort: 28 h (≈ 3–4 dev days)._ Tasks can run in parallel per feature
team.

## 4 🏁 Milestones

| Milestone              | Tasks              | ETA         |
| ---------------------- | ------------------ | ----------- |
| **M1** – Core Services | G1, G2, G5, G7, G8 | **Day 1–2** |
| **M2** – UI Refactors  | G3, G4, G6         | **Day 2–3** |
| **M3** – CI & Docs     | G9, G10            | **Day 4**   |

## 5 ✅ Acceptance Criteria

- No file exceeds its limit per `component_governance.md`.
- All existing tests pass; coverage ≥ current baseline.
- New/updated tests cover extracted code (>85 % for new services).
- CI (`flutter-ci.yml` ➔ size checker) passes on PR.

## 6 Risks & Mitigations

| Risk                                                | Mitigation                                            |
| --------------------------------------------------- | ----------------------------------------------------- |
| Hidden coupling in large files causes regressions   | Add unit tests before refactor; migrate incrementally |
| Refactor increases file count and import complexity | Enforce clear naming & directories per governance doc |

---

_This sprint PRD is auto-generated by Cursor AI (2025-07-??). Update task status
inline as work progresses._
