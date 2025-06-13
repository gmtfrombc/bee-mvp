/// Tests for Android Callback Flow Service
/// Part of Epic 2.2 Task T2.2.2.3
library;

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:health/health.dart';
import 'package:app/core/services/android_callback_flow_service.dart';
import 'package:app/core/services/wearable_live_models.dart';

class MockHealth extends Mock implements Health {}

class MockStreamController extends Mock
    implements StreamController<WearableLiveMessage> {}

/// Testable version of AndroidCallbackFlowService for unit testing
class TestableAndroidCallbackFlowService extends AndroidCallbackFlowService {
  final bool isAndroidPlatform;

  TestableAndroidCallbackFlowService(
    super.health,
    super.controller, {
    required this.isAndroidPlatform,
    super.config,
  });

  @override
  bool get isSupported => isAndroidPlatform;
}

void main() {
  late MockHealth mockHealth;
  late MockStreamController mockController;
  late AndroidCallbackFlowService service;

  setUp(() {
    mockHealth = MockHealth();
    mockController = MockStreamController();
    service = AndroidCallbackFlowService(mockHealth, mockController);
  });

  group('AndroidCallbackFlowService', () {
    test('initializes with correct configuration', () {
      // Note: On non-Android platforms, isSupported returns false
      // but the service still initializes properly for testing
      expect(service.isActive, isFalse);
      expect(service.enabledTypes, isNotEmpty);
    });

    test('setup returns unsupported on non-Android platforms', () async {
      // On non-Android platforms, setup should return CallbackFlowUnsupported
      final result = await service.setupCallbackFlow();

      expect(result, isA<CallbackFlowUnsupported>());
      expect(service.isActive, isFalse);
    });

    test(
      'setup would fail when Health Connect unavailable on Android',
      () async {
        // This test simulates Android behavior - actual Android testing
        // would be done through integration tests on Android devices
        // Here we test the error handling logic structure
        when(
          () => mockHealth.configure(),
        ).thenThrow(Exception('Not available'));

        // Create a modified service that simulates Android platform
        final androidService = TestableAndroidCallbackFlowService(
          mockHealth,
          mockController,
          isAndroidPlatform: true,
        );

        final result = await androidService.setupCallbackFlow();

        expect(result, isA<CallbackFlowFailure>());
        expect(
          (result as CallbackFlowFailure).error,
          contains('Not available'),
        );
      },
    );

    test('setup succeeds with valid permissions on Android', () async {
      when(() => mockHealth.configure()).thenAnswer((_) async {});
      when(
        () => mockHealth.hasPermissions(any()),
      ).thenAnswer((_) async => true);

      // Create a testable Android service
      final androidService = TestableAndroidCallbackFlowService(
        mockHealth,
        mockController,
        isAndroidPlatform: true,
      );

      final result = await androidService.setupCallbackFlow();

      expect(result, isA<CallbackFlowSuccess>());
      expect(androidService.isActive, isTrue);

      // Clean up
      await androidService.stopCallbackFlow();
    });

    test('stops callback flow correctly', () async {
      // Test that stopCallbackFlow works even when service not active
      expect(service.isActive, isFalse);

      await service.stopCallbackFlow();
      expect(service.isActive, isFalse);

      // Test that it properly cleans up when stopping an active service
      // (simulated with a testable Android service)
      final androidService = TestableAndroidCallbackFlowService(
        mockHealth,
        mockController,
        isAndroidPlatform: true,
      );

      when(() => mockHealth.configure()).thenAnswer((_) async {});
      when(
        () => mockHealth.hasPermissions(any()),
      ).thenAnswer((_) async => true);

      await androidService.setupCallbackFlow();
      expect(androidService.isActive, isTrue);

      await androidService.stopCallbackFlow();
      expect(androidService.isActive, isFalse);
    });

    test('provides accurate statistics', () async {
      final stats = service.getCallbackFlowStats();

      expect(stats['isActive'], isFalse);
      expect(stats['isSupported'], service.isSupported); // Use actual value
      expect(stats['enabledTypes'], isA<List>());
      expect(stats['throttleInterval'], 5);
    });

    test('disposes resources properly', () async {
      await service.dispose();
      expect(service.isActive, isFalse);
    });
  });
}
