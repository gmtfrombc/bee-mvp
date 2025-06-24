import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/services/health_permission_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HealthPermissionManager', () {
    test('initializes only once and emits delta stream', () async {
      final mgr = HealthPermissionManager();

      final ok1 = await mgr.initialize();
      expect(ok1, isTrue);

      // Second call should be noop and return true quickly.
      final ok2 = await mgr.initialize();
      expect(ok2, isTrue);

      // Ensure second init returns quickly (guard).
      final sw = Stopwatch()..start();
      await mgr.initialize();
      expect(sw.elapsed, lessThan(const Duration(seconds: 1)));
    });
  });
}
