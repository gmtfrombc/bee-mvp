# Mini-Sprint: Improve Test Coverage & Stability

**Location:** `app/` **Duration:** 3–5 working days (adjust as needed)
**Drivers:** Engineering Lead + Assigned Developer **Last updated:**
<!--- fill on kickoff --->

---
## 1. Objective
Raise automated-test coverage for Tier A & B code to a sustainable level and lock it in CI.

* **Target after sprint:**
  * Tier A + B filtered coverage ≥ **60 %** (stretch 70 %)
  * No new regressions; full suite passes on CI & locally

## 2. Coverage Framework (reference)
| Tier | Code category | Coverage target | Notes |
|------|---------------|-----------------|-------|
| **A** | Core business logic, algorithms, critical services | **≥ 90 %** | Heart of the product; must stay green |
| **B** | Supporting services, reducers, providers | **≥ 70 %** | Stability without over-testing |
| **C** | UI widgets / screens | Spot tests, goldens, smoke flows | Visual correctness only |
| **D** | Generated, theme, DTOs, boiler-plate | **Excluded** | Low business value |

CI gates Tier A + B combined; baseline threshold starts at **60 %** and rises ±5 % when comfortably exceeded.

## 3. Sprint Backlog
| ID | Task | Owner | Definition of Done |
|----|------|-------|--------------------|
| T-1 | Capture **baseline** filtered coverage report | Dev | `coverage/lcov_ci_filtered.info` committed in PR |
| T-2 | Audit & **update filter lists**<br/>(`dart_test.yaml`, CI `lcov --remove`) | Dev | Tier C/D code fully excluded, commit passes CI |
| T-3 | **Prioritise Tier A modules** (top 10 by risk/size) | Lead | Spreadsheet prioritisation attached |
| T-4 | Write **happy-path tests** for each Tier A module | Dev | Each file ≥ 80 % lines, tests green |
| T-5 | Write **edge-case tests** (error, boundary) for Tier A modules | Dev | Coverage bump verified |
| T-6 | Select 5 largest Tier B gaps & add tests | Dev | Each file ≥ 50 % lines |
| T-7 | **Raise CI threshold** to 60 % | Dev | Pipeline fails below 60 % |
| T-8 | Generate **HTML coverage report** (`genhtml`) & attach to PR artifact | Dev | Accessible in CI summary |
| T-9 | Update `docs/testing/flutter_testing_guide.md` if patterns change | Dev | Guide reflects reality |
| T-10 | Post-sprint **retrospective & follow-ups** | Team | Action items documented |

## 4. Milestones & Timeline (example)
| Day | Milestone |
|----:|-----------|
| 0.5 | Sprint kickoff, baseline captured (T-1) |
| 1   | Filter review done (T-2) |
| 2   | Tier A happy-path tests complete (T-4) |
| 3   | Tier A edge-cases + Tier B tests drafted (T-5, T-6) |
| 4   | CI threshold raised, docs updated (T-7, T-9) |
| 5   | Demo & retro (T-8, T-10) |

## 5. Acceptance Criteria
1. `flutter test` passes locally with `--fatal-warnings`.
2. Filtered coverage ≥ 60 %.
3. CI badge on README shows updated percentage.
4. New tests follow project conventions (mocktail, Riverpod overrides, no flaky timers).
5. No Tier A files remain below 80 % line coverage.

## 6. Risks & Mitigations
| Risk | Mitigation |
|------|------------|
| Flaky widget tests on CI | Use `pumpAndSettle()` carefully; avoid real platform channels |
| Large refactors uncovered | Focus on high-churn services first |
| Time overrun | Scope Tier B work to top 5 files only |

## 7. Tools & References
* Guide: `docs/testing/flutter_testing_guide.md`
* CI workflow: `.github/workflows/flutter-ci.yml`
* Coverage commands:
  ```bash
  flutter test --coverage         # raw
  lcov --remove coverage/lcov.info ... -o coverage/lcov_ci_filtered.info
  genhtml coverage/lcov_ci_filtered.info -o coverage/html
  open coverage/html/index.html   # macOS helper
  ```
---

Happy testing! 🎯
