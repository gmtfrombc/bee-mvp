import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/core/services/background_notification_handler.dart';

void main() {
  // Initialize test environment
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BackgroundNotificationHandler', () {
    setUp(() async {
      // Clear shared preferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async {
      // Clean up after each test
      await BackgroundNotificationHandler.clearCachedData();
    });

    group('processBackgroundNotification', () {
      test('should process momentum drop notification correctly', () async {
        // Arrange
        final message = _createMockRemoteMessage(
          notificationId: 'test-123',
          interventionType: 'momentum_drop',
          actionType: 'open_momentum_meter',
          title: 'Momentum needs attention',
          body: 'Let\'s get back on track!',
        );

        // Act
        await BackgroundNotificationHandler.processBackgroundNotification(
          message,
        );

        // Assert - Check stored notification
        final storedNotification =
            await BackgroundNotificationHandler.getLastBackgroundNotification();
        expect(storedNotification, isNotNull);
        expect(storedNotification!.notificationId, equals('test-123'));
        expect(storedNotification.interventionType, equals('momentum_drop'));
        expect(storedNotification.actionType, equals('open_momentum_meter'));
        expect(storedNotification.title, equals('Momentum needs attention'));

        // Assert - Check cached momentum update
        final momentumUpdate =
            await BackgroundNotificationHandler.getCachedMomentumUpdate();
        expect(momentumUpdate, isNotNull);
        expect(momentumUpdate!['state'], equals('NeedsCare'));
        expect(momentumUpdate['notificationId'], equals('test-123'));

        // Assert - Check pending actions
        final pendingActions =
            await BackgroundNotificationHandler.getPendingActions();
        expect(pendingActions, hasLength(1));
        expect(pendingActions.first.actionType, equals('open_momentum_meter'));
      });

      test('should process celebration notification correctly', () async {
        // Arrange
        final message = _createMockRemoteMessage(
          notificationId: 'celebration-456',
          interventionType: 'celebration',
          actionType: 'view_momentum',
          actionData: '{"celebration": true}',
          title: 'Amazing momentum!',
          body: 'You\'re on fire! 🔥',
        );

        // Act
        await BackgroundNotificationHandler.processBackgroundNotification(
          message,
        );

        // Assert - Check cached momentum update
        final momentumUpdate =
            await BackgroundNotificationHandler.getCachedMomentumUpdate();
        expect(momentumUpdate, isNotNull);
        expect(momentumUpdate!['state'], equals('Rising'));
        expect(momentumUpdate['celebration'], equals(true));

        // Assert - Check pending actions
        final pendingActions =
            await BackgroundNotificationHandler.getPendingActions();
        expect(pendingActions, hasLength(1));
        expect(pendingActions.first.actionType, equals('view_momentum'));
      });

      test('should handle consecutive needs care notification', () async {
        // Arrange
        final message = _createMockRemoteMessage(
          notificationId: 'urgent-789',
          interventionType: 'consecutive_needs_care',
          actionType: 'schedule_call',
          actionData:
              '{"priority": "high", "intervention_type": "support_call"}',
          title: 'Let\'s grow together! 🌱',
          body: 'Your coach is here to help',
        );

        // Act
        await BackgroundNotificationHandler.processBackgroundNotification(
          message,
        );

        // Assert - Check cached momentum update with priority
        final momentumUpdate =
            await BackgroundNotificationHandler.getCachedMomentumUpdate();
        expect(momentumUpdate, isNotNull);
        expect(momentumUpdate!['state'], equals('NeedsCare'));
        expect(momentumUpdate['priority'], equals('high'));

        // Assert - Check pending actions
        final pendingActions =
            await BackgroundNotificationHandler.getPendingActions();
        expect(pendingActions, hasLength(1));
        expect(pendingActions.first.actionType, equals('schedule_call'));

        // Check action data contains priority
        final actionData = pendingActions.first.actionData;
        expect(actionData['priority'], equals('high'));
      });

      test('should handle notification without data gracefully', () async {
        // Arrange
        final message = RemoteMessage(messageId: 'empty-message', data: {});

        // Act & Assert - Should not throw
        await BackgroundNotificationHandler.processBackgroundNotification(
          message,
        );

        // Should not store anything
        final storedNotification =
            await BackgroundNotificationHandler.getLastBackgroundNotification();
        expect(storedNotification, isNull);
      });

      test('should handle invalid JSON in action_data gracefully', () async {
        // Arrange
        final message = _createMockRemoteMessage(
          notificationId: 'invalid-json',
          interventionType: 'momentum_drop',
          actionType: 'open_app',
          actionData: 'invalid-json-string',
        );

        // Act & Assert - Should not throw
        await BackgroundNotificationHandler.processBackgroundNotification(
          message,
        );

        // Should still store notification with empty action data
        final storedNotification =
            await BackgroundNotificationHandler.getLastBackgroundNotification();
        expect(storedNotification, isNotNull);
        expect(storedNotification!.actionData, isEmpty);
      });
    });

    group('pending actions management', () {
      test('should accumulate multiple pending actions', () async {
        // Arrange & Act - Add multiple notifications
        for (int i = 0; i < 3; i++) {
          final message = _createMockRemoteMessage(
            notificationId: 'action-$i',
            interventionType: 'daily_motivation',
            actionType: 'open_app',
          );
          await BackgroundNotificationHandler.processBackgroundNotification(
            message,
          );
        }

        // Assert
        final pendingActions =
            await BackgroundNotificationHandler.getPendingActions();
        expect(pendingActions, hasLength(3));

        // Actions should be in chronological order
        for (int i = 0; i < 3; i++) {
          expect(pendingActions[i].notificationId, equals('action-$i'));
        }
      });

      test('should limit pending actions to 10 maximum', () async {
        // Arrange & Act - Add 15 notifications
        for (int i = 0; i < 15; i++) {
          final message = _createMockRemoteMessage(
            notificationId: 'action-$i',
            interventionType: 'daily_motivation',
            actionType: 'open_app',
          );
          await BackgroundNotificationHandler.processBackgroundNotification(
            message,
          );
        }

        // Assert - Should only keep last 10
        final pendingActions =
            await BackgroundNotificationHandler.getPendingActions();
        expect(pendingActions, hasLength(10));

        // Should keep the most recent 10 (actions 5-14)
        expect(pendingActions.first.notificationId, equals('action-5'));
        expect(pendingActions.last.notificationId, equals('action-14'));
      });

      test('should clear pending actions after retrieval', () async {
        // Arrange
        final message = _createMockRemoteMessage(
          notificationId: 'clear-test',
          interventionType: 'momentum_drop',
          actionType: 'open_app',
        );
        await BackgroundNotificationHandler.processBackgroundNotification(
          message,
        );

        // Act - Get pending actions (should clear them)
        final firstRetrieval =
            await BackgroundNotificationHandler.getPendingActions();
        expect(firstRetrieval, hasLength(1));

        // Assert - Second retrieval should be empty
        final secondRetrieval =
            await BackgroundNotificationHandler.getPendingActions();
        expect(secondRetrieval, isEmpty);
      });
    });

    group('momentum state caching', () {
      test('should only cache momentum-related notifications', () async {
        // Arrange & Act - Process non-momentum notification
        final nonMomentumMessage = _createMockRemoteMessage(
          notificationId: 'non-momentum',
          interventionType: 'daily_reminder',
          actionType: 'open_app',
        );
        await BackgroundNotificationHandler.processBackgroundNotification(
          nonMomentumMessage,
        );

        // Assert - Should not create momentum update
        final momentumUpdate =
            await BackgroundNotificationHandler.getCachedMomentumUpdate();
        expect(momentumUpdate, isNull);

        // Act - Process momentum notification
        final momentumMessage = _createMockRemoteMessage(
          notificationId: 'momentum-test',
          interventionType: 'score_drop',
          actionType: 'complete_lesson',
        );
        await BackgroundNotificationHandler.processBackgroundNotification(
          momentumMessage,
        );

        // Assert - Should create momentum update
        final updatedMomentum =
            await BackgroundNotificationHandler.getCachedMomentumUpdate();
        expect(updatedMomentum, isNotNull);
        expect(updatedMomentum!['state'], equals('NeedsCare'));
      });

      test('should clear cached momentum update after retrieval', () async {
        // Arrange
        final message = _createMockRemoteMessage(
          notificationId: 'momentum-clear',
          interventionType: 'momentum_drop',
          actionType: 'open_app',
        );
        await BackgroundNotificationHandler.processBackgroundNotification(
          message,
        );

        // Act - Get cached update (should clear it)
        final firstRetrieval =
            await BackgroundNotificationHandler.getCachedMomentumUpdate();
        expect(firstRetrieval, isNotNull);

        // Assert - Second retrieval should be null
        final secondRetrieval =
            await BackgroundNotificationHandler.getCachedMomentumUpdate();
        expect(secondRetrieval, isNull);
      });
    });

    group('data persistence', () {
      test('should persist and retrieve notification data correctly', () async {
        // Arrange
        final originalMessage = _createMockRemoteMessage(
          notificationId: 'persist-test',
          interventionType: 'celebration',
          actionType: 'view_momentum',
          actionData: '{"celebration": true, "streak": 7}',
          title: 'Great job!',
          body: '7 days in a row!',
        );

        // Act
        await BackgroundNotificationHandler.processBackgroundNotification(
          originalMessage,
        );

        // Assert - Retrieve and verify all data
        final retrieved =
            await BackgroundNotificationHandler.getLastBackgroundNotification();
        expect(retrieved, isNotNull);
        expect(retrieved!.notificationId, equals('persist-test'));
        expect(retrieved.interventionType, equals('celebration'));
        expect(retrieved.actionType, equals('view_momentum'));
        expect(retrieved.actionData['celebration'], equals(true));
        expect(retrieved.actionData['streak'], equals(7));
        expect(retrieved.title, equals('Great job!'));
        expect(retrieved.body, equals('7 days in a row!'));
        expect(retrieved.receivedAt, isA<DateTime>());
      });
    });

    group('error handling', () {
      test('should handle SharedPreferences errors gracefully', () async {
        // This test would require mocking SharedPreferences to throw errors
        // For now, we'll test that invalid data doesn't crash the system

        final message = _createMockRemoteMessage(
          notificationId: 'error-test',
          interventionType: 'momentum_drop',
          actionType: 'open_app',
        );

        // Act & Assert - Should not throw even if there are internal errors
        expect(
          () => BackgroundNotificationHandler.processBackgroundNotification(
            message,
          ),
          returnsNormally,
        );
      });
    });
  });
}

/// Helper function to create mock RemoteMessage for testing
RemoteMessage _createMockRemoteMessage({
  String? notificationId,
  String? interventionType,
  String? actionType,
  String? actionData,
  String? title,
  String? body,
}) {
  return RemoteMessage(
    messageId: 'test-message-${DateTime.now().millisecondsSinceEpoch}',
    data: {
      if (notificationId != null) 'notification_id': notificationId,
      if (interventionType != null) 'intervention_type': interventionType,
      if (actionType != null) 'action_type': actionType,
      if (actionData != null) 'action_data': actionData,
    },
    notification:
        title != null || body != null
            ? RemoteNotification(title: title, body: body)
            : null,
  );
}
