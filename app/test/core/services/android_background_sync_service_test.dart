import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/android_background_sync_service.dart';

void main() {
  group('AndroidBackgroundSyncService', () {
    late AndroidBackgroundSyncService service;

    setUp(() {
      service = AndroidBackgroundSyncService();
    });

    test(
      'checkBackgroundSync returns unsupported on non-Android platform',
      () async {
        // Note: This test runs on the test platform, not Android
        final result = await service.checkBackgroundSync();

        expect(result.status, BackgroundSyncStatus.unsupported);
        expect(result.message, contains('Health Connect not available'));
      },
    );

    test('BackgroundSyncResult has correct status flags', () {
      const availableResult = BackgroundSyncResult(
        status: BackgroundSyncStatus.available,
        message: 'Available',
      );

      const limitedResult = BackgroundSyncResult(
        status: BackgroundSyncStatus.limited,
        message: 'Limited',
      );

      const deniedResult = BackgroundSyncResult(
        status: BackgroundSyncStatus.denied,
        message: 'Denied',
      );

      expect(availableResult.isAvailable, isTrue);
      expect(availableResult.isLimited, isFalse);

      expect(limitedResult.isAvailable, isFalse);
      expect(limitedResult.isLimited, isTrue);

      expect(deniedResult.isAvailable, isFalse);
      expect(deniedResult.isLimited, isFalse);
    });

    test('singleton instance returns same object', () {
      final service1 = AndroidBackgroundSyncService();
      final service2 = AndroidBackgroundSyncService();

      expect(identical(service1, service2), isTrue);
    });

    test('isSupported returns false on test platform', () async {
      final supported = await service.isSupported();
      expect(supported, isFalse);
    });

    test('requestPermissions handles empty data types', () async {
      final result = await service.requestPermissions(dataTypes: []);

      expect(result.status, BackgroundSyncStatus.denied);
      expect(result.message, contains('No valid data types'));
    });
  });
}
