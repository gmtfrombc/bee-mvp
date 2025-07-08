# 📜 Onboarding Intake Schema & Security

This document describes the database objects introduced in milestone **M1.11.1 –
Supabase Schema & RLS**.

## Enum: `energy_rating_schedule`

| Value       |
| ----------- |
| `morning`   |
| `afternoon` |
| `evening`   |
| `night`     |

> Used by `energy_rating_schedules.schedule` to record the user’s preferred
> time-of-day check-in.

---

## Tables

### 1. `public.onboarding_responses`

| Column        | Type          | Constraints                    |
| ------------- | ------------- | ------------------------------ |
| `id`          | `uuid`        | PK, `gen_random_uuid()`        |
| `user_id`     | `uuid`        | FK → `auth.users.id`, NOT NULL |
| `answers`     | `jsonb`       | NOT NULL (raw survey answers)  |
| `inserted_at` | `timestamptz` | default `now()`                |
| `updated_at`  | `timestamptz` | default `now()`                |

_RLS_ – owner-only CRUD (`user_id = auth.uid()`).

_Audit_ – trigger `audit_onboarding_responses` calls `_shared.audit()` on
INSERT/UPDATE/DELETE.

---

### 2. `public.medical_history`

Stores optional medical background details.

| Column                            | Type     |
| --------------------------------- | -------- |
| `conditions`                      | `text[]` |
| `medications`                     | `jsonb`  |
| `allergies`                       | `text[]` |
| `family_history`                  | `jsonb`  |
| _(plus standard id/time columns)_ |          |

_Security_ – owner-only RLS, `audit_medical_history` trigger.

---

### 3. `public.biometrics`

Height, weight, BMI and related baseline biomarkers.

_Security_ – owner-only RLS, `audit_biometrics` trigger.

---

### 4. `public.energy_rating_schedules`

Maps a user to an `energy_rating_schedule` enum value.

_Security_ – owner-only RLS, `audit_energy_rating_schedules` trigger.

---

## Security Summary

1. **Row-Level Security** is enabled on all four tables.
2. Two policies per table:
   - `*_owner_select` – allows `SELECT` when `auth.uid() = user_id`.
   - `*_owner_crud` – allows `INSERT/UPDATE/DELETE` when the same condition
     holds.
3. **Auditing** – every mutating statement is logged to `_shared.audit_log` via
   `_shared.audit()` trigger function.

These objects are created via the migration files prefixed `2025070812****`
under `supabase/migrations/` and are covered by integration tests in
`tests/db/`.
