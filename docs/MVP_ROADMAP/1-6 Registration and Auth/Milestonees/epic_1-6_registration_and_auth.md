### Epic: 1.6 · Registration & Auth

**Module:** Core Mobile Experience\
**Status:** 🟡 Planned\
**Dependencies:** Supabase project & env secrets ✅, Epic 1.11 – Onboarding
Intake Surveys ⚪

---

## 📋 Epic Overview

**Goal:** Provide secure email/password registration and login plus session
management using Supabase Auth. After successful authentication, users are
routed to the onboarding flow. Achieve HIPAA-grade security and maintain ≥ 85 %
unit/widget test coverage.

**Success Criteria:**

- 100 % of new users can register and verify their email.
- Login latency < 1 s p95; session persists after app restart.
- Password-reset flow delivers email link within 30 s.
- Static analysis & runtime checks pass (`--fatal-warnings`), ≥ 85 % unit/widget
  coverage.
- No P1 security findings in OWASP MASVS audit.

---

## 🏁 Milestone Breakdown

### M1.6.1 · Supabase Auth Backend Setup

| Task | Description                                             | Hours | Status |
| ---- | ------------------------------------------------------- | ----- | ------ |
| T1   | Enable email/password provider, enforce password policy | 2h    | 🟡     |
| T2   | Create `profiles` table referencing `auth.users.id`     | 1h    | 🟡     |
| T3   | Configure RLS policies & audit triggers                 | 4h    | 🟡     |

**Deliverables:** Supabase migration scripts, verified deployment in staging.

**Acceptance Criteria:**

- `profiles` schema deployed via migration.
- RLS denies cross-user access.
- CI migration tests green.

**QA / Tests:** SQL unit tests for RLS (`test_rls_audit.py`), rollback
verification.

---

### M1.6.2 · Flutter Registration & Login UI

| Task | Description                                                  | Hours | Status |
| ---- | ------------------------------------------------------------ | ----- | ------ |
| T1   | Build `AuthPage` with Riverpod forms (Name, Email, Password) | 6h    | 🟡     |
| T2   | Implement `LoginPage` with validation & error states         | 4h    | 🟡     |
| T3   | Wire forms to Supabase Dart SDK; show snackbar on error      | 2h    | 🟡     |

**Acceptance Criteria:**

- Form validation matches password rules.
- Happy-path E2E test passes on iOS & Android.
- Colors/sizing via `theme.dart` & `responsive_services.dart` (no magic
  numbers).

**QA / Tests:** Widget tests for validation; integration test with Supabase
emulator.

---

### M1.6.3 · Password Reset & Email Verification

| Task | Description                                       | Hours | Status |
| ---- | ------------------------------------------------- | ----- | ------ |
| T1   | Trigger `supabase.auth.resetPasswordForEmail`     | 1h    | 🟡     |
| T2   | Deep-link handler to open password-reset screen   | 3h    | 🟡     |
| T3   | Verification banner removal after confirmed email | 2h    | 🟡     |

**Acceptance Criteria:**

- User can reset password via email link.
- Verification banner disappears once email verified.

**QA / Tests:** Deep-link unit tests; mocked email flow in CI.

---

### M1.6.4 · Session Persistence & Security Hardening

| Task | Description                                                      | Hours | Status |
| ---- | ---------------------------------------------------------------- | ----- | ------ |
| T1   | Persist session with `supabase.auth.currentSession` on app start | 2h    | 🟡     |
| T2   | Implement token-refresh listener                                 | 2h    | 🟡     |
| T3   | Add MFA toggle placeholder (non-blocking)                        | 1h    | 🟡     |

**Acceptance Criteria:**

- Auto-login works after force-quit.
- Tokens refresh silently.
- No plaintext secrets committed.

**QA / Tests:** Unit test for `AuthController` state restore; static scan for
secrets.

---

### M1.6.5 · Onboarding Redirect Hook

| Task | Description                                      | Hours | Status |
| ---- | ------------------------------------------------ | ----- | ------ |
| T1   | Query `profiles.onboarding_complete` after login | 1h    | 🟡     |
| T2   | Navigate to Onboarding flow (Epic 1.11) if false | 1h    | 🟡     |
| T3   | Update flag to true at end of onboarding         | 1h    | 🟡     |

**Acceptance Criteria:**

- New accounts automatically enter onboarding.
- Returning users skip onboarding.
- Unit test confirms routing logic.

**QA / Tests:** Flow test using `integration_test` package.

---

## ⏱ Status Flags

🟡 Planned 🔵 In Progress ✅ Complete

---

## 🔗 Dependencies

- Supabase project & secrets at `~/.bee_secrets/supabase.env`.
- Flutter SDK 3.3.2a with Riverpod v2.
- Epic 1.11 onboarding screens (for redirect).
- CI pipeline enforcing `--fatal-warnings`.
