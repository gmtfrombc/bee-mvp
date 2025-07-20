### Mini-Sprint 0-3 · Component Size Governance – Technical Plan

> **Related overview:** `ms_0-3_component_size_pass.md` **Author:** AI
> Pair-Programmer **Last Updated:** 2025-07-24
>
> This document translates the high-level goal (refactor oversized files) into a
> concrete, step-by-step technical plan with task tracking.

---

## 🎯 Objectives

1. Introduce a two-tier size-checking system (cap + hard-fail ceiling) while
   keeping CI green during the sprint.
2. Refactor the **~10** hard-fail files (> _ceiling_) identified by the latest
   audit.
3. Leave soft-warning enforcement in place for ~30 moderate violators.
4. Flip CI to _enforced_ mode at the end of the sprint.

## 🗂️ Order of Operations

1. **Script Upgrade** – add ceiling constants & `HARD_FAIL` toggle in
   `scripts/check_component_sizes.sh` (default `false`).
2. **GitHub Action (warning mode)** – run the script on every PR; logs show ❌
   when a file exceeds the ceiling but the job exits 0.
3. **Initial Audit** – run the upgraded script to export a list of HARD-FAIL
   files.
4. **Refactor Pass** – tackle each HARD-FAIL file (tasks G1–G8 below).
5. **Flip the Switch** – set `HARD_FAIL=true` in the CI step; remove wording
   that permits `--no-verify`.
6. **Clean-up** – delete any temporary `@size-exempt` annotations, re-run audit;
   CI must pass.

## 🔧 Implementation Details

| Constant | Current Cap | Hard-Fail Ceiling (Cap × 1.5) |
| -------- | ----------- | ----------------------------- |
| Services | 500         | **750**                       |
| Widgets  | 300         | **450**                       |
| Screens  | 400         | **600**                       |
| Modals   | 250         | **375**                       |

Code snippet to add to bash script:

```bash
# === Hard-fail ceilings ===
SERVICE_CEILING=750
WIDGET_CEILING=450
SCREEN_CEILING=600
MODAL_CEILING=375
# Toggle via env var
HARD_FAIL=${HARD_FAIL:-false}
...
if [[ $lines -gt $ceiling ]]; then
  HARD_FAIL_COUNT=$((HARD_FAIL_COUNT+1))
  echo "❌ HARD-FAIL candidate: $file – ${lines} LOC ($ceiling allowed)"
fi
...
if [[ $HARD_FAIL == true && $HARD_FAIL_COUNT -gt 0 ]]; then
  exit 1
fi
```

GitHub Action excerpt:

```yaml
- name: Component size check (warning mode)
  run: ./scripts/check_component_sizes.sh
```

At sprint end:

```yaml
- name: Component size check (enforced)
  run: HARD_FAIL=true ./scripts/check_component_sizes.sh
```

## 📋 Task Table

| ID | Description                                               | Target File(s) / Path                                               | Owner         | Est  | Status |
| -- | --------------------------------------------------------- | ------------------------------------------------------------------- | ------------- | ---- | ------ |
| P0 | **Upgrade script** with ceilings + `HARD_FAIL` toggle     | `scripts/check_component_sizes.sh`                                  | dev-infra     | 1h   | ✅     |
| P1 | **Add GH Action** step (warning mode)                     | `.github/workflows/ci.yml`                                          | dev-infra     | 0.5h | ✅     |
| P2 | **Run audit** – generate `component_size_audit_report.md` | root                                                                | dev-infra     | 0.5h | ✅     |
| G1 | Extract data-access helpers & mappers                     | `core/services/wearable_data_repository.dart`                       | backend       | 4h   | ✅     |
| G2 | Split JSON/state classes                                  | `features/today_feed/domain/models/today_feed_content.dart`         | mobile        | 3h   | ✅     |
| G3 | Break composite widget into sub-widgets                   | `features/today_feed/presentation/widgets/offline`                  | mobile        | 3h   | ✅     |
| G4 | Decompose achievements screen                             | `features/gamification/ui/achievements_screen.dart`                 | gamification  | 4h   | ✅     |
| G5 | Extract permissions util, platform helpers                | `core/services/health_permission_manager.dart`                      | core          | 3h   | ✅     |
| G6 | Refactor coach chat screen                                | `features/ai_coach/ui/coach_chat_screen.dart`                       | ai-coach      | 4h   | ✅     |
| G7 | Factor out analytics helpers                              | `features/today_feed/data/services/today_feed_sharing_service.dart` | today_feed    | 3h   | ✅     |
| G8 | Move test fixtures/builders out                           | `core/services/notification_test_validator.dart` et al.             | notifications | 3h   | ⬜     |
| P3 | **Enable HARD_FAIL** in CI, remove `--no-verify` note     | `.github/workflows/ci.yml`, docs                                    | dev-infra     | 0.5h | ⬜     |
| P4 | Clean-up `@size-exempt` annotations & re-audit            | repo-wide                                                           | dev-infra     | 0.5h | ⬜     |

_Total est. effort:_ 28 h (matches PRD)\
_Possible parallel work:_ G-tasks per feature team; infra tasks P0-P2 can land
first.

## ✅ Acceptance Criteria

1. `HARD_FAIL=true ./scripts/check_component_sizes.sh` exits **0**.
2. GH Action passes with HARD_FAIL enabled.
3. All refactored files compile (`flutter analyze`) and tests green
   (`flutter test`).

## 🛡️ Rollback Plan

If the enforced step blocks PRs unexpectedly:

- Temporarily set `HARD_FAIL=false` in the workflow.
- Investigate offending file(s) and schedule follow-up patch.

---

_End of technical plan_
