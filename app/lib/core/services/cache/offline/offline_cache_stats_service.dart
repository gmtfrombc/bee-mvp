import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Statistics and health monitoring service for offline cache
class OfflineCacheStatsService {
  // SharedPreferences keys used by this service
  static const String _momentumDataKey = 'cached_momentum_data';
  static const String _lastUpdateKey = 'momentum_last_update';
  static const String _pendingActionsKey = 'pending_actions';
  static const String _errorQueueKey = 'error_queue';
  static const String _weeklyTrendKey = 'cached_weekly_trend';
  static const String _momentumStatsKey = 'cached_momentum_stats';
  static const String _backgroundSyncKey = 'background_sync_enabled';
  static const String _lastSyncAttemptKey = 'last_sync_attempt';
  static const String _cacheVersionKey = 'cache_version';

  // Cache validity periods (in hours) - same as main service
  static const int _defaultCacheValidityHours = 24;

  static SharedPreferences? _prefs;

  /// Initialize the stats service with SharedPreferences
  static Future<void> initialize(SharedPreferences prefs) async {
    _prefs = prefs;
  }

  /// Get comprehensive cache statistics
  static Future<Map<String, dynamic>> getEnhancedCacheStats() async {
    final hasCachedData = _prefs!.containsKey(_momentumDataKey);
    final cacheAge = await getCachedDataAge();
    final pendingActions = await _getPendingActions();
    final queuedErrors = await _getQueuedErrors();
    final lastSyncAttempt = _prefs!.getString(_lastSyncAttemptKey);

    // Calculate cache health score (0-100)
    final healthScore = _calculateHealthScore(
      hasCachedData: hasCachedData,
      cacheAge: cacheAge,
      pendingActionsCount: pendingActions.length,
      queuedErrorsCount: queuedErrors.length,
    );

    return {
      'hasCachedData': hasCachedData,
      'cacheAge': cacheAge?.inHours,
      'cacheAgeMinutes': cacheAge?.inMinutes,
      'isValid': await _isCachedDataValid(),
      'pendingActionsCount': pendingActions.length,
      'queuedErrorsCount': queuedErrors.length,
      'lastUpdate': _prefs!.getString(_lastUpdateKey),
      'lastSyncAttempt': lastSyncAttempt,
      'backgroundSyncEnabled': await _isBackgroundSyncEnabled(),
      'cacheVersion': _prefs!.getInt(_cacheVersionKey),
      'healthScore': healthScore,
      'hasWeeklyTrend': _prefs!.containsKey(_weeklyTrendKey),
      'hasMomentumStats': _prefs!.containsKey(_momentumStatsKey),
    };
  }

  /// Get the age of cached data
  static Future<Duration?> getCachedDataAge() async {
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

  /// Get cache statistics (legacy method for backward compatibility)
  static Future<Map<String, dynamic>> getCacheStats() async {
    return await getEnhancedCacheStats();
  }

  /// Monitor cache size and trigger cleanup if needed
  static Future<void> checkCacheHealth() async {
    try {
      final stats = await getEnhancedCacheStats();
      final healthScore = stats['healthScore'] as int;

      // If health score is low, trigger cleanup
      if (healthScore < 70) {
        debugPrint(
          '⚠️ Cache health score low ($healthScore), triggering cleanup',
        );
        // Note: cleanup functionality will be delegated to main service for now
        // This will be properly handled when maintenance service is extracted
        debugPrint(
          '✅ Cache health check completed (cleanup not implemented yet)',
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to check cache health: $e');
    }
  }

  /// Helper method to check if background sync is enabled (delegates to main service for now)
  static Future<bool> _isBackgroundSyncEnabled() async {
    return _prefs!.getBool(_backgroundSyncKey) ?? true; // Default enabled
  }

  /// Helper method to check cache validity (uses basic validation for now)
  static Future<bool> _isCachedDataValid() async {
    try {
      final lastUpdateString = _prefs!.getString(_lastUpdateKey);
      if (lastUpdateString == null) return false;

      final lastUpdate = DateTime.parse(lastUpdateString);
      final now = DateTime.now();
      final difference = now.difference(lastUpdate);

      return difference.inHours < _defaultCacheValidityHours;
    } catch (e) {
      debugPrint('❌ Failed to check cache validity: $e');
      return false;
    }
  }

  /// Get all pending actions (helper method for stats)
  static Future<List<Map<String, dynamic>>> _getPendingActions() async {
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

  /// Get all queued errors (helper method for stats)
  static Future<List<Map<String, dynamic>>> _getQueuedErrors() async {
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

  /// Calculate cache health score (0-100)
  static int _calculateHealthScore({
    required bool hasCachedData,
    required Duration? cacheAge,
    required int pendingActionsCount,
    required int queuedErrorsCount,
  }) {
    int healthScore = 100;
    if (!hasCachedData) healthScore -= 40;
    if (cacheAge != null && cacheAge.inHours > _defaultCacheValidityHours) {
      healthScore -= 30;
    }
    if (pendingActionsCount > 5) healthScore -= 20;
    if (queuedErrorsCount > 3) healthScore -= 10;
    return healthScore;
  }
}
