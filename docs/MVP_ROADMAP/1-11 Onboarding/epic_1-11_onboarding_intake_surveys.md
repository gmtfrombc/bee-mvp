### Epic: 1.11 · Onboarding Intake Surveys

**Module:** Core Mobile Experience\
**Status:** 🟡 Planned\
**Dependencies:** Epic 1.6 – Registration & Auth ✅, Supabase project & env
secrets, Design System components

---

## 📋 Epic Overview

**Goal:** Implement a post-registration onboarding flow that personalises the
coaching experience by collecting demographic, behavioural, motivational, and
medical-history data. Responses are stored securely in Supabase, scored into
motivation & readiness tags, and routed to the AI Coach and Momentum algorithms.
Completion flips the `profiles.onboarding_complete` flag so users land on the
Home screen thereafter.

**Success Criteria:**

- ≥ 95 % of new users complete onboarding without crash or block.
- All form submissions persist to Supabase with row-level security enforced.
- Motivation score & AI tags generated in <200 ms (p95) per submission.
- Page transitions <1 s (p95); network payload ≤50 KB per section.
- Static analysis passes (`--fatal-warnings`); overall unit/widget test coverage
  ≥85 %.
- No P1/P2 accessibility issues (WCAG AA checked via tests).

---

## 🏁 Milestone Breakdown

### M1.11.1 · Supabase Schema & RLS 🟡 Planned

| Task | Description                                                  | Hours | Status |
| ---- | ------------------------------------------------------------ | ----- | ------ |
| T1   | Create `onboarding_responses` table (user FK, JSONB answers) | 2h    | 🟡     |
| T2   | Create `medical_history` & `biometrics` tables               | 2h    | 🟡     |
| T3   | Add `energy_rating_schedule` enum + table                    | 1h    | 🟡     |
| T4   | Write RLS policies & `shared_audit` triggers                 | 3h    | 🟡     |
| T5   | Migration tests in CI (`pytest` SQL)                         | 1h    | 🟡     |

**Acceptance Criteria:**

- Tables deployed via migration scripts; rollback verified.
- RLS denies cross-user access; audit trigger logs inserts/updates.

**QA / Tests:** SQL unit tests for RLS; automated rollback test; psql lint.

---

### M1.11.2 · UI – Sections 1–2 (About You, Preferences) 🟡 Planned

| Task | Description                                      | Hours | Status |
| ---- | ------------------------------------------------ | ----- | ------ |
| T1   | Build Riverpod `OnboardingController` state      | 3h    | 🟡     |
| T2   | Create `AboutYouPage` form widgets               | 4h    | 🟡     |
| T3   | Create `PreferencesPage` w/ multi-select chips   | 4h    | 🟡     |
| T4   | Validation & responsive layout (tablet & mobile) | 2h    | 🟡     |

**Acceptance Criteria:**

- Forms follow design system; no magic numbers (use `theme.dart`,
  `responsive_services.dart`).
- Invalid fields show helper text & disable Continue button.

**QA / Tests:** Widget tests for validation; golden tests for layout on three
breakpoints.

---

### M1.11.3 · UI – Sections 3–4 (Readiness & Mindset) 🟡 Planned

| Task | Description                                 | Hours | Status |
| ---- | ------------------------------------------- | ----- | ------ |
| T1   | Build Likert-scale selector component       | 3h    | 🟡     |
| T2   | Implement `ReadinessPage` (questions 10–12) | 3h    | 🟡     |
| T3   | Implement `MindsetPage` (questions 13–16)   | 4h    | 🟡     |
| T4   | Accessibility audit (voice-over, contrast)  | 2h    | 🟡     |

**Acceptance Criteria:**

- Keyboard & screen-reader navigation works.
- Data stored locally in controller until submission.

**QA / Tests:** Unit tests for state serialization; axe-flutter automated a11y
scan.

---

### M1.11.4 · UI – Sections 5 Goal Setup & 6 Medical History 🟡 Planned

| Task | Description                                          | Hours | Status |
| ---- | ---------------------------------------------------- | ----- | ------ |
| T1   | Build `GoalSetupPage` with dynamic follow-up field   | 4h    | 🟡     |
| T2   | Build `MedicalHistoryPage` (checkbox grid)           | 4h    | 🟡     |
| T3   | Biometrics inputs with numeric keyboard + unit hints | 3h    | 🟡     |
| T4   | Persist partial progress for app restarts            | 2h    | 🟡     |

**Acceptance Criteria:**

- Checkbox grid scrolls efficiently (≤16ms/frame).
- Numeric fields reject non-numeric input.

**QA / Tests:** Integration test for resume-after-restart; widget test numeric
validation.

---

### M1.11.5 · Scoring & AI-Tag Generation Logic 🟡 Planned

| Task | Description                                                               | Hours | Status |
| ---- | ------------------------------------------------------------------------- | ----- | ------ |
| T1   | Translate scoring rules (@Onboarding_Survey_Scoring.md) into Dart service | 3h    | 🟡     |
| T2   | Generate `motivation_type`, `readiness_level`, `coach_style` tags         | 2h    | 🟡     |
| T3   | Unit tests covering all score ranges (branch ≥ 95 %)                      | 2h    | 🟡     |
| T4   | Edge-function stub to sync tags to `coach_memory`                         | 3h    | 🟡     |

**Acceptance Criteria:**

- Service returns correct tag for each fixture case.
- Tag generation ≤200 ms (p95) in profile mode.

**QA / Tests:** Pure Dart unit tests; benchmark test; contract test for
edge-function call.

---

### M1.11.6 · Navigation & Completion Hook 🟡 Planned

| Task | Description                                      | Hours | Status |
| ---- | ------------------------------------------------ | ----- | ------ |
| T1   | Submit all collected data to Supabase inside txn | 2h    | 🟡     |
| T2   | Flip `profiles.onboarding_complete = true`       | 1h    | 🟡     |
| T3   | Navigate to Home; guard route on future launches | 2h    | 🟡     |
| T4   | E2E test across reg → onboarding → home flow     | 3h    | 🟡     |

**Acceptance Criteria:**

- New users see onboarding exactly once.
- Returning users bypass onboarding within 100 ms of app start.

**QA / Tests:** Integration test using `integration_test` package; deep-link
test.

---

## ⏱ Status Flags

🟡 Planned 🔵 In Progress ✅ Complete

---

## 🔗 Dependencies

- Supabase project & secrets at `~/.bee_secrets/supabase.env`.
- Flutter SDK 3.3.2a with Riverpod v2.
- Design system components (`theme.dart`, `responsive_services.dart`).
- Epic 1.6 – Registration & Auth (for routing into onboarding).
- CI pipeline enforcing `--fatal-warnings` and coverage ≥85 %.
