import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/services/vitals_notifier_service.dart';
import 'package:app/core/services/wearable_data_models.dart';

void main() {
  group('Sleep aggregation', () {
    test('computes restorative sleep from segments and in-bed/awake', () {
      final DateTime base = DateTime(2025, 1, 2, 22); // 10 PM

      // Helper to build a HealthSample in minutes
      HealthSample sample(
        WearableDataType type,
        double minutes,
        DateTime timestamp,
      ) {
        return HealthSample(
          id: '${type.name}_${timestamp.millisecondsSinceEpoch}',
          type: type,
          value: minutes, // minutes
          unit: 'min',
          timestamp: timestamp,
          endTime: timestamp.add(Duration(minutes: minutes.round())),
          source: 'Test',
        );
      }

      final samples = <HealthSample>[
        // In-bed total 480 min (8 h)
        sample(WearableDataType.sleepInBed, 480, base),
        // Awake minutes (20)
        sample(
          WearableDataType.sleepAwake,
          20,
          base.add(const Duration(hours: 1)),
        ),
        // Stages
        sample(
          WearableDataType.sleepDeep,
          90,
          base.add(const Duration(hours: 2)),
        ),
        sample(
          WearableDataType.sleepLight,
          270,
          base.add(const Duration(hours: 3)),
        ),
        sample(
          WearableDataType.sleepRem,
          100,
          base.add(const Duration(hours: 4)),
        ),
      ];

      final hours = VitalsNotifierService.computeRestfulSleepForTest(samples);
      expect(hours, closeTo(7.6667, 0.0001)); // 460 min / 60 ≈ 7.6667 h
    });
  });
}
