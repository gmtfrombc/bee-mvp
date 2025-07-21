# Mini-Sprint: Navigation Refactor & Stability

**Epic:** Stability → Auth & Navigation  
**Owner:** AI Pair-Programmer + Graeme  
**Start:** 2025-07-23  
**Duration:** 5 phases (~5 dev days + QA)

## 🎯 Goal
Fully standardise navigation on GoRouter, eliminate flaky Navigator 1 fallbacks, and harden tests & guards for future regressions.

## 🗂 Phase Breakdown
| Phase | Scope | Status |
|-------|-------|--------|
| P1 | Purge residual `Navigator.push*` & hard-coded route strings in Auth/Onboarding | 🟣 In Progress |
| P2 | Route-constant sweep & introduce linter/CI guard | ⚪ Pending |
| P3 | Stabilise widget tests, add `MockGoRouter` helper, re-enable skipped tests | ⚪ Pending |
| P4 | Refactor `LaunchController` into `/launch` redirect + cold-start test | ⚪ Pending |
| P5 | Cache onboarding flag & optimise `OnboardingGuard` | ⚪ Pending |

## 📝 Task Table
| ID | Task | File(s) / Area | Owner | Est (h) | Status |
|----|------|----------------|-------|---------|--------|
| T1 | Replace Navigator calls in `LoginPage` | `features/auth/ui/login_page.dart` | FE | 1 | 🟣 |
| T2 | Replace Navigator fallback in `AuthPage` | `features/auth/ui/auth_page.dart` | FE | 1 | ⚪ |
| T3 | Replace Navigator fallback in `ReadinessPage` | `features/onboarding/ui/readiness_page.dart` | FE | 1 | ⚪ |
| T4 | Replace hard-coded `'/launch'` with `kLaunchRoute` in above files | project-wide | FE | 0.5 | ⚪ |
| T5 | Un-skip & fix `login_create_account_flow_test.dart` | tests | QA | 1 | ⚪ |
| T6 | Grep sweep for raw route strings; convert to constants | project-wide | FE | 1 | ⚪ |
| T7 | Add custom linter rule for raw Navigator pushes / literals | `analysis_options.yaml` | DX | 2 | ⚪ |
| T8 | Introduce `MockGoRouter` helper & update tests | tests/helpers | QA | 2 | ⚪ |
| T9 | Create new cold-start integration test | `test/integration/launch_redirect_test.dart` | QA | 3 | ⚪ |
| T10 | Convert `LaunchController` to redirect pattern | `core/navigation` | FE | 3 | ⚪ |
| T11 | Implement `onboardingStatusProvider` cache | `core/providers` | FE | 2 | ⚪ |
| T12 | Update documentation & changelog | docs | DX | 1 | ⚪ |

Legend: 🟣 In Progress | 🟡 Blocked | 🟢 Done | ⚪ Pending

## ✅ Acceptance Criteria
1. No root-level `Navigator.push`, `pushReplacement`, or `pushAndRemoveUntil` remain (verified via CI grep).
2. All navigation uses route constants (`k*Route`).
3. Login → Create Account → Confirmation Pending flow passes widget & integration tests.
4. Cold-start redirects correctly to Login/Onboarding/AppWrapper across iOS & Android.
5. Widget/integration tests pass 50 consecutive CI iterations without navigation flakes.
6. Initial navigation after sign-in executes with ≤1 Supabase profile query.

## 📦 Deliverables
- Refactored source code (Phases 1-5).
- Updated tests (widget + integration) & new cold-start test.
- Linter/CI guard script.
- Documentation updates in `architecture.md`, `testing_guide.md`.
- Changelog entry under *Unreleased*.

## 🗓 Timeline
| Day | Focus |
|-----|-------|
| Day 1 | Phase 1 |
| Day 2 | Phase 2 + 50 % Phase 3 |
| Day 3 | Finish Phase 3, start Phase 4 |
| Day 4 | Finish Phase 4 |
| Day 5 | Phase 5 + QA regression |

## 🧪 User Testing Checkpoints
| Phase | When User Should Test | What to Test |
|-------|----------------------|--------------|
| P1 | Once Phase-1 branch is merged & CI green | 1. Log-in → verify router sends you to **/launch**.<br/>2. Tap “Create account” → AuthPage opens via router.<br/>3. Complete signup → ConfirmationPending shows.<br/>4. Back button returns to previous screen without assertion failures. |
| P2 | After Phase-2 PR merges | 1. Smoke-click all menu / tab links – ensure they navigate correctly.<br/>2. Confirm no hard-coded route strings remain by running `dart analyze` (should show zero navigation warnings). |
| P3 | After Phase-3 PR merges | 1. Run full widget test suite locally (`flutter test`).<br/>2. Manually open Today Feed → tap an article → Back returns to feed.<br/>3. Verify skipped tests are now active and passing. |
| P4 | After Phase-4 PR merges | 1. Cold-start the app (fresh install) – expect Splash → Login.<br/>2. Cold-start while logged-in – expect Splash → Home.<br/>3. Cold-start with incomplete onboarding – expect redirect to `/onboarding/step1`.<br/>4. Deep-link to Today Feed article – should open article then allow normal back navigation. |
| P5 | After Phase-5 PR merges | 1. Observe launch latency (<2 s to first interactive screen).<br/>2. Browse around for 5 min – ensure no surprise redirects into onboarding.<br/>3. Repeat item 1 & 2 on both iOS and Android simulators. |

---
*Created on 2025-07-23 by AI Pair-Programmer* 