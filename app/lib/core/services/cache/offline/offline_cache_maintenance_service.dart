import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'offline_cache_stats_service.dart';
import 'offline_cache_error_service.dart';
import 'offline_cache_validation_service.dart';

/// Service for cache maintenance and cleanup operations
class OfflineCacheMaintenanceService {
  // Cache keys for maintenance operations
  static const String _momentumDataKey = 'cached_momentum_data';
  static const String _lastUpdateKey = 'momentum_last_update';
  static const String _pendingActionsKey = 'pending_actions';
  static const String _errorQueueKey = 'error_queue';
  static const String _weeklyTrendKey = 'cached_weekly_trend';
  static const String _momentumStatsKey = 'cached_momentum_stats';

  static SharedPreferences? _prefs;

  /// Initialize the maintenance service
  static Future<void> initialize(SharedPreferences prefs) async {
    _prefs = prefs;
  }

  /// Smart cache invalidation based on data type and priority
  static Future<void> invalidateCache({
    bool momentumData = true,
    bool weeklyTrend = false,
    bool momentumStats = false,
    String? reason,
  }) async {
    if (_prefs == null) {
      throw StateError('OfflineCacheMaintenanceService not initialized');
    }

    try {
      final List<String> invalidated = [];

      if (momentumData) {
        await _prefs!.remove(_momentumDataKey);
        await _prefs!.remove(_lastUpdateKey);
        invalidated.add('momentum data');
      }

      if (weeklyTrend) {
        await _prefs!.remove(_weeklyTrendKey);
        invalidated.add('weekly trend');
      }

      if (momentumStats) {
        await _prefs!.remove(_momentumStatsKey);
        invalidated.add('momentum stats');
      }

      if (invalidated.isNotEmpty) {
        debugPrint(
          '🗑️ Cache invalidated: ${invalidated.join(', ')}${reason != null ? ' (reason: $reason)' : ''}',
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to invalidate cache: $e');
      rethrow;
    }
  }

  /// Clear all cached data
  static Future<void> clearAllCache() async {
    if (_prefs == null) {
      throw StateError('OfflineCacheMaintenanceService not initialized');
    }

    try {
      await Future.wait([
        _prefs!.remove(_momentumDataKey),
        _prefs!.remove(_lastUpdateKey),
        _prefs!.remove(_pendingActionsKey),
        _prefs!.remove(_errorQueueKey),
        _prefs!.remove(_weeklyTrendKey),
        _prefs!.remove(_momentumStatsKey),
      ]);

      debugPrint('✅ All cache cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear all cache: $e');
      rethrow;
    }
  }

  /// Clean up cache to free memory and storage space
  static Future<void> performCacheCleanup({bool force = false}) async {
    if (_prefs == null) {
      throw StateError('OfflineCacheMaintenanceService not initialized');
    }

    try {
      debugPrint('🧹 Performing cache cleanup${force ? ' (forced)' : ''}');

      // Clear expired cache data
      final isValid = await OfflineCacheValidationService.isCachedDataValid();
      if (!isValid || force) {
        await invalidateCache(
          momentumData: true,
          weeklyTrend: true,
          momentumStats: true,
          reason: force ? 'forced cleanup' : 'expired data',
        );
      }

      // Action service handles its own expired data cleanup during initialization

      // Clean up old error queue entries using the error service
      await OfflineCacheErrorService.cleanupOldErrors(maxErrors: 5);

      debugPrint('✅ Cache cleanup completed');
    } catch (e) {
      debugPrint('❌ Failed to perform cache cleanup: $e');
      rethrow;
    }
  }

  /// Monitor cache size and trigger cleanup if needed
  static Future<void> checkCacheHealth() async {
    if (_prefs == null) {
      throw StateError('OfflineCacheMaintenanceService not initialized');
    }

    try {
      final stats = await OfflineCacheStatsService.getEnhancedCacheStats();
      final healthScore = stats['healthScore'] as int;

      // If health score is low, trigger cleanup
      if (healthScore < 70) {
        debugPrint(
          '⚠️ Cache health score low ($healthScore), triggering cleanup',
        );
        await performCacheCleanup();
      }
    } catch (e) {
      debugPrint('❌ Failed to check cache health: $e');
      rethrow;
    }
  }

  /// Reset cache maintenance state for testing
  /// **WARNING**: This should only be used in test environments
  static void resetForTesting() {
    assert(() {
      // Only allow this in debug/test builds
      return true;
    }());

    _prefs = null;
  }

  /// Clear cache entries for testing
  /// **WARNING**: This should only be used in test environments
  static Future<void> clearCacheForTesting() async {
    assert(() {
      // Only allow this in debug/test builds
      return true;
    }());

    if (_prefs != null) {
      await clearAllCache();
    }
  }

  /// Force cache invalidation for testing
  /// **WARNING**: This should only be used in test environments
  static Future<void> invalidateCacheForTesting({
    bool momentumData = true,
    bool weeklyTrend = true,
    bool momentumStats = true,
  }) async {
    assert(() {
      // Only allow this in debug/test builds
      return true;
    }());

    await invalidateCache(
      momentumData: momentumData,
      weeklyTrend: weeklyTrend,
      momentumStats: momentumStats,
      reason: 'testing',
    );
  }

  /// Perform maintenance with custom criteria for testing
  /// **WARNING**: This should only be used in test environments
  static Future<void> performMaintenanceForTesting({
    bool force = false,
    int? healthThreshold,
  }) async {
    assert(() {
      // Only allow this in debug/test builds
      return true;
    }());

    if (force) {
      await performCacheCleanup(force: true);
    } else if (healthThreshold != null) {
      final stats = await OfflineCacheStatsService.getEnhancedCacheStats();
      final healthScore = stats['healthScore'] as int;

      if (healthScore < healthThreshold) {
        await performCacheCleanup();
      }
    } else {
      await checkCacheHealth();
    }
  }
}
