# Sprint PRD – Health-Data Module Foundation (Generated 2025-07-17)

> **Goal** — Establish a cross-cutting `core/health_data/` module holding
> models, repository layer, validators, and migrations for Perceived Energy
> Score (PES) & Manual Biometrics. This supplies a single source of truth for
> health signals before the upcoming **Health Signals** Epic.
>
> **Scope** — Pure groundwork; _no end-user UI_. Widgets such as
> `EnergyInputSlider` will be implemented in the feature Epic. Tests and docs
> included; generated files excluded.

---

## 1 📊 Current Gaps

| Area          | Gap                                                        |
| ------------- | ---------------------------------------------------------- |
| Domain models | No canonical `EnergyLevel` / `BiometricManualInput` models |
| Data access   | Ad-hoc Supabase calls spread across features               |
| Migrations    | Tables not yet created                                     |
| Validation    | Unit / range checks duplicated or missing                  |
| Tests         | No coverage for serialisation or CRUD                      |

---

## 2 🎯 Objectives

1. Create `core/health_data/` with sub-folders `models/`, `services/`,
   `validators/`, `widgets/` (empty placeholder).
2. Implement Dart models: `EnergyLevel`, `BiometricManualInput`,
   `MetabolicScore`.
3. Implement `HealthDataRepository` (Riverpod provider) offering CRUD + cache.
4. Add Supabase migration **V20250717_health_data.sql** creating `energy_levels`
   & `biometric_manual_inputs` with RLS.
5. Centralise numeric/unit validators used by biometrics.
6. Unit & repository tests (≥90 % coverage).
7. README documenting extension guidelines.
8. Update architecture docs.

---

## 3 🗂 Task Breakdown

| ID   | Task                                                                                        | Target File(s) / Location | Owner     | Est. hrs | Status      | Deps    |
| ---- | ------------------------------------------------------------------------------------------- | ------------------------- | --------- | -------- | ----------- | ------- |
| HD1  | Create folder skeleton `app/lib/core/health_data/...`                                       | new dirs                  | mobile    | 0.5      | ✅ Complete | —       |
| HD2  | Implement `models/energy_level.dart` & unit enum mapping                                    | new                       | mobile    | 1        | ✅ Complete | HD1     |
| HD3  | Implement `models/biometric_manual_input.dart`, `metabolic_score.dart`                      | new                       | mobile    | 2        | ✅ Complete | HD1     |
| HD4  | Implement `validators/numeric_validators.dart`, unit converter utils                        | new                       | mobile    | 1        | ⚪ Planned  | HD1     |
| HD5  | Implement `services/health_data_repository.dart` with Riverpod provider                     | new                       | mobile    | 2        | ⚪ Planned  | HD2-HD4 |
| HD6  | Supabase migration file + RLS for both tables                                               | `supabase/migrations/`    | backend   | 2        | ⚪ Planned  | —       |
| HD7  | Integration test using Supabase emulator (`test/core/health_data_repo_test.dart`)           | new                       | QA        | 2        | ⚪ Planned  | HD5-HD6 |
| HD8  | Widget placeholder files (`widgets/README.md`) explaining upcoming widgets & style contract | new                       | mobile    | 0.5      | ⚪ Planned  | HD1     |
| HD9  | Add README inside `core/health_data/` outlining extension guidelines                        | new                       | DX        | 0.5      | ⚪ Planned  | All     |
| HD10 | Update `docs/architecture/auto_flutter_architecture.md` + new diagram                       | docs                      | DX        | 1        | ⚪ Planned  | All     |
| HD11 | Ensure CI (make ci-fast) runs flutter tests in `core/health_data/`                          | CI                        | dev-infra | 0.5      | ⚪ Planned  | HD7     |

_Total effort: ≈ 12 hrs (1.5 dev-days)._ Tasks HD2–HD5 can run concurrently
after HD1.

---

## 4 🔄 Workflow Steps

1. **Branch:** `feat/health-data-foundation` off `main`.
2. Implement HD1–HD4; commit small chunks.
3. Implement migration HD6; run locally via `supabase db push` (CI uses Docker).
4. Implement repository HD5 and tests HD7.
5. Add README/docs (HD8–HD10).
6. Update CI config (HD11).
7. Open PR; ensure all lint/tests green, request review.
8. Merge & delete branch; tag release `v0.8.1`.

---

## 5 ✅ Acceptance Criteria

- [ ] `core/health_data/` exists with models, services, validators, README.
- [ ] Supabase migration applies cleanly; RLS blocks unauthenticated access.
- [ ] `HealthDataRepository` passes CRUD tests against local emulator.
- [ ] Unit & repo tests ≥ 90 % coverage.
- [ ] No linter warnings (`flutter analyze --fatal-warnings`).
- [ ] Documentation updated; architecture diagram shows module.

---

## 6 ⏳ Timeline

| Milestone                    | Tasks    | ETA     |
| ---------------------------- | -------- | ------- |
| **M1** – Models & Validators | HD1–HD4  | Day 1   |
| **M2** – Repo + Migration    | HD5–HD7  | Day 1–2 |
| **M3** – Docs & CI           | HD8–HD11 | Day 2   |

---

## 7 🚧 Risks & Mitigations

| Risk                                     | Mitigation                                   |
| ---------------------------------------- | -------------------------------------------- |
| Migration conflict with parallel feature | Branch cut short; merge before feature work. |
| Unexpected RLS edge cases                | Add integration tests covering row access.   |
| Future widget requirements change models | Keep models extensible; use nullable fields. |

---

_This sprint PRD is auto-generated by Cursor AI (2025-07-17). Update task status
inline as work progresses._
