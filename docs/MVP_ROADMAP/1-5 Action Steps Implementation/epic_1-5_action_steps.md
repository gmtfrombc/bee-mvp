### Epic: 1.5 · Action Steps

**Module:** Core Mobile Experience & AI Coach **Status:** 🟡 Planned
**Dependencies:** Supabase project & env secrets ✅, Epic 1.8 – Momentum Score
⚪, Epic 1.11 – Onboarding ✅

---

## 📋 Epic Overview

**Goal:** Enable patients to set, track, and reflect on weekly _Action
Steps_—small, process-focused goals—integrated with the AI Coach. The feature
must store structured goals, deliver coach-led suggestions, log completions, and
update the Momentum Score. Maintain ≥ 85 % unit/widget coverage and follow
Flutter 3.3.2a + Supabase architecture rules.

**Success Criteria:**

- ≥ 90 % of active users successfully set an Action Step within their first
  eligible week.
- Goal-setting latency < 2 s p95; completion logging < 1 s p95.
- Momentum Score reflects Action-Step completion within 5 min (staging metrics).
- WCAG AA compliance for all new UI; no magic numbers (use
  `responsive_services.dart`, `theme.dart`).
- Static analysis passes with `--fatal-warnings`; ≥ 85 % unit/widget coverage.
- No P1 security findings in OWASP MASVS audit.

---

## 🏁 Milestone Breakdown

### M1.5.1 · Supabase Schema & RLS Policies

| Task | Description                                                                                                                 | Hours | Status     |
| ---- | --------------------------------------------------------------------------------------------------------------------------- | ----- | ---------- |
| T1   | Design `action_steps` table (`id`, `user_id`, `category`, `description`, `frequency`, `week_start`, `source`, `created_at`) | 2h    | 🟡 Planned |
| T2   | Add audit & `updated_at` triggers                                                                                           | 2h    | 🟡 Planned |
| T3   | Implement RLS to enforce row-level user isolation                                                                           | 3h    | 🟡 Planned |
| T4   | Write SQL unit tests for RLS + triggers (`tests/db/test_action_steps.py`)                                                   | 3h    | 🟡 Planned |

**Deliverables:** Migration SQL, RLS policies, CI tests green.

**Acceptance Criteria:** Table deploys via migration; unauthorized access
blocked; tests pass in CI.

**QA / Tests:** Postgres unit tests via `pytest` container.

---

### M1.5.2 · Flutter Goal-Setting UI

| Task | Description                                                                           | Hours | Status     |
| ---- | ------------------------------------------------------------------------------------- | ----- | ---------- |
| T1   | Build `ActionStepSetupPage` with Riverpod form (Category, Description, Frequency 3-7) | 6h    | 🟡 Planned |
| T2   | Implement validation (positive phrasing, frequency bounds)                            | 3h    | 🟡 Planned |
| T3   | Connect page to Supabase insert RPC; show snackbar on error                           | 2h    | 🟡 Planned |
| T4   | Integrate with onboarding flow (Epic 1.11) – optional first-time prompt               | 2h    | 🟡 Planned |

**Acceptance Criteria:** Users can create/edit Action Step; validation prevents
invalid goals; E2E test passes on iOS & Android.

**QA / Tests:** Widget tests for validation; integration test with Supabase
emulator.

---

### M1.5.3 · AI Coach Suggestion Engine (Edge Function)

| Task | Description                                                                     | Hours | Status     |
| ---- | ------------------------------------------------------------------------------- | ----- | ---------- |
| T1   | Create edge function `suggest-action-steps@1.0.0` (SemVer tag)                  | 4h    | 🟡 Planned |
| T2   | Implement logic: fetch past goals, user priorities, return 3-5 suggestions JSON | 4h    | 🟡 Planned |
| T3   | Add unit tests (`supabase/functions/tests/suggest_action_steps_test.ts`)        | 3h    | 🟡 Planned |
| T4   | Wire function into AI Coach conversation engine                                 | 3h    | 🟡 Planned |

**Acceptance Criteria:** Function returns suggestions < 500 ms p95; coach
message renders options; unit tests ≥ 90 % coverage.

**QA / Tests:** Deno test suite; integration test via PostgREST stub.

---

### M1.5.4 · Weekly Tracking & Momentum Update

| Task | Description                                                             | Hours | Status     |
| ---- | ----------------------------------------------------------------------- | ----- | ---------- |
| T1   | Create daily check-in UI widget to mark completion/skip                 | 4h    | 🟡 Planned |
| T2   | Persist completions in `action_step_logs` table (new)                   | 3h    | 🟡 Planned |
| T3   | Edge function `update-momentum-from-action-step@1.0.0` to publish event | 3h    | 🟡 Planned |
| T4   | Write Flutter provider to listen for momentum updates                   | 2h    | 🟡 Planned |

**Acceptance Criteria:** Completion toggles update UI instantly; Momentum Score
visible change within 5 min in staging.

**QA / Tests:** Widget test for completion flow; unit test for event payload.

---

### M1.5.5 · Rewards, Accessibility & Analytics

| Task | Description                                                              | Hours | Status     |
| ---- | ------------------------------------------------------------------------ | ----- | ---------- |
| T1   | Implement confetti animation (respect animation-reduce setting)          | 2h    | 🟡 Planned |
| T2   | Add empathetic coach message variants for success/failure                | 2h    | 🟡 Planned |
| T3   | Instrument analytics events (`action_step_set`, `action_step_completed`) | 2h    | 🟡 Planned |
| T4   | Conduct WCAG AA audit & fix issues                                       | 2h    | 🟡 Planned |

**Acceptance Criteria:** Animation disabled when
`MediaQuery.of(context).disableAnimations` true; analytics events captured in
Amplitude; accessibility audit passes.

**QA / Tests:** Golden tests for reduced-motion mode; analytics unit test using
mock.

---

## ⏱ Status Flags

🟡 Planned 🔵 In Progress ✅ Complete

---

## 🔗 Dependencies

- Supabase secrets at `~/.bee_secrets/supabase.env`.
- Flutter SDK 3.3.2a with Riverpod v2.
- Epic 1.8 Momentum Score calculator (event consumer).
- Epic 1.11 Onboarding intro screens.
- CI pipeline enforcing `--fatal-warnings` + ≥ 85 % coverage.
