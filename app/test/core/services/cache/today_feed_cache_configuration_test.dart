import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/services/cache/today_feed_cache_configuration.dart';

void main() {
  group('TodayFeedCacheConfiguration Tests', () {
    setUp(() {
      // Reset to production environment before each test
      TodayFeedCacheConfiguration.forProductionEnvironment();
    });

    group('Environment Management', () {
      test('should default to production environment', () {
        expect(
          TodayFeedCacheConfiguration.environment,
          equals(CacheEnvironment.production),
        );
        expect(TodayFeedCacheConfiguration.isProductionEnvironment, isTrue);
        expect(TodayFeedCacheConfiguration.isDevelopmentEnvironment, isFalse);
        expect(TodayFeedCacheConfiguration.isTestEnvironment, isFalse);
      });

      test('should switch to test environment correctly', () {
        TodayFeedCacheConfiguration.forTestEnvironment();

        expect(
          TodayFeedCacheConfiguration.environment,
          equals(CacheEnvironment.testing),
        );
        expect(TodayFeedCacheConfiguration.isTestEnvironment, isTrue);
        expect(TodayFeedCacheConfiguration.isProductionEnvironment, isFalse);
        expect(TodayFeedCacheConfiguration.isDevelopmentEnvironment, isFalse);
      });

      test('should switch to development environment correctly', () {
        TodayFeedCacheConfiguration.forDevelopmentEnvironment();

        expect(
          TodayFeedCacheConfiguration.environment,
          equals(CacheEnvironment.development),
        );
        expect(TodayFeedCacheConfiguration.isDevelopmentEnvironment, isTrue);
        expect(TodayFeedCacheConfiguration.isProductionEnvironment, isFalse);
        expect(TodayFeedCacheConfiguration.isTestEnvironment, isFalse);
      });

      test('should manually set environment', () {
        TodayFeedCacheConfiguration.setEnvironment(CacheEnvironment.testing);
        expect(TodayFeedCacheConfiguration.isTestEnvironment, isTrue);

        TodayFeedCacheConfiguration.setEnvironment(
          CacheEnvironment.development,
        );
        expect(TodayFeedCacheConfiguration.isDevelopmentEnvironment, isTrue);

        TodayFeedCacheConfiguration.setEnvironment(CacheEnvironment.production);
        expect(TodayFeedCacheConfiguration.isProductionEnvironment, isTrue);
      });
    });

    group('Cache Keys Access', () {
      test('should provide correct cache keys', () {
        expect(
          TodayFeedCacheConfiguration.cacheVersionKey,
          equals('today_feed_cache_version'),
        );
        expect(
          TodayFeedCacheConfiguration.timezoneMetadataKey,
          equals('today_feed_timezone_metadata'),
        );
        expect(
          TodayFeedCacheConfiguration.lastTimezoneCheckKey,
          equals('today_feed_last_timezone_check'),
        );
        expect(
          TodayFeedCacheConfiguration.contentDataKey,
          equals('today_feed_content_data'),
        );
        expect(
          TodayFeedCacheConfiguration.previousContentDataKey,
          equals('today_feed_previous_content_data'),
        );
        expect(
          TodayFeedCacheConfiguration.lastRefreshTimeKey,
          equals('today_feed_last_refresh_time'),
        );
      });
    });

    group('Version Management', () {
      test('should provide correct version information', () {
        expect(TodayFeedCacheConfiguration.currentCacheVersion, equals(1));
        expect(TodayFeedCacheConfiguration.minimumCacheVersion, equals(1));
        expect(TodayFeedCacheConfiguration.supportedCacheVersions, equals([1]));
      });

      test('should validate cache versions correctly', () {
        expect(TodayFeedCacheConfiguration.isValidCacheVersion(1), isTrue);
        expect(TodayFeedCacheConfiguration.isValidCacheVersion(0), isFalse);
        expect(TodayFeedCacheConfiguration.isValidCacheVersion(2), isFalse);
        expect(TodayFeedCacheConfiguration.isValidCacheVersion(-1), isFalse);
      });
    });

    group('Timing Configuration - Production Environment', () {
      setUp(() {
        TodayFeedCacheConfiguration.forProductionEnvironment();
      });

      test('should provide correct production timing values', () {
        expect(
          TodayFeedCacheConfiguration.defaultRefreshInterval,
          equals(const Duration(hours: 24)),
        );
        expect(
          TodayFeedCacheConfiguration.fallbackRefreshInterval,
          equals(const Duration(hours: 6)),
        );
        expect(
          TodayFeedCacheConfiguration.forceRefreshCooldown,
          equals(const Duration(minutes: 30)),
        );
        expect(
          TodayFeedCacheConfiguration.timezoneCheckInterval,
          equals(const Duration(minutes: 30)),
        );
        expect(
          TodayFeedCacheConfiguration.scheduledWarmingInterval,
          equals(const Duration(hours: 2)),
        );
        expect(
          TodayFeedCacheConfiguration.predictiveWarmingInterval,
          equals(const Duration(minutes: 30)),
        );
        expect(
          TodayFeedCacheConfiguration.automaticCleanupInterval,
          equals(const Duration(hours: 12)),
        );
        expect(
          TodayFeedCacheConfiguration.syncRetryDelay,
          equals(const Duration(minutes: 2)),
        );
      });
    });

    group('Timing Configuration - Test Environment', () {
      setUp(() {
        TodayFeedCacheConfiguration.forTestEnvironment();
      });

      test('should provide correct test timing values', () {
        expect(
          TodayFeedCacheConfiguration.defaultRefreshInterval,
          equals(const Duration(seconds: 10)),
        );
        expect(
          TodayFeedCacheConfiguration.timezoneCheckInterval,
          equals(const Duration(seconds: 5)),
        );
        expect(
          TodayFeedCacheConfiguration.scheduledWarmingInterval,
          equals(const Duration(seconds: 30)),
        );
        expect(
          TodayFeedCacheConfiguration.automaticCleanupInterval,
          equals(const Duration(minutes: 1)),
        );
        expect(
          TodayFeedCacheConfiguration.syncRetryDelay,
          equals(const Duration(milliseconds: 100)),
        );
      });
    });

    group('Performance Configuration - Production Environment', () {
      setUp(() {
        TodayFeedCacheConfiguration.forProductionEnvironment();
      });

      test('should provide correct production performance values', () {
        expect(
          TodayFeedCacheConfiguration.maxCacheSizeBytes,
          equals(10 * 1024 * 1024), // 10MB
        );
        expect(
          TodayFeedCacheConfiguration.maxResponseTime,
          equals(const Duration(milliseconds: 500)),
        );
        expect(TodayFeedCacheConfiguration.healthThreshold, equals(0.85));
        expect(
          TodayFeedCacheConfiguration.warningHealthThreshold,
          equals(0.70),
        );
        expect(
          TodayFeedCacheConfiguration.criticalHealthThreshold,
          equals(0.50),
        );
        expect(TodayFeedCacheConfiguration.maxHistoryEntries, equals(50));
        expect(TodayFeedCacheConfiguration.maxPendingInteractions, equals(100));
      });
    });

    group('Performance Configuration - Test Environment', () {
      setUp(() {
        TodayFeedCacheConfiguration.forTestEnvironment();
      });

      test('should provide correct test performance values', () {
        expect(
          TodayFeedCacheConfiguration.maxCacheSizeBytes,
          equals(1024 * 1024), // 1MB
        );
        expect(
          TodayFeedCacheConfiguration.maxResponseTime,
          equals(const Duration(milliseconds: 100)),
        );
        expect(TodayFeedCacheConfiguration.healthThreshold, equals(0.75));
        expect(TodayFeedCacheConfiguration.maxHistoryEntries, equals(10));
        expect(TodayFeedCacheConfiguration.maxPendingInteractions, equals(20));
      });
    });

    group('Configuration Validation', () {
      test('should validate correct timing configuration', () {
        TodayFeedCacheConfiguration.forProductionEnvironment();
        expect(
          TodayFeedCacheConfiguration.validateTimingConfiguration(),
          isTrue,
        );
      });

      test('should validate correct performance configuration', () {
        TodayFeedCacheConfiguration.forProductionEnvironment();
        expect(
          TodayFeedCacheConfiguration.validatePerformanceConfiguration(),
          isTrue,
        );
      });

      test('should validate overall configuration', () {
        TodayFeedCacheConfiguration.forProductionEnvironment();
        expect(TodayFeedCacheConfiguration.validateConfiguration(), isTrue);
      });

      test('should validate test environment configuration', () {
        TodayFeedCacheConfiguration.forTestEnvironment();
        expect(TodayFeedCacheConfiguration.validateConfiguration(), isTrue);
      });

      test('should validate development environment configuration', () {
        TodayFeedCacheConfiguration.forDevelopmentEnvironment();
        expect(TodayFeedCacheConfiguration.validateConfiguration(), isTrue);
      });
    });

    group('Health Threshold Validation', () {
      test('should validate health threshold ordering', () {
        final critical = TodayFeedCacheConfiguration.criticalHealthThreshold;
        final warning = TodayFeedCacheConfiguration.warningHealthThreshold;
        final normal = TodayFeedCacheConfiguration.healthThreshold;

        expect(critical < warning, isTrue);
        expect(warning < normal, isTrue);
        expect(critical < normal, isTrue);
      });

      test('should validate health thresholds are within valid range', () {
        final thresholds = [
          TodayFeedCacheConfiguration.criticalHealthThreshold,
          TodayFeedCacheConfiguration.warningHealthThreshold,
          TodayFeedCacheConfiguration.healthThreshold,
        ];

        for (final threshold in thresholds) {
          expect(threshold >= 0.0, isTrue);
          expect(threshold <= 1.0, isTrue);
        }
      });
    });

    group('Configuration Summary', () {
      test('should provide comprehensive configuration summary', () {
        TodayFeedCacheConfiguration.forProductionEnvironment();
        final summary = TodayFeedCacheConfiguration.getConfigurationSummary();

        expect(summary, isA<Map<String, dynamic>>());
        expect(summary['environment'], equals('production'));
        expect(summary['cache_version'], equals(1));

        expect(summary['timing'], isA<Map<String, dynamic>>());
        expect(summary['timing']['default_refresh_interval'], isNotNull);
        expect(summary['timing']['fallback_refresh_interval'], isNotNull);
        expect(summary['timing']['timezone_check_interval'], isNotNull);
        expect(summary['timing']['warming_interval'], isNotNull);
        expect(summary['timing']['cleanup_interval'], isNotNull);

        expect(summary['performance'], isA<Map<String, dynamic>>());
        expect(summary['performance']['max_cache_size_mb'], isNotNull);
        expect(summary['performance']['max_response_time_ms'], isNotNull);
        expect(summary['performance']['health_threshold'], isNotNull);
        expect(summary['performance']['max_history_entries'], isNotNull);
        expect(summary['performance']['max_pending_interactions'], isNotNull);

        expect(summary['validation'], isA<Map<String, dynamic>>());
        expect(summary['validation']['timing_valid'], isTrue);
        expect(summary['validation']['performance_valid'], isTrue);
        expect(summary['validation']['overall_valid'], isTrue);
      });

      test(
        'should provide correct configuration summary for test environment',
        () {
          TodayFeedCacheConfiguration.forTestEnvironment();
          final summary = TodayFeedCacheConfiguration.getConfigurationSummary();

          expect(summary['environment'], equals('testing'));
          expect(summary['performance']['max_cache_size_mb'], equals('1.0'));
          expect(summary['performance']['max_response_time_ms'], equals(100));
          expect(summary['performance']['health_threshold'], equals(0.75));
        },
      );
    });

    group('Constants Validation', () {
      test('should have positive duration values', () {
        final durations = [
          CacheTiming.defaultRefreshInterval,
          CacheTiming.fallbackRefreshInterval,
          CacheTiming.forceRefreshCooldown,
          CacheTiming.timezoneCheckInterval,
          CacheTiming.timezoneValidationInterval,
          CacheTiming.scheduledWarmingInterval,
          CacheTiming.predictiveWarmingInterval,
          CacheTiming.connectivityWarmingDelay,
          CacheTiming.automaticCleanupInterval,
          CacheTiming.healthCheckInterval,
          CacheTiming.performanceCheckInterval,
          CacheTiming.syncRetryDelay,
          CacheTiming.maxSyncDelay,
          CacheTiming.backgroundSyncInterval,
        ];

        for (final duration in durations) {
          expect(duration.isNegative, isFalse);
          expect(duration.inMilliseconds > 0, isTrue);
        }
      });

      test('should have positive size and count values', () {
        expect(CachePerformance.maxCacheSizeBytes > 0, isTrue);
        expect(CachePerformance.maxHistoryEntries > 0, isTrue);
        expect(CachePerformance.maxPendingInteractions > 0, isTrue);
      });

      test('should have valid threshold ranges', () {
        final thresholds = [
          CachePerformance.healthThreshold,
          CachePerformance.warningHealthThreshold,
          CachePerformance.criticalHealthThreshold,
          CachePerformance.minSuccessRate,
          CachePerformance.warningSuccessRate,
          CachePerformance.criticalSuccessRate,
        ];

        for (final threshold in thresholds) {
          expect(threshold >= 0.0, isTrue);
          expect(threshold <= 1.0, isTrue);
        }
      });

      test('should have reasonable test configuration values', () {
        expect(TestConfiguration.testRefreshInterval.inSeconds >= 1, isTrue);
        expect(TestConfiguration.testMaxCacheSize > 0, isTrue);
        expect(TestConfiguration.testMaxHistoryEntries > 0, isTrue);
        expect(TestConfiguration.testMaxPendingInteractions > 0, isTrue);
        expect(TestConfiguration.testHealthThreshold >= 0.0, isTrue);
        expect(TestConfiguration.testHealthThreshold <= 1.0, isTrue);
      });
    });

    group('Cache Keys Validation', () {
      test('should have non-empty cache keys', () {
        final keys = [
          CacheKeys.cacheVersion,
          CacheKeys.timezoneMetadata,
          CacheKeys.lastTimezoneCheck,
          CacheKeys.contentData,
          CacheKeys.previousContentData,
          CacheKeys.lastRefreshTime,
          CacheKeys.cacheStatistics,
          CacheKeys.healthMetrics,
          CacheKeys.performanceMetrics,
          CacheKeys.warmingStats,
          CacheKeys.warmingConfig,
          CacheKeys.pendingInteractions,
          CacheKeys.syncStatus,
          CacheKeys.maintenanceLog,
        ];

        for (final key in keys) {
          expect(key.isNotEmpty, isTrue);
          expect(key.contains('today_feed'), isTrue);
        }
      });

      test('should have unique cache keys', () {
        final keys = [
          CacheKeys.cacheVersion,
          CacheKeys.timezoneMetadata,
          CacheKeys.lastTimezoneCheck,
          CacheKeys.contentData,
          CacheKeys.previousContentData,
          CacheKeys.lastRefreshTime,
          CacheKeys.cacheStatistics,
          CacheKeys.healthMetrics,
          CacheKeys.performanceMetrics,
          CacheKeys.warmingStats,
          CacheKeys.warmingConfig,
          CacheKeys.pendingInteractions,
          CacheKeys.syncStatus,
          CacheKeys.maintenanceLog,
        ];

        final uniqueKeys = keys.toSet();
        expect(uniqueKeys.length, equals(keys.length));
      });
    });

    group('Environment Switching Edge Cases', () {
      test('should handle rapid environment switching', () {
        TodayFeedCacheConfiguration.forProductionEnvironment();
        expect(TodayFeedCacheConfiguration.isProductionEnvironment, isTrue);

        TodayFeedCacheConfiguration.forTestEnvironment();
        expect(TodayFeedCacheConfiguration.isTestEnvironment, isTrue);

        TodayFeedCacheConfiguration.forDevelopmentEnvironment();
        expect(TodayFeedCacheConfiguration.isDevelopmentEnvironment, isTrue);

        TodayFeedCacheConfiguration.forProductionEnvironment();
        expect(TodayFeedCacheConfiguration.isProductionEnvironment, isTrue);
      });

      test(
        'should maintain configuration consistency after environment switches',
        () {
          // Test production configuration
          TodayFeedCacheConfiguration.forProductionEnvironment();
          final prodRefreshInterval =
              TodayFeedCacheConfiguration.defaultRefreshInterval;
          final prodCacheSize = TodayFeedCacheConfiguration.maxCacheSizeBytes;

          // Switch to test
          TodayFeedCacheConfiguration.forTestEnvironment();
          final testRefreshInterval =
              TodayFeedCacheConfiguration.defaultRefreshInterval;
          final testCacheSize = TodayFeedCacheConfiguration.maxCacheSizeBytes;

          // Values should be different
          expect(prodRefreshInterval != testRefreshInterval, isTrue);
          expect(prodCacheSize != testCacheSize, isTrue);

          // Switch back to production
          TodayFeedCacheConfiguration.forProductionEnvironment();
          expect(
            TodayFeedCacheConfiguration.defaultRefreshInterval,
            equals(prodRefreshInterval),
          );
          expect(
            TodayFeedCacheConfiguration.maxCacheSizeBytes,
            equals(prodCacheSize),
          );
        },
      );
    });
  });
}
