import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/core/services/vitals_notifier_service.dart';
import 'package:app/core/services/vitals/cache/vitals_cache.dart';

void main() {
  group('VitalsCache', () {
    late VitalsCache cache;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      cache = VitalsCache();
    });

    test('returns null when nothing cached', () async {
      final result = await cache.read();
      expect(result, isNull);
    });

    test('writes and reads snapshot successfully', () async {
      final data = VitalsData(
        heartRate: 72,
        steps: 1000,
        sleepHours: 7.5,
        timestamp: DateTime(2025, 6, 25, 12),
      );

      await cache.write(data);
      final restored = await cache.read();

      expect(restored?.heartRate, 72);
      expect(restored?.steps, 1000);
      expect(restored?.sleepHours, 7.5);
    });
  });
}
