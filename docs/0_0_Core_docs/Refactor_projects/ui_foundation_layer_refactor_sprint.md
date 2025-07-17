# Sprint PRD – UI Foundation Layer Refactor (Generated 2025-07-17)

> **Goal** — Introduce a shared UI foundation to eliminate duplicate form &
> feedback widgets (text fields, snackbars, validators) and enforce consistent
> styling across the Flutter code-base.
>
> **Scope** — `app/lib/core/` additions + targeted refactor of existing screens
> (Auth, Onboarding) to adopt the new components. Tests & generated files are
> excluded unless specifically listed.

---

## 1 📊 Current Pain Points

| Duplicate element  | Count                                                 | Notes                           |
| ------------------ | ----------------------------------------------------- | ------------------------------- |
| Text input widgets | 2 bespoke `_BeeTextField`s + ≈15 raw `TextFormField`s | Inconsistent padding/decoration |
| Snack-bar calls    | >50 direct `ScaffoldMessenger.of` invocations         | Divergent colours & wording     |
| Validators         | ≥4 ad-hoc email/password/number validators            | Impossible to update globally   |

---

## 2 🎯 Objectives

1. Provide a reusable **BeeTextField** supporting label, obscure toggle, suffix
   icon & validation.
2. Provide a **BeeSnackbar / BeeToast** helper for success, error, info toasts.
3. Centralise common validators under `core/validators/`.
4. Update Auth & Onboarding flows to use the new components (proof of adoption).
5. Add linter rule (custom) to forbid raw `TextFormField` outside core.

---

## 3 🗂 Task Breakdown

| ID  | Task                                                                                  | Target File(s) | Owner     | Est. hrs | Status      | Dependencies |
| --- | ------------------------------------------------------------------------------------- | -------------- | --------- | -------- | ----------- | ------------ |
| U1  | Create `core/ui/widgets/bee_text_field.dart`                                          | new            | mobile    | 2        | ✅ Complete | —            |
| U2  | Create `core/ui/bee_toast.dart` (snackbar wrapper)                                    | new            | mobile    | 2        | ✅ Complete | —            |
| U3  | Move email & pwd validators to `core/validators/auth_validators.dart`                 | new            | mobile    | 1        | ✅ Complete | —            |
| U4  | Add numeric range & unit validators `core/validators/numeric_validators.dart`         | new            | mobile    | 1        | ⚪ Planned  | —            |
| U5  | Refactor `auth/ui/auth_page.dart` & `auth/ui/login_page.dart` to use **BeeTextField** | existing       | mobile    | 2        | ⚪ Planned  | U1-U3        |
| U6  | Refactor `onboarding/ui/about_you_page.dart`, `goal_setup_page.dart`                  | existing       | mobile    | 2        | ⚪ Planned  | U1-U4        |
| U7  | Implement `BeeDropdown` (generic) & `BeePrimaryButton` (loading state)                | new            | mobile    | 2        | ⚪ Planned  | —            |
| U8  | Custom lint rule in `analysis_options.yaml` to disallow raw `TextFormField`           | config         | dev-infra | 1        | ⚪ Planned  | U1           |
| U9  | Widget & unit tests for **BeeTextField** & **BeeToast** (coverage ≥90 %)              | test           | QA        | 2        | ⚪ Planned  | U1, U2       |
| U10 | Update docs (`architecture/auto_flutter_architecture.md`)                             | docs           | DX        | 1        | ⚪ Planned  | All          |
| U11 | Add CI check to ensure lint passes                                                    | CI             | dev-infra | 1        | ⚪ Planned  | U8           |

_Total effort: 16 hrs (≈ 2 dev-days)._ Tasks U5–U7 can run in parallel once
U1–U3 merge.

---

## 4 🔄 Workflow Steps

1. **Branch:** `feat/ui-foundation-layer` off `main`.
2. Implement tasks U1–U4, add tests (U9), commit individually.
3. Open PR #1, request review; ensure CI (lint + tests) passes.
4. After merge, branch `feat/ui-foundation-adoption`.
5. Implement tasks U5–U8, update docs (U10), add CI tweak (U11).
6. Open PR #2, request review; ensure full test suite green.
7. Merge & delete branches; tag release `v0.8.0`.

---

## 5 ✅ Acceptance Criteria

- [ ] **BeeTextField** replaces all bespoke text fields in Auth & Onboarding
      screens.
- [ ] **BeeToast** used in ≥80 % of previous snackbar call-sites within modified
      screens.
- [ ] Centralised validators cover email, password, numeric range; no duplicate
      code remains in modified files.
- [ ] No `TextFormField(` usage outside core/ (lint enforced).
- [ ] All tests pass; added widget/unit tests ≥ 85 % coverage for new
      components.
- [ ] No linter warnings (`flutter analyze --fatal-warnings`).

---

## 6 ⏳ Timeline

| Milestone                            | Tasks     | ETA   |
| ------------------------------------ | --------- | ----- |
| **M1** – Foundation Components       | U1–U4, U9 | Day 1 |
| **M2** – Adoption in Auth/Onboarding | U5–U7     | Day 2 |
| **M3** – Lint & CI, Docs             | U8–U11    | Day 3 |

---

## 7 🚧 Risks & Mitigations

| Risk                                   | Mitigation                                                |
| -------------------------------------- | --------------------------------------------------------- |
| Overhaul breaks form layouts           | Release behind feature flag `kNewUIText` for initial QA.  |
| Linter rule causes widespread failures | Apply as `warning` first; flip to `error` after adoption. |
| Inconsistent Toast styles on dark-mode | Create theme extension & snapshot test both modes.        |

---

_This sprint PRD is auto-generated by Cursor AI (2025-07-??). Update task status
inline as work progresses._
