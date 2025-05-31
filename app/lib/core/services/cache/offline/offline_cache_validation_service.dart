import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Cache validation and data integrity service for offline cache
class OfflineCacheValidationService {
  // SharedPreferences keys used by this service
  static const String _momentumDataKey = 'cached_momentum_data';
  static const String _lastUpdateKey = 'momentum_last_update';
  static const String _pendingActionsKey = 'pending_actions';
  static const String _errorQueueKey = 'error_queue';
  static const String _cacheVersionKey = 'cache_version';
  static const String _weeklyTrendKey = 'cached_weekly_trend';
  static const String _momentumStatsKey = 'cached_momentum_stats';

  // Cache validity periods (in hours) - shared constants
  static const int _defaultCacheValidityHours = 24;
  static const int _criticalCacheValidityHours = 1; // For critical updates
  static const int _weeklyTrendValidityHours = 12; // Weekly data can be older
  static const int _statsValidityHours = 6; // Stats update more frequently

  static const int _currentCacheVersion =
      2; // Increment to invalidate old cache

  static SharedPreferences? _prefs;

  /// Initialize the validation service with SharedPreferences
  static Future<void> initialize(SharedPreferences prefs) async {
    _prefs = prefs;
  }

  /// Validate cache version and clear if outdated
  static Future<void> validateCacheVersion() async {
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

  /// Enhanced cache validity check with customizable periods
  static Future<bool> isCachedDataValid({
    Duration? customValidityPeriod,
    bool isHighPriorityUpdate = false,
  }) async {
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

  /// Check if weekly trend data is valid
  static Future<bool> isWeeklyTrendValid({bool allowStaleData = false}) async {
    try {
      final jsonString = _prefs!.getString(_weeklyTrendKey);
      if (jsonString == null) return false;

      final cacheData = jsonDecode(jsonString) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(cacheData['cached_at']);
      final age = DateTime.now().difference(cachedAt);

      return age.inHours <= _weeklyTrendValidityHours || allowStaleData;
    } catch (e) {
      debugPrint('❌ Failed to check weekly trend validity: $e');
      return false;
    }
  }

  /// Check if momentum stats data is valid
  static Future<bool> isMomentumStatsValid({
    bool allowStaleData = false,
  }) async {
    try {
      final jsonString = _prefs!.getString(_momentumStatsKey);
      if (jsonString == null) return false;

      final cacheData = jsonDecode(jsonString) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(cacheData['cached_at']);
      final age = DateTime.now().difference(cachedAt);

      return age.inHours <= _statsValidityHours || allowStaleData;
    } catch (e) {
      debugPrint('❌ Failed to check momentum stats validity: $e');
      return false;
    }
  }

  /// Get validation status for all cache components
  static Future<Map<String, bool>> getValidationStatus() async {
    return {
      'momentumData': await isCachedDataValid(),
      'weeklyTrend': await isWeeklyTrendValid(),
      'momentumStats': await isMomentumStatsValid(),
    };
  }

  /// Get cache validity periods (for stats and debugging)
  static Map<String, int> getValidityPeriods() {
    return {
      'defaultCacheValidityHours': _defaultCacheValidityHours,
      'criticalCacheValidityHours': _criticalCacheValidityHours,
      'weeklyTrendValidityHours': _weeklyTrendValidityHours,
      'statsValidityHours': _statsValidityHours,
    };
  }

  /// Get current cache version
  static int getCurrentCacheVersion() {
    return _currentCacheVersion;
  }

  /// Get stored cache version
  static Future<int> getStoredCacheVersion() async {
    return _prefs!.getInt(_cacheVersionKey) ?? 1;
  }

  /// Check if cache version is current
  static Future<bool> isCacheVersionCurrent() async {
    final storedVersion = await getStoredCacheVersion();
    return storedVersion >= _currentCacheVersion;
  }
}
