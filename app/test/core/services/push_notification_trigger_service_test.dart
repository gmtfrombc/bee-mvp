import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/push_notification_trigger_service.dart';

void main() {
  group('PushNotificationTriggerService Data Classes', () {
    group('MomentumData', () {
      test('should serialize to JSON correctly', () {
        // Arrange
        final momentumData = MomentumData(
          currentState: 'Rising',
          previousState: 'Steady',
          score: 85.0,
          date: '2024-12-20',
        );

        // Act
        final json = momentumData.toJson();

        // Assert
        expect(
          json,
          equals({
            'current_state': 'Rising',
            'previous_state': 'Steady',
            'score': 85.0,
            'date': '2024-12-20',
          }),
        );
      });

      test('should serialize without previous state', () {
        // Arrange
        final momentumData = MomentumData(
          currentState: 'Rising',
          score: 85.0,
          date: '2024-12-20',
        );

        // Act
        final json = momentumData.toJson();

        // Assert
        expect(
          json,
          equals({
            'current_state': 'Rising',
            'score': 85.0,
            'date': '2024-12-20',
          }),
        );
        expect(json.containsKey('previous_state'), isFalse);
      });
    });

    group('TriggerResult', () {
      test('should deserialize from JSON correctly', () {
        // Arrange
        final json = {
          'success': true,
          'results': [
            {
              'success': true,
              'user_id': 'user1',
              'notifications_sent': 2,
              'interventions_created': 1,
            },
          ],
          'summary': {
            'total_users_processed': 1,
            'total_notifications_sent': 2,
            'total_interventions_created': 1,
            'failed_users': 0,
          },
        };

        // Act
        final result = TriggerResult.fromJson(json);

        // Assert
        expect(result.success, isTrue);
        expect(result.results.length, equals(1));
        expect(result.results.first.success, isTrue);
        expect(result.results.first.userId, equals('user1'));
        expect(result.results.first.notificationsSent, equals(2));
        expect(result.results.first.interventionsCreated, equals(1));
        expect(result.summary?.totalUsersProcessed, equals(1));
        expect(result.summary?.totalNotificationsSent, equals(2));
        expect(result.summary?.totalInterventionsCreated, equals(1));
        expect(result.summary?.failedUsers, equals(0));
      });

      test('should handle error response', () {
        // Arrange
        final json = {
          'success': false,
          'error': 'Something went wrong',
          'results': [],
        };

        // Act
        final result = TriggerResult.fromJson(json);

        // Assert
        expect(result.success, isFalse);
        expect(result.error, equals('Something went wrong'));
        expect(result.results, isEmpty);
      });
    });

    group('UserTriggerResult', () {
      test('should deserialize from JSON correctly', () {
        // Arrange
        final json = {
          'success': true,
          'user_id': 'test-user',
          'notifications_sent': 3,
          'interventions_created': 2,
        };

        // Act
        final result = UserTriggerResult.fromJson(json);

        // Assert
        expect(result.success, isTrue);
        expect(result.userId, equals('test-user'));
        expect(result.notificationsSent, equals(3));
        expect(result.interventionsCreated, equals(2));
        expect(result.error, isNull);
      });

      test('should handle error in user result', () {
        // Arrange
        final json = {
          'success': false,
          'user_id': 'test-user',
          'notifications_sent': 0,
          'interventions_created': 0,
          'error': 'User not found',
        };

        // Act
        final result = UserTriggerResult.fromJson(json);

        // Assert
        expect(result.success, isFalse);
        expect(result.userId, equals('test-user'));
        expect(result.notificationsSent, equals(0));
        expect(result.interventionsCreated, equals(0));
        expect(result.error, equals('User not found'));
      });
    });

    group('NotificationPreferences', () {
      test('should create default preferences', () {
        // Act
        final preferences = NotificationPreferences.defaultPreferences();

        // Assert
        expect(preferences.dailyMotivationEnabled, isTrue);
        expect(preferences.celebrationEnabled, isTrue);
        expect(preferences.supportRemindersEnabled, isTrue);
        expect(preferences.coachInterventionEnabled, isTrue);
        expect(preferences.quietHoursStart, equals('22:00'));
        expect(preferences.quietHoursEnd, equals('08:00'));
        expect(preferences.timezone, isNotNull);
      });

      test('should serialize to JSON correctly', () {
        // Arrange
        final preferences = NotificationPreferences(
          dailyMotivationEnabled: true,
          celebrationEnabled: false,
          supportRemindersEnabled: true,
          coachInterventionEnabled: false,
          quietHoursStart: '23:00',
          quietHoursEnd: '07:00',
          timezone: 'UTC',
        );

        // Act
        final json = preferences.toJson();

        // Assert
        expect(
          json,
          equals({
            'daily_motivation_enabled': true,
            'celebration_enabled': false,
            'support_reminders_enabled': true,
            'coach_intervention_enabled': false,
            'quiet_hours_start': '23:00',
            'quiet_hours_end': '07:00',
            'timezone': 'UTC',
          }),
        );
      });

      test('should deserialize from JSON correctly', () {
        // Arrange
        final json = {
          'daily_motivation_enabled': false,
          'celebration_enabled': true,
          'support_reminders_enabled': false,
          'coach_intervention_enabled': true,
          'quiet_hours_start': '21:00',
          'quiet_hours_end': '06:00',
          'timezone': 'EST',
        };

        // Act
        final preferences = NotificationPreferences.fromJson(json);

        // Assert
        expect(preferences.dailyMotivationEnabled, isFalse);
        expect(preferences.celebrationEnabled, isTrue);
        expect(preferences.supportRemindersEnabled, isFalse);
        expect(preferences.coachInterventionEnabled, isTrue);
        expect(preferences.quietHoursStart, equals('21:00'));
        expect(preferences.quietHoursEnd, equals('06:00'));
        expect(preferences.timezone, equals('EST'));
      });
    });

    group('NotificationAnalytics', () {
      test('should deserialize from JSON correctly', () {
        // Arrange
        final json = {
          'notification_date': '2024-12-20',
          'notification_type': 'daily_motivation',
          'delivery_status': 'sent',
          'count': 150,
          'unique_users': 75,
        };

        // Act
        final analytics = NotificationAnalytics.fromJson(json);

        // Assert
        expect(
          analytics.notificationDate,
          equals(DateTime.parse('2024-12-20')),
        );
        expect(analytics.notificationType, equals('daily_motivation'));
        expect(analytics.deliveryStatus, equals('sent'));
        expect(analytics.count, equals(150));
        expect(analytics.uniqueUsers, equals(75));
      });
    });

    group('NotificationRecord', () {
      test('should deserialize from JSON correctly', () {
        // Arrange
        final json = {
          'id': 'notif-123',
          'user_id': 'user-456',
          'notification_type': 'celebration',
          'title': 'Great job!',
          'message': 'You are doing amazing!',
          'delivery_status': 'sent',
          'created_at': '2024-12-20T10:00:00Z',
          'sent_at': '2024-12-20T10:01:00Z',
        };

        // Act
        final record = NotificationRecord.fromJson(json);

        // Assert
        expect(record.id, equals('notif-123'));
        expect(record.userId, equals('user-456'));
        expect(record.notificationType, equals('celebration'));
        expect(record.title, equals('Great job!'));
        expect(record.message, equals('You are doing amazing!'));
        expect(record.deliveryStatus, equals('sent'));
        expect(
          record.createdAt,
          equals(DateTime.parse('2024-12-20T10:00:00Z')),
        );
        expect(record.sentAt, equals(DateTime.parse('2024-12-20T10:01:00Z')));
        expect(record.errorMessage, isNull);
      });

      test('should handle failed notification', () {
        // Arrange
        final json = {
          'id': 'notif-123',
          'user_id': 'user-456',
          'notification_type': 'daily_motivation',
          'title': 'Keep going!',
          'message': 'You can do this!',
          'delivery_status': 'failed',
          'created_at': '2024-12-20T10:00:00Z',
          'error_message': 'Invalid FCM token',
        };

        // Act
        final record = NotificationRecord.fromJson(json);

        // Assert
        expect(record.id, equals('notif-123'));
        expect(record.deliveryStatus, equals('failed'));
        expect(record.sentAt, isNull);
        expect(record.errorMessage, equals('Invalid FCM token'));
      });
    });

    group('TriggerType', () {
      test('should have correct string values', () {
        expect(TriggerType.momentumChange.name, equals('momentum_change'));
        expect(TriggerType.dailyCheck.name, equals('daily_check'));
        expect(TriggerType.manual.name, equals('manual'));
        expect(TriggerType.batchProcess.name, equals('batch_process'));
      });

      test('should have correct value properties', () {
        expect(TriggerType.momentumChange.value, equals('momentum_change'));
        expect(TriggerType.dailyCheck.value, equals('daily_check'));
        expect(TriggerType.manual.value, equals('manual'));
        expect(TriggerType.batchProcess.value, equals('batch_process'));
      });
    });

    group('TriggerSummary', () {
      test('should deserialize from JSON correctly', () {
        // Arrange
        final json = {
          'total_users_processed': 100,
          'total_notifications_sent': 250,
          'total_interventions_created': 15,
          'failed_users': 3,
        };

        // Act
        final summary = TriggerSummary.fromJson(json);

        // Assert
        expect(summary.totalUsersProcessed, equals(100));
        expect(summary.totalNotificationsSent, equals(250));
        expect(summary.totalInterventionsCreated, equals(15));
        expect(summary.failedUsers, equals(3));
      });
    });
  });
}
