/// Service responsible for generating personalized notification content
/// based on momentum states and user context
library;

class NotificationContentService {
  static NotificationContentService? _instance;
  static NotificationContentService get instance =>
      _instance ??= NotificationContentService._();

  NotificationContentService._();

  /// Generate notification content for momentum drop scenarios
  NotificationContent getMomentumDropNotification({
    required String userName,
    required int previousScore,
    required int currentScore,
    required int daysSinceLastActivity,
  }) {
    final scoreDrop = previousScore - currentScore;

    // Select message based on severity of drop
    if (scoreDrop >= 25) {
      return NotificationContent(
        type: 'momentum_drop_severe',
        title: 'We\'re here to help! 🌱',
        body:
            'Hi $userName, your momentum dipped recently - that\'s completely normal! Small steps can get you back on track.',
        data: {
          'action': 'open_momentum_meter',
          'encouragement_level': 'gentle',
          'score_drop': scoreDrop,
          'priority': 'high',
        },
        actionButtons: [
          NotificationAction(
            id: 'quick_start',
            title: 'Quick Start',
            action: 'open_quick_start',
          ),
          NotificationAction(
            id: 'get_support',
            title: 'Get Support',
            action: 'schedule_coach_call',
          ),
        ],
      );
    } else if (scoreDrop >= 15) {
      return NotificationContent(
        type: 'momentum_drop_moderate',
        title: 'You\'ve got this! 💪',
        body:
            'Hey $userName, let\'s get your momentum flowing again. Every journey has its ups and downs!',
        data: {
          'action': 'open_momentum_meter',
          'encouragement_level': 'supportive',
          'score_drop': scoreDrop,
          'priority': 'medium',
        },
        actionButtons: [
          NotificationAction(
            id: 'view_progress',
            title: 'View Progress',
            action: 'open_momentum_meter',
          ),
          NotificationAction(
            id: 'start_lesson',
            title: 'Start Lesson',
            action: 'open_lessons',
          ),
        ],
      );
    } else {
      return NotificationContent(
        type: 'momentum_drop_gentle',
        title: 'Ready for a fresh start? ✨',
        body:
            '$userName, your momentum is looking for a little boost. What small step could you take today?',
        data: {
          'action': 'open_momentum_meter',
          'encouragement_level': 'gentle',
          'score_drop': scoreDrop,
          'priority': 'low',
        },
        actionButtons: [
          NotificationAction(
            id: 'quick_check_in',
            title: 'Quick Check-in',
            action: 'open_momentum_meter',
          ),
        ],
      );
    }
  }

  /// Generate coach intervention notification
  NotificationContent getCoachInterventionNotification({
    required String userName,
    required String coachName,
    required int consecutiveDaysInNeedsCare,
  }) {
    return NotificationContent(
      type: 'coach_intervention',
      title: '$coachName wants to connect 🤝',
      body:
          'Hi $userName, we\'ve noticed you might benefit from some support. Let\'s chat about how to get your momentum flowing!',
      data: {
        'action': 'schedule_coach_call',
        'priority': 'high',
        'coach_name': coachName,
        'consecutive_days': consecutiveDaysInNeedsCare,
        'intervention_type': 'momentum_support',
      },
      actionButtons: [
        NotificationAction(
          id: 'schedule_call',
          title: 'Schedule Call',
          action: 'schedule_coach_call',
        ),
        NotificationAction(
          id: 'send_message',
          title: 'Send Message',
          action: 'open_coach_chat',
        ),
      ],
    );
  }

  /// Generate celebration notification for positive momentum
  NotificationContent getCelebrationNotification({
    required String userName,
    required int consecutiveGoodDays,
    required String achievementType,
  }) {
    if (consecutiveGoodDays >= 7) {
      return NotificationContent(
        type: 'celebration_weekly_streak',
        title: 'Amazing momentum! 🚀',
        body:
            '$userName, you\'ve had fantastic momentum for $consecutiveGoodDays days! You\'re absolutely crushing it!',
        data: {
          'action': 'view_achievements',
          'celebration_type': 'weekly_streak',
          'streak_days': consecutiveGoodDays,
          'momentum_state': achievementType,
        },
        actionButtons: [
          NotificationAction(
            id: 'view_achievements',
            title: 'View Achievements',
            action: 'view_achievements',
          ),
          NotificationAction(
            id: 'share_progress',
            title: 'Share Progress',
            action: 'share_progress',
          ),
        ],
      );
    } else if (consecutiveGoodDays >= 5) {
      return NotificationContent(
        type: 'celebration_streak',
        title: 'You\'re on a roll! 🎉',
        body:
            'Hey $userName, $consecutiveGoodDays days of great momentum! Keep up the fantastic work!',
        data: {
          'action': 'view_achievements',
          'celebration_type': 'streak',
          'streak_days': consecutiveGoodDays,
          'momentum_state': achievementType,
        },
        actionButtons: [
          NotificationAction(
            id: 'keep_going',
            title: 'Keep Going!',
            action: 'open_momentum_meter',
          ),
        ],
      );
    } else {
      return NotificationContent(
        type: 'celebration_milestone',
        title: 'Great work today! ⭐',
        body:
            '$userName, your momentum is looking great! Every positive step counts.',
        data: {
          'action': 'open_momentum_meter',
          'celebration_type': 'daily',
          'momentum_state': achievementType,
        },
        actionButtons: [
          NotificationAction(
            id: 'view_progress',
            title: 'View Progress',
            action: 'open_momentum_meter',
          ),
        ],
      );
    }
  }

  /// Generate engagement reminder notification
  NotificationContent getEngagementReminderNotification({
    required String userName,
    required int hoursSinceLastActivity,
    required String lastKnownMomentumState,
  }) {
    if (hoursSinceLastActivity >= 72) {
      // 72+ hours inactive - gentle reminder
      return NotificationContent(
        type: 'engagement_reminder_gentle',
        title: 'We miss you! 🌱',
        body:
            '$userName, your momentum is waiting for you to return! Even small steps count.',
        data: {
          'action': 'open_momentum_meter',
          'reminder_type': 'gentle_check_in',
          'hours_inactive': hoursSinceLastActivity,
          'last_activity': lastKnownMomentumState,
        },
        actionButtons: [
          NotificationAction(
            id: 'continue',
            title: 'Continue',
            action: 'open_momentum_meter',
          ),
        ],
      );
    } else if (hoursSinceLastActivity >= 48) {
      // 48+ hours inactive - supportive reminder
      return NotificationContent(
        type: 'engagement_reminder_supportive',
        title: 'Your momentum is waiting! 💪',
        body:
            '$userName, ready to get back on track? Your momentum is ready when you are!',
        data: {
          'action': 'open_momentum_meter',
          'reminder_type': 'supportive',
          'hours_inactive': hoursSinceLastActivity,
          'last_activity': lastKnownMomentumState,
        },
        actionButtons: [
          NotificationAction(
            id: 'continue',
            title: 'Continue',
            action: 'open_momentum_meter',
          ),
          NotificationAction(
            id: 'get_support',
            title: 'Get Support',
            action: 'schedule_coach_call',
          ),
        ],
      );
    } else {
      // Less than 48 hours - encouraging reminder
      return NotificationContent(
        type: 'engagement_reminder_encouraging',
        title: 'Ready to continue? ✨',
        body:
            '$userName, how are you feeling today? Check in with your momentum!',
        data: {
          'action': 'open_momentum_meter',
          'reminder_type': 'encouraging',
          'hours_inactive': hoursSinceLastActivity,
          'last_activity': lastKnownMomentumState,
        },
        actionButtons: [
          NotificationAction(
            id: 'continue',
            title: 'Continue',
            action: 'open_momentum_meter',
          ),
        ],
      );
    }
  }

  /// Generate daily momentum update notification
  NotificationContent getDailyUpdateNotification({
    required String userName,
    required String momentumState,
    required int currentScore,
    required String todayStats,
  }) {
    String stateEmoji;
    String stateMessage;

    switch (momentumState.toLowerCase()) {
      case 'rising':
        stateEmoji = '🚀';
        stateMessage = 'Your momentum is rising! Keep up the amazing work.';
        break;
      case 'steady':
        stateEmoji = '🙂';
        stateMessage =
            'You\'re maintaining steady momentum. Consistency is key!';
        break;
      case 'needs care':
        stateEmoji = '🌱';
        stateMessage =
            'Your momentum needs a little care. Every small step counts!';
        break;
      default:
        stateEmoji = '✨';
        stateMessage = 'Your momentum is unique to you. Keep going!';
    }

    return NotificationContent(
      type: 'daily_update',
      title: 'Daily Momentum Update $stateEmoji',
      body:
          '$userName, $stateMessage ${todayStats.isNotEmpty ? todayStats : ''}',
      data: {
        'action': 'open_momentum_meter',
        'update_type': 'daily',
        'momentum_state': momentumState,
        'score': currentScore,
        'highlight': todayStats,
      },
      actionButtons: [
        NotificationAction(
          id: 'view_momentum',
          title: 'View Momentum',
          action: 'open_momentum_meter',
        ),
      ],
    );
  }

  /// Generate custom notification with personalization
  NotificationContent getCustomNotification({
    required String type,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    List<NotificationAction>? actionButtons,
  }) {
    return NotificationContent(
      type: type,
      title: title,
      body: body,
      data: data,
      actionButtons: actionButtons ?? [],
    );
  }

  /// Get motivational quotes for different momentum states
  String getMotivationalQuote(String momentumState) {
    final quotes = _getQuotesForState(momentumState);
    quotes.shuffle();
    return quotes.first;
  }

  List<String> _getQuotesForState(String state) {
    switch (state.toLowerCase()) {
      case 'rising':
        return [
          'You\'re on fire! Keep up the incredible momentum!',
          'Amazing progress! Your consistency is paying off.',
          'You\'re crushing your goals! Keep it going!',
          'Fantastic work! Your momentum is truly inspiring.',
        ];
      case 'steady':
        return [
          'Steady wins the race! Your consistency is impressive.',
          'You\'re doing great! Small steps lead to big changes.',
          'Keep it up! Consistency is the key to lasting change.',
          'You\'re building strong habits! Well done.',
        ];
      case 'needs_care':
        return [
          'Every journey has its valleys. You\'ve got this!',
          'Small steps count. You\'re stronger than you know.',
          'Growth happens in the valleys too. Keep going!',
          'Your comeback story starts now. We believe in you!',
        ];
      default:
        return [
          'Every step forward matters!',
          'You\'re on a unique journey. Keep going!',
          'Progress isn\'t always linear, and that\'s okay!',
        ];
    }
  }
}

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
