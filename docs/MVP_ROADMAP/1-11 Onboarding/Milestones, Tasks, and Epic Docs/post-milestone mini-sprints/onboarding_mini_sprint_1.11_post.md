# Mini-Sprint Plan: Epic 1.11 Onboarding – Post-Milestone Completion (July 2025)

This mini-sprint finalises the onboarding flow so QA can run full end-to-end
tests with Supabase persistence and profile flagging.

---

## 📋 Milestones Overview

| ID     | Milestone                          | Goal                                                                                                                 |
| ------ | ---------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| **M1** | Submission Pipeline & Profile Flag | Persist onboarding answers via RPC, clear local draft, and flip `profiles.onboarding_complete`.                      |
| **M2** | Scoring & Personalisation Tags     | Compute motivation / readiness / coach-style tags and pass them to Supabase.                                         |
| **M3** | Navigation & UX Polish             | Ensure a seamless multi-step journey using `GoRouter`, show loading/error states, and land users on the Home screen. |
| **M4** | Automated Tests                    | Cover new logic with integration & unit tests, update coverage to ≥ 85 %.                                            |

---

## ✅ Acceptance Criteria & Tasks

### M1 — Submission Pipeline & Profile Flag

**Acceptance Criteria**

# [x] Tapping **Finish** on `MedicalHistoryPage` triggers asynchronous submission.

# [x] RPC `submit_onboarding` succeeds and returns `200`.

# [x] `AuthService.completeOnboarding()` is invoked; Supabase row shows `onboarding_complete = true`.

# [x] Local `OnboardingDraft` is cleared.

# [x] Failure shows retry snackbar; success navigates to `LaunchController`.

**Tasks**

| ID   | Description                                                         | Status  |
| ---- | ------------------------------------------------------------------- | ------- |
| T1.1 | Add `OnboardingCompletionController` (handles loading/error state). | ✅ Done |
| T1.2 | Invoke `onboardingRepository.submit()` with current draft.          | ✅ Done |
| T1.3 | After success call `authService.completeOnboarding()`.              | ✅ Done |
| T1.4 | Clear `OnboardingDraftStorageService` and cancel autosave timer.    | ✅ Done |
| T1.5 | Replace `Navigator.pop()` in `MedicalHistoryPage` with new handler. | ✅ Done |
| T1.6 | Add snackbar + progress indicator widget.                           | ✅ Done |

---

### M2 — Scoring & Personalisation Tags

**Acceptance Criteria**

[x] Motivation type, readiness level, and coach style are computed exactly
per`M1.11.5` rules. [x] Tags are included in the RPC parameters and stored in
Supabase. [x] Computation completes in < 200 ms (p95).

**Tasks**

| ID   | Description                                                                               | Status  |
| ---- | ----------------------------------------------------------------------------------------- | ------- |
| T2.1 | Expose `ScoringService.computeTags(OnboardingDraft)` (pure Dart).                         | ✅ Done |
| T2.2 | Call service before submission; capture `motivationType`, `readinessLevel`, `coachStyle`. | ✅ Done |
| T2.3 | Unit-test boundary values for tag mapping (≥ 95 % branch coverage).                       | ✅ Done |

---

### M3 — Navigation & UX Polish

**Acceptance Criteria**

[ ] Entire onboarding flow uses `GoRouter` paths `/onboarding/step1–6`. [ ]
Deep-linked steps cannot be accessed unless previous steps complete. [ ]
Progress indicator shows current step / total. [ ] After completion, relaunching
app never reopens onboarding for that user.

**Tasks**

| ID   | Description                                                    | Status     |
| ---- | -------------------------------------------------------------- | ---------- |
| T3.1 | Extend `routes.dart` with steps 3-6, guard by draft state.     | ⚪ Planned |
| T3.2 | Add `StepProgressBar` widget to all onboarding pages.          | ⚪ Planned |
| T3.3 | Implement `CanPopScope` to prevent accidental back navigation. | ⚪ Planned |
| T3.4 | Update `OnboardingGuard` to allow in-flight submissions.       | ⚪ Planned |

---

### M4 — Automated Tests

**Acceptance Criteria**

[ ] Happy-path integration test simulates all six pages, asserts RPC & profile
flag. [ ] Failure path test simulates network error and shows retry. [ ]
Coverage ≥ 85 % on new services/controllers.

**Tasks**

| ID   | Description                                                              | Status     |
| ---- | ------------------------------------------------------------------------ | ---------- |
| T4.1 | Create `onboarding_full_flow_test.dart` using `mocktail` + `fake_async`. | ⚪ Planned |
| T4.2 | Add unit tests for `ScoringService` edge cases.                          | ⚪ Planned |
| T4.3 | Update CI coverage thresholds and golden files.                          | ⚪ Planned |

---

## ⏱ Estimated Effort

| Milestone | Complexity | Estimate                |
| --------- | ---------- | ----------------------- |
| M1        | Medium     | 8 h                     |
| M2        | Light      | 4 h                     |
| M3        | Medium     | 6 h                     |
| M4        | Light      | 4 h                     |
| **Total** |            | **22 h** (≈ 3 dev-days) |

---

## 🚀 Sprint Definition of Done

[ ] All acceptance criteria met. [ ] CI (`make ci-local -j fast`) passes green.
[ ] Coverage report ≥ 85 % overall. [ ] QA can complete onboarding, data visible
in Supabase dashboard. [ ] Documentation updated (this file + README snippets if
API changed).
