# Health Data Module

The **Health Data** module provides a single source of truth for all
health-signal data – from perceived energy to manual biometrics – across the Bee
mobile application.

## Directory map

```
app/lib/core/health_data/
  models/            ← Data classes (EnergyLevel, BiometricManualInput, MetabolicScore)
  validators/        ← Numeric & unit validators shared by features
  services/          ← HealthDataRepository + Riverpod provider
  widgets/           ← UI components (EnergyInputSlider, BiometricsForm, etc.)
```

## Extending the module

1. **Add/modify a model** in `models/`, ensuring `freezed` + `json_serializable`
   are used where appropriate.
2. **Expose CRUD methods** in `HealthDataRepository` (or a sub-repository) –
   keep queries in the repository layer; UI must never talk to Supabase
   directly.
3. **Add validators** to `validators/` when logic will be reused across
   features.
4. **Create widgets** in `widgets/` that read from Riverpod providers and remain
   stateless.

> 💡 Keep each file < 300 LOC to avoid "God" files (see component governance
> docs).

## Supabase & RLS

Schema lives in `supabase/migrations/V20250717_health_data.sql` and is protected
by Row Level Security. All queries must include the authenticated user ID
(`auth.uid()`). Repository tests mock Supabase to validate policy compliance.

## Testing & coverage

- Target ≥ 90 % line coverage for services/validators and ≥ 70 % for widgets
  (golden tests counted).
- Widget tests run in CI via `flutter test` – no extra configuration is
  required.

_Last updated: 2025-07-18_
