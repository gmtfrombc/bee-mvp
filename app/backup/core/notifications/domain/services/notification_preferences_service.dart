import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_types.dart';

/// Optimized service for managing user notification preferences
///
/// Consolidated from legacy notification_preferences_service with:
/// - Modern async/await patterns
/// - Unified domain models integration
/// - Streamlined API surface
/// - Enhanced debugging capabilities
class NotificationPreferencesService {
  // Storage keys consolidated into groups
  static const Map<String, String> _keys = {
    'enabled': 'notifications_enabled',
    'momentum': 'momentum_notifications',
    'celebration': 'celebration_notifications',
    'intervention': 'intervention_notifications',
    'quietEnabled': 'quiet_hours_enabled',
    'quietStart': 'quiet_hours_start',
    'quietEnd': 'quiet_hours_end',
    'frequency': 'notification_frequency',
    'lastTime': 'last_notification_time',
    'dailyCount': 'daily_notification_count',
    'lastReset': 'last_reset_date',
  };

  static NotificationPreferencesService? _instance;
  static NotificationPreferencesService get instance {
    _instance ??= NotificationPreferencesService._();
    return _instance!;
  }

  NotificationPreferencesService._();

  SharedPreferences? _prefs;
  bool _isInitialized = false;

  /// Initialize the service with automatic daily reset
  Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    await _resetDailyCountIfNeeded();
    _isInitialized = true;

    if (kDebugMode) {
      debugPrint('🔔 NotificationPreferencesService initialized');
    }
  }

  /// Global notification settings
  bool get notificationsEnabled => _prefs?.getBool(_keys['enabled']!) ?? true;

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs?.setBool(_keys['enabled']!, enabled);
    _debugLog('Global notifications', enabled);
  }

  /// Notification type preferences
  bool get momentumNotificationsEnabled =>
      _prefs?.getBool(_keys['momentum']!) ?? true;

  Future<void> setMomentumNotificationsEnabled(bool enabled) async {
    await _prefs?.setBool(_keys['momentum']!, enabled);
    _debugLog('Momentum notifications', enabled);
  }

  bool get celebrationNotificationsEnabled =>
      _prefs?.getBool(_keys['celebration']!) ?? true;

  Future<void> setCelebrationNotificationsEnabled(bool enabled) async {
    await _prefs?.setBool(_keys['celebration']!, enabled);
    _debugLog('Celebration notifications', enabled);
  }

  bool get interventionNotificationsEnabled =>
      _prefs?.getBool(_keys['intervention']!) ?? true;

  Future<void> setInterventionNotificationsEnabled(bool enabled) async {
    await _prefs?.setBool(_keys['intervention']!, enabled);
    _debugLog('Intervention notifications', enabled);
  }

  /// Quiet hours management
  bool get quietHoursEnabled =>
      _prefs?.getBool(_keys['quietEnabled']!) ?? false;

  Future<void> setQuietHoursEnabled(bool enabled) async {
    await _prefs?.setBool(_keys['quietEnabled']!, enabled);
    _debugLog('Quiet hours', enabled);
  }

  int get quietHoursStart =>
      _prefs?.getInt(_keys['quietStart']!) ?? 22; // 10 PM default

  Future<void> setQuietHoursStart(int hour) async {
    await _prefs?.setInt(_keys['quietStart']!, hour);
    if (kDebugMode) {
      debugPrint('🌙 Quiet hours start: $hour:00');
    }
  }

  int get quietHoursEnd =>
      _prefs?.getInt(_keys['quietEnd']!) ?? 8; // 8 AM default

  Future<void> setQuietHoursEnd(int hour) async {
    await _prefs?.setInt(_keys['quietEnd']!, hour);
    if (kDebugMode) {
      debugPrint('🌙 Quiet hours end: $hour:00');
    }
  }

  bool get isInQuietHours {
    if (!quietHoursEnabled) return false;

    final currentHour = DateTime.now().hour;
    final start = quietHoursStart;
    final end = quietHoursEnd;

    // Handle overnight quiet hours (22:00 to 08:00)
    return start > end
        ? (currentHour >= start || currentHour < end)
        : (currentHour >= start && currentHour < end);
  }

  /// Notification frequency management using unified enum
  NotificationFrequency get notificationFrequency {
    final value = _prefs?.getString(_keys['frequency']!);
    return NotificationFrequency.values.firstWhere(
      (freq) => freq.name == value,
      orElse: () => NotificationFrequency.normal,
    );
  }

  Future<void> setNotificationFrequency(NotificationFrequency frequency) async {
    await _prefs?.setString(_keys['frequency']!, frequency.name);
    if (kDebugMode) {
      debugPrint(
        '⏱️ Frequency: ${frequency.displayName} (${frequency.maxDailyNotifications}/day)',
      );
    }
  }

  /// Smart notification permission checking
  bool get canSendNotification {
    if (!notificationsEnabled || isInQuietHours) return false;

    final frequency = notificationFrequency;
    final dailyCount = _getDailyNotificationCount();
    final lastTime = _getLastNotificationTime();

    // Check daily limit
    if (dailyCount >= frequency.maxDailyNotifications) {
      _debugLog(
        'Daily limit reached',
        false,
        extra: '$dailyCount/${frequency.maxDailyNotifications}',
      );
      return false;
    }

    // Check minimum interval
    if (lastTime != null) {
      final minutesSince = DateTime.now().difference(lastTime).inMinutes;
      if (minutesSince < frequency.minIntervalMinutes) {
        _debugLog(
          'Too soon since last',
          false,
          extra: '$minutesSince/${frequency.minIntervalMinutes}min',
        );
        return false;
      }
    }

    return true;
  }

  /// Check permission for specific notification types using unified enum
  bool shouldSendNotificationType(NotificationType type) {
    if (!canSendNotification) return false;

    return switch (type) {
      NotificationType.momentum => momentumNotificationsEnabled,
      NotificationType.celebration => celebrationNotificationsEnabled,
      NotificationType.intervention => interventionNotificationsEnabled,
      _ => true, // engagement, daily, coach, custom use base settings
    };
  }

  /// Record notification sent with automatic tracking
  Future<void> recordNotificationSent() async {
    final now = DateTime.now();
    await _prefs?.setInt(_keys['lastTime']!, now.millisecondsSinceEpoch);

    final newCount = _getDailyNotificationCount() + 1;
    await _prefs?.setInt(_keys['dailyCount']!, newCount);

    if (kDebugMode) {
      debugPrint(
        '📝 Notification recorded. Daily: $newCount/${notificationFrequency.maxDailyNotifications}',
      );
    }
  }

  /// Bulk preference updates for settings screens
  Future<void> updatePreferences({
    bool? notificationsEnabled,
    bool? momentumEnabled,
    bool? celebrationEnabled,
    bool? interventionEnabled,
    bool? quietHoursEnabled,
    int? quietStart,
    int? quietEnd,
    NotificationFrequency? frequency,
  }) async {
    final updates = <Future<void>>[];

    if (notificationsEnabled != null) {
      updates.add(setNotificationsEnabled(notificationsEnabled));
    }
    if (momentumEnabled != null) {
      updates.add(setMomentumNotificationsEnabled(momentumEnabled));
    }
    if (celebrationEnabled != null) {
      updates.add(setCelebrationNotificationsEnabled(celebrationEnabled));
    }
    if (interventionEnabled != null) {
      updates.add(setInterventionNotificationsEnabled(interventionEnabled));
    }
    if (quietHoursEnabled != null) {
      updates.add(setQuietHoursEnabled(quietHoursEnabled));
    }
    if (quietStart != null) {
      updates.add(setQuietHoursStart(quietStart));
    }
    if (quietEnd != null) {
      updates.add(setQuietHoursEnd(quietEnd));
    }
    if (frequency != null) {
      updates.add(setNotificationFrequency(frequency));
    }

    await Future.wait(updates);
  }

  /// Debug information for analytics and troubleshooting
  Map<String, dynamic> getDebugInfo() => {
    'initialized': _isInitialized,
    'globalEnabled': notificationsEnabled,
    'typePreferences': {
      'momentum': momentumNotificationsEnabled,
      'celebration': celebrationNotificationsEnabled,
      'intervention': interventionNotificationsEnabled,
    },
    'quietHours': {
      'enabled': quietHoursEnabled,
      'start': quietHoursStart,
      'end': quietHoursEnd,
      'currentlyInQuietHours': isInQuietHours,
    },
    'frequency': {
      'setting': notificationFrequency.name,
      'maxDaily': notificationFrequency.maxDailyNotifications,
      'minInterval': notificationFrequency.minIntervalMinutes,
      'dailyCount': _getDailyNotificationCount(),
    },
    'canSend': canSendNotification,
  };

  // Private helper methods
  DateTime? _getLastNotificationTime() {
    final timestamp = _prefs?.getInt(_keys['lastTime']!);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  int _getDailyNotificationCount() => _prefs?.getInt(_keys['dailyCount']!) ?? 0;

  Future<void> _resetDailyCountIfNeeded() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastResetTimestamp = _prefs?.getInt(_keys['lastReset']!);

    if (lastResetTimestamp == null) {
      // First time initialization
      await _prefs?.setInt(_keys['dailyCount']!, 0);
      await _prefs?.setInt(_keys['lastReset']!, today.millisecondsSinceEpoch);
      return;
    }

    final lastReset = DateTime.fromMillisecondsSinceEpoch(lastResetTimestamp);
    final lastResetDate = DateTime(
      lastReset.year,
      lastReset.month,
      lastReset.day,
    );

    if (today.isAfter(lastResetDate)) {
      await _prefs?.setInt(_keys['dailyCount']!, 0);
      await _prefs?.setInt(_keys['lastReset']!, today.millisecondsSinceEpoch);
      if (kDebugMode) {
        debugPrint('🔄 Daily notification count reset');
      }
    }
  }

  void _debugLog(String setting, bool enabled, {String? extra}) {
    if (kDebugMode) {
      final status = enabled ? 'enabled' : 'disabled';
      final extraInfo = extra != null ? ' ($extra)' : '';
      debugPrint('🔔 $setting $status$extraInfo');
    }
  }
}
