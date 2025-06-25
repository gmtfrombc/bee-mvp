import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/services/wearable_data_models.dart';
import 'package:app/core/services/vitals/processing/sleep_analyzer.dart';

void main() {
  group('SleepAnalyzer', () {
    test('computes restorative sleep from stages', () {
      final DateTime base = DateTime(2025, 6, 25, 23); // 11 PM

      List<HealthSample> samples = [
        // Deep 100 min
        HealthSample(
          id: '1',
          type: WearableDataType.sleepDeep,
          value: 100.0,
          unit: 'min',
          timestamp: base.add(const Duration(minutes: 10)),
          endTime: null,
          source: 'Apple Watch',
        ),
        // Light 120 min
        HealthSample(
          id: '2',
          type: WearableDataType.sleepLight,
          value: 120.0,
          unit: 'min',
          timestamp: base.add(const Duration(minutes: 120)),
          endTime: null,
          source: 'Apple Watch',
        ),
      ];

      final hours = SleepAnalyzer.computeRestfulSleepHours(samples);
      expect(hours, closeTo((100 + 120) / 60.0, 0.001));
    });

    test('returns null when no valid samples', () {
      expect(SleepAnalyzer.computeRestfulSleepHours([]), isNull);
    });
  });
}
