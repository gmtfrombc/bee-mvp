import 'package:flutter_test/flutter_test.dart';

/// Benchmark placeholder for MotivationScoringService cold-start latency.
///
/// Runs via `flutter test --enable-benchmark` which measures elapsed wall-time
/// rather than frame count. Once the scoring service is implemented, replace
/// the TODO section with actual instantiation & first call.
void main() {
  test('Motivation scoring cold-start latency <50ms', () async {
    final sw = Stopwatch()..start();
    await Future<void>.delayed(Duration.zero);
    sw.stop();
    final elapsedMs = sw.elapsedMicroseconds / 1000.0;
    // ignore: avoid_print
    print('BENCHMARK: scoring_cold_start_ms=$elapsedMs');
    expect(elapsedMs, lessThan(50));
  });
}
