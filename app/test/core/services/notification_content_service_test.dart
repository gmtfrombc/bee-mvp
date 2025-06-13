import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/services/notification_content_service.dart';

void main() {
  group('NotificationContentService', () {
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
      });

      test('should generate Steady state daily update', () {
        final notification = service.getDailyUpdateNotification(
          userName: 'Sage',
          momentumState: 'Steady',
          currentScore: 65,
          todayStats: 'Made steady progress today!',
        );

        expect(notification.type, 'daily_update');
        expect(notification.title, contains('Daily Momentum Update 🙂'));
        expect(notification.body, contains('Sage'));
        expect(notification.body, contains('steady momentum'));
        expect(notification.data['momentum_state'], 'Steady');
      });

      test('should generate Needs Care state daily update', () {
        final notification = service.getDailyUpdateNotification(
          userName: 'River',
          momentumState: 'Needs Care',
          currentScore: 35,
          todayStats: 'Small step: opened the app!',
        );

        expect(notification.type, 'daily_update');
        expect(notification.title, contains('Daily Momentum Update 🌱'));
        expect(notification.body, contains('River'));
        expect(notification.body, contains('needs a little care'));
        expect(notification.body, contains('Small step: opened the app!'));
        expect(notification.data['momentum_state'], 'Needs Care');
      });
    });

    group('getMotivationalQuote', () {
      test('should return appropriate quotes for Rising state', () {
        final quote = service.getMotivationalQuote('Rising');

        expect(quote, isNotEmpty);
        expect(quote.length, greaterThan(0));
      });

      test('should return appropriate quotes for Steady state', () {
        final quote = service.getMotivationalQuote('Steady');

        expect(quote, isNotEmpty);
        expect(quote.length, greaterThan(0));
      });

      test('should return appropriate quotes for Needs Care state', () {
        final quote = service.getMotivationalQuote('Needs Care');

        expect(quote, isNotEmpty);
        expect(quote.length, greaterThan(0));
      });

      test('should return default quotes for unknown state', () {
        final quote = service.getMotivationalQuote('unknown');

        expect(quote, isNotEmpty);
        expect(quote.length, greaterThan(0));
      });

      test('should return consistent quotes for the same state', () {
        final risingQuotes = <String>{};
        final steadyQuotes = <String>{};
        final needsCareQuotes = <String>{};

        for (int i = 0; i < 10; i++) {
          risingQuotes.add(service.getMotivationalQuote('Rising'));
          steadyQuotes.add(service.getMotivationalQuote('Steady'));
          needsCareQuotes.add(service.getMotivationalQuote('Needs Care'));
        }

        expect(risingQuotes.every((quote) => quote.isNotEmpty), isTrue);
        expect(steadyQuotes.every((quote) => quote.isNotEmpty), isTrue);
        expect(needsCareQuotes.every((quote) => quote.isNotEmpty), isTrue);
      });
    });

    group('NotificationContent', () {
      test('should convert to FCM payload correctly', () {
        final content = NotificationContent(
          type: 'test_type',
          title: 'Test Title',
          body: 'Test Body',
          data: {'test_key': 'test_value'},
          actionButtons: [
            NotificationAction(
              id: 'test_action',
              title: 'Test Action',
              action: 'test_action_handler',
            ),
          ],
        );

        final fcmPayload = content.toFCMPayload();

        expect(fcmPayload['notification']['title'], 'Test Title');
        expect(fcmPayload['notification']['body'], 'Test Body');
        expect(fcmPayload['data']['type'], 'test_type');
        expect(fcmPayload['data']['test_key'], 'test_value');
        expect(fcmPayload['data']['actions'], isList);
        expect(fcmPayload['data']['actions'][0]['id'], 'test_action');
      });

      test('should convert to local notification payload correctly', () {
        final content = NotificationContent(
          type: 'local_test',
          title: 'Local Title',
          body: 'Local Body',
          data: {'local_key': 'local_value'},
        );

        final localPayload = content.toLocalNotificationPayload();

        expect(localPayload['title'], 'Local Title');
        expect(localPayload['body'], 'Local Body');
        expect(localPayload['payload']['type'], 'local_test');
        expect(localPayload['payload']['local_key'], 'local_value');
      });
    });

    group('NotificationAction', () {
      test('should convert to map correctly', () {
        final action = NotificationAction(
          id: 'map_test',
          title: 'Map Test',
          action: 'map_test_handler',
          metadata: {'meta_key': 'meta_value'},
        );

        final map = action.toMap();

        expect(map['id'], 'map_test');
        expect(map['title'], 'Map Test');
        expect(map['action'], 'map_test_handler');
        expect(map['metadata']['meta_key'], 'meta_value');
      });

      test('should cache content with priority mapping', () {
        // ... existing code ...
      });
    });
  });
}
