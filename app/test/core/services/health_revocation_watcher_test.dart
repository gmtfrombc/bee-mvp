import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/providers/health_revocation_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Health revocation providers', () {
    test('revocationFlagProvider returns true when flag persisted', () async {
      // Arrange – set mock prefs before ProviderContainer is created.
      SharedPreferences.setMockInitialValues({
        'health_permissions_revoked_v1': true,
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Act
      final result = await container.read(revocationFlagProvider.future);

      // Assert
      expect(result, isTrue);
    });

    test('revokedStreamProvider emits latest value', () async {
      // Immediate stream override returning `true` then completes.
      final container = ProviderContainer(
        overrides: [
          revokedStreamProvider.overrideWith((ref) => Stream.value(true)),
        ],
      );
      addTearDown(container.dispose);

      final value = await container.read(revokedStreamProvider.future);
      expect(value, isTrue);
    });
  });
}
