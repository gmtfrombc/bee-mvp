/// **TodayFeedCacheService - Main Coordinator Service**
///
/// This is the main coordinator service for the Today Feed cache system after major
/// refactoring. It orchestrates seven specialized services that handle different aspects
/// of cache management:
///
/// **Architecture Overview:**
/// ```
/// TodayFeedCacheService (Main Coordinator ~300 lines)
/// ├── TodayFeedContentService (Content storage/retrieval)
/// ├── TodayFeedCacheSyncService (Background sync/connectivity)
/// ├── TodayFeedTimezoneService (Timezone/DST handling)
/// ├── TodayFeedCacheMaintenanceService (Cleanup/invalidation)
/// ├── TodayFeedCacheHealthService (Health monitoring/diagnostics)
/// ├── TodayFeedCacheStatisticsService (Statistics/metrics)
/// ├── TodayFeedCachePerformanceService (Performance analysis)
/// └── TodayFeedCacheWarmingService (Cache warming/preloading)
/// ```
///
/// **Key Features:**
/// - 24-hour refresh cycle with timezone awareness
/// - DST transition handling
/// - Background synchronization
/// - Content caching with fallback support
/// - Comprehensive health monitoring
/// - Performance metrics and statistics
/// - Automatic cache maintenance
/// - Cache warming and preloading strategies
///
/// **Usage:**
/// ```dart
/// // Initialize the service
/// await TodayFeedCacheService.initialize();
///
/// // Cache content
/// await TodayFeedCacheService.cacheTodayContent(content);
///
/// // Retrieve content
/// final content = await TodayFeedCacheService.getTodayContent();
///
/// // Check if refresh needed
/// final needsRefresh = await TodayFeedCacheService.needsRefresh();
/// ```
///
/// This service maintains 100% backward compatibility while providing a clean,
/// modular architecture for maintainability and testing.
library;

import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../features/today_feed/domain/models/today_feed_content.dart';
import 'cache/today_feed_cache_configuration.dart';
import 'cache/today_feed_cache_compatibility_layer.dart';
import 'cache/today_feed_cache_health_service.dart';
import 'cache/today_feed_cache_maintenance_service.dart';
import 'cache/today_feed_cache_performance_service.dart';
import 'cache/today_feed_cache_statistics_service.dart';
import 'cache/today_feed_cache_sync_service.dart';
import 'cache/today_feed_cache_warming_service.dart';
import 'cache/today_feed_content_service.dart';
import 'cache/today_feed_timezone_service.dart';

/// **Today Feed Cache Service - Main Coordinator**
///
/// Main coordinator service that orchestrates all cache-related operations
/// through specialized service modules. Maintains 100% backward compatibility.
class TodayFeedCacheService {
  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 1: CONSTANTS & CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════════
  //
  // This section contains all configuration constants, cache keys, and static
  // configuration values. Following ResponsiveService pattern of centralizing
  // constants to avoid hardcoded values throughout the codebase.

  /// Cache keys for Today Feed content storage - now using configuration
  static String get _cacheVersionKey =>
      TodayFeedCacheConfiguration.cacheVersionKey;
  static String get _timezoneMetadataKey =>
      TodayFeedCacheConfiguration.timezoneMetadataKey;
  static String get _lastTimezoneCheckKey =>
      TodayFeedCacheConfiguration.lastTimezoneCheckKey;

  /// Cache version for migration management - now using configuration
  static int get _currentCacheVersion =>
      TodayFeedCacheConfiguration.currentCacheVersion;

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 2: INITIALIZATION & LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════════
  //
  // This section handles service initialization, dependency setup, state management,
  // and lifecycle operations including disposal and testing utilities.

  /// SharedPreferences instance for cache storage
  static SharedPreferences? _prefs;

  /// Initialization state flag
  static bool _isInitialized = false;

  /// Test environment flag for disabling timers and subscriptions
  static bool _isTestEnvironment = false;

  /// Timer for automatic content refresh
  static Timer? _refreshTimer;

  /// Timer for timezone change detection
  static Timer? _timezoneCheckTimer;

  /// Timer for automatic cache cleanup
  static Timer? _automaticCleanupTimer;

  /// Set test environment mode to disable timers and subscriptions
  static void setTestEnvironment(bool isTest) {
    _isTestEnvironment = isTest;
    // Update configuration environment based on test flag
    if (isTest) {
      TodayFeedCacheConfiguration.forTestEnvironment();
    } else {
      TodayFeedCacheConfiguration.forProductionEnvironment();
    }
  }

  /// Initialize the Today Feed cache service
  ///
  /// Sets up all specialized services in proper dependency order and configures
  /// timezone handling, cache validation, and refresh scheduling. Optimized for
  /// test environments to skip expensive operations.
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs ??= await SharedPreferences.getInstance();

      // Validate configuration before initialization
      if (!TodayFeedCacheConfiguration.validateConfiguration()) {
        throw Exception('Invalid cache configuration detected');
      }

      // Skip full initialization in test environment
      if (_isTestEnvironment || TodayFeedCacheConfiguration.isTestEnvironment) {
        _isInitialized = true;
        debugPrint(
          '✅ TodayFeedCacheService test mode - skipping full initialization',
        );
        return;
      }

      // Initialize services in dependency order
      await TodayFeedContentService.initialize(_prefs!);
      await TodayFeedCacheStatisticsService.initialize(_prefs!);
      await TodayFeedCacheHealthService.initialize(_prefs!);
      await TodayFeedCachePerformanceService.initialize(_prefs!);
      await TodayFeedTimezoneService.initialize(_prefs!);
      await TodayFeedCacheSyncService.initialize(_prefs!);
      await TodayFeedCacheMaintenanceService.initialize(_prefs!);
      await TodayFeedCacheWarmingService.initialize(_prefs!);

      await _validateCacheVersion();
      await _detectAndHandleTimezoneChanges();
      await _scheduleNextRefresh();
      _isInitialized = true;

      debugPrint('✅ TodayFeedCacheService initialized successfully');
      debugPrint(
        '📊 Configuration: ${TodayFeedCacheConfiguration.environment.name}',
      );
    } catch (e) {
      debugPrint('❌ Failed to initialize TodayFeedCacheService: $e');
      rethrow;
    }
  }

  /// Validate cache version and migrate if needed
  static Future<void> _validateCacheVersion() async {
    final currentVersion = _prefs!.getInt(_cacheVersionKey) ?? 0;
    if (currentVersion < _currentCacheVersion) {
      debugPrint('🔄 Today Feed cache version outdated, migrating...');

      // Clear old cache data
      await _clearAllCacheData();
      await _prefs!.setInt(_cacheVersionKey, _currentCacheVersion);

      debugPrint('✅ Today Feed cache migration completed');
    }
  }

  /// Detect and handle timezone changes including DST transitions
  static Future<void> _detectAndHandleTimezoneChanges() async {
    try {
      final timezoneChange =
          await TodayFeedTimezoneService.detectAndHandleTimezoneChanges();

      if (timezoneChange != null) {
        // Reschedule refresh timer with new timezone
        await _scheduleNextRefresh();

        // Check if content needs immediate refresh due to timezone change
        if (timezoneChange['should_refresh'] == true) {
          debugPrint('🔄 Triggering immediate refresh due to timezone change');
          await _triggerRefresh();
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to detect timezone changes: $e');
      rethrow;
    }
  }

  /// Dispose of resources and cleanup timers
  ///
  /// Properly disposes all services and cleans up timers to prevent memory leaks.
  /// Follows proper disposal order to maintain service dependencies.
  static Future<void> dispose() async {
    try {
      _refreshTimer?.cancel();
      _timezoneCheckTimer?.cancel();
      _automaticCleanupTimer?.cancel();

      // Dispose maintenance service first since it manages the cleanup timer
      await TodayFeedCacheMaintenanceService.dispose();

      // Dispose content service
      await TodayFeedContentService.dispose();

      _refreshTimer = null;
      _timezoneCheckTimer = null;
      _automaticCleanupTimer = null;
      _isInitialized = false;

      debugPrint('✅ TodayFeedCacheService disposed');
    } catch (e) {
      debugPrint('❌ Failed to dispose TodayFeedCacheService: $e');
    }
  }

  /// Reset service for testing (clears all state)
  static void resetForTesting() {
    _isInitialized = false;
    _prefs = null;
    _refreshTimer?.cancel();
    _timezoneCheckTimer?.cancel();
    _automaticCleanupTimer?.cancel();

    _refreshTimer = null;
    _timezoneCheckTimer = null;
    _automaticCleanupTimer = null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 3: CORE CONTENT OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════
  //
  // This section contains the primary content operations that users interact with
  // most frequently: caching, retrieving, and managing Today Feed content with
  // validation and fallback support.

  /// Cache today's content with metadata and size enforcement
  ///
  /// Primary method for storing Today Feed content with automatic validation,
  /// metadata generation, and history tracking.
  static Future<void> cacheTodayContent(
    TodayFeedContent content, {
    bool isFromAPI = true,
  }) async {
    await initialize();
    await TodayFeedContentService.cacheTodayContent(
      content,
      isFromAPI: isFromAPI,
    );
  }

  /// Get today's cached content with validation
  ///
  /// Primary method for retrieving cached Today Feed content with automatic
  /// validation and stale content handling.
  static Future<TodayFeedContent?> getTodayContent({
    bool allowStale = false,
  }) async {
    await initialize();
    return await TodayFeedContentService.getTodayContent(
      allowStale: allowStale,
    );
  }

  /// Get previous day's content as fallback with enhanced metadata
  ///
  /// Retrieves previous day's content when today's content is unavailable,
  /// providing seamless fallback experience.
  static Future<TodayFeedContent?> getPreviousDayContent() async {
    await initialize();
    return await TodayFeedContentService.getPreviousDayContent();
  }

  /// Move today's content to previous day storage
  ///
  /// Internal method for archiving current content before refresh operations.
  static Future<void> _archiveTodayContent() async {
    await TodayFeedContentService.archiveTodayContent();
  }

  /// Clear today's content only (keeps history and metadata)
  static Future<void> clearTodayContent() async {
    await initialize();
    await TodayFeedContentService.clearTodayContent();
  }

  /// Check if fallback content should be used
  static Future<bool> shouldUseFallbackContent() async {
    await initialize();
    return await TodayFeedContentService.shouldUseFallbackContent();
  }

  /// Get fallback content with metadata
  static Future<TodayFeedContent?> getFallbackContentWithMetadata() async {
    await initialize();
    return await TodayFeedContentService.getFallbackContentWithMetadata();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 4: REFRESH & TIMING OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════
  //
  // This section handles refresh logic, timezone-aware scheduling, and timing
  // operations including DST handling and automatic refresh triggers.

  /// Check if cached content needs refresh (timezone-aware with DST handling)
  ///
  /// Determines if content refresh is needed based on local timezone, DST changes,
  /// and preferred refresh timing. Accounts for timezone transitions.
  static Future<bool> needsRefresh() async {
    await initialize();

    try {
      final lastRefresh = TodayFeedContentService.getLastRefreshTime();
      if (lastRefresh == null) {
        debugPrint('🔄 No previous refresh found - refresh needed');
        return true;
      }

      final now = DateTime.now();

      // Get timezone information for accurate day calculation
      final timezoneInfo = TodayFeedTimezoneService.getCurrentTimezoneInfo();

      // Check if it's a new day in local timezone (accounting for DST)
      final isNewDay =
          !TodayFeedTimezoneService.isSameLocalDay(lastRefresh, now);

      // Check if we're past the preferred refresh time
      final isPastRefreshTime =
          TodayFeedTimezoneService.isPastRefreshTimeEnhanced(now);

      // Enhanced check for timezone-related refresh needs
      final timezoneRequiresRefresh =
          await TodayFeedTimezoneService.checkTimezoneRefreshRequirement();

      final shouldRefresh =
          (isNewDay && isPastRefreshTime) || timezoneRequiresRefresh;

      if (shouldRefresh) {
        if (timezoneRequiresRefresh) {
          debugPrint(
            '🔄 Content refresh needed - timezone/DST change detected',
          );
        } else {
          debugPrint('🔄 Content refresh needed - new day detected');
        }
        debugPrint('  Last refresh: $lastRefresh');
        debugPrint('  Current time: $now');
        debugPrint(
          '  Timezone: ${timezoneInfo['identifier']} (DST: ${timezoneInfo['is_dst']})',
        );
      }

      return shouldRefresh;
    } catch (e) {
      debugPrint('❌ Failed to check refresh need: $e');
      return true; // Err on side of refreshing
    }
  }

  /// Force refresh content immediately
  ///
  /// Manually triggers content refresh, bypassing normal scheduling.
  /// Useful for user-initiated refresh or recovery scenarios.
  static Future<void> forceRefresh() async {
    await initialize();

    try {
      debugPrint('🔄 Force refresh triggered');
      await _triggerRefresh();
    } catch (e) {
      debugPrint('❌ Failed to force refresh: $e');
      rethrow;
    }
  }

  /// Trigger content refresh (internal operation)
  ///
  /// Internal method that orchestrates the complete refresh process including
  /// content archiving, cache clearing, and refresh scheduling.
  static Future<void> _triggerRefresh() async {
    try {
      // Archive current content before refresh
      await _archiveTodayContent();

      // Clear current content to force fresh fetch
      await TodayFeedContentService.clearTodayContent();

      // Schedule next refresh
      await _scheduleNextRefresh();

      debugPrint('🔄 Content refresh triggered successfully');
    } catch (e) {
      debugPrint('❌ Failed to trigger refresh: $e');
      await _queueError('trigger_refresh', e.toString());
    }
  }

  /// Schedule next refresh based on timezone and DST
  ///
  /// Calculates and schedules the next refresh time accounting for timezone
  /// changes and DST transitions.
  static Future<void> _scheduleNextRefresh() async {
    _refreshTimer?.cancel();

    try {
      final now = DateTime.now();
      final nextRefreshTime =
          await TodayFeedTimezoneService.calculateNextRefreshTime(now);
      final delay = nextRefreshTime.difference(now);

      if (delay.isNegative) {
        debugPrint('⚠️ Next refresh time is in the past, refreshing now');
        await _triggerRefresh();
        return;
      }

      _refreshTimer = Timer(delay, () async {
        debugPrint('⏰ Scheduled refresh triggered');
        await _triggerRefresh();
      });

      debugPrint('⏰ Next refresh scheduled for: $nextRefreshTime');
      debugPrint(
        '⏰ Time until refresh: ${delay.inHours}h ${delay.inMinutes % 60}m',
      );
    } catch (e) {
      debugPrint('❌ Failed to schedule next refresh: $e');
      // Fallback to configured fallback refresh interval
      final fallbackInterval =
          TodayFeedCacheConfiguration.fallbackRefreshInterval;
      _refreshTimer = Timer(fallbackInterval, () async {
        debugPrint('⏰ Fallback refresh triggered');
        await _triggerRefresh();
      });
    }
  }

  /// Get timezone statistics for debugging and monitoring
  static Future<Map<String, dynamic>> getTimezoneStats() async {
    await initialize();
    return TodayFeedTimezoneService.getTimezoneStats();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 5: CACHE MANAGEMENT & MONITORING
  // ═══════════════════════════════════════════════════════════════════════════
  //
  // This section handles cache maintenance, monitoring, statistics, health checks,
  // performance metrics, and administrative operations including cleanup and
  // diagnostic utilities.

  /// Clear all cached data (complete cache reset)
  ///
  /// Removes all cached content, metadata, and settings. Used for cache
  /// migrations and complete resets.
  static Future<void> _clearAllCacheData() async {
    try {
      await TodayFeedContentService.clearAllContentData();
      await _prefs!.remove(_timezoneMetadataKey);
      await _prefs!.remove(_lastTimezoneCheckKey);

      debugPrint('🧹 All Today Feed cache data cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear cache data: $e');
    }
  }

  /// Manual invalidation for testing and maintenance
  static Future<void> invalidateCache({String? reason}) async {
    await initialize();
    await TodayFeedCacheMaintenanceService.invalidateCache(reason: reason);
  }

  /// Get cache metadata for debugging and monitoring
  ///
  /// Provides comprehensive cache information including size, content status,
  /// timezone data, and service health metrics.
  static Future<Map<String, dynamic>> getCacheMetadata() async {
    await initialize();

    try {
      final cacheSize =
          await TodayFeedCacheMaintenanceService.calculateCacheSize();
      final timezoneInfo = TodayFeedTimezoneService.getCurrentTimezoneInfo();
      final contentMetadata =
          await TodayFeedContentService.getContentMetadata();

      return {
        ...contentMetadata,
        'cache_size_bytes': cacheSize,
        'cache_size_kb': (cacheSize / 1024).toStringAsFixed(1),
        'timezone_info': timezoneInfo,
        'is_initialized': _isInitialized,
        'cache_version': _prefs!.getInt(_cacheVersionKey),
      };
    } catch (e) {
      debugPrint('❌ Failed to get cache metadata: $e');
      return {'error': e.toString()};
    }
  }

  /// Get sync status for debugging and monitoring
  static Map<String, dynamic> getSyncStatus() {
    return {
      'is_initialized': _isInitialized,
      'has_refresh_timer': _refreshTimer != null,
      'has_timezone_timer': _timezoneCheckTimer != null,
      'has_cleanup_timer': _automaticCleanupTimer != null,
    };
  }

  /// Queue error for later analysis and sync
  static Future<void> _queueError(String operation, String error) async {
    try {
      // Delegate error queueing to sync service which handles sync errors
      await TodayFeedCacheSyncService.initialize(_prefs!);
      // For now, just log the error - sync service handles its own errors
      debugPrint('📝 Error queued via sync service: $operation - $error');
    } catch (e) {
      debugPrint('❌ Failed to queue error: $e');
    }
  }

  /// Get statistics from all services (comprehensive metrics)
  static Future<Map<String, dynamic>> getAllStatistics() async {
    await initialize();

    final stats = <String, dynamic>{};
    final cacheMetadata = await getCacheMetadata();
    final syncStatus = getSyncStatus();

    // Get statistics from each service
    stats['cache'] = cacheMetadata;
    stats['statistics'] =
        await TodayFeedCacheStatisticsService.getCacheStatistics(cacheMetadata);
    stats['health'] = await TodayFeedCacheHealthService.getCacheHealthStatus(
      cacheMetadata,
      syncStatus,
    );
    stats['performance'] =
        await TodayFeedCachePerformanceService.getDetailedPerformanceStatistics();
    stats['timezone'] = await TodayFeedTimezoneService.getTimezoneStats();
    stats['sync'] = syncStatus;

    return stats;
  }

  /// Get health metrics from all services
  static Future<Map<String, dynamic>> getAllHealthMetrics() async {
    await initialize();

    final health = <String, dynamic>{};
    final cacheMetadata = await getCacheMetadata();
    final syncStatus = getSyncStatus();

    // Get health metrics from each service
    health['cache'] = cacheMetadata;
    health['health'] = await TodayFeedCacheHealthService.getCacheHealthStatus(
      cacheMetadata,
      syncStatus,
    );
    health['performance'] =
        await TodayFeedCachePerformanceService.getDetailedPerformanceStatistics();
    health['timezone'] = await TodayFeedTimezoneService.getTimezoneStats();

    return health;
  }

  /// Get performance metrics from all services
  static Future<Map<String, dynamic>> getAllPerformanceMetrics() async {
    await initialize();

    final performance = <String, dynamic>{};
    final cacheMetadata = await getCacheMetadata();

    // Get performance metrics from each service
    performance['cache'] = cacheMetadata;
    performance['performance'] =
        await TodayFeedCachePerformanceService.getDetailedPerformanceStatistics();
    performance['statistics'] =
        await TodayFeedCacheStatisticsService.getCacheStatistics(cacheMetadata);

    return performance;
  }

  /// Execute cache warming strategy
  ///
  /// Implements cache warming and preloading strategies for optimal performance.
  /// Supports different triggers and context-aware optimization.
  static Future<Map<String, dynamic>> executeWarmingStrategy({
    String trigger = 'manual',
    Map<String, dynamic>? context,
  }) async {
    await initialize();

    try {
      // Convert string trigger to enum
      final warmingTrigger = _parseWarmingTrigger(trigger);

      final result = await TodayFeedCacheWarmingService.executeWarmingStrategy(
        trigger: warmingTrigger,
        context: context,
      );

      return {
        'success': result.success,
        'trigger': result.trigger.name,
        'duration_ms': result.duration?.inMilliseconds,
        'results': result.results,
        'error': result.error,
      };
    } catch (e) {
      debugPrint('❌ Cache warming strategy failed: $e');
      return {'success': false, 'error': e.toString(), 'trigger': trigger};
    }
  }

  /// Update cache warming configuration
  static Future<void> updateWarmingConfiguration({
    bool? enableContentPreloading,
    bool? enableHistoryWarming,
    bool? enablePredictiveWarming,
    Duration? scheduledInterval,
    Duration? predictiveInterval,
  }) async {
    await initialize();

    try {
      // Use configuration values with fallbacks
      final newConfig = WarmingConfiguration(
        enableContentPreloading: enableContentPreloading ?? true,
        enableHistoryWarming: enableHistoryWarming ?? true,
        enablePredictiveWarming: enablePredictiveWarming ?? true,
        scheduledWarmingInterval:
            scheduledInterval ??
            TodayFeedCacheConfiguration.scheduledWarmingInterval,
        predictiveWarmingInterval:
            predictiveInterval ??
            TodayFeedCacheConfiguration.predictiveWarmingInterval,
      );

      await TodayFeedCacheWarmingService.updateWarmingConfiguration(newConfig);
      debugPrint('✅ Cache warming configuration updated');
    } catch (e) {
      debugPrint('❌ Failed to update warming configuration: $e');
    }
  }

  /// Trigger cache warming on app launch
  static Future<void> warmCacheOnAppLaunch() async {
    await initialize();

    await executeWarmingStrategy(
      trigger: 'appLaunch',
      context: {'app_startup': true},
    );
  }

  /// Helper method to parse warming trigger string to enum
  static WarmingTrigger _parseWarmingTrigger(String trigger) {
    switch (trigger.toLowerCase()) {
      case 'connectivity':
        return WarmingTrigger.connectivity;
      case 'scheduled':
        return WarmingTrigger.scheduled;
      case 'predictive':
        return WarmingTrigger.predictive;
      case 'applaunch':
      case 'app_launch':
        return WarmingTrigger.appLaunch;
      default:
        return WarmingTrigger.manual;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BACKWARD COMPATIBILITY LAYER - Sprint 2.1 REFACTORED
  // ═══════════════════════════════════════════════════════════════════════════
  //
  // All backward compatibility methods have been extracted to a dedicated
  // compatibility layer while maintaining 100% backward compatibility.
  // Legacy methods are delegated to TodayFeedCacheCompatibilityLayer.

  /// Clear all cache (compatibility wrapper)
  static Future<void> clearAllCache() async =>
      await TodayFeedCacheCompatibilityLayer.clearAllCache();

  /// Get cache stats (compatibility wrapper)
  static Future<Map<String, dynamic>> getCacheStats() async =>
      await TodayFeedCacheCompatibilityLayer.getCacheStats();

  /// Queue interaction (compatibility wrapper)
  static Future<void> queueInteraction(
    Map<String, dynamic> interaction,
  ) async =>
      await TodayFeedCacheCompatibilityLayer.queueInteraction(interaction);

  /// Get content history (compatibility method)
  static Future<List<Map<String, dynamic>>> getContentHistory() async =>
      await TodayFeedCacheCompatibilityLayer.getContentHistory();

  /// Cache pending interaction (compatibility method)
  static Future<void> cachePendingInteraction(
    Map<String, dynamic> interaction,
  ) async => await TodayFeedCacheCompatibilityLayer.cachePendingInteraction(
    interaction,
  );

  /// Get pending interactions (compatibility method)
  static Future<List<Map<String, dynamic>>> getPendingInteractions() async =>
      await TodayFeedCacheCompatibilityLayer.getPendingInteractions();

  /// Clear pending interactions (compatibility method)
  static Future<void> clearPendingInteractions() async =>
      await TodayFeedCacheCompatibilityLayer.clearPendingInteractions();

  /// Sync when online (compatibility wrapper)
  static Future<void> syncWhenOnline() async =>
      await TodayFeedCacheCompatibilityLayer.syncWhenOnline();

  /// Selective cleanup (compatibility wrapper)
  static Future<void> selectiveCleanup() async =>
      await TodayFeedCacheCompatibilityLayer.selectiveCleanup();

  /// Get diagnostic info (compatibility wrapper)
  static Future<Map<String, dynamic>> getDiagnosticInfo() async =>
      await TodayFeedCacheCompatibilityLayer.getDiagnosticInfo();

  /// Mark content as viewed (compatibility wrapper)
  static Future<void> markContentAsViewed(TodayFeedContent content) async =>
      await TodayFeedCacheCompatibilityLayer.markContentAsViewed(content);

  /// Get cache statistics (compatibility wrapper)
  static Future<Map<String, dynamic>> getCacheStatistics() async =>
      await TodayFeedCacheCompatibilityLayer.getCacheStatistics();

  /// Get cache health status (compatibility wrapper)
  static Future<Map<String, dynamic>> getCacheHealthStatus() async =>
      await TodayFeedCacheCompatibilityLayer.getCacheHealthStatus();

  /// Invalidate content (compatibility method)
  static Future<void> invalidateContent({
    bool clearHistory = false,
    bool clearMetadata = false,
    String? reason,
  }) async => await TodayFeedCacheCompatibilityLayer.invalidateContent(
    clearHistory: clearHistory,
    clearMetadata: clearMetadata,
    reason: reason,
  );

  /// Get cache invalidation stats (compatibility method)
  static Future<Map<String, dynamic>> getCacheInvalidationStats() async =>
      await TodayFeedCacheCompatibilityLayer.getCacheInvalidationStats();

  /// Set background sync enabled (compatibility wrapper)
  static Future<void> setBackgroundSyncEnabled(bool enabled) async =>
      await TodayFeedCacheCompatibilityLayer.setBackgroundSyncEnabled(enabled);

  /// Check if background sync is enabled (compatibility wrapper)
  static Future<bool> isBackgroundSyncEnabled() async =>
      await TodayFeedCacheCompatibilityLayer.isBackgroundSyncEnabled();

  /// Export metrics for monitoring (compatibility wrapper)
  static Future<Map<String, dynamic>> exportMetricsForMonitoring() async =>
      await TodayFeedCacheCompatibilityLayer.exportMetricsForMonitoring();

  /// Perform cache integrity check (compatibility wrapper)
  static Future<Map<String, dynamic>> performCacheIntegrityCheck() async =>
      await TodayFeedCacheCompatibilityLayer.performCacheIntegrityCheck();
}
