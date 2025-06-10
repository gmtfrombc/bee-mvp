/// Health Permission Manager Tests
///
/// Simple tests following BEE testing policy:
/// - One happy-path test and critical edge-case tests only
/// - Focus on core logic coverage without complex mocking
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/core/services/health_permission_manager.dart';
import 'package:app/core/services/wearable_data_models.dart';

void main() {
  // Initialize Flutter binding for tests
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('PermissionCacheEntry', () {
    test('happy path - serialization and deserialization', () {
      // Arrange
      final entry = PermissionCacheEntry(
        dataType: WearableDataType.steps,
        isGranted: true,
        lastChecked: DateTime(2024, 1, 1),
        grantedAt: DateTime(2024, 1, 1),
      );

      // Act
      final map = entry.toMap();
      final recreated = PermissionCacheEntry.fromMap(map);

      // Assert
      expect(recreated.dataType, equals(entry.dataType));
      expect(recreated.isGranted, equals(entry.isGranted));
      expect(recreated.lastChecked, equals(entry.lastChecked));
      expect(recreated.grantedAt, equals(entry.grantedAt));
    });

    test('edge case - handles unknown data type', () {
      // Arrange
      final map = {
        'dataType': 'unknown_type',
        'isGranted': true,
        'lastChecked': DateTime(2024, 1, 1).toIso8601String(),
      };

      // Act
      final entry = PermissionCacheEntry.fromMap(map);

      // Assert
      expect(entry.dataType, equals(WearableDataType.unknown));
      expect(entry.isGranted, isTrue);
    });
  });

  group('PermissionDelta', () {
    test('happy path - delta status detection', () {
      // Arrange & Act
      final newlyGranted = PermissionDelta(
        dataType: WearableDataType.steps,
        previousStatus: false,
        currentStatus: true,
        timestamp: DateTime.now(),
      );

      final newlyDenied = PermissionDelta(
        dataType: WearableDataType.heartRate,
        previousStatus: true,
        currentStatus: false,
        timestamp: DateTime.now(),
      );

      final firstTime = PermissionDelta(
        dataType: WearableDataType.sleepDuration,
        previousStatus: null,
        currentStatus: true,
        timestamp: DateTime.now(),
      );

      // Assert
      expect(newlyGranted.isNewlyGranted, isTrue);
      expect(newlyGranted.isNewlyDenied, isFalse);

      expect(newlyDenied.isNewlyGranted, isFalse);
      expect(newlyDenied.isNewlyDenied, isTrue);

      expect(firstTime.isFirstTimeChecked, isTrue);
      expect(firstTime.isNewlyGranted, isFalse);
    });
  });

  group('PermissionManagerConfig', () {
    test('happy path - default configuration', () {
      // Arrange & Act
      const config = PermissionManagerConfig();

      // Assert
      expect(config.cacheExpiration, equals(const Duration(hours: 24)));
      expect(config.toastDisplayDuration, equals(const Duration(seconds: 4)));
      expect(config.enableAutoRetry, isTrue);
      expect(config.maxRetryAttempts, equals(3));
      expect(config.requiredPermissions, contains(WearableDataType.steps));
      expect(config.requiredPermissions, contains(WearableDataType.heartRate));
    });

    test('edge case - custom configuration', () {
      // Arrange & Act
      const config = PermissionManagerConfig(
        cacheExpiration: Duration(hours: 12),
        enableAutoRetry: false,
        maxRetryAttempts: 1,
        requiredPermissions: [WearableDataType.steps],
      );

      // Assert
      expect(config.cacheExpiration, equals(const Duration(hours: 12)));
      expect(config.enableAutoRetry, isFalse);
      expect(config.maxRetryAttempts, equals(1));
      expect(config.requiredPermissions.length, equals(1));
    });
  });

  group('HealthPermissionManager - Basic functionality', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('happy path - singleton instance', () {
      // Act
      final manager1 = HealthPermissionManager();
      final manager2 = HealthPermissionManager();

      // Assert
      expect(identical(manager1, manager2), isTrue);
    });

    test('edge case - not initialized error handling', () {
      // Arrange
      final manager = HealthPermissionManager();

      // Act & Assert
      expect(() => manager.requestPermissions(), throwsA(isA<StateError>()));

      expect(() => manager.checkPermissions(), throwsA(isA<StateError>()));
    });
  });
}
