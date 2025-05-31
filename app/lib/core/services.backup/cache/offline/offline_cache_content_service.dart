import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../../../features/momentum/domain/models/momentum_data.dart';
import 'offline_cache_validation_service.dart';
import 'offline_cache_error_service.dart';

/// Core content caching and retrieval service for offline momentum data
class OfflineCacheContentService {
  // SharedPreferences keys used by this service
  static const String _momentumDataKey = 'cached_momentum_data';
  static const String _lastUpdateKey = 'momentum_last_update';
  static const String _weeklyTrendKey = 'cached_weekly_trend';
  static const String _momentumStatsKey = 'cached_momentum_stats';

  static SharedPreferences? _prefs;

  /// Initialize the content service with SharedPreferences
  static Future<void> initialize(SharedPreferences prefs) async {
    _prefs = prefs;
  }

  /// Enhanced momentum data caching with granular control
  static Future<void> cacheMomentumData(
    MomentumData data, {
    bool isHighPriority = false,
    bool skipIfRecentUpdate = false,
  }) async {
    if (_prefs == null) {
      throw StateError('OfflineCacheContentService not initialized');
    }

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
      await OfflineCacheErrorService.queueError({
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
    if (_prefs == null) {
      throw StateError('OfflineCacheContentService not initialized');
    }

    try {
      final jsonString = _prefs!.getString(_momentumDataKey);
      if (jsonString == null) return null;

      // Check validity using validation service
      final isValid = await OfflineCacheValidationService.isCachedDataValid(
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

  /// Get cached weekly trend with separate validity check
  static Future<List<DailyMomentum>?> getCachedWeeklyTrend({
    bool allowStaleData = false,
  }) async {
    if (_prefs == null) {
      throw StateError('OfflineCacheContentService not initialized');
    }

    try {
      final jsonString = _prefs!.getString(_weeklyTrendKey);
      if (jsonString == null) return null;

      // Use validation service to check validity
      final isValid = await OfflineCacheValidationService.isWeeklyTrendValid(
        allowStaleData: allowStaleData,
      );

      if (!isValid && !allowStaleData) {
        return null;
      }

      final cacheData = jsonDecode(jsonString) as Map<String, dynamic>;
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
    if (_prefs == null) {
      throw StateError('OfflineCacheContentService not initialized');
    }

    try {
      final jsonString = _prefs!.getString(_momentumStatsKey);
      if (jsonString == null) return null;

      // Use validation service to check validity
      final isValid = await OfflineCacheValidationService.isMomentumStatsValid(
        allowStaleData: allowStaleData,
      );

      if (!isValid && !allowStaleData) {
        return null;
      }

      final cacheData = jsonDecode(jsonString) as Map<String, dynamic>;
      return MomentumStats.fromJson(cacheData['data']);
    } catch (e) {
      debugPrint('❌ Failed to load cached momentum stats: $e');
      return null;
    }
  }

  /// Cache weekly trend data separately (public method for external use)
  static Future<void> cacheWeeklyTrend(List<DailyMomentum> weeklyTrend) async {
    if (_prefs == null) {
      throw StateError('OfflineCacheContentService not initialized');
    }
    await _cacheWeeklyTrend(weeklyTrend);
  }

  /// Cache momentum stats separately (public method for external use)
  static Future<void> cacheMomentumStats(MomentumStats stats) async {
    if (_prefs == null) {
      throw StateError('OfflineCacheContentService not initialized');
    }
    await _cacheMomentumStats(stats);
  }

  /// Get the last cache update timestamp
  static Future<DateTime?> getLastUpdateTime() async {
    if (_prefs == null) {
      throw StateError('OfflineCacheContentService not initialized');
    }

    try {
      final lastUpdateString = _prefs!.getString(_lastUpdateKey);
      if (lastUpdateString == null) return null;

      return DateTime.parse(lastUpdateString);
    } catch (e) {
      debugPrint('❌ Failed to get last update time: $e');
      return null;
    }
  }

  /// Check if any cached content exists
  static Future<bool> hasCachedContent() async {
    if (_prefs == null) {
      throw StateError('OfflineCacheContentService not initialized');
    }

    return _prefs!.containsKey(_momentumDataKey) ||
        _prefs!.containsKey(_weeklyTrendKey) ||
        _prefs!.containsKey(_momentumStatsKey);
  }

  /// Get a summary of cached content availability
  static Future<Map<String, bool>> getCachedContentSummary() async {
    if (_prefs == null) {
      throw StateError('OfflineCacheContentService not initialized');
    }

    return {
      'momentumData': _prefs!.containsKey(_momentumDataKey),
      'weeklyTrend': _prefs!.containsKey(_weeklyTrendKey),
      'momentumStats': _prefs!.containsKey(_momentumStatsKey),
    };
  }

  /// Reset content service state for testing
  /// **WARNING**: This should only be used in test environments
  static void resetForTesting() {
    assert(() {
      // Only allow this in debug/test builds
      return true;
    }());

    _prefs = null;
  }
}
