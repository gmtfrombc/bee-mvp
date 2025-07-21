# Navigator → go_router Refactor Mini-Sprint

**Phase:** 0 – Stability & Hygiene  |  **Owner:** AI Pair-Programmer (in partnership with Graeme)  |  **Start:** 2025-07-22  |  **Duration:** 2 dev days

---

## 1 Goal
Eliminate remaining imperative `Navigator` calls at the root level and standardise on **go_router** navigation across the codebase. This prevents assertion failures in page-based navigators and aligns all feature modules with the router architecture.

## 2 Scope
* Replace `Navigator.of(context).push…`, `pushAndRemoveUntil`, and `pushReplacement` usages that cross screen-stack boundaries.
* Update or add routes in `core/navigation/routes.dart` where needed.
* Adjust widget/integration tests to use router location assertions.
* Retain *local* `Navigator` usage for in-page overlays (e.g. bottom sheets).

Out of scope: design changes, new UX flows, deep-link expansion.

## 3 Deliverables
| # | Deliverable | Description |
|---|-------------|-------------|
| D1 | Refactored source code | All target files migrated to go_router helpers. |
| D2 | Updated tests | Tests pass (`flutter test`) without Navigator assertions. |
| D3 | Changelog entry | `CHANGELOG.md` entry under *Unreleased*. |
| D4 | Documentation | This mini-sprint doc + any README tweaks. |

## 4 Task Table
| ID | Task | File(s) / Area | Owner | Status |
|----|------|----------------|-------|--------|
| T1 | Swap `pushAndRemoveUntil` in Auth flow | `auth_page.dart`, `confirmation_pending_page.dart`, `login_page.dart` | AI-PG | ✅ Complete |
| T2 | Swap `pushReplacement` in Registration success | `registration_success_page.dart` | AI-PG | ✅ Complete |
| T3 | Onboarding screen final push | `onboarding_screen.dart` | AI-PG | ✅ Complete |
| T4 | Add `/confirm` & `/auth` routes | `routes.dart` | AI-PG | ✅ Complete |
| T5 | Sweep remaining root pushes (Momentum, Today Feed, etc.) | see grep list | AI-PG | ✅ Complete |
| T6 | Update affected widget/integration tests | tests under `app/test` | AI-PG | ✅ Complete |
| T7 | CI run & fix lints | project-wide | AI-PG | 🟡 Pending |
| T8 | QA regression pass on iPhone | Graeme | ⚪ Not Started |

Legend: 🔴 Blocked  |  🟡 Pending  |  🟣 In Progress  |  🟢 Done  |  ⚪ N/A

## 5 Acceptance Criteria
1. Register → onboarding flow completes without Flutter navigator assertions on a fresh install.
2. All automated tests (`flutter test`) pass locally and in CI.
3. Manual smoke test of Momentum screen, Today Feed tile navigation, Profile settings, etc. shows no navigation regressions.
4. No direct `Navigator.of(context)` root pushes remain (verified via grep).

## 6 Timeline
| Day | Focus |
|-----|-------|
| **Day 1** | T1–T4 code refactor, green unit tests |
| **Day 2** | T5 sweep & test updates, CI run, QA hand-off |

## 7 Risks & Mitigations
* **Hidden imperative calls** – Mitigate with comprehensive grep search before PR.
* **Test fragility** – Widget tests may rely on Navigator; update expectations early.
* **Deep-link side-effects** – Verify LaunchController deep-link handling after router changes.

## 8 Review & Sign-off
| Role | Name | Sign-off |
|------|------|----------|
| Founder / QA | Graeme | ☐ |
| AI Pair-Programmer | ChatGPT-o3 | ☐ | 