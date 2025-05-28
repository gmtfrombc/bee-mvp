import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for manually triggering push notifications and managing notification triggers
class PushNotificationTriggerService {
  static PushNotificationTriggerService? _instance;
  static PushNotificationTriggerService get instance =>
      _instance ??= PushNotificationTriggerService._();

  PushNotificationTriggerService._();

  final _supabase = Supabase.instance.client;

  /// Manually trigger push notifications for a specific user
  Future<TriggerResult> triggerUserNotifications({
    required String userId,
    TriggerType triggerType = TriggerType.manual,
    MomentumData? momentumData,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'push-notification-triggers',
        body: {
          'user_id': userId,
          'trigger_type': triggerType.name,
          if (momentumData != null) 'momentum_data': momentumData.toJson(),
        },
      );

      if (response.status == 200) {
        final data = response.data as Map<String, dynamic>;
        return TriggerResult.fromJson(data);
      } else {
        throw Exception('Failed to trigger notifications: ${response.status}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error triggering user notifications: $e');
      }
      return TriggerResult(success: false, error: e.toString(), results: []);
    }
  }

  /// Trigger batch processing for all active users
  Future<TriggerResult> triggerBatchNotifications() async {
    try {
      final response = await _supabase.functions.invoke(
        'push-notification-triggers',
        body: {'trigger_type': 'batch_process'},
      );

      if (response.status == 200) {
        final data = response.data as Map<String, dynamic>;
        return TriggerResult.fromJson(data);
      } else {
        throw Exception(
          'Failed to trigger batch notifications: ${response.status}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error triggering batch notifications: $e');
      }
      return TriggerResult(success: false, error: e.toString(), results: []);
    }
  }

  /// Get notification analytics for the current user
  Future<List<NotificationAnalytics>> getNotificationAnalytics({
    int days = 30,
  }) async {
    try {
      final response = await _supabase
          .from('notification_analytics')
          .select()
          .gte(
            'notification_date',
            DateTime.now()
                .subtract(Duration(days: days))
                .toIso8601String()
                .split('T')[0],
          )
          .order('notification_date', ascending: false);

      return (response as List)
          .map((item) => NotificationAnalytics.fromJson(item))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting notification analytics: $e');
      }
      return [];
    }
  }

  /// Get user's notification history
  Future<List<NotificationRecord>> getUserNotificationHistory({
    String? userId,
    int limit = 50,
  }) async {
    try {
      final currentUserId = userId ?? _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('No user ID provided and no current user');
      }

      final response = await _supabase
          .from('momentum_notifications')
          .select()
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((item) => NotificationRecord.fromJson(item))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting notification history: $e');
      }
      return [];
    }
  }

  /// Check if user has reached notification rate limit
  Future<bool> checkRateLimit({
    required String notificationType,
    String? userId,
    int maxPerDay = 3,
  }) async {
    try {
      final currentUserId = userId ?? _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('No user ID provided and no current user');
      }

      final response = await _supabase.rpc(
        'check_notification_rate_limit',
        params: {
          'p_user_id': currentUserId,
          'p_notification_type': notificationType,
          'p_max_per_day': maxPerDay,
        },
      );

      return response as bool;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking rate limit: $e');
      }
      return false; // Assume rate limited on error
    }
  }

  /// Update notification preferences for the current user
  Future<bool> updateNotificationPreferences({
    required NotificationPreferences preferences,
    String? userId,
  }) async {
    try {
      final currentUserId = userId ?? _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('No user ID provided and no current user');
      }

      await _supabase.from('user_notification_preferences').upsert({
        'user_id': currentUserId,
        'daily_motivation_enabled': preferences.dailyMotivationEnabled,
        'celebration_enabled': preferences.celebrationEnabled,
        'support_reminders_enabled': preferences.supportRemindersEnabled,
        'coach_intervention_enabled': preferences.coachInterventionEnabled,
        'quiet_hours_start': preferences.quietHoursStart,
        'quiet_hours_end': preferences.quietHoursEnd,
        'timezone': preferences.timezone,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating notification preferences: $e');
      }
      return false;
    }
  }

  /// Get notification preferences for the current user
  Future<NotificationPreferences?> getNotificationPreferences({
    String? userId,
  }) async {
    try {
      final currentUserId = userId ?? _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('No user ID provided and no current user');
      }

      final response =
          await _supabase
              .from('user_notification_preferences')
              .select()
              .eq('user_id', currentUserId)
              .maybeSingle();

      if (response != null) {
        return NotificationPreferences.fromJson(response);
      }

      // Return default preferences if none exist
      return NotificationPreferences.defaultPreferences();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting notification preferences: $e');
      }
      return NotificationPreferences.defaultPreferences();
    }
  }

  /// Test notification delivery (for development/testing)
  Future<bool> sendTestNotification({
    required String title,
    required String message,
    String? userId,
  }) async {
    try {
      final currentUserId = userId ?? _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('No user ID provided and no current user');
      }

      final result = await triggerUserNotifications(
        userId: currentUserId,
        triggerType: TriggerType.manual,
        momentumData: MomentumData(
          currentState: 'Rising',
          score: 85.0,
          date: DateTime.now().toIso8601String().split('T')[0],
        ),
      );

      return result.success;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending test notification: $e');
      }
      return false;
    }
  }
}

/// Enum for different trigger types
enum TriggerType {
  momentumChange('momentum_change'),
  dailyCheck('daily_check'),
  manual('manual'),
  batchProcess('batch_process');

  const TriggerType(this.value);
  final String value;

  String get name => value;
}

/// Data class for momentum data in triggers
class MomentumData {
  final String currentState;
  final String? previousState;
  final double score;
  final String date;

  MomentumData({
    required this.currentState,
    this.previousState,
    required this.score,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'current_state': currentState,
    if (previousState != null) 'previous_state': previousState,
    'score': score,
    'date': date,
  };
}

/// Result of trigger operation
class TriggerResult {
  final bool success;
  final String? error;
  final List<UserTriggerResult> results;
  final TriggerSummary? summary;

  TriggerResult({
    required this.success,
    this.error,
    required this.results,
    this.summary,
  });

  factory TriggerResult.fromJson(Map<String, dynamic> json) {
    return TriggerResult(
      success: json['success'] ?? false,
      error: json['error'],
      results:
          (json['results'] as List? ?? [])
              .map((item) => UserTriggerResult.fromJson(item))
              .toList(),
      summary:
          json['summary'] != null
              ? TriggerSummary.fromJson(json['summary'])
              : null,
    );
  }
}

/// Result for individual user trigger
class UserTriggerResult {
  final bool success;
  final String userId;
  final int notificationsSent;
  final int interventionsCreated;
  final String? error;

  UserTriggerResult({
    required this.success,
    required this.userId,
    required this.notificationsSent,
    required this.interventionsCreated,
    this.error,
  });

  factory UserTriggerResult.fromJson(Map<String, dynamic> json) {
    return UserTriggerResult(
      success: json['success'] ?? false,
      userId: json['user_id'] ?? '',
      notificationsSent: json['notifications_sent'] ?? 0,
      interventionsCreated: json['interventions_created'] ?? 0,
      error: json['error'],
    );
  }
}

/// Summary of trigger operation
class TriggerSummary {
  final int totalUsersProcessed;
  final int totalNotificationsSent;
  final int totalInterventionsCreated;
  final int failedUsers;

  TriggerSummary({
    required this.totalUsersProcessed,
    required this.totalNotificationsSent,
    required this.totalInterventionsCreated,
    required this.failedUsers,
  });

  factory TriggerSummary.fromJson(Map<String, dynamic> json) {
    return TriggerSummary(
      totalUsersProcessed: json['total_users_processed'] ?? 0,
      totalNotificationsSent: json['total_notifications_sent'] ?? 0,
      totalInterventionsCreated: json['total_interventions_created'] ?? 0,
      failedUsers: json['failed_users'] ?? 0,
    );
  }
}

/// Notification analytics data
class NotificationAnalytics {
  final DateTime notificationDate;
  final String notificationType;
  final String deliveryStatus;
  final int count;
  final int uniqueUsers;

  NotificationAnalytics({
    required this.notificationDate,
    required this.notificationType,
    required this.deliveryStatus,
    required this.count,
    required this.uniqueUsers,
  });

  factory NotificationAnalytics.fromJson(Map<String, dynamic> json) {
    return NotificationAnalytics(
      notificationDate: DateTime.parse(json['notification_date']),
      notificationType: json['notification_type'] ?? '',
      deliveryStatus: json['delivery_status'] ?? '',
      count: json['count'] ?? 0,
      uniqueUsers: json['unique_users'] ?? 0,
    );
  }
}

/// Individual notification record
class NotificationRecord {
  final String id;
  final String userId;
  final String notificationType;
  final String title;
  final String message;
  final String deliveryStatus;
  final DateTime createdAt;
  final DateTime? sentAt;
  final String? errorMessage;

  NotificationRecord({
    required this.id,
    required this.userId,
    required this.notificationType,
    required this.title,
    required this.message,
    required this.deliveryStatus,
    required this.createdAt,
    this.sentAt,
    this.errorMessage,
  });

  factory NotificationRecord.fromJson(Map<String, dynamic> json) {
    return NotificationRecord(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      notificationType: json['notification_type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      deliveryStatus: json['delivery_status'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at']) : null,
      errorMessage: json['error_message'],
    );
  }
}

/// User notification preferences
class NotificationPreferences {
  final bool dailyMotivationEnabled;
  final bool celebrationEnabled;
  final bool supportRemindersEnabled;
  final bool coachInterventionEnabled;
  final String? quietHoursStart;
  final String? quietHoursEnd;
  final String? timezone;

  NotificationPreferences({
    required this.dailyMotivationEnabled,
    required this.celebrationEnabled,
    required this.supportRemindersEnabled,
    required this.coachInterventionEnabled,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.timezone,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      dailyMotivationEnabled: json['daily_motivation_enabled'] ?? true,
      celebrationEnabled: json['celebration_enabled'] ?? true,
      supportRemindersEnabled: json['support_reminders_enabled'] ?? true,
      coachInterventionEnabled: json['coach_intervention_enabled'] ?? true,
      quietHoursStart: json['quiet_hours_start'],
      quietHoursEnd: json['quiet_hours_end'],
      timezone: json['timezone'],
    );
  }

  factory NotificationPreferences.defaultPreferences() {
    return NotificationPreferences(
      dailyMotivationEnabled: true,
      celebrationEnabled: true,
      supportRemindersEnabled: true,
      coachInterventionEnabled: true,
      quietHoursStart: '22:00',
      quietHoursEnd: '08:00',
      timezone: DateTime.now().timeZoneName,
    );
  }

  Map<String, dynamic> toJson() => {
    'daily_motivation_enabled': dailyMotivationEnabled,
    'celebration_enabled': celebrationEnabled,
    'support_reminders_enabled': supportRemindersEnabled,
    'coach_intervention_enabled': coachInterventionEnabled,
    'quiet_hours_start': quietHoursStart,
    'quiet_hours_end': quietHoursEnd,
    'timezone': timezone,
  };
}
