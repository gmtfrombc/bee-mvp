import '../notifications/domain/models/notification_types.dart';
import '../notifications/domain/services/notification_trigger_service.dart'
    as domain;

/// Service for manually triggering push notifications and managing notification triggers
///
/// This service now delegates to the domain NotificationTriggerService
/// while maintaining backward compatibility for existing code.
class PushNotificationTriggerService {
  static PushNotificationTriggerService? _instance;
  static PushNotificationTriggerService get instance =>
      _instance ??= PushNotificationTriggerService._();

  PushNotificationTriggerService._();

  // Delegate to domain service
  final _domainService = domain.NotificationTriggerService.instance;

  /// Manually trigger push notifications for a specific user
  Future<TriggerResult> triggerUserNotifications({
    required String userId,
    TriggerType triggerType = TriggerType.manual,
    MomentumData? momentumData,
    NotificationType? notificationType,
  }) async {
    final domainTriggerType = _convertTriggerType(triggerType);
    final domainMomentumData =
        momentumData != null
            ? domain.MomentumData(
              currentState: momentumData.currentState,
              previousState: momentumData.previousState,
              score: momentumData.score,
              date: momentumData.date,
            )
            : null;

    final domainResult = await _domainService.triggerUserNotifications(
      userId: userId,
      triggerType: domainTriggerType,
      momentumData: domainMomentumData,
      notificationType: notificationType,
    );

    return _convertFromDomainTriggerResult(domainResult);
  }

  /// Trigger batch processing for all active users
  Future<TriggerResult> triggerBatchNotifications() async {
    final domainResult = await _domainService.triggerBatchNotifications();
    return _convertFromDomainTriggerResult(domainResult);
  }

  /// Get notification analytics for the current user
  Future<List<NotificationAnalytics>> getNotificationAnalytics({
    int days = 30,
  }) async {
    final domainAnalytics = await _domainService.getNotificationAnalytics(
      days: days,
    );
    return domainAnalytics
        .map(
          (analytics) => NotificationAnalytics(
            notificationDate: analytics.notificationDate,
            notificationType: analytics.notificationType,
            deliveryStatus: analytics.deliveryStatus,
            count: analytics.count,
            uniqueUsers: analytics.uniqueUsers,
          ),
        )
        .toList();
  }

  /// Get user's notification history
  Future<List<NotificationRecord>> getUserNotificationHistory({
    String? userId,
    int limit = 50,
  }) async {
    final domainRecords = await _domainService.getUserNotificationHistory(
      userId: userId,
      limit: limit,
    );
    return domainRecords
        .map(
          (record) => NotificationRecord(
            id: record.id,
            userId: record.userId,
            notificationType: record.notificationType,
            title: record.title,
            message: record.message,
            deliveryStatus: record.deliveryStatus,
            createdAt: record.createdAt,
            sentAt: record.sentAt,
            errorMessage: record.errorMessage,
          ),
        )
        .toList();
  }

  /// Check if user has reached notification rate limit
  Future<bool> checkRateLimit({
    required String notificationType,
    String? userId,
    int maxPerDay = 3,
  }) async {
    return await _domainService.checkRateLimit(
      notificationType: notificationType,
      userId: userId,
      maxPerDay: maxPerDay,
    );
  }

  /// Update notification preferences for the current user
  Future<bool> updateNotificationPreferences({
    required NotificationPreferences preferences,
    String? userId,
  }) async {
    final domainPreferences = domain.NotificationPreferences(
      dailyMotivationEnabled: preferences.dailyMotivationEnabled,
      celebrationEnabled: preferences.celebrationEnabled,
      supportRemindersEnabled: preferences.supportRemindersEnabled,
      coachInterventionEnabled: preferences.coachInterventionEnabled,
      quietHoursStart: preferences.quietHoursStart,
      quietHoursEnd: preferences.quietHoursEnd,
      timezone: preferences.timezone,
    );

    return await _domainService.updateNotificationPreferences(
      preferences: domainPreferences,
      userId: userId,
    );
  }

  /// Get notification preferences for the current user
  Future<NotificationPreferences?> getNotificationPreferences({
    String? userId,
  }) async {
    final domainPreferences = await _domainService.getNotificationPreferences(
      userId: userId,
    );
    if (domainPreferences == null) return null;

    return NotificationPreferences(
      dailyMotivationEnabled: domainPreferences.dailyMotivationEnabled,
      celebrationEnabled: domainPreferences.celebrationEnabled,
      supportRemindersEnabled: domainPreferences.supportRemindersEnabled,
      coachInterventionEnabled: domainPreferences.coachInterventionEnabled,
      quietHoursStart: domainPreferences.quietHoursStart,
      quietHoursEnd: domainPreferences.quietHoursEnd,
      timezone: domainPreferences.timezone,
    );
  }

  /// Test notification delivery (for development/testing)
  Future<bool> sendTestNotification({
    required String title,
    required String message,
    String? userId,
  }) async {
    return await _domainService.sendTestNotification(
      title: title,
      message: message,
      userId: userId,
    );
  }

  /// Convert legacy TriggerType to domain TriggerType
  domain.TriggerType _convertTriggerType(TriggerType triggerType) {
    switch (triggerType) {
      case TriggerType.momentumChange:
        return domain.TriggerType.momentumChange;
      case TriggerType.dailyCheck:
        return domain.TriggerType.dailyCheck;
      case TriggerType.manual:
        return domain.TriggerType.manual;
      case TriggerType.batchProcess:
        return domain.TriggerType.batchProcess;
    }
  }

  /// Convert domain TriggerResult to legacy TriggerResult
  TriggerResult _convertFromDomainTriggerResult(
    domain.TriggerResult domainResult,
  ) {
    return TriggerResult(
      success: domainResult.success,
      error: domainResult.error,
      results:
          domainResult.results
              .map(
                (result) => UserTriggerResult(
                  success: result.success,
                  userId: result.userId,
                  notificationsSent: result.notificationsSent,
                  interventionsCreated: result.interventionsCreated,
                  error: result.error,
                ),
              )
              .toList(),
      summary:
          domainResult.summary != null
              ? TriggerSummary(
                totalUsersProcessed: domainResult.summary!.totalUsersProcessed,
                totalNotificationsSent:
                    domainResult.summary!.totalNotificationsSent,
                totalInterventionsCreated:
                    domainResult.summary!.totalInterventionsCreated,
                failedUsers: domainResult.summary!.failedUsers,
              )
              : null,
    );
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
