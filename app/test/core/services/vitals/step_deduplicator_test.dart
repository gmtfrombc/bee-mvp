import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/services/vitals_notifier_service.dart';
import 'package:app/core/services/vitals/processing/step_deduplicator.dart';

void main() {
  group('StepDeduplicator', () {
    test('returns null for empty list', () {
      expect(StepDeduplicator.sumSteps([]), isNull);
    });

    test('deduplicates by minute and prefers watch source', () {
      final now = DateTime(2025, 6, 25, 10, 0, 15);
      final samples = [
        VitalsData(
          steps: 10,
          timestamp: now,
          metadata: const {'source': 'Apple Watch'},
        ),
        // Same minute, higher value – should win
        VitalsData(
          steps: 12,
          timestamp: now.add(const Duration(seconds: 30)),
          metadata: const {'source': 'Apple Watch'},
        ),
        // Phone sample in a different minute – ignored because watch chosen
        VitalsData(
          steps: 5,
          timestamp: now.add(const Duration(minutes: 1)),
          metadata: const {'source': 'iPhone'},
        ),
        // Watch sample in another minute
        VitalsData(
          steps: 8,
          timestamp: now.add(const Duration(minutes: 2)),
          metadata: const {'source': 'Apple Watch'},
        ),
      ];

      expect(StepDeduplicator.sumSteps(samples), 20); // 12 + 8
    });
  });
}
