# Mini-Sprint: Unify & Stabilise Navigation (GoRouter)

**Epic:** Stability → Auth & Onboarding Flow
**Duration:** 4 days (3 dev, 1 QA)

## 🎯 Goal
Eliminate flaky navigation by moving 100 % of routing inside GoRouter, replacing all imperative `Navigator.push` usages, and refactoring `LaunchController` into a proper route/redirect.

## 🔍 Context Issues
1. Dual stacks (GoRouter + Navigator) cause hidden screens.
2. `LaunchController` returns widgets outside router tree → pushed pages disappear on rebuild.
3. Fallback `Navigator.pushReplacementNamed('/')` targets unnamed routes → silent no-op.
4. Inconsistent tests hide production bugs.

## 🗂 Task Breakdown
| ID | Task | Owner | Est (h) |
|----|------|-------|---------|
| T1 | Convert **all** links (Login → Auth, Logout, etc.) to `context.go()` | FE | 3 |
| T2 | Refactor `LaunchController` decision logic into `GoRouter.redirect` callback; make `/launch` a simple splash route | FE | 5 |
| T3 | Remove Navigator fallbacks; register any required named routes | FE | 2 |
| T4 | Update widget tests to use `MockGoRouter` assertions | QA | 3 |
| T5 | New integration test: full registration → email confirm deep-link → onboarding | QA | 4 |
| T6 | Update documentation (`testing_guide.md`, `architecture.md`) | DX | 1 |

## ✅ Acceptance Criteria
1. No `Navigator.push` in `features/auth` & `core/widgets` layers (except for dialogs).
2. Registration flow reliably shows ConfirmationPending, then RegistrationSuccess, on both iOS & Android.
3. All existing tests green; new integration test passes.
4. Zero GoRouter flakes across 50 CI iterations.

## 📦 Deliverables
- Refactored routing code.
- Updated tests & docs.
- CI run showing stable navigation tests.

---
*Created on 2025-07-21 by AI pair-programmer* 