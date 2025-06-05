import 'package:shared_preferences/shared_preferences.dart';
import '../../features/momentum/domain/models/momentum_data.dart';
import 'cache/offline/offline_cache_stats_service.dart';
import 'cache/offline/offline_cache_error_service.dart';
import 'cache/offline/offline_cache_action_service.dart';
import 'cache/offline/offline_cache_sync_service.dart';
import 'cache/offline/offline_cache_validation_service.dart';
import 'cache/offline/offline_cache_maintenance_service.dart';
import 'cache/offline/offline_cache_content_service.dart';

/// **Enhanced Offline Cache Service - Main Coordinator**
///
/// This service has been refactored from a monolithic 730-line service into a
/// modular architecture with 6 specialized services. This main service acts as
/// a coordinator and maintains 100% backward compatibility.
///
/// **Architecture:**
/// - OfflineCacheContentService: Core data caching/retrieval
/// - OfflineCacheValidationService: Data integrity & validation
/// - OfflineCacheMaintenanceService: Cleanup & maintenance
/// - OfflineCacheErrorService: Error handling & queuing
/// - OfflineCacheSyncService: Background synchronization
/// - OfflineCacheActionService: Pending action management
/// - OfflineCacheStatsService: Health monitoring & statistics
///
/// **Key Features:**
/// - Enhanced momentum data caching with priority levels
/// - Granular cache validation and component-specific invalidation
/// - Priority-based pending action queue with retry logic
/// - Comprehensive error handling and reporting
/// - Background sync management and cache warming
/// - Detailed health monitoring and statistics
///
/// **Usage:**
/// ```dart
/// await OfflineCacheService.initialize();
/// await OfflineCacheService.cacheMomentumData(data, isHighPriority: true);
/// final cachedData = await OfflineCacheService.getCachedMomentumData();
/// ```
class OfflineCacheService {
  static SharedPreferences? _prefs;
  static bool _isInitialized = false;

  /// Initialize the cache service and all specialized services
  ///
  /// This method initializes all specialized services in the correct order:
  /// 1. Validation service (handles version upgrades)
  /// 2. All other services in dependency order
  ///
  /// **Safe to call multiple times** - prevents re-initialization
  static Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs ??= await SharedPreferences.getInstance();

    // Initialize validation service first (handles version upgrades)
    await OfflineCacheValidationService.initialize(_prefs!);
    await OfflineCacheValidationService.validateCacheVersion();

    // Initialize all other services
    await OfflineCacheStatsService.initialize(_prefs!);
    await OfflineCacheErrorService.initialize(_prefs!);
    await OfflineCacheActionService.initialize(_prefs!);
    await OfflineCacheSyncService.initialize(_prefs!);
    await OfflineCacheMaintenanceService.initialize(_prefs!);
    await OfflineCacheContentService.initialize(_prefs!);

    _isInitialized = true;
  }

  // ============================================================================
  // CONTENT OPERATIONS (Delegated to OfflineCacheContentService)
  // ============================================================================

  /// Cache momentum data with enhanced control options
  ///
  /// **Parameters:**
  /// - `data`: The momentum data to cache
  /// - `isHighPriority`: If true, bypasses some caching optimizations
  /// - `skipIfRecentUpdate`: If true, skips caching if recent update detected
  ///
  /// **Delegated to:** OfflineCacheContentService
  static Future<void> cacheMomentumData(
    MomentumData data, {
    bool isHighPriority = false,
    bool skipIfRecentUpdate = false,
  }) async {
    await initialize();
    await OfflineCacheContentService.cacheMomentumData(
      data,
      isHighPriority: isHighPriority,
      skipIfRecentUpdate: skipIfRecentUpdate,
    );
  }

  /// Get cached momentum data with validation options
  ///
  /// **Parameters:**
  /// - `allowStaleData`: If true, returns data even if expired
  /// - `customValidityPeriod`: Override default validity period
  ///
  /// **Returns:** Cached momentum data or null if not available/valid
  /// **Delegated to:** OfflineCacheContentService
  static Future<MomentumData?> getCachedMomentumData({
    bool allowStaleData = false,
    Duration? customValidityPeriod,
  }) async {
    await initialize();
    return await OfflineCacheContentService.getCachedMomentumData(
      allowStaleData: allowStaleData,
      customValidityPeriod: customValidityPeriod,
    );
  }

  /// Get cached weekly trend data
  ///
  /// **Parameters:**
  /// - `allowStaleData`: If true, returns data even if expired
  ///
  /// **Delegated to:** OfflineCacheContentService
  static Future<List<DailyMomentum>?> getCachedWeeklyTrend({
    bool allowStaleData = false,
  }) async {
    await initialize();
    return await OfflineCacheContentService.getCachedWeeklyTrend(
      allowStaleData: allowStaleData,
    );
  }

  /// Get cached momentum statistics
  ///
  /// **Parameters:**
  /// - `allowStaleData`: If true, returns data even if expired
  ///
  /// **Delegated to:** OfflineCacheContentService
  static Future<MomentumStats?> getCachedMomentumStats({
    bool allowStaleData = false,
  }) async {
    await initialize();
    return await OfflineCacheContentService.getCachedMomentumStats(
      allowStaleData: allowStaleData,
    );
  }

  // ============================================================================
  // VALIDATION OPERATIONS (Delegated to OfflineCacheValidationService)
  // ============================================================================

  /// Check if cached data is valid with enhanced options
  ///
  /// **Parameters:**
  /// - `customValidityPeriod`: Override default validity period
  /// - `isHighPriorityUpdate`: Use shorter validity for high priority updates
  ///
  /// **Delegated to:** OfflineCacheValidationService
  static Future<bool> isCachedDataValid({
    Duration? customValidityPeriod,
    bool isHighPriorityUpdate = false,
  }) async {
    await initialize();
    return await OfflineCacheValidationService.isCachedDataValid(
      customValidityPeriod: customValidityPeriod,
      isHighPriorityUpdate: isHighPriorityUpdate,
    );
  }

  // ============================================================================
  // MAINTENANCE OPERATIONS (Delegated to OfflineCacheMaintenanceService)
  // ============================================================================

  /// Smart cache invalidation with component-specific control
  ///
  /// **Parameters:**
  /// - `momentumData`: Invalidate main momentum data
  /// - `weeklyTrend`: Invalidate weekly trend cache
  /// - `momentumStats`: Invalidate momentum stats cache
  /// - `reason`: Optional reason for logging
  ///
  /// **Delegated to:** OfflineCacheMaintenanceService
  static Future<void> invalidateCache({
    bool momentumData = true,
    bool weeklyTrend = false,
    bool momentumStats = false,
    String? reason,
  }) async {
    await initialize();
    await OfflineCacheMaintenanceService.invalidateCache(
      momentumData: momentumData,
      weeklyTrend: weeklyTrend,
      momentumStats: momentumStats,
      reason: reason,
    );
  }

  /// Clear all cached data and reset service state
  ///
  /// **Warning:** This clears ALL cached data and resets initialization state
  /// **Delegated to:** OfflineCacheMaintenanceService
  static Future<void> clearAllCache() async {
    await initialize();
    await OfflineCacheMaintenanceService.clearAllCache();

    // Reset initialization state for complete cleanup
    _isInitialized = false;
    _prefs = null;
  }

  /// Perform cache cleanup and maintenance
  ///
  /// **Parameters:**
  /// - `force`: Force cleanup even if not needed
  ///
  /// **Delegated to:** OfflineCacheMaintenanceService
  static Future<void> performCacheCleanup({bool force = false}) async {
    await initialize();
    await OfflineCacheMaintenanceService.performCacheCleanup(force: force);
  }

  /// Monitor cache health and trigger cleanup if needed
  ///
  /// **Delegated to:** OfflineCacheMaintenanceService
  static Future<void> checkCacheHealth() async {
    await initialize();
    await OfflineCacheMaintenanceService.checkCacheHealth();
  }

  // ============================================================================
  // ACTION QUEUE OPERATIONS (Delegated to OfflineCacheActionService)
  // ============================================================================

  /// Queue a pending action with priority and retry logic
  ///
  /// **Parameters:**
  /// - `action`: Action data to queue
  /// - `priority`: 1=low, 2=medium, 3=high
  /// - `maxRetries`: Maximum retry attempts
  ///
  /// **Delegated to:** OfflineCacheActionService
  static Future<void> queuePendingAction(
    Map<String, dynamic> action, {
    int priority = 1,
    int maxRetries = 3,
  }) async {
    await initialize();
    await OfflineCacheActionService.queuePendingAction(
      action,
      priority: priority,
      maxRetries: maxRetries,
    );
  }

  /// Process all pending actions when back online
  ///
  /// **Returns:** List of successfully processed actions
  /// **Delegated to:** OfflineCacheActionService
  static Future<List<Map<String, dynamic>>> processPendingActions() async {
    await initialize();
    return await OfflineCacheActionService.processPendingActions();
  }

  /// Get all pending actions
  ///
  /// **Delegated to:** OfflineCacheActionService
  static Future<List<Map<String, dynamic>>> getPendingActions() async {
    await initialize();
    return await OfflineCacheActionService.getPendingActions();
  }

  /// Remove a pending action after successful execution
  ///
  /// **Delegated to:** OfflineCacheActionService
  static Future<void> removePendingAction(Map<String, dynamic> action) async {
    await initialize();
    await OfflineCacheActionService.removePendingAction(action);
  }

  /// Clear all pending actions
  ///
  /// **Delegated to:** OfflineCacheActionService
  static Future<void> clearPendingActions() async {
    await initialize();
    await OfflineCacheActionService.clearPendingActions();
  }

  // ============================================================================
  // SYNC OPERATIONS (Delegated to OfflineCacheSyncService)
  // ============================================================================

  /// Enable or disable background synchronization
  ///
  /// **Delegated to:** OfflineCacheSyncService
  static Future<void> enableBackgroundSync(bool enabled) async {
    await initialize();
    await OfflineCacheSyncService.enableBackgroundSync(enabled);
  }

  /// Check if background sync is enabled
  ///
  /// **Delegated to:** OfflineCacheSyncService
  static Future<bool> isBackgroundSyncEnabled() async {
    await initialize();
    return await OfflineCacheSyncService.isBackgroundSyncEnabled();
  }

  /// Warm the cache with fresh data when coming online
  ///
  /// **Delegated to:** OfflineCacheSyncService
  static Future<void> warmCache() async {
    await initialize();
    await OfflineCacheSyncService.warmCache();
  }

  // ============================================================================
  // ERROR OPERATIONS (Delegated to OfflineCacheErrorService)
  // ============================================================================

  /// Queue an error for later reporting
  ///
  /// **Delegated to:** OfflineCacheErrorService
  static Future<void> queueError(Map<String, dynamic> error) async {
    await initialize();
    await OfflineCacheErrorService.queueError(error);
  }

  /// Get all queued errors
  ///
  /// **Delegated to:** OfflineCacheErrorService
  static Future<List<Map<String, dynamic>>> getQueuedErrors() async {
    await initialize();
    return await OfflineCacheErrorService.getQueuedErrors();
  }

  /// Clear all queued errors
  ///
  /// **Delegated to:** OfflineCacheErrorService
  static Future<void> clearQueuedErrors() async {
    await initialize();
    await OfflineCacheErrorService.clearQueuedErrors();
  }

  // ============================================================================
  // STATISTICS OPERATIONS (Delegated to OfflineCacheStatsService)
  // ============================================================================

  /// Get comprehensive cache statistics and health information
  ///
  /// **Returns:** Map containing detailed cache statistics including:
  /// - Health score (0-100)
  /// - Cache validity and age
  /// - Component availability
  /// - Queue sizes
  /// - Background sync status
  ///
  /// **Delegated to:** OfflineCacheStatsService
  static Future<Map<String, dynamic>> getEnhancedCacheStats() async {
    await initialize();
    return await OfflineCacheStatsService.getEnhancedCacheStats();
  }

  /// Get the age of cached data
  ///
  /// **Returns:** Duration since data was cached, or null if no data
  /// **Delegated to:** OfflineCacheStatsService
  static Future<Duration?> getCachedDataAge() async {
    await initialize();
    return await OfflineCacheStatsService.getCachedDataAge();
  }

  /// Get cache statistics (legacy method for backward compatibility)
  ///
  /// **Delegated to:** OfflineCacheStatsService
  static Future<Map<String, dynamic>> getCacheStats() async {
    await initialize();
    return await OfflineCacheStatsService.getCacheStats();
  }

  // ============================================================================
  // TESTING HELPER METHODS
  // ============================================================================

  /// Reset the service state for testing
  ///
  /// **WARNING:** This should only be used in test environments
  /// Resets all initialization state and cached test data
  static void resetForTesting() {
    assert(() {
      // Only allow this in debug/test builds
      return true;
    }());

    _isInitialized = false;
    _prefs = null;
    _testCachedData = null;
    _testCacheIsValid = false;
  }

  /// Set cached data for testing purposes
  ///
  /// **WARNING:** This should only be used in test environments
  static void setCachedDataForTesting(
    MomentumData? data, {
    required bool isValid,
  }) {
    assert(() {
      // Only allow this in debug/test builds
      return true;
    }());

    _testCachedData = data;
    _testCacheIsValid = isValid;
  }

  /// Clear cache for testing
  ///
  /// **WARNING:** This should only be used in test environments
  static void clearCacheForTesting() {
    assert(() {
      // Only allow this in debug/test builds
      return true;
    }());

    _testCachedData = null;
    _testCacheIsValid = false;
  }

  /// Override getCachedMomentumData for testing
  ///
  /// **WARNING:** This should only be used in test environments
  static Future<MomentumData?> getCachedMomentumDataForTesting() async {
    return _testCachedData;
  }

  /// Override isCachedDataValid for testing
  ///
  /// **WARNING:** This should only be used in test environments
  static Future<bool> isCachedDataValidForTesting() async {
    return _testCacheIsValid;
  }

  // Test data storage
  static MomentumData? _testCachedData;
  static bool _testCacheIsValid = false;
}
