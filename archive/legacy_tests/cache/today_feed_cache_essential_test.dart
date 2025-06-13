import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/core/services/cache/managers/today_feed_cache_lifecycle_manager.dart';
import 'package:app/core/services/cache/managers/today_feed_cache_metrics_aggregator.dart';
import 'package:app/core/services/cache/today_feed_cache_configuration.dart';

/// **Consolidated Cache Essential Tests**
///
/// Essential tests for cache functionality needed for Epic 1.3 (Adaptive AI Coach Foundation)
/// Consolidates key tests from lifecycle manager and metrics aggregator while removing redundancy
///
/// **Core Coverage:**
/// - Basic cache initialization
/// - Cache invalidation
/// - Error handling
/// - Essential metrics collection
/// - Test environment management
void main() {
  group('TodayFeed Cache Essential Functionality', () {
    setUp(() async {
      // Reset shared preferences and cache state
      SharedPreferences.setMockInitialValues({});
      TodayFeedCacheLifecycleManager.resetForTesting();
      TodayFeedCacheLifecycleManager.setTestEnvironment(true);
      TodayFeedCacheConfiguration.forTestEnvironment();
    });

    tearDown(() async {
      // Clean up after each test
      if (TodayFeedCacheLifecycleManager.isInitialized) {
        await TodayFeedCacheLifecycleManager.dispose();
      }
      TodayFeedCacheLifecycleManager.resetForTesting();
    });

    // ═════════════════════════════════════════════════════════════════════════
    // BASIC INITIALIZATION TESTS
    // ═════════════════════════════════════════════════════════════════════════

    group('Cache Initialization', () {
      test('should initialize successfully in test environment', () async {
        // Arrange
        expect(TodayFeedCacheLifecycleManager.isInitialized, false);

        // Act
        await TodayFeedCacheLifecycleManager.initialize();

        // Assert
        expect(TodayFeedCacheLifecycleManager.isInitialized, true);
        expect(TodayFeedCacheLifecycleManager.preferences, isNotNull);

        final steps = TodayFeedCacheLifecycleManager.initializationSteps;
        expect(steps, contains('shared_preferences_initialized'));
        expect(steps, contains('test_mode_completed'));
      });

      test('should handle double initialization gracefully', () async {
        // Arrange
        await TodayFeedCacheLifecycleManager.initialize();
        expect(TodayFeedCacheLifecycleManager.isInitialized, true);

        // Act & Assert
        expect(() async {
          await TodayFeedCacheLifecycleManager.initialize();
        }, returnsNormally);
        expect(TodayFeedCacheLifecycleManager.isInitialized, true);
      });

      test('should provide basic initialization metrics', () async {
        // Act
        await TodayFeedCacheLifecycleManager.initialize();
        final metrics =
            TodayFeedCacheLifecycleManager.getInitializationMetrics();

        // Assert
        expect(metrics['initialization_duration_ms'], isA<int>());
        expect(metrics['steps_completed'], greaterThan(0));
        expect(metrics['has_error'], false);
        expect(metrics['test_mode'], true);
      });

      test('should track initialization steps in correct order', () async {
        // CRITICAL BUSINESS LOGIC: Ensures proper initialization sequence for AI services

        // Act
        await TodayFeedCacheLifecycleManager.initialize();
        final steps = TodayFeedCacheLifecycleManager.initializationSteps;

        // Assert - Order is critical for Epic 1.3 AI coach reliability
        expect(
          steps.indexOf('shared_preferences_initialized'),
          lessThan(steps.indexOf('configuration_validated')),
          reason:
              'SharedPreferences must be initialized before configuration validation',
        );
        expect(
          steps.indexOf('configuration_validated'),
          lessThan(steps.indexOf('test_mode_completed')),
          reason: 'Configuration must be validated before test mode completion',
        );
      });
    });

    // ═════════════════════════════════════════════════════════════════════════
    // CACHE INVALIDATION TESTS
    // ═════════════════════════════════════════════════════════════════════════

    group('Cache Invalidation', () {
      test('should dispose successfully after initialization', () async {
        // Arrange
        await TodayFeedCacheLifecycleManager.initialize();
        expect(TodayFeedCacheLifecycleManager.isInitialized, true);

        // Act
        await TodayFeedCacheLifecycleManager.dispose();

        // Assert
        expect(TodayFeedCacheLifecycleManager.isInitialized, false);
      });

      test('should handle dispose when not initialized', () async {
        // Arrange
        expect(TodayFeedCacheLifecycleManager.isInitialized, false);

        // Act & Assert
        expect(() async {
          await TodayFeedCacheLifecycleManager.dispose();
        }, returnsNormally);
      });
    });

    // ═════════════════════════════════════════════════════════════════════════
    // ERROR HANDLING TESTS
    // ═════════════════════════════════════════════════════════════════════════

    group('Error Handling', () {
      test('should handle test environment setup correctly', () {
        // Act
        TodayFeedCacheLifecycleManager.setTestEnvironment(true);

        // Assert
        expect(TodayFeedCacheLifecycleManager.isTestEnvironment, true);
      });

      test('should skip full initialization in test environment', () async {
        // Arrange
        TodayFeedCacheLifecycleManager.setTestEnvironment(true);

        // Act
        await TodayFeedCacheLifecycleManager.initialize();
        final steps = TodayFeedCacheLifecycleManager.initializationSteps;

        // Assert - Should skip production-only steps in test mode
        expect(steps, contains('test_mode_completed'));
        expect(steps, isNot(contains('content_service_initialized')));
        expect(steps, isNot(contains('warming_service_initialized')));
      });
    });

    // ═════════════════════════════════════════════════════════════════════════
    // ESSENTIAL METRICS COLLECTION
    // ═════════════════════════════════════════════════════════════════════════

    group('Essential Metrics Collection', () {
      test('should return basic statistics structure', () async {
        // Act
        final result = await TodayFeedCacheMetricsAggregator.getAllStatistics();

        // Assert - Focus on structure, not complex calculations
        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('aggregation_info'), isTrue);

        final aggregationInfo =
            result['aggregation_info'] as Map<String, dynamic>;
        expect(aggregationInfo['aggregator_version'], equals('1.0.0'));
        expect(aggregationInfo['environment'], isNotNull);
        expect(aggregationInfo['services_included'], isA<List>());
      });

      test('should handle service errors gracefully in metrics', () async {
        // Act
        final result =
            await TodayFeedCacheMetricsAggregator.getAllHealthMetrics();

        // Assert - Should return structure even with service failures
        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('aggregation_info'), isTrue);

        // Health summary present only if no errors
        if (!result.containsKey('error')) {
          expect(result.containsKey('health_summary'), isTrue);
        }
      });

      test('should provide system health assessment for AI services', () async {
        // Act
        final result =
            await TodayFeedCacheMetricsAggregator.getSystemHealthAssessment();

        // Assert - Essential for Epic 1.3 AI service monitoring
        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('timestamp'), isTrue);
        expect(result.containsKey('environment'), isTrue);

        // Core fields needed for AI coach health monitoring
        if (!result.containsKey('error')) {
          expect(result.containsKey('overall_score'), isTrue);
          expect(result.containsKey('critical_issues'), isTrue);
          expect(result.containsKey('recommendations'), isTrue);
        }
      });
    });

    // ═════════════════════════════════════════════════════════════════════════
    // BASIC METRICS FILTERING
    // ═════════════════════════════════════════════════════════════════════════

    group('Basic Metrics Filtering', () {
      test('should filter metrics with valid services', () async {
        // Arrange
        final validFilters = ['cache', 'health'];

        // Act
        final result = await TodayFeedCacheMetricsAggregator.getFilteredMetrics(
          validFilters,
        );

        // Assert
        expect(result, isA<Map<String, dynamic>>());

        if (!result.containsKey('error')) {
          expect(result.containsKey('filter_info'), isTrue);
          final filterInfo = result['filter_info'] as Map<String, dynamic>;
          expect(filterInfo['requested_services'], equals(validFilters));
        }
      });

      test('should return error for invalid filters', () async {
        // Arrange
        final invalidFilters = ['invalid_service'];

        // Act
        final result = await TodayFeedCacheMetricsAggregator.getFilteredMetrics(
          invalidFilters,
        );

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('error'), isTrue);
        expect(result['requested_filters'], equals(invalidFilters));
      });
    });

    // ═════════════════════════════════════════════════════════════════════════
    // TIMER MANAGEMENT (BASIC)
    // ═════════════════════════════════════════════════════════════════════════

    group('Basic Timer Management', () {
      test('should provide timer status structure', () async {
        // Act
        final status = TodayFeedCacheLifecycleManager.getTimerStatus();

        // Assert
        expect(status, isA<Map<String, dynamic>>());
        expect(status, containsPair('refresh_timer_active', isA<bool>()));
        expect(status, containsPair('timezone_timer_active', isA<bool>()));
        expect(status, containsPair('cleanup_timer_active', isA<bool>()));
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
    // PERFORMANCE BENCHMARKS FOR EPIC 1.3
    // ═════════════════════════════════════════════════════════════════════════

    group('Performance Benchmarks (AI Service Requirements)', () {
      test('should meet AI service response time requirements', () async {
        // This test ensures cache performance meets Epic 1.3 AI coach requirements

        // Measure cache initialization time
        final stopwatch = Stopwatch()..start();
        await TodayFeedCacheLifecycleManager.initialize();
        stopwatch.stop();

        // Assert: Initialization should be <200ms for AI services
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(200),
          reason:
              'Cache initialization must be under 200ms for AI coach responsiveness',
        );
      });

      test('should validate basic performance targets', () async {
        // Essential performance validation for Epic 1.3
        await TodayFeedCacheLifecycleManager.initialize();

        // Basic performance check
        final metrics =
            TodayFeedCacheLifecycleManager.getInitializationMetrics();

        expect(metrics['initialization_duration_ms'], isA<int>());
        expect(metrics['initialization_duration_ms'], lessThan(200));
        expect(metrics['has_error'], false);
      });
    });

    // ═════════════════════════════════════════════════════════════════════════
    // CRITICAL BUSINESS LOGIC TESTS
    // ═════════════════════════════════════════════════════════════════════════

    group('Critical Business Logic', () {
      test(
        'should provide comprehensive lifecycle status for AI monitoring',
        () async {
          // CRITICAL: Epic 1.3 AI services need detailed status monitoring

          // Arrange
          await TodayFeedCacheLifecycleManager.initialize();

          // Act
          final status = TodayFeedCacheLifecycleManager.getLifecycleStatus();

          // Assert - All fields needed for AI service health monitoring
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
        },
      );

      test('should reset all state completely for test isolation', () async {
        // CRITICAL: Complete state reset prevents cross-test contamination for AI services

        // Arrange
        await TodayFeedCacheLifecycleManager.initialize();
        expect(TodayFeedCacheLifecycleManager.isInitialized, true);
        expect(TodayFeedCacheLifecycleManager.preferences, isNotNull);

        // Act
        TodayFeedCacheLifecycleManager.resetForTesting();

        // Assert - ALL state must be cleared
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

      test(
        'should handle rapid initialization cycles for AI responsiveness',
        () async {
          // CRITICAL: AI services may need rapid restart cycles

          // Test multiple rapid cycles
          for (int i = 0; i < 3; i++) {
            TodayFeedCacheLifecycleManager.setTestEnvironment(true);
            await TodayFeedCacheLifecycleManager.initialize();
            expect(TodayFeedCacheLifecycleManager.isInitialized, true);

            await TodayFeedCacheLifecycleManager.dispose();
            expect(TodayFeedCacheLifecycleManager.isInitialized, false);

            TodayFeedCacheLifecycleManager.resetForTesting();
          }
        },
      );

      test('should track initialization errors for AI debugging', () async {
        // CRITICAL: Error tracking essential for AI service reliability

        // Act
        await TodayFeedCacheLifecycleManager.initialize();

        // Assert - Error tracking must work properly
        expect(TodayFeedCacheLifecycleManager.lastInitializationError, isNull);

        final metrics =
            TodayFeedCacheLifecycleManager.getInitializationMetrics();
        expect(metrics['has_error'], false);
      });

      test(
        'should maintain consistent timer status across operations',
        () async {
          // CRITICAL: Timer consistency needed for AI service reliability

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

      test('should allow re-initialization after reset', () async {
        // CRITICAL: Re-initialization capability needed for AI service recovery

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
    // CONFIGURATION MANAGEMENT
    // ═════════════════════════════════════════════════════════════════════════

    group('Configuration Management', () {
      test('should switch between test and production environments', () {
        // Test environment
        TodayFeedCacheConfiguration.forTestEnvironment();
        expect(TodayFeedCacheConfiguration.isTestEnvironment, isTrue);

        // Production environment
        TodayFeedCacheConfiguration.forProductionEnvironment();
        expect(TodayFeedCacheConfiguration.isProductionEnvironment, isTrue);
      });
    });
  });
}
