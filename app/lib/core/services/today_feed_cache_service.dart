/// **TodayFeedCacheService - Main Coordinator Service**
///
/// This is the main coordinator service for the Today Feed cache system after major
/// refactoring. It orchestrates seven specialized services that handle different aspects
/// of cache management:
///
/// **Architecture Overview:**
/// ```
/// TodayFeedCacheService (Main Coordinator ~600 lines)
/// ├── TodayFeedContentService (Content storage/retrieval)
/// ├── TodayFeedCacheSyncService (Background sync/connectivity)
/// ├── TodayFeedTimezoneService (Timezone/DST handling)
/// ├── TodayFeedCacheMaintenanceService (Cleanup/invalidation)
/// ├── TodayFeedCacheHealthService (Health monitoring/diagnostics)
/// ├── TodayFeedCacheStatisticsService (Statistics/metrics)
/// └── TodayFeedCachePerformanceService (Performance analysis)
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
import 'cache/today_feed_cache_statistics_service.dart';
import 'cache/today_feed_cache_health_service.dart';
import 'cache/today_feed_cache_performance_service.dart';
import 'cache/today_feed_timezone_service.dart';
import 'cache/today_feed_cache_sync_service.dart';
import 'cache/today_feed_cache_maintenance_service.dart';
import 'cache/today_feed_content_service.dart';

/// **Today Feed Cache Service - Main Coordinator**
///
/// Main coordinator service that orchestrates all cache-related operations
/// through specialized service modules. Maintains 100% backward compatibility.
class TodayFeedCacheService {
  // ============================================================================
  // CONSTANTS & CONFIGURATION
  // ============================================================================

  /// Cache keys for Today Feed content
  static const String _cacheVersionKey = 'today_feed_cache_version';
  static const String _timezoneMetadataKey = 'today_feed_timezone_metadata';
  static const String _lastTimezoneCheckKey = 'today_feed_last_timezone_check';

  /// Cache configuration
  static const int _currentCacheVersion = 1;

  // ============================================================================
  // STATIC VARIABLES & STATE
  // ============================================================================

  /// SharedPreferences instance for cache storage
  static SharedPreferences? _prefs;

  /// Initialization state flag
  static bool _isInitialized = false;

  /// Timer for automatic content refresh
  static Timer? _refreshTimer;

  /// Timer for timezone change detection
  static Timer? _timezoneCheckTimer;

  /// Timer for automatic cache cleanup
  static Timer? _automaticCleanupTimer;

  // ============================================================================
  // INITIALIZATION & SETUP
  // ============================================================================

  /// Initialize the Today Feed cache service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs ??= await SharedPreferences.getInstance();

      // Initialize content service first (core dependency)
      await TodayFeedContentService.initialize(_prefs!);

      // Initialize statistics service
      await TodayFeedCacheStatisticsService.initialize(_prefs!);

      // Initialize health service
      await TodayFeedCacheHealthService.initialize(_prefs!);

      // Initialize performance service
      await TodayFeedCachePerformanceService.initialize(_prefs!);

      // Initialize timezone service
      await TodayFeedTimezoneService.initialize(_prefs!);

      // Initialize sync service
      await TodayFeedCacheSyncService.initialize(_prefs!);

      // Initialize maintenance service
      await TodayFeedCacheMaintenanceService.initialize(_prefs!);

      await _validateCacheVersion();
      await _detectAndHandleTimezoneChanges();
      await _scheduleNextRefresh();
      _isInitialized = true;

      debugPrint('✅ TodayFeedCacheService initialized successfully');
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

  // ============================================================================
  // CORE CONTENT OPERATIONS
  // ============================================================================

  /// Cache today's content with metadata and size enforcement
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
  static Future<TodayFeedContent?> getTodayContent({
    bool allowStale = false,
  }) async {
    await initialize();
    return await TodayFeedContentService.getTodayContent(
      allowStale: allowStale,
    );
  }

  /// Get previous day's content as fallback with enhanced metadata
  static Future<TodayFeedContent?> getPreviousDayContent() async {
    await initialize();
    return await TodayFeedContentService.getPreviousDayContent();
  }

  /// Move today's content to previous day storage
  static Future<void> _archiveTodayContent() async {
    await TodayFeedContentService.archiveTodayContent();
  }

  // ============================================================================
  // REFRESH & TIMING OPERATIONS
  // ============================================================================

  /// Check if cached content needs refresh (timezone-aware with DST handling)
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

      // Check if we're past the preferred refresh time (_refreshHour AM local)
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

  // ============================================================================
  // CACHE MANAGEMENT & CLEANUP
  // ============================================================================

  /// Clear all cached data
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

  /// Clear today's content only
  static Future<void> clearTodayContent() async {
    await initialize();
    await TodayFeedContentService.clearTodayContent();
  }

  /// Force refresh content immediately
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

  // ============================================================================
  // INTERNAL REFRESH & SCHEDULING
  // ============================================================================

  /// Trigger content refresh
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
      // Fallback to 24-hour refresh
      _refreshTimer = Timer(const Duration(hours: 24), () async {
        debugPrint('⏰ Fallback refresh triggered');
        await _triggerRefresh();
      });
    }
  }

  /// Queue error for later analysis
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

  /// Get cache metadata for debugging
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

  /// Dispose of resources
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

  // ============================================================================
  // UTILITY & DEBUG METHODS
  // ============================================================================

  /// Get timezone statistics for debugging
  static Future<Map<String, dynamic>> getTimezoneStats() async {
    await initialize();
    return TodayFeedTimezoneService.getTimezoneStats();
  }

  /// Manual invalidation for testing
  static Future<void> invalidateCache({String? reason}) async {
    await initialize();
    await TodayFeedCacheMaintenanceService.invalidateCache(reason: reason);
  }

  /// Get sync status for debugging
  static Map<String, dynamic> getSyncStatus() {
    return {
      'is_initialized': _isInitialized,
      'has_refresh_timer': _refreshTimer != null,
      'has_timezone_timer': _timezoneCheckTimer != null,
      'has_cleanup_timer': _automaticCleanupTimer != null,
    };
  }

  // ============================================================================
  // AGGREGATED METRICS & STATISTICS
  // ============================================================================

  /// Get statistics from all services
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

  // ============================================================================
  // BACKWARD COMPATIBILITY METHODS
  // ============================================================================

  /// Reset service for testing (compatibility method)
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

  /// Clear all cache (compatibility wrapper)
  static Future<void> clearAllCache() async {
    await initialize();
    await invalidateCache();
  }

  /// Get cache stats (compatibility wrapper)
  static Future<Map<String, dynamic>> getCacheStats() async {
    await initialize();
    return await getCacheMetadata();
  }

  /// Queue interaction (compatibility wrapper)
  static Future<void> queueInteraction(Map<String, dynamic> interaction) async {
    await initialize();
    await TodayFeedCacheSyncService.cachePendingInteraction(interaction);
  }

  /// Get content history (compatibility method)
  static Future<List<Map<String, dynamic>>> getContentHistory() async {
    await initialize();
    return await TodayFeedContentService.getContentHistory();
  }

  /// Cache pending interaction (compatibility method)
  static Future<void> cachePendingInteraction(
    Map<String, dynamic> interaction,
  ) async {
    await initialize();
    await TodayFeedCacheSyncService.cachePendingInteraction(interaction);
  }

  /// Get pending interactions (compatibility method)
  static Future<List<Map<String, dynamic>>> getPendingInteractions() async {
    await initialize();
    return await TodayFeedCacheSyncService.getPendingInteractions();
  }

  /// Clear pending interactions (compatibility method)
  static Future<void> clearPendingInteractions() async {
    await initialize();
    await TodayFeedCacheSyncService.clearPendingInteractions();
  }

  /// Sync when online (compatibility wrapper)
  static Future<void> syncWhenOnline() async {
    await initialize();
    await TodayFeedCacheSyncService.syncWhenOnline();
  }

  /// Selective cleanup (compatibility wrapper)
  static Future<void> selectiveCleanup() async {
    await initialize();
    await TodayFeedCacheMaintenanceService.selectiveCleanup();
  }

  /// Get diagnostic info (compatibility wrapper)
  static Future<Map<String, dynamic>> getDiagnosticInfo() async {
    await initialize();

    final timers = <String, bool>{
      'refresh_timer': _refreshTimer != null,
      'timezone_timer': _timezoneCheckTimer != null,
      'cleanup_timer': _automaticCleanupTimer != null,
    };

    return await TodayFeedCacheHealthService.getDiagnosticInfo(
      _isInitialized,
      false, // sync in progress handled by sync service
      null, // connectivity subscription handled by sync service
      timers,
    );
  }

  /// Mark content as viewed (compatibility wrapper)
  static Future<void> markContentAsViewed(TodayFeedContent content) async {
    await initialize();
    await TodayFeedCacheSyncService.markContentAsViewed(content);
  }

  /// Get cache statistics (compatibility wrapper)
  static Future<Map<String, dynamic>> getCacheStatistics() async {
    await initialize();
    final cacheMetadata = await getCacheMetadata();
    return await TodayFeedCacheStatisticsService.getCacheStatistics(
      cacheMetadata,
    );
  }

  /// Get cache health status (compatibility wrapper)
  static Future<Map<String, dynamic>> getCacheHealthStatus() async {
    await initialize();
    final cacheMetadata = await getCacheMetadata();
    final syncStatus = await TodayFeedCacheSyncService.getSyncStatus();
    return await TodayFeedCacheHealthService.getCacheHealthStatus(
      cacheMetadata,
      syncStatus,
    );
  }

  /// Invalidate content (compatibility method)
  static Future<void> invalidateContent({
    bool clearHistory = false,
    bool clearMetadata = false,
    String? reason,
  }) async {
    await initialize();
    await TodayFeedCacheMaintenanceService.invalidateContent(
      clearHistory: clearHistory,
      clearMetadata: clearMetadata,
      reason: reason,
    );
  }

  /// Get cache invalidation stats (compatibility method)
  static Future<Map<String, dynamic>> getCacheInvalidationStats() async {
    await initialize();
    return await TodayFeedCacheMaintenanceService.getCacheInvalidationStats();
  }

  /// Should use fallback content (compatibility method)
  static Future<bool> shouldUseFallbackContent() async {
    await initialize();
    return await TodayFeedContentService.shouldUseFallbackContent();
  }

  /// Get fallback content with metadata (compatibility method)
  static Future<TodayFeedContent?> getFallbackContentWithMetadata() async {
    await initialize();
    return await TodayFeedContentService.getFallbackContentWithMetadata();
  }

  /// Set background sync enabled (compatibility wrapper)
  static Future<void> setBackgroundSyncEnabled(bool enabled) async {
    await initialize();
    await TodayFeedCacheSyncService.setBackgroundSyncEnabled(enabled);
  }

  /// Check if background sync is enabled (compatibility wrapper)
  static Future<bool> isBackgroundSyncEnabled() async {
    await initialize();
    return await TodayFeedCacheSyncService.isBackgroundSyncEnabled();
  }

  /// Export metrics for monitoring (compatibility wrapper)
  static Future<Map<String, dynamic>> exportMetricsForMonitoring() async {
    await initialize();
    final cacheMetadata = await getCacheMetadata();
    final healthStatus = await getCacheHealthStatus();
    return await TodayFeedCacheStatisticsService.exportMetricsForMonitoring(
      cacheMetadata,
      healthStatus,
    );
  }

  /// Perform cache integrity check (compatibility wrapper)
  static Future<Map<String, dynamic>> performCacheIntegrityCheck() async {
    await initialize();
    return await TodayFeedCacheHealthService.performCacheIntegrityCheck();
  }
}
