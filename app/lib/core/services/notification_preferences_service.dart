import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../notifications/domain/models/notification_types.dart';

/// Service for managing user notification preferences
class NotificationPreferencesService {
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyMomentumNotifications = 'momentum_notifications';
  static const String _keyCelebrationNotifications =
      'celebration_notifications';
  static const String _keyInterventionNotifications =
      'intervention_notifications';
  static const String _keyQuietHoursEnabled = 'quiet_hours_enabled';
  static const String _keyQuietHoursStart = 'quiet_hours_start';
  static const String _keyQuietHoursEnd = 'quiet_hours_end';
  static const String _keyNotificationFrequency = 'notification_frequency';
  static const String _keyLastNotificationTime = 'last_notification_time';
  static const String _keyDailyNotificationCount = 'daily_notification_count';
  static const String _keyLastResetDate = 'last_reset_date';

  static NotificationPreferencesService? _instance;
  static NotificationPreferencesService get instance {
    _instance ??= NotificationPreferencesService._();
    return _instance!;
  }

  NotificationPreferencesService._();

  SharedPreferences? _prefs;

  /// Initialize the service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _resetDailyCountIfNeeded();
  }

  /// Check if notifications are enabled globally
  bool get notificationsEnabled {
    return _prefs?.getBool(_keyNotificationsEnabled) ?? true;
  }

  /// Set global notification enabled state
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs?.setBool(_keyNotificationsEnabled, enabled);
    if (kDebugMode) {
      debugPrint('🔔 Notifications ${enabled ? 'enabled' : 'disabled'}');
    }
  }

  /// Check if momentum notifications are enabled
  bool get momentumNotificationsEnabled {
    return _prefs?.getBool(_keyMomentumNotifications) ?? true;
  }

  /// Set momentum notifications enabled state
  Future<void> setMomentumNotificationsEnabled(bool enabled) async {
    await _prefs?.setBool(_keyMomentumNotifications, enabled);
    if (kDebugMode) {
      debugPrint(
        '📊 Momentum notifications ${enabled ? 'enabled' : 'disabled'}',
      );
    }
  }

  /// Check if celebration notifications are enabled
  bool get celebrationNotificationsEnabled {
    return _prefs?.getBool(_keyCelebrationNotifications) ?? true;
  }

  /// Set celebration notifications enabled state
  Future<void> setCelebrationNotificationsEnabled(bool enabled) async {
    await _prefs?.setBool(_keyCelebrationNotifications, enabled);
    if (kDebugMode) {
      debugPrint(
        '🎉 Celebration notifications ${enabled ? 'enabled' : 'disabled'}',
      );
    }
  }

  /// Check if intervention notifications are enabled
  bool get interventionNotificationsEnabled {
    return _prefs?.getBool(_keyInterventionNotifications) ?? true;
  }

  /// Set intervention notifications enabled state
  Future<void> setInterventionNotificationsEnabled(bool enabled) async {
    await _prefs?.setBool(_keyInterventionNotifications, enabled);
    if (kDebugMode) {
      debugPrint(
        '🚨 Intervention notifications ${enabled ? 'enabled' : 'disabled'}',
      );
    }
  }

  /// Check if quiet hours are enabled
  bool get quietHoursEnabled {
    return _prefs?.getBool(_keyQuietHoursEnabled) ?? false;
  }

  /// Set quiet hours enabled state
  Future<void> setQuietHoursEnabled(bool enabled) async {
    await _prefs?.setBool(_keyQuietHoursEnabled, enabled);
    if (kDebugMode) {
      debugPrint('🌙 Quiet hours ${enabled ? 'enabled' : 'disabled'}');
    }
  }

  /// Get quiet hours start time (hour of day, 0-23)
  int get quietHoursStart {
    return _prefs?.getInt(_keyQuietHoursStart) ?? 22; // 10 PM default
  }

  /// Set quiet hours start time
  Future<void> setQuietHoursStart(int hour) async {
    await _prefs?.setInt(_keyQuietHoursStart, hour);
    if (kDebugMode) {
      debugPrint('🌙 Quiet hours start set to $hour:00');
    }
  }

  /// Get quiet hours end time (hour of day, 0-23)
  int get quietHoursEnd {
    return _prefs?.getInt(_keyQuietHoursEnd) ?? 8; // 8 AM default
  }

  /// Set quiet hours end time
  Future<void> setQuietHoursEnd(int hour) async {
    await _prefs?.setInt(_keyQuietHoursEnd, hour);
    if (kDebugMode) {
      debugPrint('🌙 Quiet hours end set to $hour:00');
    }
  }

  /// Get notification frequency setting
  NotificationFrequency get notificationFrequency {
    final value = _prefs?.getString(_keyNotificationFrequency);
    return NotificationFrequency.values.firstWhere(
      (freq) => freq.name == value,
      orElse: () => NotificationFrequency.normal,
    );
  }

  /// Set notification frequency
  Future<void> setNotificationFrequency(NotificationFrequency frequency) async {
    await _prefs?.setString(_keyNotificationFrequency, frequency.name);
    if (kDebugMode) {
      debugPrint('⏱️ Notification frequency set to ${frequency.name}');
    }
  }

  /// Check if we're currently in quiet hours
  bool get isInQuietHours {
    if (!quietHoursEnabled) return false;

    final now = DateTime.now();
    final currentHour = now.hour;
    final start = quietHoursStart;
    final end = quietHoursEnd;

    // Handle overnight quiet hours (e.g., 22:00 to 08:00)
    if (start > end) {
      return currentHour >= start || currentHour < end;
    }
    // Handle same-day quiet hours (e.g., 12:00 to 14:00)
    else {
      return currentHour >= start && currentHour < end;
    }
  }

  /// Check if we can send a notification based on frequency limits
  bool get canSendNotification {
    if (!notificationsEnabled) return false;
    if (isInQuietHours) return false;

    final frequency = notificationFrequency;
    final now = DateTime.now();
    final lastNotificationTime = _getLastNotificationTime();
    final dailyCount = _getDailyNotificationCount();

    // Check daily limits
    if (dailyCount >= frequency.maxDailyNotifications) {
      if (kDebugMode) {
        debugPrint(
          '⚠️ Daily notification limit reached: $dailyCount/${frequency.maxDailyNotifications}',
        );
      }
      return false;
    }

    // Check minimum interval
    if (lastNotificationTime != null) {
      final timeSinceLastNotification = now.difference(lastNotificationTime);
      if (timeSinceLastNotification.inMinutes < frequency.minIntervalMinutes) {
        if (kDebugMode) {
          debugPrint(
            '⚠️ Too soon since last notification: ${timeSinceLastNotification.inMinutes}/${frequency.minIntervalMinutes} minutes',
          );
        }
        return false;
      }
    }

    return true;
  }

  /// Record that a notification was sent
  Future<void> recordNotificationSent() async {
    final now = DateTime.now();
    await _prefs?.setInt(_keyLastNotificationTime, now.millisecondsSinceEpoch);

    final currentCount = _getDailyNotificationCount();
    await _prefs?.setInt(_keyDailyNotificationCount, currentCount + 1);

    if (kDebugMode) {
      debugPrint(
        '📝 Notification sent recorded. Daily count: ${currentCount + 1}',
      );
    }
  }

  /// Get the last notification time
  DateTime? _getLastNotificationTime() {
    final timestamp = _prefs?.getInt(_keyLastNotificationTime);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  /// Get daily notification count
  int _getDailyNotificationCount() {
    return _prefs?.getInt(_keyDailyNotificationCount) ?? 0;
  }

  /// Reset daily count if it's a new day
  Future<void> _resetDailyCountIfNeeded() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastResetTimestamp = _prefs?.getInt(_keyLastResetDate);

    DateTime? lastResetDate;
    if (lastResetTimestamp != null) {
      final lastReset = DateTime.fromMillisecondsSinceEpoch(lastResetTimestamp);
      lastResetDate = DateTime(lastReset.year, lastReset.month, lastReset.day);
    }

    if (lastResetDate == null || today.isAfter(lastResetDate)) {
      await _prefs?.setInt(_keyDailyNotificationCount, 0);
      await _prefs?.setInt(_keyLastResetDate, today.millisecondsSinceEpoch);
      if (kDebugMode) {
        debugPrint('🔄 Daily notification count reset for new day');
      }
    }
  }

  /// Check if a specific notification type should be sent
  bool shouldSendNotificationType(NotificationType type) {
    if (!canSendNotification) return false;

    switch (type) {
      case NotificationType.momentum:
        return momentumNotificationsEnabled;
      case NotificationType.celebration:
        return celebrationNotificationsEnabled;
      case NotificationType.intervention:
        return interventionNotificationsEnabled;
      case NotificationType.engagement:
      case NotificationType.daily:
      case NotificationType.coach:
      case NotificationType.custom:
        return true; // These use base notification settings
    }
  }

  /// Get all preferences as a map for debugging
  Map<String, dynamic> getAllPreferences() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'momentumNotificationsEnabled': momentumNotificationsEnabled,
      'celebrationNotificationsEnabled': celebrationNotificationsEnabled,
      'interventionNotificationsEnabled': interventionNotificationsEnabled,
      'quietHoursEnabled': quietHoursEnabled,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'notificationFrequency': notificationFrequency.name,
      'isInQuietHours': isInQuietHours,
      'canSendNotification': canSendNotification,
      'dailyNotificationCount': _getDailyNotificationCount(),
    };
  }
}
