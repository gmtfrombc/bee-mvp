/// Unified notification types, enums, and constants for the notification system
///
/// This file consolidates all notification-related enums and constants that were
/// scattered across the 11 notification services.
library;

/// Types of notifications in the system
enum NotificationType {
  momentum,
  celebration,
  intervention,
  engagement,
  daily,
  coach,
  custom,
}

/// Notification frequency settings for user preferences
enum NotificationFrequency {
  minimal(
    name: 'minimal',
    displayName: 'Minimal',
    description: 'Only urgent notifications',
    maxDailyNotifications: 2,
    minIntervalMinutes: 240, // 4 hours
  ),
  normal(
    name: 'normal',
    displayName: 'Normal',
    description: 'Balanced notification frequency',
    maxDailyNotifications: 5,
    minIntervalMinutes: 120, // 2 hours
  ),
  frequent(
    name: 'frequent',
    displayName: 'Frequent',
    description: 'More notifications for extra support',
    maxDailyNotifications: 8,
    minIntervalMinutes: 60, // 1 hour
  );

  const NotificationFrequency({
    required this.name,
    required this.displayName,
    required this.description,
    required this.maxDailyNotifications,
    required this.minIntervalMinutes,
  });

  final String name;
  final String displayName;
  final String description;
  final int maxDailyNotifications;
  final int minIntervalMinutes;
}

/// A/B test variant types for notifications
enum VariantType {
  control,
  personalized,
  urgent,
  encouraging,
  social,
  gamified,
}

/// Events tracked for notification analytics
enum NotificationEvent {
  sent,
  delivered,
  opened,
  clicked,
  dismissed,
  converted,
}

/// Health status of the notification system
enum NotificationSystemHealth { excellent, good, fair, poor, unknown }

/// Error categories for notification system issues
enum ErrorCategory {
  configuration,
  permissions,
  connectivity,
  delivery,
  general,
}

/// Severity levels for notification errors
enum ErrorSeverity { critical, high, medium, low }

/// Notification delivery status constants
class NotificationDeliveryStatus {
  static const String pending = 'pending';
  static const String sent = 'sent';
  static const String delivered = 'delivered';
  static const String failed = 'failed';
  static const String error = 'error';
}

/// Common notification action types
class NotificationActionTypes {
  static const String openMomentumMeter = 'open_momentum_meter';
  static const String openQuickStart = 'open_quick_start';
  static const String scheduleCoachCall = 'schedule_coach_call';
  static const String openCoachChat = 'open_coach_chat';
  static const String viewAchievements = 'view_achievements';
  static const String shareProgress = 'share_progress';
  static const String viewProgress = 'view_progress';
  static const String startLesson = 'open_lessons';
  static const String quickCheckIn = 'quick_check_in';
  static const String viewMomentum = 'view_momentum';
  static const String keepGoing = 'keep_going';
  static const String getSuppport = 'get_support';
  static const String sendMessage = 'send_message';
  static const String continue_ = 'continue';
}

/// Notification priorities
class NotificationPriority {
  static const String low = 'low';
  static const String medium = 'medium';
  static const String high = 'high';
  static const String critical = 'critical';
}

/// Encouragement levels for personalized notifications
class EncouragementLevel {
  static const String gentle = 'gentle';
  static const String supportive = 'supportive';
  static const String motivational = 'motivational';
  static const String celebratory = 'celebratory';
}

/// Celebration types
class CelebrationType {
  static const String daily = 'daily';
  static const String streak = 'streak';
  static const String weeklyStreak = 'weekly_streak';
  static const String milestone = 'milestone';
}

/// Intervention types
class InterventionType {
  static const String momentumSupport = 'momentum_support';
  static const String coachIntervention = 'coach_intervention';
  static const String engagementReminder = 'engagement_reminder';
  static const String dailyUpdate = 'daily_update';
}
