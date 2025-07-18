### Epic: 1.7 · Health Signals

**Module:** Core Mobile Experience & AI Coach **Status:** 🟡 Planned\
**Dependencies:** `health_data` foundation sprint ⚪, UI Foundation layer ✅,
Epic 1.8 – Momentum Score ⚪

---

## 📋 Epic Overview

**Goal:** Surface both subjective (Perceived Energy Score) and objective (Manual
Biometrics & Biometric Flags) health signals in the BEE app, store them
centrally, and use them to enrich Momentum Score and coach interactions. Must
keep code modular via `core/health_data/`, achieve ≥ 85 % test coverage, and
respect Flutter 3.3.2a + Supabase rules.

**Success Criteria:**

- ≥ 80 % of active users log at least one PES entry within first week
  post-launch.
- Manual Biometrics form completion error rate < 2 %.
- Biometric-trigger chat prompts achieve ≥ 20 % reply rate.
- Momentum Score updates < 5 min from PES/Biometrics events in staging.
- WCAG AA compliance; no magic numbers (use `responsive_services.dart`,
  `theme.dart`).
- `flutter analyze --fatal-warnings` passes; overall coverage ≥ 85 %.

---

## 🏁 Milestone Breakdown

### M1.7.1 · Perceived Energy Score System

| Task | Description                                                         | Hours | Status      |
| ---- | ------------------------------------------------------------------- | ----- | ----------- |
| T1   | Build `EnergyInputSlider` widget (emoji 1-5) with Riverpod provider | 6h    | ✅ Complete |
| T2   | Create PES trend spark-line widget on Momentum screen               | 4h    | ✅ Complete |
| T3   | Persist entries via `HealthDataRepository.insertEnergyLevel()`      | 2h    | ✅ Complete |
| T4   | Daily prompt scheduler (default daily, user configurable)           | 3h    | ✅ Complete |
| T5   | Edge function call `updateMomentumScore()` (+10 pts) on insert      | 3h    | ✅ Complete |

**Deliverables:** Flutter widgets, provider logic, Supabase integration,
edge-function hook.

**Acceptance Criteria:** Users can log energy in ≤ 3 taps; new entry reflects in
Momentum gauge within 5 min; unit/widget tests ≥ 90 % for widgets & provider.

---

### M1.7.2 · Manual Biometrics & Metabolic Health Score

| Task | Description                                                          | Hours | Status     |
| ---- | -------------------------------------------------------------------- | ----- | ---------- |
| T1   | Build `BiometricManualInputForm` using `HealthInputField` components | 8h    | ⚪ Planned |
| T2   | Add numeric/unit validation (lbs↔kg, cm↔ft/in) using core validators | 4h    | ⚪ Planned |
| T3   | Implement `MetabolicHealthScoreService` (z-score → percentile)       | 4h    | ⚪ Planned |
| T4   | Profile tile with latest MHS & 30-day trendline                      | 4h    | ⚪ Planned |
| T5   | Persist data via `HealthDataRepository.insertBiometrics()`           | 2h    | ⚪ Planned |
| T6   | Send Momentum modifier & coach context update on save                | 3h    | ⚪ Planned |

**Deliverables:** Biometrics form UI, backend CRUD, MHS calculation, profile
display.

**Acceptance Criteria:** Valid inputs required; MHS visible immediately on save;
calculation unit tests ≥ 95 % accuracy vs reference dataset.

---

### M1.7.3 · Biometric-Trigger Logic

| Task | Description                                                            | Hours | Status     |
| ---- | ---------------------------------------------------------------------- | ----- | ---------- |
| T1   | Create `biometric_flags` table + RLS                                   | 3h    | ⚪ Planned |
| T2   | Edge function `biometric_flag_detector@1.0.0` (steps/sleep drop rules) | 6h    | ⚪ Planned |
| T3   | AI Coach prompt integration with template variants                     | 4h    | ⚪ Planned |
| T4   | Momentum score update when user confirms disengagement                 | 3h    | ⚪ Planned |
| T5   | Integration tests with Supabase emulator & mocked coach API            | 3h    | ⚪ Planned |

**Deliverables:** Flag detection function, coach prompt flow, updated Momentum
logic, tests.

**Acceptance Criteria:** Flag detection latency < 2 min post-cron; coach prompt
asks relevant question; unit + integration tests ≥ 90 %.

---

### M1.7.4 · Advanced Metabolic Health Score & Gauge

| Task | Description                                                              | Hours | Status     |
| ---- | ------------------------------------------------------------------------ | ----- | ---------- |
| T1   | Convert coefficient tables to JSON asset & repository loader             | 2h    | ⚪ Planned |
| T2   | Extend `MetabolicHealthScoreService` for BMI, A1C→FG, percentile mapping | 3h    | ⚪ Planned |
| T3   | Implement `mapMhsToCategory()` helper for colour bands                   | 1h    | ⚪ Planned |
| T4   | Build `MetabolicScoreGauge` widget with colour-wheel gauge               | 4h    | ⚪ Planned |
| T5   | Enhance form: BMI auto-calc, A1C toggle, validators & tests              | 2h    | ⚪ Planned |
| T6   | Update docs, increase coverage to ≥ 90 % lines / 100 % branches          | 1h    | ⚪ Planned |

**Deliverables:** JSON coefficients asset (or Supabase table), upgraded score
service, category mapper, gauge widget, enhanced form logic, documentation and
tests.

**Acceptance Criteria:**

- Correct coefficient set chosen by sex & cohort; unit tests ≥ 95 % accuracy.
- Score appears in gauge within 3 s of save; category colour matches bands.
- `<10` values rendered as “<10”.
- WCAG AA; no magic numbers; `flutter analyze --fatal-warnings` passes.
- Coverage targets met; widget & service tests green in CI.

---

## ⏱ Status Flags

⚪ Planned 🔵 In Progress ✅ Complete

---

## 🔗 Dependencies

- `~/.bee_secrets/supabase.env` for Supabase creds.
- Flutter 3.3.2a + Riverpod v2.
- Epic 1.8 Momentum Score consumer for score modifiers.
- AI Coach Conversation Engine for chat prompt delivery.
- CI pipeline enforcing `--fatal-warnings`, ≥ 85 % coverage.
