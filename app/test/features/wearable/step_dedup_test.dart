// Placeholder test for step deduplication (VR-03).
// A proper mock of VitalsNotifierService will be added in a follow-up patch.

import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/services/vitals_notifier_service.dart';
import 'package:app/core/services/vitals_notifier_service.dart'
    show VitalsData, VitalsQuality;

void main() {
  group('sumStepsForTest', () {
    test('chooses watch samples over phone within same minute', () {
      final base = DateTime(2025, 1, 1, 12, 0);

      final samples = [
        // Phone sample at 12:00 with 50 steps
        _sample(50, base, source: 'iPhone'),
        // Watch sample at 12:00 with 60 steps → should win
        _sample(60, base, source: 'Apple Watch'),
        // Next minute phone only 30
        _sample(30, base.add(const Duration(minutes: 1)), source: 'iPhone'),
      ];

      final total = VitalsNotifierService.sumStepsForTest(samples);

      // Expect 60 (minute 0) + 0 = 60 because minute 1 phone sample is ignored
      expect(total, 60);
    });

    test('dedups multiple samples per minute by max value', () {
      final base = DateTime(2025, 1, 1, 9, 15);

      final samples = [
        _sample(10, base, source: 'iPhone'),
        _sample(12, base.add(const Duration(seconds: 30)), source: 'iPhone'),
        _sample(5, base.add(const Duration(minutes: 1)), source: 'iPhone'),
      ];

      // Expected: minute 0 → max(10,12)=12; minute 1 → 5; total=17
      final total = VitalsNotifierService.sumStepsForTest(samples);
      expect(total, 17);
    });

    test('returns null for empty list', () {
      expect(VitalsNotifierService.sumStepsForTest([]), isNull);
    });
  });
}

// Helper to build VitalsData quickly.
VitalsData _sample(int steps, DateTime ts, {required String source}) {
  return VitalsData(
    steps: steps,
    timestamp: ts,
    quality: VitalsQuality.good,
    metadata: {'source': source},
  );
}
