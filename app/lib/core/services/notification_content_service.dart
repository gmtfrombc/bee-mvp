/// Service responsible for generating personalized notification content
/// based on momentum states and user context
///
/// This service now delegates to the domain NotificationContentService
/// while maintaining backward compatibility for existing code.
library;

import '../notifications/domain/services/notification_content_service.dart'
    as domain;
import '../notifications/domain/models/notification_models.dart'
    as domain_models;

/// Data class for notification content
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

/// Data class for notification actions
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

class NotificationContentService {
  static NotificationContentService? _instance;
  static NotificationContentService get instance =>
      _instance ??= NotificationContentService._();

  NotificationContentService._();

  // Delegate to domain service
  final _domainService = domain.NotificationContentService.instance;

  /// Generate notification content for momentum drop scenarios
  NotificationContent getMomentumDropNotification({
    required String userName,
    required int previousScore,
    required int currentScore,
    required int daysSinceLastActivity,
  }) {
    final domainContent = _domainService.getMomentumDropNotification(
      userName: userName,
      previousScore: previousScore,
      currentScore: currentScore,
      daysSinceLastActivity: daysSinceLastActivity,
    );

    return _convertFromDomain(domainContent);
  }

  /// Generate coach intervention notification
  NotificationContent getCoachInterventionNotification({
    required String userName,
    required String coachName,
    required int consecutiveDaysInNeedsCare,
  }) {
    final domainContent = _domainService.getCoachInterventionNotification(
      userName: userName,
      coachName: coachName,
      consecutiveDaysInNeedsCare: consecutiveDaysInNeedsCare,
    );

    return _convertFromDomain(domainContent);
  }

  /// Generate celebration notification for positive momentum
  NotificationContent getCelebrationNotification({
    required String userName,
    required int consecutiveGoodDays,
    required String achievementType,
  }) {
    final domainContent = _domainService.getCelebrationNotification(
      userName: userName,
      consecutiveGoodDays: consecutiveGoodDays,
      achievementType: achievementType,
    );

    return _convertFromDomain(domainContent);
  }

  /// Generate engagement reminder notification
  NotificationContent getEngagementReminderNotification({
    required String userName,
    required int hoursSinceLastActivity,
    required String lastKnownMomentumState,
  }) {
    final domainContent = _domainService.getEngagementReminderNotification(
      userName: userName,
      hoursSinceLastActivity: hoursSinceLastActivity,
      lastKnownMomentumState: lastKnownMomentumState,
    );

    return _convertFromDomain(domainContent);
  }

  /// Generate daily momentum update notification
  NotificationContent getDailyUpdateNotification({
    required String userName,
    required String momentumState,
    required int currentScore,
    required String todayStats,
  }) {
    final domainContent = _domainService.getDailyUpdateNotification(
      userName: userName,
      momentumState: momentumState,
      currentScore: currentScore,
      todayStats: todayStats,
    );

    return _convertFromDomain(domainContent);
  }

  /// Generate custom notification with personalization
  NotificationContent getCustomNotification({
    required String type,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    List<NotificationAction>? actionButtons,
  }) {
    final domainActions =
        actionButtons
            ?.map(
              (action) => domain_models.NotificationAction(
                id: action.id,
                title: action.title,
                action: action.action,
                metadata: action.metadata,
              ),
            )
            .toList();

    final domainContent = _domainService.getCustomNotification(
      type: type,
      title: title,
      body: body,
      data: data,
      actionButtons: domainActions,
    );

    return _convertFromDomain(domainContent);
  }

  /// Get motivational quotes for different momentum states
  String getMotivationalQuote(String momentumState) {
    return _domainService.getMotivationalQuote(momentumState);
  }

  /// Convert domain NotificationContent to legacy NotificationContent
  NotificationContent _convertFromDomain(
    domain_models.NotificationContent domainContent,
  ) {
    return NotificationContent(
      type: domainContent.type,
      title: domainContent.title,
      body: domainContent.body,
      data: domainContent.data,
      actionButtons:
          domainContent.actionButtons
              .map(
                (domainAction) => NotificationAction(
                  id: domainAction.id,
                  title: domainAction.title,
                  action: domainAction.action,
                  metadata: domainAction.metadata,
                ),
              )
              .toList(),
    );
  }
}
