/// Provides helpers to deduplicate step samples and sum totals.
library;

import 'package:app/core/services/vitals_notifier_service.dart';

class StepDeduplicator {
  StepDeduplicator._();

  /// Returns the summed step count after minute-level deduplication.
  ///
  /// Algorithm is identical to the legacy `_sumStepsDedupByMinute` used inside
  /// `VitalsNotifierService`, but extracted here so it can be unit-tested
  /// independently.
  static int? sumSteps(List<VitalsData> samples) {
    if (samples.isEmpty) return null;

    // Group by source string so we can prefer Watch over Phone.
    final Map<String, List<VitalsData>> bySource = {};
    for (final s in samples) {
      final src = (s.metadata['source']?.toString() ?? 'unknown').toLowerCase();
      bySource.putIfAbsent(src, () => <VitalsData>[]).add(s);
    }

    // Prefer Watch samples when available.
    List<VitalsData> chosen;
    final watchEntry = bySource.entries.firstWhere(
      (e) => e.key.contains('watch'),
      orElse: () => const MapEntry<String, List<VitalsData>>('', []),
    );
    if (watchEntry.value.isNotEmpty) {
      chosen = watchEntry.value;
    } else {
      // Otherwise pick the source with the largest step sum.
      chosen = bySource.values.reduce((a, b) {
        final sumA = a.fold<int>(0, (p, v) => p + (v.steps ?? 0));
        final sumB = b.fold<int>(0, (p, v) => p + (v.steps ?? 0));
        return sumA >= sumB ? a : b;
      });
    }

    // Minute-precision deduplication.
    final Map<int, int> minuteMax = {};
    for (final d in chosen) {
      final minuteEpoch =
          DateTime(
            d.timestamp.year,
            d.timestamp.month,
            d.timestamp.day,
            d.timestamp.hour,
            d.timestamp.minute,
          ).millisecondsSinceEpoch;
      final currentMax = minuteMax[minuteEpoch] ?? 0;
      final stepsVal = d.steps ?? 0;
      if (stepsVal > currentMax) minuteMax[minuteEpoch] = stepsVal;
    }

    if (minuteMax.isEmpty) return null;
    return minuteMax.values.fold<int>(0, (a, b) => a + b);
  }
}
