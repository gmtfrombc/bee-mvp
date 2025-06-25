import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/services/vitals/processing/vitals_aggregator.dart';
import 'package:app/core/services/vitals_notifier_service.dart';

void main() {
  group('VitalsAggregator', () {
    late VitalsAggregator agg;

    setUp(() {
      agg = VitalsAggregator();
    });

    test('emits merged snapshot and aggregated steps', () async {
      final now = DateTime(2025, 6, 25, 9, 0);
      final later = now.add(const Duration(minutes: 1));

      final raw1 = VitalsData(
        steps: 100,
        timestamp: now,
        metadata: const {'source': 'watch'},
      );
      final raw2 = VitalsData(
        steps: 150,
        timestamp: later,
        metadata: const {'source': 'watch'},
      );

      final emitted = <VitalsData>[];
      agg.stream.listen(emitted.add);

      agg.add(raw1);
      agg.add(raw2);

      // Wait microtask for stream.
      await Future.delayed(Duration.zero);

      // Expect latest merged snapshot at end of list
      expect(emitted.last.steps, 250); // aggregated total today
      expect(emitted.last.metadata['aggregated'], true);
    });

    test('aggregates active energy', () async {
      final now = DateTime.now();
      agg.add(
        VitalsData(
          activeEnergy: 50,
          timestamp: now,
          metadata: const {'source': 'watch'},
        ),
      );
      agg.add(
        VitalsData(
          activeEnergy: 25,
          timestamp: now.add(const Duration(hours: 1)),
          metadata: const {'source': 'watch'},
        ),
      );

      await Future.delayed(Duration.zero);
      expect(agg.current?.activeEnergy, 75);
    });
  });
}
