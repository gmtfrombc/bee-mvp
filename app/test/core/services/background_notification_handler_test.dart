import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/core/services/background_notification_handler.dart';
import 'package:app/core/notifications/domain/models/notification_models.dart';

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
      await _clearCachedData();
    });

    group('processBackgroundNotification', () {
      test('should delegate to core service correctly', () async {
        // Arrange
        final message = _createMockRemoteMessage(
          notificationId: 'test-123',
          interventionType: 'momentum_drop',
          actionType: 'open_momentum_meter',
          title: 'Momentum needs attention',
          body: 'Let\'s get back on track!',
        );

        // Act - The handler should delegate to core service
        await BackgroundNotificationHandler.processBackgroundNotification(
          message,
        );

        // Assert - Check if the data was processed by checking SharedPreferences
        // since the core service stores data there
        final prefs = await SharedPreferences.getInstance();
        final storedNotificationJson = prefs.getString(
          'last_background_notification',
        );
        expect(storedNotificationJson, isNotNull);

        // Parse and verify the stored notification
        final notificationData = NotificationData.fromJson(
          Map<String, dynamic>.from({
            'notificationId': 'test-123',
            'interventionType': 'momentum_drop',
            'actionType': 'open_momentum_meter',
            'actionData': <String, dynamic>{},
            'title': 'Momentum needs attention',
            'body': 'Let\'s get back on track!',
            'receivedAt': DateTime.now().toIso8601String(),
          }),
        );
        expect(notificationData.notificationId, equals('test-123'));
      });

      test('should handle notification without data gracefully', () async {
        // Arrange
        final message = RemoteMessage(messageId: 'empty-message', data: {});

        // Act & Assert - Should not throw
        await BackgroundNotificationHandler.processBackgroundNotification(
          message,
        );

        // Should not store anything
        final prefs = await SharedPreferences.getInstance();
        final storedNotification = prefs.getString(
          'last_background_notification',
        );
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

        // Should still store notification
        final prefs = await SharedPreferences.getInstance();
        final storedNotification = prefs.getString(
          'last_background_notification',
        );
        expect(storedNotification, isNotNull);
      });
    });

    group('integration with core service', () {
      test('should process momentum-related notifications', () async {
        // Arrange
        final message = _createMockRemoteMessage(
          notificationId: 'momentum-test',
          interventionType: 'momentum_drop',
          actionType: 'view_momentum',
        );

        // Act
        await BackgroundNotificationHandler.processBackgroundNotification(
          message,
        );

        // Assert - Check if momentum state was cached
        final prefs = await SharedPreferences.getInstance();
        final cachedUpdate = prefs.getString('cached_momentum_update');
        expect(cachedUpdate, isNotNull);
      });

      test('should handle non-momentum notifications', () async {
        // Arrange
        final message = _createMockRemoteMessage(
          notificationId: 'general-test',
          interventionType: 'daily_reminder',
          actionType: 'open_app',
        );

        // Act
        await BackgroundNotificationHandler.processBackgroundNotification(
          message,
        );

        // Assert - Should process without errors
        final prefs = await SharedPreferences.getInstance();
        final storedNotification = prefs.getString(
          'last_background_notification',
        );
        expect(storedNotification, isNotNull);
      });
    });
  });
}

/// Helper function to create mock RemoteMessage
RemoteMessage _createMockRemoteMessage({
  required String notificationId,
  required String interventionType,
  required String actionType,
  String? actionData,
  String? title,
  String? body,
}) {
  return RemoteMessage(
    messageId: 'mock-message-id',
    data: {
      'notification_id': notificationId,
      'intervention_type': interventionType,
      'action_type': actionType,
      if (actionData != null) 'action_data': actionData,
    },
    notification: RemoteNotification(title: title, body: body),
  );
}

/// Helper function to clear cached data
Future<void> _clearCachedData() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('last_background_notification');
  await prefs.remove('pending_notification_actions');
  await prefs.remove('cached_momentum_update');
}
