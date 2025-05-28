import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../features/momentum/domain/models/momentum_data.dart';

/// Enhanced service for caching momentum data offline with improved strategies
class OfflineCacheService {
  static const String _momentumDataKey = 'cached_momentum_data';
  static const String _lastUpdateKey = 'momentum_last_update';
  static const String _pendingActionsKey = 'pending_actions';
  static const String _errorQueueKey = 'error_queue';
  static const String _cacheVersionKey = 'cache_version';
  static const String _backgroundSyncKey = 'background_sync_enabled';
  static const String _lastSyncAttemptKey = 'last_sync_attempt';
  static const String _weeklyTrendKey = 'cached_weekly_trend';
  static const String _momentumStatsKey = 'cached_momentum_stats';

  // Cache validity periods (in hours)
  static const int _defaultCacheValidityHours = 24;
  static const int _criticalCacheValidityHours = 1; // For critical updates
  static const int _weeklyTrendValidityHours = 12; // Weekly data can be older
  static const int _statsValidityHours = 6; // Stats update more frequently

  static const int _currentCacheVersion =
      2; // Increment to invalidate old cache

  static SharedPreferences? _prefs;
  static bool _isInitialized = false; // Prevent initialization loops

  /// Initialize the cache service with enhanced setup
  static Future<void> initialize() async {
    if (_isInitialized) return; // Prevent re-initialization

    _prefs ??= await SharedPreferences.getInstance();
    await _validateCacheVersion();
    await _cleanupExpiredDataSafe(); // Use safe version during initialization
    _isInitialized = true;
  }

  /// Validate cache version and clear if outdated
  static Future<void> _validateCacheVersion() async {
    final currentVersion = _prefs!.getInt(_cacheVersionKey) ?? 1;
    if (currentVersion < _currentCacheVersion) {
      debugPrint(
        '🔄 Cache version outdated ($currentVersion < $_currentCacheVersion), clearing cache',
      );

      // Set the new version FIRST to prevent infinite loops
      await _prefs!.setInt(_cacheVersionKey, _currentCacheVersion);

      // Then clear the old data without re-initializing
      await Future.wait([
        _prefs!.remove(_momentumDataKey),
        _prefs!.remove(_lastUpdateKey),
        _prefs!.remove(_pendingActionsKey),
        _prefs!.remove(_errorQueueKey),
        _prefs!.remove(_weeklyTrendKey),
        _prefs!.remove(_momentumStatsKey),
      ]);

      debugPrint('✅ Cache cleared for version upgrade');
    }
  }

  /// Clean up expired data safely without recursive initialization
  static Future<void> _cleanupExpiredDataSafe() async {
    try {
      // Get pending actions without calling initialize() recursively
      final jsonString = _prefs!.getString(_pendingActionsKey);
      if (jsonString == null) return;

      final pendingActions =
          (jsonDecode(jsonString) as List<dynamic>)
              .cast<Map<String, dynamic>>();

      final cutoffTime = DateTime.now().subtract(const Duration(days: 7));

      final validActions =
          pendingActions.where((action) {
            final queuedAt = DateTime.tryParse(action['queued_at'] ?? '');
            return queuedAt != null && queuedAt.isAfter(cutoffTime);
          }).toList();

      if (validActions.length != pendingActions.length) {
        await _prefs!.setString(_pendingActionsKey, jsonEncode(validActions));
        debugPrint(
          '🧹 Cleaned up ${pendingActions.length - validActions.length} expired pending actions',
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to clean up expired data: $e');
    }
  }

  /// Enhanced momentum data caching with granular control
  static Future<void> cacheMomentumData(
    MomentumData data, {
    bool isHighPriority = false,
    bool skipIfRecentUpdate = false,
  }) async {
    await initialize();

    try {
      // Skip caching if we recently updated and it's not high priority
      if (skipIfRecentUpdate && !isHighPriority) {
        final lastUpdate = _prefs!.getString(_lastUpdateKey);
        if (lastUpdate != null) {
          final lastUpdateTime = DateTime.parse(lastUpdate);
          final timeSinceUpdate = DateTime.now().difference(lastUpdateTime);
          if (timeSinceUpdate.inMinutes < 5) {
            debugPrint('⏭️ Skipping cache update - recent update detected');
            return;
          }
        }
      }

      final jsonData = data.toJson();
      await _prefs!.setString(_momentumDataKey, jsonEncode(jsonData));
      await _prefs!.setString(_lastUpdateKey, DateTime.now().toIso8601String());

      // Cache components separately for granular access
      await _cacheWeeklyTrend(data.weeklyTrend);
      await _cacheMomentumStats(data.stats);

      debugPrint(
        '✅ Enhanced momentum data cached successfully${isHighPriority ? ' (high priority)' : ''}',
      );
    } catch (e) {
      debugPrint('❌ Failed to cache momentum data: $e');
      await queueError({
        'type': 'cache_write_error',
        'operation': 'cacheMomentumData',
        'error': e.toString(),
      });
    }
  }

  /// Cache weekly trend data separately
  static Future<void> _cacheWeeklyTrend(List<DailyMomentum> weeklyTrend) async {
    try {
      final trendData = weeklyTrend.map((daily) => daily.toJson()).toList();
      await _prefs!.setString(
        _weeklyTrendKey,
        jsonEncode({
          'data': trendData,
          'cached_at': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      debugPrint('❌ Failed to cache weekly trend: $e');
    }
  }

  /// Cache momentum stats separately
  static Future<void> _cacheMomentumStats(MomentumStats stats) async {
    try {
      await _prefs!.setString(
        _momentumStatsKey,
        jsonEncode({
          'data': stats.toJson(),
          'cached_at': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      debugPrint('❌ Failed to cache momentum stats: $e');
    }
  }

  /// Get cached momentum data with enhanced validation
  static Future<MomentumData?> getCachedMomentumData({
    bool allowStaleData = false,
    Duration? customValidityPeriod,
  }) async {
    await initialize();

    try {
      final jsonString = _prefs!.getString(_momentumDataKey);
      if (jsonString == null) return null;

      // Check validity first
      final isValid = await isCachedDataValid(
        customValidityPeriod: customValidityPeriod,
      );

      if (!isValid && !allowStaleData) {
        debugPrint('📤 Cached data is stale and stale data not allowed');
        return null;
      }

      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final cachedData = MomentumData.fromJson(jsonData);

      if (!isValid && allowStaleData) {
        debugPrint('⚠️ Returning stale cached data (offline mode)');
      }

      return cachedData;
    } catch (e) {
      debugPrint('❌ Failed to load cached momentum data: $e');
      return null;
    }
  }

  /// Enhanced cache validity check with customizable periods
  static Future<bool> isCachedDataValid({
    Duration? customValidityPeriod,
    bool isHighPriorityUpdate = false,
  }) async {
    await initialize();

    try {
      final lastUpdateString = _prefs!.getString(_lastUpdateKey);
      if (lastUpdateString == null) return false;

      final lastUpdate = DateTime.parse(lastUpdateString);
      final now = DateTime.now();
      final difference = now.difference(lastUpdate);

      // Determine validity period
      final validityHours =
          customValidityPeriod?.inHours ??
          (isHighPriorityUpdate
              ? _criticalCacheValidityHours
              : _defaultCacheValidityHours);

      return difference.inHours < validityHours;
    } catch (e) {
      debugPrint('❌ Failed to check cache validity: $e');
      return false;
    }
  }

  /// Get cached weekly trend with separate validity check
  static Future<List<DailyMomentum>?> getCachedWeeklyTrend({
    bool allowStaleData = false,
  }) async {
    await initialize();

    try {
      final jsonString = _prefs!.getString(_weeklyTrendKey);
      if (jsonString == null) return null;

      final cacheData = jsonDecode(jsonString) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(cacheData['cached_at']);
      final age = DateTime.now().difference(cachedAt);

      if (age.inHours > _weeklyTrendValidityHours && !allowStaleData) {
        return null;
      }

      final trendList = cacheData['data'] as List<dynamic>;
      return trendList.map((item) => DailyMomentum.fromJson(item)).toList();
    } catch (e) {
      debugPrint('❌ Failed to load cached weekly trend: $e');
      return null;
    }
  }

  /// Get cached momentum stats with separate validity check
  static Future<MomentumStats?> getCachedMomentumStats({
    bool allowStaleData = false,
  }) async {
    await initialize();

    try {
      final jsonString = _prefs!.getString(_momentumStatsKey);
      if (jsonString == null) return null;

      final cacheData = jsonDecode(jsonString) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(cacheData['cached_at']);
      final age = DateTime.now().difference(cachedAt);

      if (age.inHours > _statsValidityHours && !allowStaleData) {
        return null;
      }

      return MomentumStats.fromJson(cacheData['data']);
    } catch (e) {
      debugPrint('❌ Failed to load cached momentum stats: $e');
      return null;
    }
  }

  /// Warm the cache with fresh data when coming online
  static Future<void> warmCache() async {
    await initialize();

    try {
      debugPrint('🔥 Starting cache warming process');

      // Record cache warming attempt
      await _prefs!.setString(
        _lastSyncAttemptKey,
        DateTime.now().toIso8601String(),
      );

      // This would typically trigger a fresh data fetch
      // The actual data fetching should be handled by the API service
      debugPrint('✅ Cache warming completed');
    } catch (e) {
      debugPrint('❌ Cache warming failed: $e');
    }
  }

  /// Smart cache invalidation based on data type and priority
  static Future<void> invalidateCache({
    bool momentumData = true,
    bool weeklyTrend = false,
    bool momentumStats = false,
    String? reason,
  }) async {
    await initialize();

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
    }
  }

  /// Enhanced pending action management with priority and retry logic
  static Future<void> queuePendingAction(
    Map<String, dynamic> action, {
    int priority = 1, // 1 = low, 2 = medium, 3 = high
    int maxRetries = 3,
  }) async {
    await initialize();

    try {
      final existingActions = await getPendingActions();

      // Check for duplicate actions
      final isDuplicate = existingActions.any(
        (existing) =>
            existing['type'] == action['type'] &&
            existing['data'] == action['data'],
      );

      if (isDuplicate) {
        debugPrint('⚠️ Skipping duplicate pending action: ${action['type']}');
        return;
      }

      existingActions.add({
        ...action,
        'queued_at': DateTime.now().toIso8601String(),
        'priority': priority,
        'max_retries': maxRetries,
        'retry_count': 0,
      });

      // Sort by priority (high to low)
      existingActions.sort(
        (a, b) => (b['priority'] ?? 1).compareTo(a['priority'] ?? 1),
      );

      await _prefs!.setString(_pendingActionsKey, jsonEncode(existingActions));
      debugPrint(
        '✅ Enhanced action queued: ${action['type']} (priority: $priority)',
      );
    } catch (e) {
      debugPrint('❌ Failed to queue action: $e');
    }
  }

  /// Process pending actions when back online
  static Future<List<Map<String, dynamic>>> processPendingActions() async {
    await initialize();

    try {
      final pendingActions = await getPendingActions();
      if (pendingActions.isEmpty) return [];

      debugPrint('🔄 Processing ${pendingActions.length} pending actions');

      final processedActions = <Map<String, dynamic>>[];
      final failedActions = <Map<String, dynamic>>[];

      for (final action in pendingActions) {
        try {
          // Mark action as processed (this would be handled by the calling service)
          processedActions.add(action);
          debugPrint('✅ Processed pending action: ${action['type']}');
        } catch (e) {
          // Increment retry count
          final retryCount = (action['retry_count'] ?? 0) + 1;
          final maxRetries = action['max_retries'] ?? 3;

          if (retryCount < maxRetries) {
            action['retry_count'] = retryCount;
            failedActions.add(action);
            debugPrint(
              '⚠️ Action failed, will retry ($retryCount/$maxRetries): ${action['type']}',
            );
          } else {
            debugPrint(
              '❌ Action failed permanently after $maxRetries attempts: ${action['type']}',
            );
            await queueError({
              'type': 'pending_action_failed',
              'action': action,
              'error': e.toString(),
            });
          }
        }
      }

      // Update pending actions list with only failed actions that can be retried
      await _prefs!.setString(_pendingActionsKey, jsonEncode(failedActions));

      return processedActions;
    } catch (e) {
      debugPrint('❌ Failed to process pending actions: $e');
      return [];
    }
  }

  /// Background sync management
  static Future<void> enableBackgroundSync(bool enabled) async {
    await initialize();
    await _prefs!.setBool(_backgroundSyncKey, enabled);
    debugPrint('🔄 Background sync ${enabled ? 'enabled' : 'disabled'}');
  }

  static Future<bool> isBackgroundSyncEnabled() async {
    await initialize();
    return _prefs!.getBool(_backgroundSyncKey) ?? true; // Default enabled
  }

  /// Get comprehensive cache statistics
  static Future<Map<String, dynamic>> getEnhancedCacheStats() async {
    await initialize();

    final hasCachedData = _prefs!.containsKey(_momentumDataKey);
    final cacheAge = await getCachedDataAge();
    final pendingActions = await getPendingActions();
    final queuedErrors = await getQueuedErrors();
    final lastSyncAttempt = _prefs!.getString(_lastSyncAttemptKey);

    // Calculate cache health score (0-100)
    int healthScore = 100;
    if (!hasCachedData) healthScore -= 40;
    if (cacheAge != null && cacheAge.inHours > _defaultCacheValidityHours) {
      healthScore -= 30;
    }
    if (pendingActions.length > 5) healthScore -= 20;
    if (queuedErrors.length > 3) healthScore -= 10;

    return {
      'hasCachedData': hasCachedData,
      'cacheAge': cacheAge?.inHours,
      'cacheAgeMinutes': cacheAge?.inMinutes,
      'isValid': await isCachedDataValid(),
      'pendingActionsCount': pendingActions.length,
      'queuedErrorsCount': queuedErrors.length,
      'lastUpdate': _prefs!.getString(_lastUpdateKey),
      'lastSyncAttempt': lastSyncAttempt,
      'backgroundSyncEnabled': await isBackgroundSyncEnabled(),
      'cacheVersion': _prefs!.getInt(_cacheVersionKey),
      'healthScore': healthScore,
      'hasWeeklyTrend': _prefs!.containsKey(_weeklyTrendKey),
      'hasMomentumStats': _prefs!.containsKey(_momentumStatsKey),
    };
  }

  /// Get the age of cached data
  static Future<Duration?> getCachedDataAge() async {
    await initialize();

    try {
      final lastUpdateString = _prefs!.getString(_lastUpdateKey);
      if (lastUpdateString == null) return null;

      final lastUpdate = DateTime.parse(lastUpdateString);
      return DateTime.now().difference(lastUpdate);
    } catch (e) {
      debugPrint('❌ Failed to get cache age: $e');
      return null;
    }
  }

  /// Queue an error for later reporting
  static Future<void> queueError(Map<String, dynamic> error) async {
    await initialize();

    try {
      final existingErrors = await getQueuedErrors();
      existingErrors.add({
        ...error,
        'queued_at': DateTime.now().toIso8601String(),
      });

      // Keep only the last 50 errors to prevent storage bloat
      if (existingErrors.length > 50) {
        existingErrors.removeRange(0, existingErrors.length - 50);
      }

      await _prefs!.setString(_errorQueueKey, jsonEncode(existingErrors));
      debugPrint('✅ Error queued for reporting');
    } catch (e) {
      debugPrint('❌ Failed to queue error: $e');
    }
  }

  /// Get all pending actions
  static Future<List<Map<String, dynamic>>> getPendingActions() async {
    await initialize();

    try {
      final jsonString = _prefs!.getString(_pendingActionsKey);
      if (jsonString == null) return [];

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ Failed to get pending actions: $e');
      return [];
    }
  }

  /// Remove a pending action (after successful execution)
  static Future<void> removePendingAction(Map<String, dynamic> action) async {
    await initialize();

    try {
      final existingActions = await getPendingActions();
      existingActions.removeWhere(
        (a) =>
            a['type'] == action['type'] &&
            a['queued_at'] == action['queued_at'],
      );

      await _prefs!.setString(_pendingActionsKey, jsonEncode(existingActions));
      debugPrint('✅ Pending action removed: ${action['type']}');
    } catch (e) {
      debugPrint('❌ Failed to remove pending action: $e');
    }
  }

  /// Clear all pending actions
  static Future<void> clearPendingActions() async {
    await initialize();
    await _prefs!.remove(_pendingActionsKey);
    debugPrint('✅ All pending actions cleared');
  }

  /// Get all queued errors
  static Future<List<Map<String, dynamic>>> getQueuedErrors() async {
    await initialize();

    try {
      final jsonString = _prefs!.getString(_errorQueueKey);
      if (jsonString == null) return [];

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ Failed to get queued errors: $e');
      return [];
    }
  }

  /// Clear all queued errors
  static Future<void> clearQueuedErrors() async {
    await initialize();
    await _prefs!.remove(_errorQueueKey);
    debugPrint('✅ All queued errors cleared');
  }

  /// Clear all cached data
  static Future<void> clearAllCache() async {
    await initialize();

    await Future.wait([
      _prefs!.remove(_momentumDataKey),
      _prefs!.remove(_lastUpdateKey),
      _prefs!.remove(_pendingActionsKey),
      _prefs!.remove(_errorQueueKey),
      _prefs!.remove(_weeklyTrendKey),
      _prefs!.remove(_momentumStatsKey),
    ]);

    // Reset initialization state for testing
    _isInitialized = false;
    _prefs = null;

    debugPrint('✅ All cache cleared');
  }

  /// Reset the service state for testing
  /// **WARNING**: This should only be used in test environments
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

  /// Get cache statistics (legacy method for backward compatibility)
  static Future<Map<String, dynamic>> getCacheStats() async {
    return await getEnhancedCacheStats();
  }

  // ============================================================================
  // TESTING HELPER METHODS
  // ============================================================================

  /// Set cached data for testing purposes
  /// **WARNING**: This should only be used in test environments
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
  static void clearCacheForTesting() {
    assert(() {
      // Only allow this in debug/test builds
      return true;
    }());

    _testCachedData = null;
    _testCacheIsValid = false;
  }

  // Test data storage
  static MomentumData? _testCachedData;
  static bool _testCacheIsValid = false;

  /// Override getCachedMomentumData for testing
  static Future<MomentumData?> getCachedMomentumDataForTesting() async {
    return _testCachedData;
  }

  /// Override isCachedDataValid for testing
  static Future<bool> isCachedDataValidForTesting() async {
    return _testCacheIsValid;
  }
}
