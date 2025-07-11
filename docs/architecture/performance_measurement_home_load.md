# Performance Measurement Plan – Splash → Home Load

Milestone **M1.11.6** · Action **C3**\
Status: 🟡 Draft – pending review

---

## Objective

Verify that the Home screen becomes visible within **100 ms** after the Splash
screen dismisses on representative devices (Android & iOS).

---

## Measurement Points

1. **T₀ (Splash Dismiss):** `WidgetsBinding.instance.endOfFrame` immediately
   after `SplashScreen` navigation completes.
2. **T₁ (Home First Frame):** First frame rendered for `HomePage` root widget.
3. **Δ = T₁ − T₀** should be ≤ 100 ms.

---

## Tooling

- **Integration Test** using `flutter_test` + `integration_test`.
- **Patrol** for device-level automation (deep-link setup).
- **Timeline Trace:** Use `dart:developer` `Timeline` events to emit
  `splash_end` and `home_first_frame` markers; assert delta.
- **CI Device Lab:** Runs on GitHub Actions with Pixel 4a (Android x86) & iPhone
  11 (simulator) using `future-toolkit` runner.

---

## Benchmark Harness Skeleton

```dart
// test/performance/home_load_benchmark_test.dart
void main() {
  patrol('Splash → Home <100ms', ($) async {
    // Launch app normally
    await $.pumpWidgetAndSettle(MyApp());

    // Wait until HomePage is displayed
    await $(HomePage).waitUntilVisible();

    // Fetch custom timeline events
    final events = await $.timelineEvents;
    final start = events.firstWhere((e) => e.name == 'splash_end');
    final end   = events.firstWhere((e) => e.name == 'home_first_frame');

    expect(end.timestampMicros - start.timestampMicros, lessThan(100000));
  });
}
```

---

## Reporting & Regression Guard

- Benchmark runs on each PR; failure blocks merge.
- Rolling 7-day median tracked in Grafana.

---

_Author: AI Pair-Programmer\
Date: 2025-07-11_
