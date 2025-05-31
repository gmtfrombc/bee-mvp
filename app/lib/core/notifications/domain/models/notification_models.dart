/// Unified notification models for the notification system
///
/// This file consolidates all notification-related data models that were
/// scattered across the 11 notification services into clean domain objects.
library;

import 'notification_types.dart';

/// Main notification content model
/// Extracted from notification_content_service.dart
class NotificationContent {
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final List<NotificationAction> actionButtons;

  NotificationContent({
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    this.actionButtons = const [],
  });

  /// Convert to FCM message format
  Map<String, dynamic> toFCMPayload() {
    return {
      'notification': {'title': title, 'body': body},
      'data': {
        ...data,
        'type': type,
        'actions': actionButtons.map((action) => action.toMap()).toList(),
      },
    };
  }

  /// Convert to local notification format
  Map<String, dynamic> toLocalNotificationPayload() {
    return {
      'title': title,
      'body': body,
      'payload': {
        ...data,
        'type': type,
        'actions': actionButtons.map((action) => action.toMap()).toList(),
      },
    };
  }

  @override
  String toString() {
    return 'NotificationContent(type: $type, title: $title, body: $body)';
  }
}

/// Notification action model
/// Extracted from notification_content_service.dart
class NotificationAction {
  final String id;
  final String title;
  final String action;
  final Map<String, dynamic>? metadata;

  NotificationAction({
    required this.id,
    required this.title,
    required this.action,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'action': action,
      if (metadata != null) 'metadata': metadata,
    };
  }

  @override
  String toString() {
    return 'NotificationAction(id: $id, title: $title, action: $action)';
  }
}

/// Background notification data model
/// Extracted from background_notification_handler.dart
class NotificationData {
  final String notificationId;
  final String interventionType;
  final String actionType;
  final Map<String, dynamic> actionData;
  final String title;
  final String body;
  final DateTime receivedAt;

  const NotificationData({
    required this.notificationId,
    required this.interventionType,
    required this.actionType,
    required this.actionData,
    required this.title,
    required this.body,
    required this.receivedAt,
  });

  Map<String, dynamic> toJson() => {
    'notificationId': notificationId,
    'interventionType': interventionType,
    'actionType': actionType,
    'actionData': actionData,
    'title': title,
    'body': body,
    'receivedAt': receivedAt.toIso8601String(),
  };

  factory NotificationData.fromJson(Map<String, dynamic> json) =>
      NotificationData(
        notificationId: (json['notificationId'] as String?) ?? '',
        interventionType: (json['interventionType'] as String?) ?? '',
        actionType: (json['actionType'] as String?) ?? '',
        actionData:
            (json['actionData'] as Map<String, dynamic>?) ??
            <String, dynamic>{},
        title: (json['title'] as String?) ?? '',
        body: (json['body'] as String?) ?? '',
        receivedAt: DateTime.parse(json['receivedAt'] as String),
      );
}

/// Pending notification action model
/// Extracted from background_notification_handler.dart
class PendingNotificationAction {
  final String notificationId;
  final String actionType;
  final Map<String, dynamic> actionData;
  final DateTime receivedAt;

  const PendingNotificationAction({
    required this.notificationId,
    required this.actionType,
    required this.actionData,
    required this.receivedAt,
  });

  Map<String, dynamic> toJson() => {
    'notificationId': notificationId,
    'actionType': actionType,
    'actionData': actionData,
    'receivedAt': receivedAt.toIso8601String(),
  };

  factory PendingNotificationAction.fromJson(Map<String, dynamic> json) =>
      PendingNotificationAction(
        notificationId: (json['notificationId'] as String?) ?? '',
        actionType: (json['actionType'] as String?) ?? '',
        actionData:
            (json['actionData'] as Map<String, dynamic>?) ??
            <String, dynamic>{},
        receivedAt: DateTime.parse(json['receivedAt'] as String),
      );
}

/// A/B test notification variant model
/// Extracted from notification_ab_testing_service.dart
class NotificationVariant {
  final String name;
  final VariantType type;
  final Map<String, dynamic> config;

  NotificationVariant({
    required this.name,
    required this.type,
    required this.config,
  });

  factory NotificationVariant.control() {
    return NotificationVariant(
      name: 'control',
      type: VariantType.control,
      config: {},
    );
  }

  factory NotificationVariant.fromJson(Map<String, dynamic> json) {
    return NotificationVariant(
      name: json['name'],
      type: VariantType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => VariantType.control,
      ),
      config: json['config'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'type': type.name, 'config': config};
  }
}

/// A/B test configuration model
/// Extracted from notification_ab_testing_service.dart
class ABTest {
  final String testName;
  final String description;
  final List<NotificationVariant> variants;
  final Map<String, double> trafficAllocation;
  final DateTime startDate;
  final DateTime? endDate;
  final String status;

  ABTest({
    required this.testName,
    required this.description,
    required this.variants,
    required this.trafficAllocation,
    required this.startDate,
    this.endDate,
    required this.status,
  });

  factory ABTest.fromJson(Map<String, dynamic> json) {
    return ABTest(
      testName: json['test_name'],
      description: json['description'],
      variants:
          (json['variants'] as List)
              .map((v) => NotificationVariant.fromJson(v))
              .toList(),
      trafficAllocation: Map<String, double>.from(json['traffic_allocation']),
      startDate: DateTime.parse(json['start_date']),
      endDate:
          json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      status: json['status'],
    );
  }
}

/// A/B test results model
/// Extracted from notification_ab_testing_service.dart
class ABTestResults {
  final String testName;
  final List<VariantResults> variants;
  final double statisticalSignificance;
  final String? winningVariant;
  final double confidenceLevel;

  ABTestResults({
    required this.testName,
    required this.variants,
    required this.statisticalSignificance,
    this.winningVariant,
    required this.confidenceLevel,
  });

  factory ABTestResults.fromJson(Map<String, dynamic> json) {
    return ABTestResults(
      testName: json['test_name'],
      variants:
          (json['variants'] as List)
              .map((v) => VariantResults.fromJson(v))
              .toList(),
      statisticalSignificance:
          (json['statistical_significance'] as num).toDouble(),
      winningVariant: json['winning_variant'],
      confidenceLevel: (json['confidence_level'] as num).toDouble(),
    );
  }
}

/// Variant test results model
/// Extracted from notification_ab_testing_service.dart
class VariantResults {
  final String name;
  final int participants;
  final double deliveryRate;
  final double openRate;
  final double clickRate;
  final double conversionRate;
  final double engagementScore;

  VariantResults({
    required this.name,
    required this.participants,
    required this.deliveryRate,
    required this.openRate,
    required this.clickRate,
    required this.conversionRate,
    required this.engagementScore,
  });

  factory VariantResults.fromJson(Map<String, dynamic> json) {
    return VariantResults(
      name: json['name'],
      participants: json['participants'],
      deliveryRate: (json['delivery_rate'] as num).toDouble(),
      openRate: (json['open_rate'] as num).toDouble(),
      clickRate: (json['click_rate'] as num).toDouble(),
      conversionRate: (json['conversion_rate'] as num).toDouble(),
      engagementScore: (json['engagement_score'] as num).toDouble(),
    );
  }
}

/// Notification analytics model
/// Extracted from push_notification_trigger_service.dart
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

/// Individual notification record model
/// Extracted from push_notification_trigger_service.dart
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

/// User notification preferences model
/// Note: This consolidates duplicated NotificationPreferences from
/// push_notification_trigger_service.dart with the NotificationPreferencesService logic
class NotificationPreferencesModel {
  final bool notificationsEnabled;
  final bool momentumNotificationsEnabled;
  final bool celebrationNotificationsEnabled;
  final bool interventionNotificationsEnabled;
  final bool quietHoursEnabled;
  final int quietHoursStart;
  final int quietHoursEnd;
  final NotificationFrequency notificationFrequency;
  final String? timezone;

  NotificationPreferencesModel({
    this.notificationsEnabled = true,
    this.momentumNotificationsEnabled = true,
    this.celebrationNotificationsEnabled = true,
    this.interventionNotificationsEnabled = true,
    this.quietHoursEnabled = false,
    this.quietHoursStart = 22,
    this.quietHoursEnd = 8,
    this.notificationFrequency = NotificationFrequency.normal,
    this.timezone,
  });

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferencesModel(
      notificationsEnabled: json['notifications_enabled'] ?? true,
      momentumNotificationsEnabled:
          json['momentum_notifications_enabled'] ?? true,
      celebrationNotificationsEnabled:
          json['celebration_notifications_enabled'] ?? true,
      interventionNotificationsEnabled:
          json['intervention_notifications_enabled'] ?? true,
      quietHoursEnabled: json['quiet_hours_enabled'] ?? false,
      quietHoursStart: json['quiet_hours_start'] ?? 22,
      quietHoursEnd: json['quiet_hours_end'] ?? 8,
      notificationFrequency: NotificationFrequency.values.firstWhere(
        (freq) => freq.name == json['notification_frequency'],
        orElse: () => NotificationFrequency.normal,
      ),
      timezone: json['timezone'],
    );
  }

  Map<String, dynamic> toJson() => {
    'notifications_enabled': notificationsEnabled,
    'momentum_notifications_enabled': momentumNotificationsEnabled,
    'celebration_notifications_enabled': celebrationNotificationsEnabled,
    'intervention_notifications_enabled': interventionNotificationsEnabled,
    'quiet_hours_enabled': quietHoursEnabled,
    'quiet_hours_start': quietHoursStart,
    'quiet_hours_end': quietHoursEnd,
    'notification_frequency': notificationFrequency.name,
    'timezone': timezone,
  };

  /// Check if we're currently in quiet hours
  bool get isInQuietHours {
    if (!quietHoursEnabled) return false;

    final now = DateTime.now();
    final currentHour = now.hour;

    // Handle overnight quiet hours (e.g., 22:00 to 08:00)
    if (quietHoursStart > quietHoursEnd) {
      return currentHour >= quietHoursStart || currentHour < quietHoursEnd;
    }
    // Handle same-day quiet hours (e.g., 12:00 to 14:00)
    else {
      return currentHour >= quietHoursStart && currentHour < quietHoursEnd;
    }
  }

  /// Check if a specific notification type should be sent
  bool shouldSendNotificationType(NotificationType type) {
    if (!notificationsEnabled) return false;

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
}

/// Test result model for notification testing
/// Extracted from notification_test_validator.dart
class NotificationTestResults {
  final Map<String, TestResult> testResults;
  final Map<String, String> errors;
  final double overallSuccess;

  NotificationTestResults({
    required this.testResults,
    required this.errors,
    required this.overallSuccess,
  });

  double calculateOverallSuccess() {
    if (testResults.isEmpty) return 0.0;
    final successCount = testResults.values.where((r) => r.success).length;
    return successCount / testResults.length;
  }

  Map<String, dynamic> toJson() {
    return {
      'overall_success': overallSuccess,
      'test_count': testResults.length,
      'success_count': testResults.values.where((r) => r.success).length,
      'error_count': errors.length,
      'tests': testResults.map((k, v) => MapEntry(k, v.toJson())),
      'errors': errors,
    };
  }
}

/// Individual test result
/// Extracted from notification_test_validator.dart
class TestResult {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  TestResult({
    required this.success,
    this.message,
    this.data,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Test analysis results
/// Extracted from notification_test_validator.dart
class NotificationTestAnalysis {
  final int totalTests;
  final int successCount;
  final int failureCount;
  final double successRate;
  final NotificationSystemHealth overallHealth;
  final List<String> criticalIssues;
  final List<String> warnings;
  final List<String> informational;
  final String summary;

  NotificationTestAnalysis({
    required this.totalTests,
    required this.successCount,
    required this.failureCount,
    required this.successRate,
    required this.overallHealth,
    required this.criticalIssues,
    required this.warnings,
    required this.informational,
    required this.summary,
  });
}

/// Test error details
/// Extracted from notification_test_validator.dart
class TestError {
  final String testName;
  final String errorMessage;
  final Map<String, dynamic> details;
  final ErrorCategory category;
  final ErrorSeverity severity;

  TestError({
    required this.testName,
    required this.errorMessage,
    required this.details,
    required this.category,
    required this.severity,
  });
}
