# Performance Benchmark Plan – Medical History Checkbox Grid (60 FPS)

**Component**: `MedicalHistoryPage` → `SliverGrid` checkbox list

## Goal

Verify that scrolling & interaction maintain ≥60 frames per second on devices as
old as iPhone SE (2nd gen, A13) or equivalent Android (Pixel 3).

## Approach

1. **Profile-mode integration test** using
   `IntegrationTestWidgetsFlutterBinding`.
2. Start test on physical device/emulator in profile mode
   (`flutter test --profile`).
3. Scroll through entire paginated list (simulate user flicks) & tap 10 random
   checkboxes.
4. Capture frame timing metrics via `binding.frameTimingSummaries`.
5. Fail test if any `average_frame_build_time_millis` >16.6 ms or any
   `average_frame_rasterizer_time_millis` >16.6 ms.
6. Upload `timeline_summary.json` artefact to CI for inspection.

## Sample Code Snippet

```dart
final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
    as IntegrationTestWidgetsFlutterBinding;

// after interactions
final summaries = binding.frameTimingSummaries;
final worstBuild = summaries.map((s) => s.averageBuildTimeMillis).reduce(max);
final worstRaster = summaries.map((s) => s.averageRasterizerTimeMillis).reduce(max);
expect(worstBuild, lessThan(16.7));
expect(worstRaster, lessThan(16.7));
```

## CI Integration

• Add new job `performance-test-ios` & `performance-test-android` in
`.github/workflows/ci.yml`, running on profile-mode with `--device-id` matrix.\
• Store summary files under `coverage/perf/medical_history_grid/`.

## Future Work

• Use `patrol` for more realistic gestures.\
• Automate regression alerts when metrics degrade by >10 %.

---

_Last updated: {{DATE}}_
