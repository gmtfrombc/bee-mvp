import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/notifications/domain/services/notification_trigger_service.dart';

void main() {
  group('Domain NotificationTriggerService', () {
    // Note: Service instance testing skipped due to Supabase dependency
    // Focus on testing data classes and models

    group('Data Classes', () {
      group('MomentumData', () {
        test('should create MomentumData with all fields', () {
          final data = MomentumData(
            currentState: 'Rising',
            previousState: 'Steady',
            score: 85.5,
            date: '2024-01-01',
          );

          expect(data.currentState, 'Rising');
          expect(data.previousState, 'Steady');
          expect(data.score, 85.5);
          expect(data.date, '2024-01-01');
        });

        test('should create MomentumData without previous state', () {
          final data = MomentumData(
            currentState: 'Rising',
            score: 85.5,
            date: '2024-01-01',
          );

          expect(data.currentState, 'Rising');
          expect(data.previousState, null);
          expect(data.score, 85.5);
          expect(data.date, '2024-01-01');
        });

        test('should convert to JSON correctly', () {
          final data = MomentumData(
            currentState: 'Rising',
            previousState: 'Steady',
            score: 85.5,
            date: '2024-01-01',
          );

          final json = data.toJson();
          expect(json['current_state'], 'Rising');
          expect(json['previous_state'], 'Steady');
          expect(json['score'], 85.5);
          expect(json['date'], '2024-01-01');
        });

        test('should convert to JSON without previous state', () {
          final data = MomentumData(
            currentState: 'Rising',
            score: 85.5,
            date: '2024-01-01',
          );

          final json = data.toJson();
          expect(json['current_state'], 'Rising');
          expect(json.containsKey('previous_state'), false);
          expect(json['score'], 85.5);
          expect(json['date'], '2024-01-01');
        });
      });

      group('TriggerType', () {
        test('should have correct enum values', () {
          expect(TriggerType.momentumChange.value, 'momentum_change');
          expect(TriggerType.dailyCheck.value, 'daily_check');
          expect(TriggerType.manual.value, 'manual');
          expect(TriggerType.batchProcess.value, 'batch_process');
        });

        test('should have correct name property', () {
          expect(TriggerType.momentumChange.name, 'momentum_change');
          expect(TriggerType.dailyCheck.name, 'daily_check');
          expect(TriggerType.manual.name, 'manual');
          expect(TriggerType.batchProcess.name, 'batch_process');
        });
      });

      group('UserTriggerResult', () {
        test('should create from JSON correctly', () {
          final json = {
            'success': true,
            'user_id': 'user123',
            'notifications_sent': 5,
            'interventions_created': 2,
            'error': null,
          };

          final result = UserTriggerResult.fromJson(json);
          expect(result.success, true);
          expect(result.userId, 'user123');
          expect(result.notificationsSent, 5);
          expect(result.interventionsCreated, 2);
          expect(result.error, null);
        });
      });

      group('TriggerSummary', () {
        test('should create from JSON correctly', () {
          final json = {
            'total_users_processed': 100,
            'total_notifications_sent': 250,
            'total_interventions_created': 15,
            'failed_users': 3,
          };

          final summary = TriggerSummary.fromJson(json);
          expect(summary.totalUsersProcessed, 100);
          expect(summary.totalNotificationsSent, 250);
          expect(summary.totalInterventionsCreated, 15);
          expect(summary.failedUsers, 3);
        });
      });

      group('TriggerResult', () {
        test('should create from JSON with complete data', () {
          final json = {
            'success': true,
            'error': null,
            'results': [
              {
                'success': true,
                'user_id': 'user1',
                'notifications_sent': 3,
                'interventions_created': 1,
              },
            ],
            'summary': {
              'total_users_processed': 1,
              'total_notifications_sent': 3,
              'total_interventions_created': 1,
              'failed_users': 0,
            },
          };

          final result = TriggerResult.fromJson(json);
          expect(result.success, true);
          expect(result.error, null);
          expect(result.results.length, 1);
          expect(result.summary, isNotNull);
          expect(result.summary!.totalUsersProcessed, 1);
        });

        test('should handle failure case', () {
          final json = {
            'success': false,
            'error': 'Test error',
            'results': <Map<String, dynamic>>[],
          };

          final result = TriggerResult.fromJson(json);
          expect(result.success, false);
          expect(result.error, 'Test error');
          expect(result.results.isEmpty, true);
          expect(result.summary, null);
        });
      });

      group('NotificationAnalytics', () {
        test('should create from JSON correctly', () {
          final json = {
            'notification_date': '2024-01-01T00:00:00.000Z',
            'notification_type': 'momentum_drop',
            'delivery_status': 'delivered',
            'count': 45,
            'unique_users': 32,
          };

          final analytics = NotificationAnalytics.fromJson(json);
          expect(analytics.notificationDate.year, 2024);
          expect(analytics.notificationDate.month, 1);
          expect(analytics.notificationDate.day, 1);
          expect(analytics.notificationType, 'momentum_drop');
          expect(analytics.deliveryStatus, 'delivered');
          expect(analytics.count, 45);
          expect(analytics.uniqueUsers, 32);
        });
      });

      group('NotificationRecord', () {
        test('should create from JSON correctly', () {
          final json = {
            'id': 'rec123',
            'user_id': 'user123',
            'notification_type': 'momentum_drop',
            'title': 'Test Title',
            'message': 'Test Message',
            'delivery_status': 'delivered',
            'sent_at': '2024-01-01T12:00:00.000Z',
            'created_at': '2024-01-01T11:30:00.000Z',
          };

          final record = NotificationRecord.fromJson(json);
          expect(record.id, 'rec123');
          expect(record.userId, 'user123');
          expect(record.notificationType, 'momentum_drop');
          expect(record.title, 'Test Title');
          expect(record.message, 'Test Message');
          expect(record.deliveryStatus, 'delivered');
          expect(record.sentAt, isNotNull);
          expect(record.createdAt.year, 2024);
        });
      });

      group('NotificationPreferences', () {
        test('should create with all preferences', () {
          final prefs = NotificationPreferences(
            dailyMotivationEnabled: true,
            celebrationEnabled: true,
            supportRemindersEnabled: false,
            coachInterventionEnabled: true,
            quietHoursStart: '22:00',
            quietHoursEnd: '08:00',
            timezone: 'America/New_York',
          );

          expect(prefs.dailyMotivationEnabled, true);
          expect(prefs.celebrationEnabled, true);
          expect(prefs.supportRemindersEnabled, false);
          expect(prefs.coachInterventionEnabled, true);
          expect(prefs.quietHoursStart, '22:00');
          expect(prefs.quietHoursEnd, '08:00');
          expect(prefs.timezone, 'America/New_York');
        });

        test('should create from JSON correctly', () {
          final json = {
            'daily_motivation_enabled': true,
            'celebration_enabled': false,
            'support_reminders_enabled': true,
            'coach_intervention_enabled': false,
            'quiet_hours_start': '23:00',
            'quiet_hours_end': '07:00',
            'timezone': 'UTC',
          };

          final prefs = NotificationPreferences.fromJson(json);
          expect(prefs.dailyMotivationEnabled, true);
          expect(prefs.celebrationEnabled, false);
          expect(prefs.supportRemindersEnabled, true);
          expect(prefs.coachInterventionEnabled, false);
          expect(prefs.quietHoursStart, '23:00');
          expect(prefs.quietHoursEnd, '07:00');
          expect(prefs.timezone, 'UTC');
        });

        test('should create default preferences', () {
          final prefs = NotificationPreferences.defaultPreferences();
          expect(prefs.dailyMotivationEnabled, true);
          expect(prefs.celebrationEnabled, true);
          expect(prefs.supportRemindersEnabled, true);
          expect(prefs.coachInterventionEnabled, true);
          expect(prefs.quietHoursStart, '22:00');
          expect(prefs.quietHoursEnd, '08:00');
          expect(prefs.timezone, DateTime.now().timeZoneName);
        });

        test('should convert to JSON correctly', () {
          final prefs = NotificationPreferences(
            dailyMotivationEnabled: false,
            celebrationEnabled: true,
            supportRemindersEnabled: false,
            coachInterventionEnabled: true,
            quietHoursStart: '21:30',
            quietHoursEnd: '09:00',
            timezone: 'America/Los_Angeles',
          );

          final json = prefs.toJson();
          expect(json['daily_motivation_enabled'], false);
          expect(json['celebration_enabled'], true);
          expect(json['support_reminders_enabled'], false);
          expect(json['coach_intervention_enabled'], true);
          expect(json['quiet_hours_start'], '21:30');
          expect(json['quiet_hours_end'], '09:00');
          expect(json['timezone'], 'America/Los_Angeles');
        });
      });
    });
  });
}
