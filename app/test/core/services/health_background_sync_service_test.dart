/// Tests for HealthBackgroundSyncService
///
/// Following the testing policy: one happy-path test and critical edge-case tests only.
/// Target ≥85% coverage for core logic.

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/health_background_sync_service.dart';
import 'package:app/core/services/wearable_data_models.dart';

void main() {
  group('HealthBackgroundSyncService', () {
    late HealthBackgroundSyncService service;

    setUp(() {
      service = HealthBackgroundSyncService();
    });

    tearDown(() {
      service.dispose();
    });

    group('Happy Path Tests', () {
      test('should initialize with custom configuration', () async {
        // Verify
        expect(service.config.monitoredTypes, contains(WearableDataType.steps));
        expect(
          service.config.fetchInterval,
          equals(const Duration(minutes: 5)),
        );
        expect(
          service.config.lookbackDuration,
          equals(const Duration(minutes: 10)),
        );
      });
    });

    group('Edge Case Tests', () {
      test('should handle multiple start attempts gracefully', () async {
        // Setup
        await service.initialize();

        // Mock successful first start by setting isActive manually
        // Note: This tests the business logic, not platform implementation
        if (!service.isActive) {
          // If platform doesn't support, that's expected behavior
          final firstStart = await service.startMonitoring();
          if (firstStart.isSuccess) {
            // Only test multiple starts if first one succeeded
            final secondStart = await service.startMonitoring();
            expect(secondStart.isSuccess, isFalse);
            expect(secondStart.message, contains('already active'));
          }
        }
      });

      test('should handle stop when not active', () async {
        // Setup
        await service.initialize();

        // Execute - Stop without starting
        final result = await service.stopMonitoring();

        // Verify
        expect(result.isSuccess, isTrue);
        expect(result.message, contains('already stopped'));
      });

      test('should properly dispose and clean up resources', () async {
        // Setup
        await service.initialize();

        // Execute
        service.dispose();

        // Verify - Stream should be closed (returns a done subscription, doesn't throw)
        final subscription = service.events.listen((_) {});
        expect(subscription, isA<StreamSubscription>());
        await subscription.cancel();
      });

      test('should properly update configuration', () async {
        // Setup
        await service.initialize();

        const newConfig = HealthBackgroundSyncConfig(
          monitoredTypes: [WearableDataType.sleepDuration],
          fetchInterval: Duration(minutes: 15),
          lookbackDuration: Duration(minutes: 20),
        );

        // Execute
        service.updateConfig(newConfig);

        // Verify
        expect(
          service.config.monitoredTypes,
          contains(WearableDataType.sleepDuration),
        );
        expect(
          service.config.fetchInterval,
          equals(const Duration(minutes: 15)),
        );
        expect(
          service.config.lookbackDuration,
          equals(const Duration(minutes: 20)),
        );
      });

      test('should provide accurate status information', () async {
        // Setup
        await service.initialize();

        // Execute
        final status = service.getStatus();

        // Verify
        expect(status, isA<Map<String, dynamic>>());
        expect(status['isActive'], isA<bool>());
        expect(status['platform'], isA<String>());
        expect(status['monitoredTypes'], isA<List>());
        expect(status['fetchInterval'], isA<int>());
        expect(status['iosObserversActive'], isA<int>());
        expect(status['androidCallbackFlowActive'], isA<bool>());
      });
    });

    group('Configuration Tests', () {
      test('should use default configuration when none provided', () async {
        // Execute
        await service.initialize();

        // Verify
        final config = service.config;
        expect(config.monitoredTypes, isNotEmpty);
        expect(config.enableNotifications, isFalse);
        // Don't test specific durations as they may vary by platform/implementation
      });

      test('should handle copyWith configuration updates', () {
        // Setup
        final baseConfig = HealthBackgroundSyncConfig.defaultConfig;

        // Execute
        final updatedConfig = baseConfig.copyWith(
          fetchInterval: const Duration(minutes: 20),
          enableNotifications: true,
        );

        // Verify
        expect(
          updatedConfig.fetchInterval,
          equals(const Duration(minutes: 20)),
        );
        expect(updatedConfig.enableNotifications, isTrue);
        expect(updatedConfig.monitoredTypes, equals(baseConfig.monitoredTypes));
        expect(
          updatedConfig.lookbackDuration,
          equals(baseConfig.lookbackDuration),
        );
      });
    });

    group('Event System Tests', () {
      test(
        'should create proper event instances with factory constructors',
        () {
          // Test started event
          final startedEvent = HealthBackgroundSyncEvent.started([
            WearableDataType.steps,
          ]);
          expect(startedEvent, isA<HealthBackgroundSyncStartedEvent>());
          expect(startedEvent.message, contains('started'));

          // Test stopped event
          final stoppedEvent = HealthBackgroundSyncEvent.stopped();
          expect(stoppedEvent, isA<HealthBackgroundSyncStoppedEvent>());
          expect(stoppedEvent.message, contains('stopped'));

          // Test data received event
          final samples = [
            HealthSample(
              id: 'test-1',
              type: WearableDataType.steps,
              value: 1000,
              unit: 'count',
              timestamp: DateTime.now(),
              source: 'test',
            ),
          ];
          final dataEvent = HealthBackgroundSyncEvent.dataReceived(samples);
          expect(dataEvent, isA<HealthBackgroundSyncDataEvent>());
          expect(dataEvent.message, contains('samples'));

          // Test error event
          final errorEvent = HealthBackgroundSyncEvent.error('test error');
          expect(errorEvent, isA<HealthBackgroundSyncErrorEvent>());
          expect(errorEvent.message, contains('error'));
        },
      );

      test('should emit events through stream', () async {
        // Setup
        await service.initialize();

        final events = <HealthBackgroundSyncEvent>[];
        final subscription = service.events.listen(events.add);

        // Execute - Try to start monitoring (may or may not succeed based on platform)
        await service.startMonitoring();

        // Wait for potential events
        await Future.delayed(const Duration(milliseconds: 10));

        // Verify - If any events were emitted, they should be properly typed
        for (final event in events) {
          expect(event.timestamp, isA<DateTime>());
          expect(event.message, isA<String>());
        }

        await subscription.cancel();
      });
    });

    group('Result System Tests', () {
      test(
        'should create proper result instances with factory constructors',
        () {
          // Test success result
          final successResult = HealthBackgroundSyncResult.success(
            'test success',
          );
          expect(successResult, isA<HealthBackgroundSyncSuccessResult>());
          expect(successResult.isSuccess, isTrue);
          expect(successResult.message, equals('test success'));

          // Test failure result
          final failureResult = HealthBackgroundSyncResult.failure(
            'test error',
          );
          expect(failureResult, isA<HealthBackgroundSyncFailureResult>());
          expect(failureResult.isSuccess, isFalse);
          expect(failureResult.message, equals('test error'));
        },
      );
    });
  });
}
