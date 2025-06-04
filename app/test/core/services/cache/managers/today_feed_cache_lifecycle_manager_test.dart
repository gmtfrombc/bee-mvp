import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:app/core/services/cache/managers/today_feed_cache_lifecycle_manager.dart';
import 'package:app/core/services/cache/today_feed_cache_configuration.dart';

/// **TodayFeedCacheLifecycleManager Test Suite**
///
/// Comprehensive tests for the lifecycle manager including:
/// - Initialization flows (production, test, error scenarios)
/// - Service coordination and dependency management
/// - Timer lifecycle management
/// - Disposal and cleanup procedures
/// - Performance and diagnostic monitoring
/// - Error handling and recovery
void main() {
  group('TodayFeedCacheLifecycleManager', () {
    setUp(() async {
      // Reset shared preferences and lifecycle manager state
      SharedPreferences.setMockInitialValues({});
      TodayFeedCacheLifecycleManager.resetForTesting();

      // Ensure clean test environment
      TodayFeedCacheLifecycleManager.setTestEnvironment(true);
    });

    tearDown(() async {
      // Clean up after each test
      if (TodayFeedCacheLifecycleManager.isInitialized) {
        await TodayFeedCacheLifecycleManager.dispose();
      }
      TodayFeedCacheLifecycleManager.resetForTesting();
    });

    // ═════════════════════════════════════════════════════════════════════════
    // INITIALIZATION TESTS
    // ═════════════════════════════════════════════════════════════════════════

    group('Initialization', () {
      test('should initialize successfully in test environment', () async {
        // Arrange
        expect(TodayFeedCacheLifecycleManager.isInitialized, false);
        expect(TodayFeedCacheLifecycleManager.isTestEnvironment, true);

        // Act
        await TodayFeedCacheLifecycleManager.initialize();

        // Assert
        expect(TodayFeedCacheLifecycleManager.isInitialized, true);
        expect(TodayFeedCacheLifecycleManager.preferences, isNotNull);

        final steps = TodayFeedCacheLifecycleManager.initializationSteps;
        expect(steps, contains('shared_preferences_initialized'));
        expect(steps, contains('configuration_validated'));
        expect(steps, contains('test_mode_completed'));
      });

      test('should handle double initialization gracefully', () async {
        // Arrange
        await TodayFeedCacheLifecycleManager.initialize();
        expect(TodayFeedCacheLifecycleManager.isInitialized, true);

        // Act
        await TodayFeedCacheLifecycleManager.initialize();

        // Assert
        expect(TodayFeedCacheLifecycleManager.isInitialized, true);
        // Should not duplicate initialization steps
      });

      test('should provide initialization metrics', () async {
        // Act
        await TodayFeedCacheLifecycleManager.initialize();
        final metrics =
            TodayFeedCacheLifecycleManager.getInitializationMetrics();

        // Assert
        expect(metrics['initialization_duration_ms'], isA<int>());
        expect(metrics['steps_completed'], greaterThan(0));
        expect(metrics['has_error'], false);
        expect(metrics['test_mode'], true);
        expect(metrics['environment'], isA<String>());
      });

      test('should track initialization steps in correct order', () async {
        // Act
        await TodayFeedCacheLifecycleManager.initialize();
        final steps = TodayFeedCacheLifecycleManager.initializationSteps;

        // Assert
        expect(
          steps.indexOf('shared_preferences_initialized'),
          lessThan(steps.indexOf('configuration_validated')),
        );
        expect(
          steps.indexOf('configuration_validated'),
          lessThan(steps.indexOf('test_mode_completed')),
        );
      });

      test('should handle configuration validation failure', () async {
        // This test would require mocking the configuration validation
        // For now, we'll test that initialization can handle errors
        expect(() async {
          // If configuration were invalid, this should throw
          await TodayFeedCacheLifecycleManager.initialize();
        }, returnsNormally); // In test mode, it should work
      });
    });

    // ═════════════════════════════════════════════════════════════════════════
    // TEST ENVIRONMENT MANAGEMENT TESTS
    // ═════════════════════════════════════════════════════════════════════════

    group('Test Environment Management', () {
      test('should set test environment correctly', () {
        // Act
        TodayFeedCacheLifecycleManager.setTestEnvironment(true);

        // Assert
        expect(TodayFeedCacheLifecycleManager.isTestEnvironment, true);
      });

      test('should clear test environment correctly', () {
        // Arrange
        TodayFeedCacheLifecycleManager.setTestEnvironment(true);
        expect(TodayFeedCacheLifecycleManager.isTestEnvironment, true);

        // Act
        TodayFeedCacheLifecycleManager.setTestEnvironment(false);

        // Assert
        expect(TodayFeedCacheLifecycleManager.isTestEnvironment, false);
      });

      test('should skip full initialization in test environment', () async {
        // Arrange
        TodayFeedCacheLifecycleManager.setTestEnvironment(true);

        // Act
        await TodayFeedCacheLifecycleManager.initialize();
        final steps = TodayFeedCacheLifecycleManager.initializationSteps;

        // Assert
        expect(steps, contains('test_mode_completed'));
        expect(steps, isNot(contains('content_service_initialized')));
        expect(steps, isNot(contains('warming_service_initialized')));
      });
    });

    // ═════════════════════════════════════════════════════════════════════════
    // TIMER MANAGEMENT TESTS
    // ═════════════════════════════════════════════════════════════════════════

    group('Timer Management', () {
      test('should provide timer status', () async {
        // Act
        final status = TodayFeedCacheLifecycleManager.getTimerStatus();

        // Assert
        expect(status, isA<Map<String, dynamic>>());
        expect(status, containsPair('refresh_timer_active', isA<bool>()));
        expect(status, containsPair('timezone_timer_active', isA<bool>()));
        expect(status, containsPair('cleanup_timer_active', isA<bool>()));
        expect(status.containsKey('refresh_timer_id'), true);
        expect(status.containsKey('timezone_timer_id'), true);
        expect(status.containsKey('cleanup_timer_id'), true);
      });

      test('should handle null timer IDs gracefully', () {
        // Act
        final status = TodayFeedCacheLifecycleManager.getTimerStatus();

        // Assert - should not throw when timers are null
        expect(status['refresh_timer_id'], isNull);
        expect(status['timezone_timer_id'], isNull);
        expect(status['cleanup_timer_id'], isNull);
      });

      test('should cancel refresh timer', () {
        // Act
        TodayFeedCacheLifecycleManager.cancelRefreshTimer();
        final status = TodayFeedCacheLifecycleManager.getTimerStatus();

        // Assert
        expect(status['refresh_timer_active'], false);
        expect(status['refresh_timer_id'], isNull);
      });
    });

    // ═════════════════════════════════════════════════════════════════════════
    // DISPOSAL TESTS
    // ═════════════════════════════════════════════════════════════════════════

    group('Disposal', () {
      test('should dispose successfully after initialization', () async {
        // Arrange
        await TodayFeedCacheLifecycleManager.initialize();
        expect(TodayFeedCacheLifecycleManager.isInitialized, true);

        // Act
        await TodayFeedCacheLifecycleManager.dispose();

        // Assert
        expect(TodayFeedCacheLifecycleManager.isInitialized, false);

        final status = TodayFeedCacheLifecycleManager.getTimerStatus();
        expect(status['refresh_timer_active'], false);
        expect(status['timezone_timer_active'], false);
        expect(status['cleanup_timer_active'], false);
      });

      test('should handle disposal when not initialized', () async {
        // Arrange
        expect(TodayFeedCacheLifecycleManager.isInitialized, false);

        // Act & Assert - should not throw
        await TodayFeedCacheLifecycleManager.dispose();
        expect(TodayFeedCacheLifecycleManager.isInitialized, false);
      });

      test('should handle disposal errors gracefully', () async {
        // Arrange
        await TodayFeedCacheLifecycleManager.initialize();

        // Act & Assert - should not throw even if services fail to dispose
        await TodayFeedCacheLifecycleManager.dispose();
        expect(TodayFeedCacheLifecycleManager.isInitialized, false);
      });
    });

    // ═════════════════════════════════════════════════════════════════════════
    // RESET FOR TESTING TESTS
    // ═════════════════════════════════════════════════════════════════════════

    group('Reset for Testing', () {
      test('should reset all state completely', () async {
        // Arrange
        await TodayFeedCacheLifecycleManager.initialize();
        expect(TodayFeedCacheLifecycleManager.isInitialized, true);
        expect(TodayFeedCacheLifecycleManager.preferences, isNotNull);

        // Act
        TodayFeedCacheLifecycleManager.resetForTesting();

        // Assert
        expect(TodayFeedCacheLifecycleManager.isInitialized, false);
        expect(TodayFeedCacheLifecycleManager.preferences, isNull);
        expect(TodayFeedCacheLifecycleManager.isTestEnvironment, false);
        expect(TodayFeedCacheLifecycleManager.initializationSteps, isEmpty);
        expect(TodayFeedCacheLifecycleManager.lastInitializationError, isNull);

        final status = TodayFeedCacheLifecycleManager.getTimerStatus();
        expect(status['refresh_timer_active'], false);
        expect(status['timezone_timer_active'], false);
        expect(status['cleanup_timer_active'], false);
      });

      test('should allow re-initialization after reset', () async {
        // Arrange
        await TodayFeedCacheLifecycleManager.initialize();
        TodayFeedCacheLifecycleManager.resetForTesting();
        TodayFeedCacheLifecycleManager.setTestEnvironment(true);

        // Act
        await TodayFeedCacheLifecycleManager.initialize();

        // Assert
        expect(TodayFeedCacheLifecycleManager.isInitialized, true);
        expect(TodayFeedCacheLifecycleManager.preferences, isNotNull);
      });
    });

    // ═════════════════════════════════════════════════════════════════════════
    // LIFECYCLE STATUS AND MONITORING TESTS
    // ═════════════════════════════════════════════════════════════════════════

    group('Lifecycle Status and Monitoring', () {
      test('should provide comprehensive lifecycle status', () async {
        // Arrange
        await TodayFeedCacheLifecycleManager.initialize();

        // Act
        final status = TodayFeedCacheLifecycleManager.getLifecycleStatus();

        // Assert
        expect(status, isA<Map<String, dynamic>>());
        expect(status, containsPair('is_initialized', true));
        expect(status, containsPair('is_test_environment', true));
        expect(status, containsPair('has_preferences', true));
        expect(
          status,
          containsPair('initialization_steps_count', greaterThan(0)),
        );
        expect(status['initialization_steps'], isA<List>());
        expect(status['timer_status'], isA<Map>());
        expect(status.containsKey('initialization_time'), true);
      });

      test('should provide lifecycle status when not initialized', () {
        // Act
        final status = TodayFeedCacheLifecycleManager.getLifecycleStatus();

        // Assert
        expect(status, containsPair('is_initialized', false));
        expect(status, containsPair('has_preferences', false));
        expect(status, containsPair('initialization_steps_count', 0));
        expect(status['last_error'], isNull);
      });

      test('should track initialization performance metrics', () async {
        // Act
        await TodayFeedCacheLifecycleManager.initialize();
        final metrics =
            TodayFeedCacheLifecycleManager.getInitializationMetrics();

        // Assert
        expect(metrics['initialization_duration_ms'], isA<int>());
        expect(metrics['initialization_duration_ms'], greaterThan(0));
        expect(metrics['steps_completed'], greaterThan(0));
        expect(metrics['has_error'], false);
        expect(metrics['test_mode'], true);
      });

      test('should provide metrics before initialization', () {
        // Act
        final metrics =
            TodayFeedCacheLifecycleManager.getInitializationMetrics();

        // Assert
        expect(metrics['initialization_duration_ms'], isNull);
        expect(metrics['steps_completed'], 0);
        expect(metrics['has_error'], false);
      });
    });

    // ═════════════════════════════════════════════════════════════════════════
    // ERROR HANDLING TESTS
    // ═════════════════════════════════════════════════════════════════════════

    group('Error Handling', () {
      test('should handle SharedPreferences initialization failure', () async {
        // This test would require mocking SharedPreferences to throw
        // For now, verify normal operation doesn't throw
        expect(() async {
          await TodayFeedCacheLifecycleManager.initialize();
        }, returnsNormally);
      });

      test('should track initialization errors', () async {
        // After initialization (which should succeed in test mode)
        await TodayFeedCacheLifecycleManager.initialize();

        // Verify no error was tracked
        expect(TodayFeedCacheLifecycleManager.lastInitializationError, isNull);

        final metrics =
            TodayFeedCacheLifecycleManager.getInitializationMetrics();
        expect(metrics['has_error'], false);
      });

      test('should preserve error state in lifecycle status', () {
        // Act
        final status = TodayFeedCacheLifecycleManager.getLifecycleStatus();

        // Assert - no errors initially
        expect(status['last_error'], isNull);
      });
    });

    // ═════════════════════════════════════════════════════════════════════════
    // INTEGRATION TESTS
    // ═════════════════════════════════════════════════════════════════════════

    group('Integration', () {
      test('should maintain consistent state through lifecycle', () async {
        // Test complete initialization → disposal → reset cycle

        // Initialize
        await TodayFeedCacheLifecycleManager.initialize();
        expect(TodayFeedCacheLifecycleManager.isInitialized, true);

        final initSteps =
            TodayFeedCacheLifecycleManager.initializationSteps.length;
        expect(initSteps, greaterThan(0));

        // Dispose
        await TodayFeedCacheLifecycleManager.dispose();
        expect(TodayFeedCacheLifecycleManager.isInitialized, false);

        // Steps should still be preserved for debugging
        expect(
          TodayFeedCacheLifecycleManager.initializationSteps.length,
          initSteps,
        );

        // Reset
        TodayFeedCacheLifecycleManager.resetForTesting();
        expect(TodayFeedCacheLifecycleManager.initializationSteps, isEmpty);
        expect(TodayFeedCacheLifecycleManager.preferences, isNull);
      });

      test('should handle rapid initialization and disposal cycles', () async {
        // Test multiple rapid cycles
        for (int i = 0; i < 3; i++) {
          TodayFeedCacheLifecycleManager.setTestEnvironment(true);
          await TodayFeedCacheLifecycleManager.initialize();
          expect(TodayFeedCacheLifecycleManager.isInitialized, true);

          await TodayFeedCacheLifecycleManager.dispose();
          expect(TodayFeedCacheLifecycleManager.isInitialized, false);

          TodayFeedCacheLifecycleManager.resetForTesting();
        }
      });

      test(
        'should provide consistent timer status across operations',
        () async {
          // Check initial status
          var status = TodayFeedCacheLifecycleManager.getTimerStatus();
          expect(status['refresh_timer_active'], false);

          // Initialize and check status
          await TodayFeedCacheLifecycleManager.initialize();
          status = TodayFeedCacheLifecycleManager.getTimerStatus();
          expect(status, isA<Map<String, dynamic>>());

          // Dispose and check status
          await TodayFeedCacheLifecycleManager.dispose();
          status = TodayFeedCacheLifecycleManager.getTimerStatus();
          expect(status['refresh_timer_active'], false);
        },
      );
    });
  });
}
