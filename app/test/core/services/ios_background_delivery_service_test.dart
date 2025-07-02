/// Tests for iOS Background Delivery Service
/// Part of Epic 2.2 Task T2.2.2.2
library;

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:health/health.dart';
import 'package:app/core/services/ios_background_delivery_service.dart';
import 'package:app/core/services/wearable_live_models.dart';

class MockHealth extends Mock implements Health {}

class MockStreamController extends Mock
    implements StreamController<WearableLiveMessage> {}

void main() {
  late MockHealth mockHealth;
  late MockStreamController mockController;
  late IOSBackgroundDeliveryService service;

  setUp(() {
    mockHealth = MockHealth();
    mockController = MockStreamController();
    service = IOSBackgroundDeliveryService(mockHealth, mockController);
  });

  group('IOSBackgroundDeliveryService', () {
    test('creates with correct initial state', () {
      // Note: service.isSupported returns false in test environment (not iOS)
      expect(service.isActive, isFalse);
      expect(service.enabledTypes, isNotEmpty);
    });

    test('setup returns unsupported on non-iOS platform', () async {
      // Act (running in test environment which is not iOS)
      final result = await service.setupBackgroundDelivery();

      // Assert
      expect(result, isA<BackgroundDeliveryUnsupported>());
      expect(service.isActive, isFalse);
    });

    test('service recognizes non-iOS platform correctly', () async {
      // Test environment correctly identifies as non-iOS
      expect(service.isSupported, isFalse);
    });

    test('stop background delivery handles gracefully', () async {
      // Act - should handle gracefully even when not active
      await service.stopBackgroundDelivery();

      // Assert
      expect(service.isActive, isFalse);
    });

    test('pause and resume work in any environment', () async {
      // Act & Assert - these methods should work regardless of platform
      service.pauseBackgroundDelivery();
      service.resumeBackgroundDelivery();

      // No exceptions should be thrown
      expect(service.isActive, isFalse); // Not active in test environment
    });
  });

  group('iOS 15.2+ Compatibility', () {
    test('configuration follows iOS budget limitations', () async {
      // This test verifies the service is configured for iOS budget limits
      const config = IOSBackgroundDeliveryConfig();

      // Should be configured for reasonable polling (not too aggressive)
      // Default polling is 10 seconds, should be at least 5 seconds
      expect(config.pollingInterval.inSeconds, greaterThanOrEqualTo(5));
      expect(config.throttleInterval.inSeconds, greaterThanOrEqualTo(5));
    });

    test('service handles test environment appropriately', () async {
      // In test environment, should return unsupported rather than error
      final result = await service.setupBackgroundDelivery();
      expect(result, isA<BackgroundDeliveryUnsupported>());
    });
  });
}
