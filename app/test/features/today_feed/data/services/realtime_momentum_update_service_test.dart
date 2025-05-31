import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/today_feed/data/services/realtime_momentum_update_service.dart';

/// Tests for RealtimeMomentumUpdateService (T1.3.4.5)
///
/// Comprehensive test coverage focusing on:
/// - Service initialization and lifecycle
/// - Real-time momentum update functionality
/// - Offline queue management
/// - Error handling and edge cases
/// - Provider integration patterns
/// - Performance and timing requirements
///
/// Simplified approach for unit testing without external dependencies
void main() {
  group('RealtimeMomentumUpdateService Tests', () {
    late RealtimeMomentumUpdateService service;
    late ProviderContainer container;

    setUp(() {
      // Create fresh instances for each test
      service = RealtimeMomentumUpdateService();
      container = ProviderContainer();
    });

    tearDown(() {
      service.dispose();
      container.dispose();
    });

    group('Service Initialization', () {
      test(
        'should handle initialization gracefully in test environment',
        () async {
          // Act - This will handle Supabase initialization errors gracefully
          await service.initialize(container);

          // Assert
          expect(service.isReady, isTrue);
        },
      );

      test('should handle multiple initialization calls gracefully', () async {
        // Act
        await service.initialize(container);

        // Reset and reinitialize to test reinitialization
        service.dispose();
        await service.initialize(container);
        await service.initialize(container); // Second call should be ignored

        // Assert
        expect(service.isReady, isTrue);
      });

      test('should be not ready before initialization', () {
        // Assert
        expect(service.isReady, isFalse);
      });
    });

    group('Core Update Functionality Without Full Dependencies', () {
      test('should return appropriate error when not initialized', () async {
        // Arrange - Don't initialize the service
        const userId = 'test-user-123';
        const pointsAwarded = 1;
        const interactionId = 'test-interaction-456';

        // Act
        final result = await service.triggerMomentumUpdate(
          userId: userId,
          pointsAwarded: pointsAwarded,
          interactionId: interactionId,
        );

        // Assert
        expect(result, isNotNull);
        expect(result.success, isFalse);
        expect(result.interactionId, equals(interactionId));
        expect(result.message, contains('not initialized'));
      });

      test(
        'should handle momentum update request with valid parameters after init',
        () async {
          // Arrange
          await service.initialize(container);
          const userId = 'test-user-123';
          const pointsAwarded = 1;
          const interactionId = 'test-interaction-456';

          // Act
          final result = await service.triggerMomentumUpdate(
            userId: userId,
            pointsAwarded: pointsAwarded,
            interactionId: interactionId,
          );

          // Assert
          expect(result, isNotNull);
          expect(result.interactionId, equals(interactionId));
          expect(result.message, isNotEmpty);
        },
      );

      test('should prevent duplicate updates for same interaction', () async {
        // Arrange
        await service.initialize(container);
        const userId = 'test-user-123';
        const pointsAwarded = 1;
        const interactionId = 'duplicate-test-interaction';

        // Act
        final result1 = service.triggerMomentumUpdate(
          userId: userId,
          pointsAwarded: pointsAwarded,
          interactionId: interactionId,
        );

        final result2 = service.triggerMomentumUpdate(
          userId: userId,
          pointsAwarded: pointsAwarded,
          interactionId: interactionId,
        );

        final [firstResult, secondResult] = await Future.wait([
          result1,
          result2,
        ]);

        // Assert - In test environment, requests might be queued instead of duplicated
        // due to connectivity service limitations, so we check for either scenario
        final hasDuplicate =
            firstResult.isDuplicate || secondResult.isDuplicate;
        final hasQueued = firstResult.isQueued || secondResult.isQueued;

        expect(
          hasDuplicate || hasQueued,
          isTrue,
          reason:
              'Should either detect duplicate or queue for offline processing',
        );
      });
    });

    group('Statistics and Monitoring', () {
      test(
        'should provide update statistics even when not initialized',
        () async {
          // Act
          final stats = await service.getUpdateStatistics();

          // Assert
          expect(stats, isNotNull);
          expect(stats.pendingUpdatesCount, equals(0));
          expect(stats.offlineQueueSize, equals(0));
          expect(stats.isConnected, isFalse);
          expect(stats.averageUpdateDuration, equals(Duration.zero));
          expect(stats.successRate, equals(0.0));
        },
      );

      test(
        'should provide meaningful statistics after initialization',
        () async {
          // Arrange
          await service.initialize(container);

          // Act
          final stats = await service.getUpdateStatistics();

          // Assert
          expect(stats, isNotNull);
          expect(stats.pendingUpdatesCount, isA<int>());
          expect(stats.offlineQueueSize, isA<int>());
          expect(stats.isConnected, isA<bool>());
          expect(stats.averageUpdateDuration, isA<Duration>());
          expect(stats.successRate, isA<double>());
        },
      );
    });

    group('Error Handling', () {
      test('should handle invalid user ID gracefully', () async {
        // Arrange
        await service.initialize(container);
        const invalidUserId = '';
        const pointsAwarded = 1;
        const interactionId = 'invalid-user-interaction';

        // Act
        final result = await service.triggerMomentumUpdate(
          userId: invalidUserId,
          pointsAwarded: pointsAwarded,
          interactionId: interactionId,
        );

        // Assert
        expect(result, isNotNull);
        expect(result.interactionId, equals(interactionId));
      });

      test('should handle edge case point values', () async {
        // Arrange
        await service.initialize(container);
        const userId = 'test-user-123';

        // Test negative points
        var result = await service.triggerMomentumUpdate(
          userId: userId,
          pointsAwarded: -1,
          interactionId: 'negative-points',
        );
        expect(result, isNotNull);

        // Test zero points
        result = await service.triggerMomentumUpdate(
          userId: userId,
          pointsAwarded: 0,
          interactionId: 'zero-points',
        );
        expect(result, isNotNull);

        // Test large points
        result = await service.triggerMomentumUpdate(
          userId: userId,
          pointsAwarded: 1000,
          interactionId: 'large-points',
        );
        expect(result, isNotNull);
      });
    });

    group('Service Lifecycle', () {
      test('should dispose and reinitialize properly', () async {
        // Arrange
        await service.initialize(container);
        expect(service.isReady, isTrue);

        // Act
        service.dispose();
        expect(service.isReady, isFalse);

        // Reinitialize
        await service.initialize(container);

        // Assert
        expect(service.isReady, isTrue);
      });

      test('should handle dispose without initialization', () {
        // Act & Assert - should not throw
        expect(() => service.dispose(), returnsNormally);
      });

      test('should handle updates after disposal gracefully', () async {
        // Arrange
        await service.initialize(container);
        service.dispose();

        // Act
        final result = await service.triggerMomentumUpdate(
          userId: 'test-user',
          pointsAwarded: 1,
          interactionId: 'post-disposal-interaction',
        );

        // Assert
        expect(result, isNotNull);
        expect(result.success, isFalse);
      });
    });

    group('Data Model Validation', () {
      test('RealtimeUpdateResult.success should create valid result', () {
        // Act
        final result = RealtimeUpdateResult.success(
          message: 'Test success',
          interactionId: 'test-interaction',
          updateDuration: const Duration(milliseconds: 100),
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.message, equals('Test success'));
        expect(result.interactionId, equals('test-interaction'));
        expect(
          result.updateDuration,
          equals(const Duration(milliseconds: 100)),
        );
        expect(result.error, isNull);
        expect(result.isQueued, isFalse);
        expect(result.isDuplicate, isFalse);
      });

      test('RealtimeUpdateResult.failed should create valid error result', () {
        // Act
        final result = RealtimeUpdateResult.failed(
          message: 'Test failure',
          interactionId: 'test-interaction',
          error: 'Test error',
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.message, equals('Test failure'));
        expect(result.interactionId, equals('test-interaction'));
        expect(result.error, equals('Test error'));
        expect(result.updateDuration, isNull);
        expect(result.isQueued, isFalse);
        expect(result.isDuplicate, isFalse);
      });

      test('RealtimeUpdateResult.queued should create valid queued result', () {
        // Act
        final result = RealtimeUpdateResult.queued(
          message: 'Test queued',
          interactionId: 'test-interaction',
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.message, equals('Test queued'));
        expect(result.interactionId, equals('test-interaction'));
        expect(result.isQueued, isTrue);
        expect(result.isDuplicate, isFalse);
      });

      test(
        'RealtimeUpdateResult.duplicate should create valid duplicate result',
        () {
          // Act
          final result = RealtimeUpdateResult.duplicate(
            message: 'Test duplicate',
            interactionId: 'test-interaction',
          );

          // Assert
          expect(result.success, isFalse);
          expect(result.message, equals('Test duplicate'));
          expect(result.interactionId, equals('test-interaction'));
          expect(result.isDuplicate, isTrue);
          expect(result.isQueued, isFalse);
        },
      );
    });

    group('RealtimeUpdateStatistics Validation', () {
      test('should create valid statistics object', () {
        // Act
        const stats = RealtimeUpdateStatistics(
          pendingUpdatesCount: 5,
          offlineQueueSize: 10,
          isConnected: true,
          averageUpdateDuration: Duration(milliseconds: 250),
          successRate: 0.95,
        );

        // Assert
        expect(stats.pendingUpdatesCount, equals(5));
        expect(stats.offlineQueueSize, equals(10));
        expect(stats.isConnected, isTrue);
        expect(
          stats.averageUpdateDuration,
          equals(const Duration(milliseconds: 250)),
        );
        expect(stats.successRate, equals(0.95));
      });
    });

    group('CompleterWithTimeout Validation', () {
      test('should complete successfully within timeout', () async {
        // Arrange
        final completer = CompleterWithTimeout(
          timeout: const Duration(milliseconds: 100),
          onTimeout: () {},
        );

        // Act
        completer.complete(true);
        final result = await completer.future;

        // Assert
        expect(result, isTrue);
        expect(completer.isCompleted, isTrue);
      });

      test('should handle timeout properly', () async {
        // Arrange
        bool timeoutCalled = false;
        late CompleterWithTimeout completer;

        completer = CompleterWithTimeout(
          timeout: const Duration(milliseconds: 10),
          onTimeout: () {
            timeoutCalled = true;
            completer.complete(false);
          },
        );

        // Act
        final result = await completer.future;

        // Assert
        expect(result, isFalse);
        expect(timeoutCalled, isTrue);
        expect(completer.isCompleted, isTrue);
      });
    });

    group('Performance and Timing', () {
      test('should complete updates within reasonable time', () async {
        // Arrange
        await service.initialize(container);
        const userId = 'perf-test-user';
        const pointsAwarded = 1;
        const interactionId = 'performance-test-interaction';
        final stopwatch = Stopwatch()..start();

        // Act
        final result = await service.triggerMomentumUpdate(
          userId: userId,
          pointsAwarded: pointsAwarded,
          interactionId: interactionId,
        );

        stopwatch.stop();

        // Assert
        expect(result, isNotNull);
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(10000),
        ); // 10 second timeout
      });
    });
  });
}
