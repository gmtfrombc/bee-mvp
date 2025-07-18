import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Handles local notification scheduling for the Perceived Energy Score (PES)
/// daily prompt. Ensures notifications fire at **09:00 local** by default and
/// respect the user’s current time-zone even after travel or daylight-saving
/// changes.
class NotificationSchedulerService {
  NotificationSchedulerService._(this._plugin);

  /// Factory constructor to perform one-time plugin + timezone initialisation.
  static Future<NotificationSchedulerService> create() async {
    final plugin = FlutterLocalNotificationsPlugin();

    // Initialise platform-specific settings.
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await plugin.initialize(initSettings);

    // Initialise timezone data and bind to the device’s current zone.
    tz.initializeTimeZones();
    final String currentTz = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTz));

    return NotificationSchedulerService._(plugin);
  }

  final FlutterLocalNotificationsPlugin _plugin;

  /// Schedules (or reschedules) a daily prompt at the given [time]. Any existing
  /// PES prompt is cancelled first to avoid duplicates.
  Future<void> scheduleDailyPrompt(TimeOfDay time) async {
    // Cancel any existing schedule.
    await cancelPrompt();

    // Compute the next occurrence of the desired local time.
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Schedule the notification.
    await _plugin.zonedSchedule(
      _pesPromptNotificationId,
      'Daily Check-In',
      'How energized do you feel today?',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _pesPromptChannelId,
          'Daily PES Prompt',
          channelDescription:
              'Daily reminder to record your perceived energy score',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Cancels the currently scheduled PES prompt (if any).
  Future<void> cancelPrompt() async {
    await _plugin.cancel(_pesPromptNotificationId);
  }

  /// Constants =================================================================
  static const int _pesPromptNotificationId = 9001;
  static const String _pesPromptChannelId = 'daily_pes_prompt';
}
