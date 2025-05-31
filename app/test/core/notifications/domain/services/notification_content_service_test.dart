import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/notifications/domain/services/notification_content_service.dart';
import 'package:app/core/notifications/domain/models/notification_models.dart';

void main() {
  group('Domain NotificationContentService', () {
    late NotificationContentService service;

    setUp(() {
      service = NotificationContentService.instance;
    });

    test('should create singleton instance correctly', () {
      expect(service, isNotNull);
      expect(NotificationContentService.instance, equals(service));
    });

    group('getMomentumDropNotification', () {
      test('should generate severe drop notification for score drop >= 25', () {
        final notification = service.getMomentumDropNotification(
          userName: 'Alex',
          previousScore: 80,
          currentScore: 50,
          daysSinceLastActivity: 3,
        );

        expect(notification.type, 'momentum_drop_severe');
        expect(notification.title, contains('We\'re here to help!'));
        expect(notification.body, contains('Alex'));
        expect(notification.data['priority'], 'high');
        expect(notification.data['score_drop'], 30);
        expect(notification.actionButtons.length, 2);
        expect(notification.actionButtons[0].action, 'open_quick_start');
        expect(notification.actionButtons[1].action, 'schedule_coach_call');
      });

      test(
        'should generate moderate drop notification for score drop >= 15',
        () {
          final notification = service.getMomentumDropNotification(
            userName: 'Sam',
            previousScore: 75,
            currentScore: 55,
            daysSinceLastActivity: 2,
          );

          expect(notification.type, 'momentum_drop_moderate');
          expect(notification.title, contains('You\'ve got this!'));
          expect(notification.body, contains('Sam'));
          expect(notification.data['priority'], 'medium');
          expect(notification.data['score_drop'], 20);
          expect(notification.actionButtons.length, 2);
        },
      );

      test(
        'should generate gentle drop notification for small score drops',
        () {
          final notification = service.getMomentumDropNotification(
            userName: 'Jordan',
            previousScore: 70,
            currentScore: 60,
            daysSinceLastActivity: 1,
          );

          expect(notification.type, 'momentum_drop_gentle');
          expect(notification.title, contains('Ready for a fresh start?'));
          expect(notification.body, contains('Jordan'));
          expect(notification.data['priority'], 'low');
          expect(notification.data['score_drop'], 10);
          expect(notification.actionButtons.length, 1);
        },
      );
    });

    group('getCoachInterventionNotification', () {
      test('should generate coach intervention notification', () {
        final notification = service.getCoachInterventionNotification(
          userName: 'Taylor',
          coachName: 'Dr. Smith',
          consecutiveDaysInNeedsCare: 3,
        );

        expect(notification.type, 'coach_intervention');
        expect(notification.title, contains('Dr. Smith wants to connect'));
        expect(notification.body, contains('Taylor'));
        expect(notification.data['priority'], 'high');
        expect(notification.data['coach_name'], 'Dr. Smith');
        expect(notification.data['consecutive_days'], 3);
        expect(notification.actionButtons.length, 2);
        expect(notification.actionButtons[0].action, 'schedule_coach_call');
        expect(notification.actionButtons[1].action, 'open_coach_chat');
      });
    });

    group('getCelebrationNotification', () {
      test('should generate weekly streak celebration for 7+ days', () {
        final notification = service.getCelebrationNotification(
          userName: 'Casey',
          consecutiveGoodDays: 10,
          achievementType: 'weekly_streak',
        );

        expect(notification.type, 'celebration_weekly_streak');
        expect(notification.title, contains('Amazing momentum!'));
        expect(notification.body, contains('Casey'));
        expect(notification.body, contains('10 days'));
        expect(notification.data['celebration_type'], 'weekly_streak');
        expect(notification.data['streak_days'], 10);
        expect(notification.actionButtons.length, 2);
      });

      test('should generate streak celebration for 5-6 days', () {
        final notification = service.getCelebrationNotification(
          userName: 'Morgan',
          consecutiveGoodDays: 5,
          achievementType: 'streak',
        );

        expect(notification.type, 'celebration_streak');
        expect(notification.title, contains('You\'re on a roll!'));
        expect(notification.body, contains('Morgan'));
        expect(notification.body, contains('5 days'));
        expect(notification.data['celebration_type'], 'streak');
        expect(notification.actionButtons.length, 1);
      });

      test('should generate milestone celebration for shorter streaks', () {
        final notification = service.getCelebrationNotification(
          userName: 'Riley',
          consecutiveGoodDays: 2,
          achievementType: 'daily',
        );

        expect(notification.type, 'celebration_milestone');
        expect(notification.title, contains('Great work today!'));
        expect(notification.body, contains('Riley'));
        expect(notification.data['celebration_type'], 'daily');
        expect(notification.actionButtons.length, 1);
      });
    });

    group('getEngagementReminderNotification', () {
      test('should generate gentle reminder for 72+ hours inactive', () {
        final notification = service.getEngagementReminderNotification(
          userName: 'Avery',
          hoursSinceLastActivity: 80,
          lastKnownMomentumState: 'Steady',
        );

        expect(notification.type, 'engagement_reminder_gentle');
        expect(notification.title, contains('We miss you!'));
        expect(notification.body, contains('Avery'));
        expect(notification.data['reminder_type'], 'gentle_check_in');
        expect(notification.data['hours_inactive'], 80);
        expect(notification.actionButtons.length, 1);
      });

      test('should generate supportive reminder for 48+ hours inactive', () {
        final notification = service.getEngagementReminderNotification(
          userName: 'Quinn',
          hoursSinceLastActivity: 50,
          lastKnownMomentumState: 'Needs Care',
        );

        expect(notification.type, 'engagement_reminder_supportive');
        expect(notification.title, contains('Your momentum is waiting!'));
        expect(notification.body, contains('Quinn'));
        expect(notification.data['reminder_type'], 'supportive');
        expect(notification.actionButtons.length, 2);
      });

      test('should generate encouraging reminder for less than 48 hours', () {
        final notification = service.getEngagementReminderNotification(
          userName: 'Dakota',
          hoursSinceLastActivity: 30,
          lastKnownMomentumState: 'Rising',
        );

        expect(notification.type, 'engagement_reminder_encouraging');
        expect(notification.title, contains('Ready to continue?'));
        expect(notification.body, contains('Dakota'));
        expect(notification.data['reminder_type'], 'encouraging');
        expect(notification.actionButtons.length, 1);
      });
    });

    group('getDailyUpdateNotification', () {
      test('should generate Rising state daily update', () {
        final notification = service.getDailyUpdateNotification(
          userName: 'Phoenix',
          momentumState: 'Rising',
          currentScore: 85,
          todayStats: 'Completed 3 lessons today!',
        );

        expect(notification.type, 'daily_update');
        expect(notification.title, contains('Daily Momentum Update 🚀'));
        expect(notification.body, contains('Phoenix'));
        expect(notification.body, contains('momentum is rising'));
        expect(notification.body, contains('Completed 3 lessons today!'));
        expect(notification.data['momentum_state'], 'Rising');
        expect(notification.data['score'], 85);
        expect(notification.actionButtons.length, 1);
      });

      test('should generate Steady state daily update', () {
        final notification = service.getDailyUpdateNotification(
          userName: 'River',
          momentumState: 'Steady',
          currentScore: 65,
          todayStats: 'Great consistency!',
        );

        expect(notification.type, 'daily_update');
        expect(notification.title, contains('Daily Momentum Update 🙂'));
        expect(notification.body, contains('River'));
        expect(notification.body, contains('maintaining steady momentum'));
        expect(notification.data['momentum_state'], 'Steady');
        expect(notification.data['score'], 65);
      });

      test('should generate Needs Care state daily update', () {
        final notification = service.getDailyUpdateNotification(
          userName: 'Sage',
          momentumState: 'Needs Care',
          currentScore: 35,
          todayStats: '',
        );

        expect(notification.type, 'daily_update');
        expect(notification.title, contains('Daily Momentum Update 🌱'));
        expect(notification.body, contains('Sage'));
        expect(notification.body, contains('needs a little care'));
        expect(notification.data['momentum_state'], 'Needs Care');
        expect(notification.data['score'], 35);
      });
    });

    group('getCustomNotification', () {
      test('should create custom notification with all fields', () {
        final notification = service.getCustomNotification(
          type: 'custom_test',
          title: 'Test Title',
          body: 'Test body message',
          data: {'key': 'value', 'number': 42},
          actionButtons: [
            NotificationAction(
              id: 'test_action',
              title: 'Test Action',
              action: 'test_tap',
            ),
          ],
        );

        expect(notification.type, 'custom_test');
        expect(notification.title, 'Test Title');
        expect(notification.body, 'Test body message');
        expect(notification.data['key'], 'value');
        expect(notification.data['number'], 42);
        expect(notification.actionButtons.length, 1);
        expect(notification.actionButtons.first.id, 'test_action');
      });

      test('should create custom notification without action buttons', () {
        final notification = service.getCustomNotification(
          type: 'simple_test',
          title: 'Simple Test',
          body: 'Simple message',
          data: {'simple': true},
        );

        expect(notification.type, 'simple_test');
        expect(notification.actionButtons.isEmpty, true);
      });
    });

    group('getMotivationalQuote', () {
      test('should return rising state quote', () {
        final quote = service.getMotivationalQuote('rising');
        expect(quote, isNotEmpty);
        expect(quote, isA<String>());
      });

      test('should return steady state quote', () {
        final quote = service.getMotivationalQuote('steady');
        expect(quote, isNotEmpty);
        expect(quote, isA<String>());
      });

      test('should return needs care state quote', () {
        final quote = service.getMotivationalQuote('needs_care');
        expect(quote, isNotEmpty);
        expect(quote, isA<String>());
      });

      test('should return default quote for unknown state', () {
        final quote = service.getMotivationalQuote('unknown_state');
        expect(quote, isNotEmpty);
        expect(quote, isA<String>());
      });

      test('should return different quotes on multiple calls', () {
        final quotes = <String>{};
        for (int i = 0; i < 10; i++) {
          quotes.add(service.getMotivationalQuote('rising'));
        }
        // Should have some variety in quotes (randomization working)
        expect(quotes.length, greaterThan(1));
      });
    });

    group('NotificationAction', () {
      test('should create action with metadata', () {
        final action = NotificationAction(
          id: 'test_id',
          title: 'Test Title',
          action: 'test_action',
          metadata: {'extra': 'data'},
        );

        expect(action.id, 'test_id');
        expect(action.title, 'Test Title');
        expect(action.action, 'test_action');
        expect(action.metadata!['extra'], 'data');
      });

      test('should convert to map correctly', () {
        final action = NotificationAction(
          id: 'test',
          title: 'Test',
          action: 'tap',
          metadata: {'key': 'value'},
        );

        final map = action.toMap();
        expect(map['id'], 'test');
        expect(map['title'], 'Test');
        expect(map['action'], 'tap');
        expect(map['metadata']['key'], 'value');
      });
    });

    group('NotificationContent', () {
      test('should convert to FCM payload correctly', () {
        final content = NotificationContent(
          type: 'test',
          title: 'Test Title',
          body: 'Test Body',
          data: {'key': 'value'},
          actionButtons: [
            NotificationAction(id: 'action1', title: 'Action', action: 'tap'),
          ],
        );

        final payload = content.toFCMPayload();
        expect(payload['notification']['title'], 'Test Title');
        expect(payload['notification']['body'], 'Test Body');
        expect(payload['data']['type'], 'test');
        expect(payload['data']['key'], 'value');
        expect(payload['data']['actions'], isA<List>());
      });

      test('should convert to local notification payload correctly', () {
        final content = NotificationContent(
          type: 'test',
          title: 'Test Title',
          body: 'Test Body',
          data: {'key': 'value'},
        );

        final payload = content.toLocalNotificationPayload();
        expect(payload['title'], 'Test Title');
        expect(payload['body'], 'Test Body');
        expect(payload['payload']['type'], 'test');
        expect(payload['payload']['key'], 'value');
      });
    });
  });
}
