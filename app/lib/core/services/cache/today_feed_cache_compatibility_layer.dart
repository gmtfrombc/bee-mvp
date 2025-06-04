/// **TodayFeedCacheCompatibilityLayer**
///
/// Provides backward compatibility for legacy method signatures and patterns.
/// This layer ensures that existing code continues to work while the core
/// service evolves with cleaner architecture.
///
/// **Purpose**:
/// - Maintains 100% backward compatibility for existing code
/// - Provides clear migration path to modern API methods
/// - Documents legacy patterns and their modern equivalents
/// - Enables gradual migration without breaking changes
///
/// **Usage Pattern**:
/// ```dart
/// // Legacy code continues to work:
/// await TodayFeedCacheService.clearAllCache();
/// await TodayFeedCacheService.getCacheStats();
///
/// // Modern equivalent (recommended for new code):
/// await TodayFeedCacheService.invalidateCache();
/// await TodayFeedCacheService.getCacheMetadata();
/// ```
///
/// **Migration Guidelines**:
/// - Use modern methods for new code development
/// - Legacy methods will be supported until v2.0
/// - Deprecation warnings will be added in future releases
/// - See migration guide for detailed upgrade paths
library;

import 'dart:async';
import '../../../features/today_feed/domain/models/today_feed_content.dart';
import '../today_feed_cache_service.dart';
import 'today_feed_cache_sync_service.dart';
import 'today_feed_cache_maintenance_service.dart';
import 'today_feed_cache_health_service.dart';
import 'today_feed_cache_statistics_service.dart';
import 'today_feed_content_service.dart';

/// **Compatibility layer for legacy Today Feed cache methods**
///
/// This class provides backward compatibility for all legacy method signatures
/// while delegating to the modern modular architecture. All methods maintain
/// identical behavior to preserve existing functionality.
class TodayFeedCacheCompatibilityLayer {
  // ═══════════════════════════════════════════════════════════════════════════
  // TESTING & LIFECYCLE COMPATIBILITY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Reset service for testing (compatibility method)
  ///
  /// **Legacy Pattern**: Direct service reset for testing
  /// **Modern Alternative**: Use TodayFeedCacheService.resetForTesting() directly
  ///
  /// This method maintains the legacy testing interface while delegating
  /// to the main service's reset functionality.
  static void resetForTesting() {
    // Delegate to the main service's reset method
    // This maintains the exact same behavior as before
    TodayFeedCacheService.resetForTesting();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CACHE MANAGEMENT COMPATIBILITY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Clear all cache (compatibility wrapper)
  ///
  /// **Legacy Pattern**: clearAllCache() for complete cache reset
  /// **Modern Alternative**: invalidateCache() with optional reason
  ///
  /// ```dart
  /// // Legacy (still supported):
  /// await TodayFeedCacheCompatibilityLayer.clearAllCache();
  ///
  /// // Modern (recommended):
  /// await TodayFeedCacheService.invalidateCache(reason: 'user_requested');
  /// ```
  static Future<void> clearAllCache() async {
    await TodayFeedCacheService.initialize();
    await TodayFeedCacheService.invalidateCache();
  }

  /// Get cache stats (compatibility wrapper)
  ///
  /// **Legacy Pattern**: getCacheStats() for basic cache information
  /// **Modern Alternative**: getCacheMetadata() for comprehensive metadata
  ///
  /// ```dart
  /// // Legacy (still supported):
  /// final stats = await TodayFeedCacheCompatibilityLayer.getCacheStats();
  ///
  /// // Modern (recommended):
  /// final metadata = await TodayFeedCacheService.getCacheMetadata();
  /// ```
  static Future<Map<String, dynamic>> getCacheStats() async {
    await TodayFeedCacheService.initialize();
    return await TodayFeedCacheService.getCacheMetadata();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // USER INTERACTION COMPATIBILITY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Queue interaction (compatibility wrapper)
  ///
  /// **Legacy Pattern**: queueInteraction() for user interactions
  /// **Modern Alternative**: TodayFeedCacheSyncService.cachePendingInteraction()
  ///
  /// Maintains backward compatibility for interaction queuing while using
  /// the modern sync service architecture.
  static Future<void> queueInteraction(Map<String, dynamic> interaction) async {
    await TodayFeedCacheService.initialize();
    await TodayFeedCacheSyncService.cachePendingInteraction(interaction);
  }

  /// Cache pending interaction (compatibility method)
  ///
  /// **Legacy Pattern**: Direct interaction caching
  /// **Modern Alternative**: Use TodayFeedCacheSyncService directly
  ///
  /// This is an alias for queueInteraction() to support both legacy patterns.
  static Future<void> cachePendingInteraction(
    Map<String, dynamic> interaction,
  ) async {
    await TodayFeedCacheService.initialize();
    await TodayFeedCacheSyncService.cachePendingInteraction(interaction);
  }

  /// Get pending interactions (compatibility method)
  ///
  /// **Legacy Pattern**: getPendingInteractions() for queued interactions
  /// **Modern Alternative**: TodayFeedCacheSyncService.getPendingInteractions()
  static Future<List<Map<String, dynamic>>> getPendingInteractions() async {
    await TodayFeedCacheService.initialize();
    return await TodayFeedCacheSyncService.getPendingInteractions();
  }

  /// Clear pending interactions (compatibility method)
  ///
  /// **Legacy Pattern**: clearPendingInteractions() for cleanup
  /// **Modern Alternative**: TodayFeedCacheSyncService.clearPendingInteractions()
  static Future<void> clearPendingInteractions() async {
    await TodayFeedCacheService.initialize();
    await TodayFeedCacheSyncService.clearPendingInteractions();
  }

  /// Mark content as viewed (compatibility wrapper)
  ///
  /// **Legacy Pattern**: markContentAsViewed() for engagement tracking
  /// **Modern Alternative**: TodayFeedCacheSyncService.markContentAsViewed()
  static Future<void> markContentAsViewed(TodayFeedContent content) async {
    await TodayFeedCacheService.initialize();
    await TodayFeedCacheSyncService.markContentAsViewed(content);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTENT MANAGEMENT COMPATIBILITY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get content history (compatibility method)
  ///
  /// **Legacy Pattern**: getContentHistory() for historical content
  /// **Modern Alternative**: TodayFeedContentService.getContentHistory()
  static Future<List<Map<String, dynamic>>> getContentHistory() async {
    await TodayFeedCacheService.initialize();
    return await TodayFeedContentService.getContentHistory();
  }

  /// Invalidate content (compatibility method)
  ///
  /// **Legacy Pattern**: invalidateContent() with specific options
  /// **Modern Alternative**: TodayFeedCacheMaintenanceService.invalidateContent()
  ///
  /// Maintains support for granular content invalidation options.
  static Future<void> invalidateContent({
    bool clearHistory = false,
    bool clearMetadata = false,
    String? reason,
  }) async {
    await TodayFeedCacheService.initialize();
    await TodayFeedCacheMaintenanceService.invalidateContent(
      clearHistory: clearHistory,
      clearMetadata: clearMetadata,
      reason: reason,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SYNC & NETWORK COMPATIBILITY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sync when online (compatibility wrapper)
  ///
  /// **Legacy Pattern**: syncWhenOnline() for connectivity-based sync
  /// **Modern Alternative**: TodayFeedCacheSyncService.syncWhenOnline()
  static Future<void> syncWhenOnline() async {
    await TodayFeedCacheService.initialize();
    await TodayFeedCacheSyncService.syncWhenOnline();
  }

  /// Set background sync enabled (compatibility wrapper)
  ///
  /// **Legacy Pattern**: setBackgroundSyncEnabled() for sync configuration
  /// **Modern Alternative**: TodayFeedCacheSyncService.setBackgroundSyncEnabled()
  static Future<void> setBackgroundSyncEnabled(bool enabled) async {
    await TodayFeedCacheService.initialize();
    await TodayFeedCacheSyncService.setBackgroundSyncEnabled(enabled);
  }

  /// Check if background sync is enabled (compatibility wrapper)
  ///
  /// **Legacy Pattern**: isBackgroundSyncEnabled() for sync status
  /// **Modern Alternative**: TodayFeedCacheSyncService.isBackgroundSyncEnabled()
  static Future<bool> isBackgroundSyncEnabled() async {
    await TodayFeedCacheService.initialize();
    return await TodayFeedCacheSyncService.isBackgroundSyncEnabled();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MAINTENANCE COMPATIBILITY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Selective cleanup (compatibility wrapper)
  ///
  /// **Legacy Pattern**: selectiveCleanup() for targeted maintenance
  /// **Modern Alternative**: TodayFeedCacheMaintenanceService.selectiveCleanup()
  static Future<void> selectiveCleanup() async {
    await TodayFeedCacheService.initialize();
    await TodayFeedCacheMaintenanceService.selectiveCleanup();
  }

  /// Get cache invalidation stats (compatibility method)
  ///
  /// **Legacy Pattern**: getCacheInvalidationStats() for maintenance metrics
  /// **Modern Alternative**: TodayFeedCacheMaintenanceService.getCacheInvalidationStats()
  static Future<Map<String, dynamic>> getCacheInvalidationStats() async {
    await TodayFeedCacheService.initialize();
    return await TodayFeedCacheMaintenanceService.getCacheInvalidationStats();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEALTH & MONITORING COMPATIBILITY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get diagnostic info (compatibility wrapper)
  ///
  /// **Legacy Pattern**: getDiagnosticInfo() for system diagnostics
  /// **Modern Alternative**: TodayFeedCacheHealthService.getDiagnosticInfo()
  ///
  /// Maintains the legacy diagnostic interface while using modern health services.
  static Future<Map<String, dynamic>> getDiagnosticInfo() async {
    await TodayFeedCacheService.initialize();

    // Recreate the legacy timer information structure
    final timers = <String, bool>{
      'refresh_timer':
          TodayFeedCacheService.getSyncStatus()['has_refresh_timer'] ?? false,
      'timezone_timer':
          TodayFeedCacheService.getSyncStatus()['has_timezone_timer'] ?? false,
      'cleanup_timer':
          TodayFeedCacheService.getSyncStatus()['has_cleanup_timer'] ?? false,
    };

    return await TodayFeedCacheHealthService.getDiagnosticInfo(
      TodayFeedCacheService.getSyncStatus()['is_initialized'] ?? false,
      false, // sync in progress handled by sync service
      null, // connectivity subscription handled by sync service
      timers,
    );
  }

  /// Get cache statistics (compatibility wrapper)
  ///
  /// **Legacy Pattern**: getCacheStatistics() for basic metrics
  /// **Modern Alternative**: TodayFeedCacheStatisticsService.getCacheStatistics()
  static Future<Map<String, dynamic>> getCacheStatistics() async {
    await TodayFeedCacheService.initialize();
    final cacheMetadata = await TodayFeedCacheService.getCacheMetadata();
    return await TodayFeedCacheStatisticsService.getCacheStatistics(
      cacheMetadata,
    );
  }

  /// Get cache health status (compatibility wrapper)
  ///
  /// **Legacy Pattern**: getCacheHealthStatus() for health monitoring
  /// **Modern Alternative**: TodayFeedCacheHealthService.getCacheHealthStatus()
  static Future<Map<String, dynamic>> getCacheHealthStatus() async {
    await TodayFeedCacheService.initialize();
    final cacheMetadata = await TodayFeedCacheService.getCacheMetadata();
    final syncStatus = await TodayFeedCacheSyncService.getSyncStatus();
    return await TodayFeedCacheHealthService.getCacheHealthStatus(
      cacheMetadata,
      syncStatus,
    );
  }

  /// Export metrics for monitoring (compatibility wrapper)
  ///
  /// **Legacy Pattern**: exportMetricsForMonitoring() for external monitoring
  /// **Modern Alternative**: TodayFeedCacheStatisticsService.exportMetricsForMonitoring()
  static Future<Map<String, dynamic>> exportMetricsForMonitoring() async {
    await TodayFeedCacheService.initialize();
    final cacheMetadata = await TodayFeedCacheService.getCacheMetadata();
    final healthStatus = await getCacheHealthStatus();
    return await TodayFeedCacheStatisticsService.exportMetricsForMonitoring(
      cacheMetadata,
      healthStatus,
    );
  }

  /// Perform cache integrity check (compatibility wrapper)
  ///
  /// **Legacy Pattern**: performCacheIntegrityCheck() for validation
  /// **Modern Alternative**: TodayFeedCacheHealthService.performCacheIntegrityCheck()
  static Future<Map<String, dynamic>> performCacheIntegrityCheck() async {
    await TodayFeedCacheService.initialize();
    return await TodayFeedCacheHealthService.performCacheIntegrityCheck();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPATIBILITY LAYER UTILITIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all available legacy methods
  ///
  /// Utility method for developers to understand what compatibility methods
  /// are available and their modern equivalents.
  static Map<String, String> getLegacyMethodMappings() {
    return {
      // Testing & Lifecycle
      'resetForTesting': 'TodayFeedCacheService.resetForTesting()',

      // Cache Management
      'clearAllCache': 'TodayFeedCacheService.invalidateCache()',
      'getCacheStats': 'TodayFeedCacheService.getCacheMetadata()',

      // User Interaction
      'queueInteraction': 'TodayFeedCacheSyncService.cachePendingInteraction()',
      'cachePendingInteraction':
          'TodayFeedCacheSyncService.cachePendingInteraction()',
      'getPendingInteractions':
          'TodayFeedCacheSyncService.getPendingInteractions()',
      'clearPendingInteractions':
          'TodayFeedCacheSyncService.clearPendingInteractions()',
      'markContentAsViewed': 'TodayFeedCacheSyncService.markContentAsViewed()',

      // Content Management
      'getContentHistory': 'TodayFeedContentService.getContentHistory()',
      'invalidateContent':
          'TodayFeedCacheMaintenanceService.invalidateContent()',

      // Sync & Network
      'syncWhenOnline': 'TodayFeedCacheSyncService.syncWhenOnline()',
      'setBackgroundSyncEnabled':
          'TodayFeedCacheSyncService.setBackgroundSyncEnabled()',
      'isBackgroundSyncEnabled':
          'TodayFeedCacheSyncService.isBackgroundSyncEnabled()',

      // Maintenance
      'selectiveCleanup': 'TodayFeedCacheMaintenanceService.selectiveCleanup()',
      'getCacheInvalidationStats':
          'TodayFeedCacheMaintenanceService.getCacheInvalidationStats()',

      // Health & Monitoring
      'getDiagnosticInfo': 'TodayFeedCacheHealthService.getDiagnosticInfo()',
      'getCacheStatistics':
          'TodayFeedCacheStatisticsService.getCacheStatistics()',
      'getCacheHealthStatus':
          'TodayFeedCacheHealthService.getCacheHealthStatus()',
      'exportMetricsForMonitoring':
          'TodayFeedCacheStatisticsService.exportMetricsForMonitoring()',
      'performCacheIntegrityCheck':
          'TodayFeedCacheHealthService.performCacheIntegrityCheck()',
    };
  }

  /// Check if a method is a legacy compatibility method
  ///
  /// Utility to help developers identify legacy patterns in their codebase.
  static bool isLegacyMethod(String methodName) {
    return getLegacyMethodMappings().containsKey(methodName);
  }

  /// Get modern equivalent for a legacy method
  ///
  /// Helps developers find the modern equivalent for migration.
  static String? getModernEquivalent(String legacyMethodName) {
    return getLegacyMethodMappings()[legacyMethodName];
  }
}
