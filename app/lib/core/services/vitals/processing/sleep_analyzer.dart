import 'package:app/core/services/wearable_data_models.dart';
import 'numeric_helpers.dart';

/// Calculates restorative sleep totals from raw sleep stage samples.
class SleepAnalyzer {
  SleepAnalyzer._();

  /// Returns restorative sleep hours for the latest sleep session contained
  /// in [samples]. Mirrors the original algorithm used inside
  /// `VitalsNotifierService._computeRestfulSleepHoursStatic`.
  static double? computeRestfulSleepHours(List<HealthSample> samples) {
    if (samples.isEmpty) return null;

    // Identify latest timestamp to anchor the analysis window (18 h lookback).
    final latestTs = samples
        .map((s) => s.timestamp)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    DateTime sessionStart;
    if (latestTs.hour < 12) {
      final prevDay = latestTs.subtract(const Duration(days: 1));
      sessionStart = DateTime(prevDay.year, prevDay.month, prevDay.day, 18);
    } else {
      sessionStart = DateTime(latestTs.year, latestTs.month, latestTs.day, 18);
    }
    final sessionEnd = sessionStart.add(const Duration(hours: 18));

    double maxMinutesInBed = 0;
    double minutesAwake = 0;
    double minutesStages = 0;

    for (final s in samples) {
      if (s.timestamp.isBefore(sessionStart) ||
          s.timestamp.isAfter(sessionEnd)) {
        continue;
      }

      final v = NumericHelpers.toDouble(s.value);
      if (v == null) continue;

      switch (s.type) {
        case WearableDataType.sleepAwake:
          minutesAwake += v;
          break;
        case WearableDataType.sleepDuration:
        case WearableDataType.sleepInBed:
          if (v > maxMinutesInBed) maxMinutesInBed = v;
          break;
        case WearableDataType.sleepDeep:
        case WearableDataType.sleepLight:
        case WearableDataType.sleepRem:
        case WearableDataType.sleepAsleep:
          minutesStages += v;
          break;
        default:
          break;
      }
    }

    double? restfulMinutes;
    if (maxMinutesInBed > 0) {
      restfulMinutes = (maxMinutesInBed - minutesAwake).clamp(
        0,
        double.infinity,
      );
    } else if (minutesStages > 0) {
      restfulMinutes = minutesStages;
    }

    if (restfulMinutes == null || restfulMinutes <= 0) return null;
    return restfulMinutes / 60.0;
  }
}
