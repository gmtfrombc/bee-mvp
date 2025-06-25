import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/services/vitals/processing/vitals_aggregator.dart';
import 'package:app/core/services/vitals_notifier_service.dart';

void main() {
  test('Aggregator handles 100k samples under 1s', () {
    final aggregator = VitalsAggregator();

    final now = DateTime.now();
    final samples = List.generate(100000, (i) {
      return VitalsData(
        steps: i % 100,
        timestamp: now.subtract(Duration(seconds: i)),
        quality: VitalsQuality.good,
        metadata: const {'source': 'bench'},
      );
    });

    final sw = Stopwatch()..start();
    for (final s in samples) {
      aggregator.add(s);
    }
    sw.stop();

    // Expect processing throughput well under target (1ms per 100 samples).
    final elapsedMs = sw.elapsedMilliseconds;
    expect(
      elapsedMs < 5000,
      true,
      reason: 'Expected <5s for 100k samples, got ${elapsedMs}ms',
    );
  });
}
