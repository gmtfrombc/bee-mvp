# Flutter Testing & Coverage Guide

This document defines **how we test the Flutter app** (`app/`) and how coverage
is measured and enforced.

## 1. Why we test

1. Catch regressions before they reach production.
2. Guarantee core algorithms and business rules behave as specified.
3. Provide quick feedback when refactoring.

## 2. Coverage tiers & targets

| Tier | Code category                                      | Target line coverage      |
| ---- | -------------------------------------------------- | ------------------------- |
| A    | Core business logic, algorithms, critical services | **≥ 90 %**                |
| B    | Supporting services, providers, reducers           | **≥ 70 %**                |
| C    | UI widgets / screens (presentation)                | Smoke / golden tests only |
| D    | Generated, theme, DTOs, assets                     | _Excluded from coverage_  |

We enforce the combined Tier A + B percentage in CI. Current gate (see
`.github/workflows/flutter-ci.yml`) is **≥ 60 %**; we raise it by ~5 % whenever
coverage naturally improves.

## 3. Excluding low-value code

Two mechanisms keep the denominator honest:

1. **Local runs** – `dart_test.yaml`
   ```yaml
   coverage:
       exclude:
           - "lib/**/ui/**"
           - "lib/core/widgets/**"
           - "lib/core/theme/**"
           - "lib/**/models/**"
           - "**/*.g.dart"
           - "lib/firebase_options*.dart"
   ```
2. **CI filter** – identical patterns are applied in the Flutter CI workflow
   using `lcov --remove`.

Feel free to extend these lists when you add new purely-visual directories.

## 4. Test types

1. **Unit tests** – pure Dart; fastest; cover Tier A/B logic.
2. **Widget tests** – run in a headless Flutter engine; cover navigation, layout
   switching & golden images.
3. **Integration tests** – spin up the app, mimic real taps & drags; use
   sparingly for critical flows (e.g. registration).
4. **Golden tests** – pixel snapshots to lock visual regressions; update via
   `flutter test --update-goldens` after intentional UI changes.

## 5. Running tests locally

```bash
# From repo root
cd app
flutter pub get

# Fast unit & widget tests
flutter test

# Regenerate goldens
flutter test --update-goldens test/features/...

# Coverage (honours dart_test.yaml excludes)
flutter test --coverage
open coverage/index.html  # macOS convenience
```

## 6. Continuous Integration

_File: `.github/workflows/flutter-ci.yml`_

CI steps:

1. `flutter test --coverage` generates `coverage/lcov.info`.
2. `lcov --remove` filters out Tier C/D paths.
3. Coverage % is extracted; build fails if below the threshold.
4. Report is uploaded to Codecov for badge & diff comments.

## 7. Pull-request checklist

When you open a PR that changes Flutter code, include:

- [ ] **At least one happy-path test** for every new public service/provider.
- [ ] **One critical edge-case test** (error, timeout, null input, etc.).
- [ ] Updated goldens if you changed pixels.
- [ ] No new warnings from `flutter analyze`.

That’s it—keeping the guard-rails simple and focused on preventing real bugs.
