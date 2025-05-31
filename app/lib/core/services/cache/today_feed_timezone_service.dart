import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Timezone and DST management service for Today Feed cache
class TodayFeedTimezoneService {
  static SharedPreferences? _prefs;
  static bool _isInitialized = false;
  static Timer? _timezoneCheckTimer;

  // Cache keys from main service
  static const String _timezoneMetadataKey = 'today_feed_timezone_metadata';
  static const String _lastTimezoneCheckKey = 'today_feed_last_timezone_check';
  static const String _lastRefreshKey = 'today_feed_last_refresh';
  static const int _refreshHour = 3; // 3 AM local time

  /// Initialize the timezone service
  static Future<void> initialize(SharedPreferences prefs) async {
    _prefs = prefs;
    _isInitialized = true;

    // Start timezone monitoring
    await _scheduleTimezoneChecks();
  }

  /// Dispose of the timezone service
  static Future<void> dispose() async {
    _timezoneCheckTimer?.cancel();
    _timezoneCheckTimer = null;
    _isInitialized = false;
  }

  /// Detect and handle timezone changes including DST transitions
  static Future<Map<String, dynamic>?> detectAndHandleTimezoneChanges() async {
    if (!_isInitialized) {
      throw StateError('TodayFeedTimezoneService not initialized');
    }

    try {
      final now = DateTime.now();
      final currentTimezoneInfo = getCurrentTimezoneInfo();
      final savedTimezoneInfo = await getSavedTimezoneInfo();

      // Save current timezone info for first run
      if (savedTimezoneInfo == null) {
        await saveTimezoneInfo(currentTimezoneInfo);
        await _prefs!.setString(_lastTimezoneCheckKey, now.toIso8601String());
        debugPrint(
          '🌍 Initial timezone saved: ${currentTimezoneInfo['identifier']}',
        );
        return null;
      }

      // Check for timezone changes
      final timezoneChanged = hasTimezoneChanged(
        currentTimezoneInfo,
        savedTimezoneInfo,
      );
      final dstChanged = hasDstChanged(currentTimezoneInfo, savedTimezoneInfo);

      if (timezoneChanged || dstChanged) {
        debugPrint('🕒 Timezone change detected:');
        debugPrint(
          '  Previous: ${savedTimezoneInfo['identifier']} (DST: ${savedTimezoneInfo['is_dst']})',
        );
        debugPrint(
          '  Current: ${currentTimezoneInfo['identifier']} (DST: ${currentTimezoneInfo['is_dst']})',
        );

        // Update saved timezone info
        await saveTimezoneInfo(currentTimezoneInfo);

        // Return information about the timezone change for the main service
        // to handle refresh scheduling and content refresh decisions
        return {
          'timezone_changed': timezoneChanged,
          'dst_changed': dstChanged,
          'should_refresh': await shouldRefreshDueToTimezoneChange(
            savedTimezoneInfo,
            currentTimezoneInfo,
          ),
          'old_timezone': savedTimezoneInfo,
          'new_timezone': currentTimezoneInfo,
        };
      }

      // Always update last timezone check timestamp
      await _prefs!.setString(_lastTimezoneCheckKey, now.toIso8601String());
      return null; // No timezone change
    } catch (e) {
      debugPrint('❌ Failed to detect timezone changes: $e');
      // Ensure timestamp is saved even on error
      try {
        await _prefs!.setString(
          _lastTimezoneCheckKey,
          DateTime.now().toIso8601String(),
        );
      } catch (saveError) {
        debugPrint('❌ Failed to save timezone check timestamp: $saveError');
      }
      rethrow;
    }
  }

  /// Get current timezone information including DST status
  static Map<String, dynamic> getCurrentTimezoneInfo() {
    final now = DateTime.now();
    final timeZone = now.timeZoneName;
    final timeZoneOffset = now.timeZoneOffset;

    // Detect DST by comparing winter and summer offsets
    final winterDate = DateTime(now.year, 1, 1);
    final summerDate = DateTime(now.year, 7, 1);
    final winterOffset = winterDate.timeZoneOffset;
    final summerOffset = summerDate.timeZoneOffset;

    final isDst =
        timeZoneOffset != winterOffset && timeZoneOffset == summerOffset;

    return {
      'identifier': timeZone,
      'offset_hours': timeZoneOffset.inHours,
      'offset_minutes': timeZoneOffset.inMinutes,
      'is_dst': isDst,
      'winter_offset_hours': winterOffset.inHours,
      'summer_offset_hours': summerOffset.inHours,
      'timestamp': now.toIso8601String(),
    };
  }

  /// Save timezone information to cache
  static Future<void> saveTimezoneInfo(
    Map<String, dynamic> timezoneInfo,
  ) async {
    if (!_isInitialized) {
      throw StateError('TodayFeedTimezoneService not initialized');
    }
    await _prefs!.setString(_timezoneMetadataKey, jsonEncode(timezoneInfo));
  }

  /// Get saved timezone information from cache
  static Future<Map<String, dynamic>?> getSavedTimezoneInfo() async {
    if (!_isInitialized) {
      throw StateError('TodayFeedTimezoneService not initialized');
    }

    try {
      final jsonString = _prefs!.getString(_timezoneMetadataKey);
      if (jsonString == null) return null;
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ Failed to get saved timezone info: $e');
      return null;
    }
  }

  /// Check if timezone identifier has changed
  static bool hasTimezoneChanged(
    Map<String, dynamic> current,
    Map<String, dynamic> saved,
  ) {
    return current['identifier'] != saved['identifier'] ||
        current['offset_hours'] != saved['offset_hours'];
  }

  /// Check if DST status has changed
  static bool hasDstChanged(
    Map<String, dynamic> current,
    Map<String, dynamic> saved,
  ) {
    return current['is_dst'] != saved['is_dst'];
  }

  /// Determine if content should be refreshed immediately due to timezone change
  static Future<bool> shouldRefreshDueToTimezoneChange(
    Map<String, dynamic> oldTimezone,
    Map<String, dynamic> newTimezone,
  ) async {
    if (!_isInitialized) {
      throw StateError('TodayFeedTimezoneService not initialized');
    }

    try {
      final lastRefreshString = _prefs!.getString(_lastRefreshKey);
      if (lastRefreshString == null) return true;

      final lastRefresh = DateTime.parse(lastRefreshString);
      final now = DateTime.now();

      // If timezone changed significantly (more than 2 hours), refresh
      final offsetDiff =
          (newTimezone['offset_hours'] as int) -
          (oldTimezone['offset_hours'] as int);
      if (offsetDiff.abs() > 2) {
        debugPrint(
          '🌍 Major timezone change detected (+/- ${offsetDiff}h), refreshing content',
        );
        return true;
      }

      // If DST changed and it's been more than 12 hours since last refresh
      if (hasDstChanged(newTimezone, oldTimezone)) {
        final hoursSinceRefresh = now.difference(lastRefresh).inHours;
        if (hoursSinceRefresh > 12) {
          debugPrint('🕒 DST change with stale content detected, refreshing');
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error checking timezone refresh need: $e');
      return false;
    }
  }

  /// Schedule periodic timezone checks to detect changes
  static Future<void> _scheduleTimezoneChecks() async {
    _timezoneCheckTimer?.cancel();

    try {
      // Check timezone every 2 hours for changes
      _timezoneCheckTimer = Timer.periodic(const Duration(hours: 2), (
        timer,
      ) async {
        debugPrint('🕒 Performing scheduled timezone check');
        await detectAndHandleTimezoneChanges();
      });

      debugPrint('⏰ Timezone checks scheduled every 2 hours');
    } catch (e) {
      debugPrint('❌ Failed to schedule timezone checks: $e');
    }
  }

  /// Enhanced refresh time check with DST and timezone considerations
  static bool isPastRefreshTimeEnhanced(DateTime now) {
    try {
      // Create refresh time for today
      final refreshTime = DateTime(
        now.year,
        now.month,
        now.day,
        _refreshHour,
        0,
        0,
      );

      // Account for potential DST transitions on the refresh day
      final refreshTimeWithDst = adjustForDstTransition(refreshTime);

      final isPast = now.isAfter(refreshTimeWithDst);

      if (refreshTimeWithDst != refreshTime) {
        debugPrint(
          '🕒 DST adjustment applied: $refreshTime → $refreshTimeWithDst',
        );
      }

      return isPast;
    } catch (e) {
      debugPrint('❌ Error checking refresh time: $e');
      // Fallback to simple check
      final refreshTime = DateTime(
        now.year,
        now.month,
        now.day,
        _refreshHour,
        0,
        0,
      );
      return now.isAfter(refreshTime);
    }
  }

  /// Adjust refresh time for potential DST transitions
  static DateTime adjustForDstTransition(DateTime refreshTime) {
    try {
      // Check if there's a DST transition around the refresh time
      final beforeTransition = refreshTime.subtract(const Duration(hours: 1));
      final afterTransition = refreshTime.add(const Duration(hours: 1));

      final beforeOffset = beforeTransition.timeZoneOffset;
      final afterOffset = afterTransition.timeZoneOffset;

      // If there's a DST transition, adjust the refresh time
      if (beforeOffset != afterOffset) {
        final offsetDiff = afterOffset.inMinutes - beforeOffset.inMinutes;
        debugPrint(
          '🕒 DST transition detected around refresh time (${offsetDiff}min change)',
        );

        // For spring forward (lose an hour), delay refresh by 1 hour
        // For fall back (gain an hour), keep original time
        if (offsetDiff > 0) {
          return refreshTime.add(Duration(minutes: offsetDiff));
        }
      }

      return refreshTime;
    } catch (e) {
      debugPrint('❌ Error adjusting for DST: $e');
      return refreshTime;
    }
  }

  /// Check if timezone changes require immediate refresh
  static Future<bool> checkTimezoneRefreshRequirement() async {
    if (!_isInitialized) {
      throw StateError('TodayFeedTimezoneService not initialized');
    }

    try {
      final currentTimezone = getCurrentTimezoneInfo();
      final savedTimezone = await getSavedTimezoneInfo();

      if (savedTimezone == null) {
        // First run, save current timezone
        await saveTimezoneInfo(currentTimezone);
        return false;
      }

      // Check for significant timezone changes
      final timezoneChanged = hasTimezoneChanged(
        currentTimezone,
        savedTimezone,
      );
      final dstChanged = hasDstChanged(currentTimezone, savedTimezone);

      if (timezoneChanged || dstChanged) {
        debugPrint('🌍 Timezone change detected for refresh check');
        return await shouldRefreshDueToTimezoneChange(
          savedTimezone,
          currentTimezone,
        );
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error checking timezone refresh requirement: $e');
      return false;
    }
  }

  /// Calculate the next refresh time with timezone and DST considerations
  static Future<DateTime> calculateNextRefreshTime(DateTime now) async {
    try {
      // Get current timezone info
      final timezoneInfo = getCurrentTimezoneInfo();
      final isDst = timezoneInfo['is_dst'] as bool;

      // Calculate today's refresh time
      DateTime todayRefreshTime = DateTime(
        now.year,
        now.month,
        now.day,
        _refreshHour,
        0,
        0,
      );

      // Adjust for DST if needed
      todayRefreshTime = adjustForDstTransition(todayRefreshTime);

      DateTime nextRefreshTime;

      if (now.isBefore(todayRefreshTime)) {
        // If it's before today's refresh time, use today
        nextRefreshTime = todayRefreshTime;
        debugPrint('📅 Scheduling refresh for today at $_refreshHour:00 AM');
      } else {
        // Otherwise, schedule for tomorrow
        DateTime tomorrowRefreshTime = DateTime(
          now.year,
          now.month,
          now.day + 1,
          _refreshHour,
          0,
          0,
        );

        // Check for potential DST transition tomorrow
        tomorrowRefreshTime = adjustForDstTransition(tomorrowRefreshTime);
        nextRefreshTime = tomorrowRefreshTime;
        debugPrint('📅 Scheduling refresh for tomorrow at $_refreshHour:00 AM');
      }

      // Validate the calculated time makes sense
      final timeDiff = nextRefreshTime.difference(now);
      if (timeDiff.inHours > 25 || timeDiff.inMinutes < 0) {
        debugPrint('⚠️ Invalid refresh time calculated, using fallback');
        nextRefreshTime = now.add(const Duration(hours: 24));
      }

      debugPrint('🌍 Timezone: ${timezoneInfo['identifier']} (DST: $isDst)');

      return nextRefreshTime;
    } catch (e) {
      debugPrint('❌ Error calculating next refresh time: $e');
      // Fallback to 24 hours from now
      return now.add(const Duration(hours: 24));
    }
  }

  /// Check if two dates are the same local day
  static bool isSameLocalDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Get timezone statistics for monitoring
  static Future<Map<String, dynamic>> getTimezoneStats() async {
    if (!_isInitialized) {
      throw StateError('TodayFeedTimezoneService not initialized');
    }

    try {
      final currentTimezone = getCurrentTimezoneInfo();
      final savedTimezone = await getSavedTimezoneInfo();
      final lastCheck = _prefs!.getString(_lastTimezoneCheckKey);

      return {
        'current_timezone': currentTimezone,
        'saved_timezone': savedTimezone,
        'timezone_changed':
            savedTimezone != null
                ? hasTimezoneChanged(currentTimezone, savedTimezone)
                : false,
        'dst_changed':
            savedTimezone != null
                ? hasDstChanged(currentTimezone, savedTimezone)
                : false,
        'last_timezone_check': lastCheck,
        'refresh_hour': _refreshHour,
        'timezone_check_timer_active': _timezoneCheckTimer?.isActive ?? false,
      };
    } catch (e) {
      debugPrint('❌ Failed to get timezone stats: $e');
      return {
        'error': e.toString(),
        'current_timezone': getCurrentTimezoneInfo(),
        'saved_timezone': null,
        'timezone_changed': false,
        'dst_changed': false,
        'last_timezone_check': null,
        'refresh_hour': _refreshHour,
        'timezone_check_timer_active': false,
      };
    }
  }
}
