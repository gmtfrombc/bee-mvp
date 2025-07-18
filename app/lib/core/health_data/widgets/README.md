# Health Data Widgets

This folder houses UI components that capture or visualise health-related user
data.

## Planned widgets

- **EnergyInputSlider** – five-point scale slider for perceived energy level.
- **BiometricsForm** – manual entry panel for weight, body-fat %, resting
  heart-rate, etc.
- **MetabolicScoreCard** – displays a composite metabolic score with trend
  arrows.
- **HealthSignalTrendChart** – sparkline able to plot any numeric signal.

## Styling contract

- Never hard-code colours or sizes – obtain them from `Theme.of(context)` and
  `responsive_services.dart`.
- Widgets must be fully responsive from 320 px widths up to tablet form-factors.
- Follow Material accessibility recommendations; label all interactive elements
  and use high-contrast focus styles.

## Data flow

Widgets are stateless and obtain data through Riverpod providers such as
`healthDataRepositoryProvider`. Repository mocks **must** be used in widget
tests to avoid network calls.

## Testing & accessibility

- Provide widget tests with golden images for visual regressions.
- Use `mocktail` to stub repository calls and ensure predictable states.
- Aim for ≥ 90 % statement coverage and include at least one a11y test using
  `flutter_test`ʼs `SemanticsTester`.
