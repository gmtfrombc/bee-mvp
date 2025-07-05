# Mini-Sprint: Registration & Auth Flow Wiring

**Objective:** Connect the completed UI and service layers from Epic 1.6 so the
user journey becomes:

1. Launch → Splash screen while restoring session.
2. No session → Registration / Login pages.
3. Post-auth → Onboarding (if required).
4. Completed onboarding → Home (Momentum screen).
5. Profile → Log-out action returns to auth flow.

**Time-box:** 3 days

---

## 🗂 Task Breakdown

| ID | Task                                                                               | Owner | Est. hrs | Status      | Dependencies              |
| -- | ---------------------------------------------------------------------------------- | ----- | -------- | ----------- | ------------------------- |
| T1 | Create `LaunchController` widget to manage splash → auth → app routing             | FE    | 4        | ✅ Complete | Supabase init logic       |
| T2 | Remove unconditional `signInAnonymously()`; hide behind `kDemoMode` flag           | FE    | 2        | ✅ Complete | SupabaseProvider refactor |
| T3 | Hook `LaunchController` into `BEEApp.home` (replace current `AppWrapper`)          | FE    | 1        | ✅ Complete | T1                        |
| T4 | Wire `OnboardingRedirect.maybeRedirect()` after successful login/signup            | FE    | 2        | ✅ Complete | Auth notifier completion  |
| T5 | Add “Log Out” ListTile in `ProfileSettingsScreen` calling `authNotifier.signOut()` | FE    | 1        | ✅ Complete | None                      |
| T6 | Navigate to `LaunchController` on sign-out                                         | FE    | 1        | ✅ Complete | T5                        |
| T7 | Integration test: cold start with & without session, onboarding branch             | QA    | 4        | ✅ Complete | T1-T4                     |
| T8 | Update docs & README (run_dev.sh, env notes)                                       | DX    | 1        | ✅ Complete | All complete              |

Total ≈ 16 hrs

---

## 🔄 Workflow Steps

1. **Branch:** `feat/auth-flow-wiring` from `main`.
2. Implement tasks T1-T6, commit per task.
3. Run existing unit/widget tests; add new integration tests T7.
4. Open PR, request review, ensure CI passes.
5. Merge & delete branch, update changelog.

---

## ✅ Acceptance Criteria

- [x] Splash shows for ≥ 300 ms while session restore runs.
- [x] Users without a session see Registration/Login.
- [x] After email/password auth, onboarding check triggers correctly.
- [x] `profiles.onboarding_complete=true` routes user directly to Momentum
      screen.
- [x] “Log Out” clears session, returns to auth screen.
- [x] All new logic covered by tests; overall coverage ≥ 85 %.
- [x] No linter warnings (`flutter analyze --fatal-warnings`).

**All acceptance criteria met.**

**Unmet Criteria – Next Actions**

1. **Splash timing**: implement minimum 300 ms delay in `
