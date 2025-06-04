/// **TodayFeedCacheConfiguration**
///
/// Centralized configuration for Today Feed cache service operations.
/// Following ResponsiveService pattern of extracting constants to avoid
/// hardcoded values throughout the codebase.
///
/// **Design Principles:**
/// - Single source of truth for all cache-related configuration
/// - Environment-aware configuration with validation
/// - Logical grouping of related constants
/// - Responsive design considerations for timing and performance
///
/// **Usage:**
/// ```dart
/// // Access cache keys
/// final key = TodayFeedCacheConfiguration.cacheVersionKey;
///
/// // Get timing configuration
/// final config = TodayFeedCacheConfiguration.getTimingConfiguration();
///
/// // Environment-specific configuration
/// final testConfig = TodayFeedCacheConfiguration.forTestEnvironment();
/// ```
library;

import 'package:flutter/foundation.dart';

/// **Cache Configuration Keys**
///
/// Centralized storage keys used throughout the cache system
class CacheKeys {
  static const String cacheVersion = 'today_feed_cache_version';
  static const String timezoneMetadata = 'today_feed_timezone_metadata';
  static const String lastTimezoneCheck = 'today_feed_last_timezone_check';
  static const String contentData = 'today_feed_content_data';
  static const String previousContentData = 'today_feed_previous_content_data';
  static const String lastRefreshTime = 'today_feed_last_refresh_time';
  static const String cacheStatistics = 'today_feed_cache_statistics';
  static const String healthMetrics = 'today_feed_health_metrics';
  static const String performanceMetrics = 'today_feed_performance_metrics';
  static const String warmingStats = 'today_feed_warming_stats';
  static const String warmingConfig = 'today_feed_warming_config';
  static const String pendingInteractions = 'today_feed_pending_interactions';
  static const String syncStatus = 'today_feed_sync_status';
  static const String maintenanceLog = 'today_feed_maintenance_log';
}

/// **Cache Version Configuration**
///
/// Version management and migration constants
class CacheVersion {
  static const int current = 1;
  static const int minimum = 1;
  static const List<int> supportedVersions = [1];
}

/// **Cache Timing Configuration**
///
/// All timing-related constants for cache operations
class CacheTiming {
  // Refresh intervals
  static const Duration defaultRefreshInterval = Duration(hours: 24);
  static const Duration fallbackRefreshInterval = Duration(hours: 6);
  static const Duration forceRefreshCooldown = Duration(minutes: 30);

  // Timezone handling
  static const Duration timezoneCheckInterval = Duration(minutes: 30);
  static const Duration timezoneValidationInterval = Duration(hours: 1);

  // Cache warming
  static const Duration scheduledWarmingInterval = Duration(hours: 2);
  static const Duration predictiveWarmingInterval = Duration(minutes: 30);
  static const Duration connectivityWarmingDelay = Duration(seconds: 10);

  // Maintenance and cleanup
  static const Duration automaticCleanupInterval = Duration(hours: 12);
  static const Duration healthCheckInterval = Duration(minutes: 15);
  static const Duration performanceCheckInterval = Duration(minutes: 5);

  // Sync operations
  static const Duration syncRetryDelay = Duration(minutes: 2);
  static const Duration maxSyncDelay = Duration(minutes: 15);
  static const Duration backgroundSyncInterval = Duration(minutes: 30);
}

/// **Cache Performance Configuration**
///
/// Performance thresholds and limits
class CachePerformance {
  // Size limits
  static const int maxCacheSizeBytes = 10 * 1024 * 1024; // 10MB
  static const int maxHistoryEntries = 50;
  static const int maxPendingInteractions = 100;

  // Response time thresholds
  static const Duration maxResponseTime = Duration(milliseconds: 500);
  static const Duration warningResponseTime = Duration(milliseconds: 300);
  static const Duration targetResponseTime = Duration(milliseconds: 200);

  // Health thresholds
  static const double healthThreshold = 0.85;
  static const double warningHealthThreshold = 0.70;
  static const double criticalHealthThreshold = 0.50;

  // Success rate thresholds
  static const double minSuccessRate = 0.95;
  static const double warningSuccessRate = 0.90;
  static const double criticalSuccessRate = 0.80;
}

/// **Test Environment Configuration**
///
/// Configuration optimized for testing environments
class TestConfiguration {
  static const Duration testRefreshInterval = Duration(seconds: 10);
  static const Duration testTimezoneCheck = Duration(seconds: 5);
  static const Duration testWarmingInterval = Duration(seconds: 30);
  static const Duration testCleanupInterval = Duration(minutes: 1);
  static const Duration testSyncDelay = Duration(milliseconds: 100);

  static const int testMaxCacheSize = 1024 * 1024; // 1MB for tests
  static const int testMaxHistoryEntries = 10;
  static const int testMaxPendingInteractions = 20;

  static const Duration testResponseTimeThreshold = Duration(milliseconds: 100);
  static const double testHealthThreshold = 0.75;
}

/// **Environment Type**
///
/// Defines the operating environment for configuration selection
enum CacheEnvironment { production, development, testing }

/// **Main Configuration Class**
///
/// Central configuration provider with environment-aware settings
class TodayFeedCacheConfiguration {
  static CacheEnvironment _environment = CacheEnvironment.production;

  /// Set the current environment
  static void setEnvironment(CacheEnvironment environment) {
    _environment = environment;
    debugPrint('🔧 TodayFeedCache environment set to: ${environment.name}');
  }

  /// Get current environment
  static CacheEnvironment get environment => _environment;

  /// Check if running in test environment
  static bool get isTestEnvironment => _environment == CacheEnvironment.testing;

  /// Check if running in development environment
  static bool get isDevelopmentEnvironment =>
      _environment == CacheEnvironment.development;

  /// Check if running in production environment
  static bool get isProductionEnvironment =>
      _environment == CacheEnvironment.production;

  // ═══════════════════════════════════════════════════════════════════════════
  // CACHE KEYS ACCESS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Cache version key
  static String get cacheVersionKey => CacheKeys.cacheVersion;

  /// Timezone metadata key
  static String get timezoneMetadataKey => CacheKeys.timezoneMetadata;

  /// Last timezone check key
  static String get lastTimezoneCheckKey => CacheKeys.lastTimezoneCheck;

  /// Content data key
  static String get contentDataKey => CacheKeys.contentData;

  /// Previous content data key
  static String get previousContentDataKey => CacheKeys.previousContentData;

  /// Last refresh time key
  static String get lastRefreshTimeKey => CacheKeys.lastRefreshTime;

  // ═══════════════════════════════════════════════════════════════════════════
  // VERSION MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Current cache version
  static int get currentCacheVersion => CacheVersion.current;

  /// Minimum supported cache version
  static int get minimumCacheVersion => CacheVersion.minimum;

  /// List of supported cache versions
  static List<int> get supportedCacheVersions => CacheVersion.supportedVersions;

  /// Validate cache version
  static bool isValidCacheVersion(int version) {
    return CacheVersion.supportedVersions.contains(version);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TIMING CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Default refresh interval (environment-aware)
  static Duration get defaultRefreshInterval {
    switch (_environment) {
      case CacheEnvironment.testing:
        return TestConfiguration.testRefreshInterval;
      case CacheEnvironment.development:
        return const Duration(hours: 1); // Faster refresh in dev
      case CacheEnvironment.production:
        return CacheTiming.defaultRefreshInterval;
    }
  }

  /// Fallback refresh interval
  static Duration get fallbackRefreshInterval =>
      CacheTiming.fallbackRefreshInterval;

  /// Force refresh cooldown period
  static Duration get forceRefreshCooldown => CacheTiming.forceRefreshCooldown;

  /// Timezone check interval (environment-aware)
  static Duration get timezoneCheckInterval {
    return _environment == CacheEnvironment.testing
        ? TestConfiguration.testTimezoneCheck
        : CacheTiming.timezoneCheckInterval;
  }

  /// Scheduled warming interval (environment-aware)
  static Duration get scheduledWarmingInterval {
    return _environment == CacheEnvironment.testing
        ? TestConfiguration.testWarmingInterval
        : CacheTiming.scheduledWarmingInterval;
  }

  /// Predictive warming interval
  static Duration get predictiveWarmingInterval =>
      CacheTiming.predictiveWarmingInterval;

  /// Automatic cleanup interval (environment-aware)
  static Duration get automaticCleanupInterval {
    return _environment == CacheEnvironment.testing
        ? TestConfiguration.testCleanupInterval
        : CacheTiming.automaticCleanupInterval;
  }

  /// Sync retry delay (environment-aware)
  static Duration get syncRetryDelay {
    return _environment == CacheEnvironment.testing
        ? TestConfiguration.testSyncDelay
        : CacheTiming.syncRetryDelay;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PERFORMANCE CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Maximum cache size in bytes (environment-aware)
  static int get maxCacheSizeBytes {
    return _environment == CacheEnvironment.testing
        ? TestConfiguration.testMaxCacheSize
        : CachePerformance.maxCacheSizeBytes;
  }

  /// Maximum response time threshold (environment-aware)
  static Duration get maxResponseTime {
    return _environment == CacheEnvironment.testing
        ? TestConfiguration.testResponseTimeThreshold
        : CachePerformance.maxResponseTime;
  }

  /// Health threshold (environment-aware)
  static double get healthThreshold {
    return _environment == CacheEnvironment.testing
        ? TestConfiguration.testHealthThreshold
        : CachePerformance.healthThreshold;
  }

  /// Warning health threshold
  static double get warningHealthThreshold =>
      CachePerformance.warningHealthThreshold;

  /// Critical health threshold
  static double get criticalHealthThreshold =>
      CachePerformance.criticalHealthThreshold;

  /// Maximum history entries (environment-aware)
  static int get maxHistoryEntries {
    return _environment == CacheEnvironment.testing
        ? TestConfiguration.testMaxHistoryEntries
        : CachePerformance.maxHistoryEntries;
  }

  /// Maximum pending interactions (environment-aware)
  static int get maxPendingInteractions {
    return _environment == CacheEnvironment.testing
        ? TestConfiguration.testMaxPendingInteractions
        : CachePerformance.maxPendingInteractions;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VALIDATION METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Validate timing configuration
  static bool validateTimingConfiguration() {
    try {
      // Validate refresh intervals
      if (defaultRefreshInterval.isNegative ||
          fallbackRefreshInterval.isNegative ||
          forceRefreshCooldown.isNegative) {
        debugPrint('❌ Invalid refresh interval configuration');
        return false;
      }

      // Validate warming intervals
      if (scheduledWarmingInterval.isNegative ||
          predictiveWarmingInterval.isNegative) {
        debugPrint('❌ Invalid warming interval configuration');
        return false;
      }

      // Validate cleanup intervals
      if (automaticCleanupInterval.isNegative || syncRetryDelay.isNegative) {
        debugPrint('❌ Invalid cleanup interval configuration');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('❌ Timing configuration validation failed: $e');
      return false;
    }
  }

  /// Validate performance configuration
  static bool validatePerformanceConfiguration() {
    try {
      // Validate size limits
      if (maxCacheSizeBytes <= 0 ||
          maxHistoryEntries <= 0 ||
          maxPendingInteractions <= 0) {
        debugPrint('❌ Invalid size limit configuration');
        return false;
      }

      // Validate response time thresholds
      if (maxResponseTime.isNegative) {
        debugPrint('❌ Invalid response time configuration');
        return false;
      }

      // Validate health thresholds
      if (healthThreshold < 0.0 ||
          healthThreshold > 1.0 ||
          warningHealthThreshold < 0.0 ||
          warningHealthThreshold > 1.0 ||
          criticalHealthThreshold < 0.0 ||
          criticalHealthThreshold > 1.0) {
        debugPrint('❌ Invalid health threshold configuration');
        return false;
      }

      // Validate threshold ordering
      if (criticalHealthThreshold >= warningHealthThreshold ||
          warningHealthThreshold >= healthThreshold) {
        debugPrint('❌ Health thresholds not properly ordered');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('❌ Performance configuration validation failed: $e');
      return false;
    }
  }

  /// Validate all configuration
  static bool validateConfiguration() {
    final timingValid = validateTimingConfiguration();
    final performanceValid = validatePerformanceConfiguration();

    final isValid = timingValid && performanceValid;

    if (isValid) {
      debugPrint('✅ TodayFeedCache configuration validation passed');
    } else {
      debugPrint('❌ TodayFeedCache configuration validation failed');
    }

    return isValid;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FACTORY METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get configuration for test environment
  static TodayFeedCacheConfiguration forTestEnvironment() {
    setEnvironment(CacheEnvironment.testing);
    return TodayFeedCacheConfiguration._();
  }

  /// Get configuration for development environment
  static TodayFeedCacheConfiguration forDevelopmentEnvironment() {
    setEnvironment(CacheEnvironment.development);
    return TodayFeedCacheConfiguration._();
  }

  /// Get configuration for production environment
  static TodayFeedCacheConfiguration forProductionEnvironment() {
    setEnvironment(CacheEnvironment.production);
    return TodayFeedCacheConfiguration._();
  }

  /// Private constructor
  TodayFeedCacheConfiguration._();

  // ═══════════════════════════════════════════════════════════════════════════
  // CONFIGURATION SUMMARY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get configuration summary for debugging
  static Map<String, dynamic> getConfigurationSummary() {
    return {
      'environment': _environment.name,
      'cache_version': currentCacheVersion,
      'timing': {
        'default_refresh_interval': defaultRefreshInterval.toString(),
        'fallback_refresh_interval': fallbackRefreshInterval.toString(),
        'timezone_check_interval': timezoneCheckInterval.toString(),
        'warming_interval': scheduledWarmingInterval.toString(),
        'cleanup_interval': automaticCleanupInterval.toString(),
      },
      'performance': {
        'max_cache_size_mb': (maxCacheSizeBytes / (1024 * 1024))
            .toStringAsFixed(1),
        'max_response_time_ms': maxResponseTime.inMilliseconds,
        'health_threshold': healthThreshold,
        'max_history_entries': maxHistoryEntries,
        'max_pending_interactions': maxPendingInteractions,
      },
      'validation': {
        'timing_valid': validateTimingConfiguration(),
        'performance_valid': validatePerformanceConfiguration(),
        'overall_valid': validateConfiguration(),
      },
    };
  }
}
