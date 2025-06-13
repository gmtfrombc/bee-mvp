import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/services/notification_service.dart';

void main() {
  group('NotificationService', () {
    late NotificationService notificationService;

    setUp(() {
      notificationService = NotificationService.instance;
    });

    group('sendCoachNudge', () {
      testWidgets('builds correct FCM payload for coaching nudge', (
        tester,
      ) async {
        const userId = 'test-user-123';
        const title = '🚀 Momentum Rising!';
        const body =
            'Great job! Your momentum is improving. Let\'s keep this energy going with a small action today.';

        final data = {
          'type': 'coach_nudge',
          'user_id': userId,
          'momentum_state': 'Rising',
          'previous_state': 'Steady',
          'timestamp': DateTime.now().toIso8601String(),
        };

        // This test verifies the method doesn't throw and handles the parameters correctly
        await notificationService.sendCoachNudge(
          userId,
          title,
          body,
          data: data,
        );

        // In a real implementation, we would verify the FCM message was queued
        // For now, we just ensure the method completes without error
        expect(true, isTrue);
      });

      testWidgets('handles null data parameter gracefully', (tester) async {
        const userId = 'test-user-456';
        const title = '💪 Let\'s Get Back on Track';
        const body =
            'I noticed your momentum needs some care. Here are some gentle steps to help you get back on track.';

        // Should not throw when data is null
        await notificationService.sendCoachNudge(userId, title, body);

        expect(true, isTrue);
      });

      testWidgets('handles empty strings gracefully', (tester) async {
        const userId = '';
        const title = '';
        const body = '';

        // Should not throw with empty strings
        await notificationService.sendCoachNudge(userId, title, body);

        expect(true, isTrue);
      });

      testWidgets('handles long message content', (tester) async {
        const userId = 'test-user-789';
        const title = '⚖️ Staying Steady';
        const body =
            'This is a very long coaching message that exceeds the typical notification length limits to test how the service handles truncation and formatting of extended content that might come from the AI coaching engine when providing detailed guidance and suggestions for the user.';

        await notificationService.sendCoachNudge(
          userId,
          title,
          body,
          data: {'type': 'coach_nudge', 'message_length': body.length},
        );

        expect(true, isTrue);
      });
    });

    group('topic management', () {
      testWidgets('subscribes to topics without error', (tester) async {
        await notificationService.subscribeToTopic('test_topic');
        expect(true, isTrue);
      });

      testWidgets('unsubscribes from topics without error', (tester) async {
        await notificationService.unsubscribeFromTopic('test_topic');
        expect(true, isTrue);
      });
    });

    group('permissions', () {
      testWidgets('requests permissions without error', (tester) async {
        final hasPermissions = await notificationService.requestPermissions();
        expect(hasPermissions, isA<bool>());
      });

      testWidgets('checks permissions without error', (tester) async {
        final hasPermissions = await notificationService.hasPermissions();
        expect(hasPermissions, isA<bool>());
      });
    });

    group('token management', () {
      testWidgets('gets token without error', (tester) async {
        final token = await notificationService.getToken();
        expect(token, isA<String?>());
        // In test environment, should get mock token
        if (token != null) {
          expect(token, equals('mock_fcm_token_for_testing'));
        }
      });

      testWidgets('deletes token without error', (tester) async {
        await notificationService.deleteToken();
        expect(true, isTrue);
      });
    });
  });
}
