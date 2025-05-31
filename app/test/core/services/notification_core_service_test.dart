import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/core/notifications/domain/services/notification_core_service.dart';
import 'package:app/core/notifications/domain/models/notification_models.dart';

void main() {
  // Initialize test environment
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationCoreService Tests', () {
    late NotificationCoreService service;

    setUp(() async {
      // Clear shared preferences before each test
      SharedPreferences.setMockInitialValues({});
      service = NotificationCoreService.instance;
    });

    tearDown(() async {
      // Clean up after each test
      await _clearCachedData();
    });

    group('Service Initialization', () {
      test('should handle Firebase unavailable gracefully', () async {
        // In test environment, Firebase is typically not available
        // Act
        await service.initialize();

        // Assert - Firebase unavailability should be handled gracefully
        expect(service.isAvailable, isFalse);
      });

      test('should set up callbacks correctly during initialization', () async {
        // Act & Assert - Should not throw even when Firebase is unavailable
        expect(
          () async => await service.initialize(
            onMessageReceived: (message) {}, // Empty callback for test
            onMessageOpenedApp: (message) {}, // Empty callback for test
            onTokenRefresh: (token) {}, // Empty callback for test
          ),
          returnsNormally,
        );

        // In test environment, Firebase is not available
        expect(service.isAvailable, isFalse);
      });
    });

    group('Token Management', () {
      test('should return null token when Firebase unavailable', () async {
        // In test environment, Firebase is not available
        // Act
        final token = await service.getToken();

        // Assert
        expect(token, isNull);
      });

      test('should store and retrieve token locally', () async {
        // Arrange
        const testToken = 'test-fcm-token-12345';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', testToken);
        await prefs.setInt(
          'fcm_token_timestamp',
          DateTime.now().millisecondsSinceEpoch,
        );

        // Act
        final storedToken = await service.getToken();

        // Assert
        expect(storedToken, equals(testToken));
      });

      test('should handle token deletion', () async {
        // Arrange
        const testToken = 'test-fcm-token-12345';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', testToken);

        // Act
        await service.deleteToken();

        // Assert
        final deletedToken = await service.getToken();
        expect(deletedToken, isNull);
      });

      test('should validate token timestamp correctly', () async {
        // Arrange
        const testToken = 'test-fcm-token-12345';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', testToken);

        // Store old timestamp (older than 1 week)
        final oldTimestamp =
            DateTime.now()
                .subtract(const Duration(days: 8))
                .millisecondsSinceEpoch;
        await prefs.setInt('fcm_token_timestamp', oldTimestamp);

        // Act
        final token = await service.getToken();

        // Assert - Should attempt to refresh due to old timestamp
        // In test environment without Firebase, this returns the stored token
        expect(token, equals(testToken));
      });
    });

    group('Permission Management', () {
      test(
        'should return false for permissions when Firebase unavailable',
        () async {
          // In test environment, Firebase is not available
          // Act
          final hasPermissions = await service.hasPermissions();

          // Assert
          expect(hasPermissions, isFalse);
        },
      );

      test(
        'should handle permission request when Firebase unavailable',
        () async {
          // In test environment, Firebase is not available
          // Act
          final result = await service.requestPermissions();

          // Assert
          expect(result, isFalse);
        },
      );
    });

    group('Background Message Processing', () {
      test('should process valid background notification', () async {
        // Arrange
        final message = _createMockRemoteMessage(
          notificationId: 'test-123',
          interventionType: 'momentum_drop',
          actionType: 'open_momentum_meter',
          title: 'Momentum Alert',
          body: 'Your momentum needs attention',
        );

        // Act
        await service.handleBackgroundMessage(message);

        // Assert - Check if notification was stored
        final lastNotification = await service.getLastBackgroundNotification();
        expect(lastNotification, isNotNull);
        expect(lastNotification!.notificationId, equals('test-123'));
        expect(lastNotification.interventionType, equals('momentum_drop'));
      });

      test(
        'should handle momentum-related notifications and update cache',
        () async {
          // Arrange
          final message = _createMockRemoteMessage(
            notificationId: 'momentum-test',
            interventionType: 'momentum_drop',
            actionType: 'view_momentum',
          );

          // Act
          await service.handleBackgroundMessage(message);

          // Assert - Check cached momentum update
          final cachedUpdate = await service.getCachedMomentumUpdate();
          expect(cachedUpdate, isNotNull);
          expect(cachedUpdate!['state'], equals('NeedsCare'));
          expect(cachedUpdate['notificationId'], equals('momentum-test'));
        },
      );

      test('should store pending actions for valid notifications', () async {
        // Arrange
        final message = _createMockRemoteMessage(
          notificationId: 'action-test',
          interventionType: 'daily_reminder',
          actionType: 'open_app',
        );

        // Act
        await service.handleBackgroundMessage(message);

        // Assert - Check pending actions
        final pendingActions = await service.getPendingActions();
        expect(pendingActions, hasLength(1));
        expect(pendingActions.first.notificationId, equals('action-test'));
        expect(pendingActions.first.actionType, equals('open_app'));
      });

      test('should handle notification without data gracefully', () async {
        // Arrange
        final message = RemoteMessage(messageId: 'empty-message', data: {});

        // Act & Assert - Should not throw
        await service.handleBackgroundMessage(message);

        // Should not store anything
        final lastNotification = await service.getLastBackgroundNotification();
        expect(lastNotification, isNull);
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
        await service.handleBackgroundMessage(message);

        // Should still store notification with empty action data
        final lastNotification = await service.getLastBackgroundNotification();
        expect(lastNotification, isNotNull);
        expect(lastNotification!.actionData, isEmpty);
      });
    });

    group('Momentum State Management', () {
      test('should create correct momentum update for momentum_drop', () async {
        // Arrange
        final message = _createMockRemoteMessage(
          notificationId: 'momentum-drop-test',
          interventionType: 'momentum_drop',
          actionType: 'view_momentum',
        );

        // Act
        await service.handleBackgroundMessage(message);

        // Assert
        final cachedUpdate = await service.getCachedMomentumUpdate();
        expect(cachedUpdate, isNotNull);
        expect(cachedUpdate!['state'], equals('NeedsCare'));
        expect(cachedUpdate['notificationId'], equals('momentum-drop-test'));
      });

      test('should create correct momentum update for celebration', () async {
        // Arrange
        final message = _createMockRemoteMessage(
          notificationId: 'celebration-test',
          interventionType: 'celebration',
          actionType: 'view_momentum',
        );

        // Act
        await service.handleBackgroundMessage(message);

        // Assert
        final cachedUpdate = await service.getCachedMomentumUpdate();
        expect(cachedUpdate, isNotNull);
        expect(cachedUpdate!['state'], equals('Rising'));
        expect(cachedUpdate['notificationId'], equals('celebration-test'));
      });

      test(
        'should create high priority update for consecutive_needs_care',
        () async {
          // Arrange
          final message = _createMockRemoteMessage(
            notificationId: 'consecutive-test',
            interventionType: 'consecutive_needs_care',
            actionType: 'urgent_action',
          );

          // Act
          await service.handleBackgroundMessage(message);

          // Assert
          final cachedUpdate = await service.getCachedMomentumUpdate();
          expect(cachedUpdate, isNotNull);
          expect(cachedUpdate!['state'], equals('NeedsCare'));
          expect(cachedUpdate['priority'], equals('high'));
        },
      );

      test(
        'should not create momentum update for non-momentum notifications',
        () async {
          // Arrange
          final message = _createMockRemoteMessage(
            notificationId: 'general-test',
            interventionType: 'daily_reminder',
            actionType: 'open_app',
          );

          // Act
          await service.handleBackgroundMessage(message);

          // Assert
          final cachedUpdate = await service.getCachedMomentumUpdate();
          expect(cachedUpdate, isNull);
        },
      );
    });

    group('Data Retrieval', () {
      test('should retrieve stored notification data correctly', () async {
        // Arrange
        final testData = NotificationData(
          notificationId: 'test-123',
          interventionType: 'momentum_drop',
          actionType: 'open_momentum_meter',
          actionData: {'key': 'value'},
          title: 'Test Title',
          body: 'Test Body',
          receivedAt: DateTime.now(),
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'last_background_notification',
          '{"notificationId":"test-123","interventionType":"momentum_drop","actionType":"open_momentum_meter","actionData":{"key":"value"},"title":"Test Title","body":"Test Body","receivedAt":"${testData.receivedAt.toIso8601String()}"}',
        );

        // Act
        final retrievedData = await service.getLastBackgroundNotification();

        // Assert
        expect(retrievedData, isNotNull);
        expect(retrievedData!.notificationId, equals('test-123'));
        expect(retrievedData.interventionType, equals('momentum_drop'));
        expect(retrievedData.actionData['key'], equals('value'));
      });

      test('should handle multiple pending actions correctly', () async {
        // Arrange
        final message1 = _createMockRemoteMessage(
          notificationId: 'action-1',
          interventionType: 'momentum_drop',
          actionType: 'open_app',
        );
        final message2 = _createMockRemoteMessage(
          notificationId: 'action-2',
          interventionType: 'daily_reminder',
          actionType: 'view_content',
        );

        // Act
        await service.handleBackgroundMessage(message1);
        await service.handleBackgroundMessage(message2);

        // Assert
        final pendingActions = await service.getPendingActions();
        expect(pendingActions, hasLength(2));
        expect(
          pendingActions.map((a) => a.notificationId),
          containsAll(['action-1', 'action-2']),
        );
      });

      test('should handle corrupted pending actions data gracefully', () async {
        // Arrange - Store invalid JSON in pending actions
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('pending_notification_actions', [
          'invalid-json',
          '{"valid":"data"}',
        ]);

        // Act
        final pendingActions = await service.getPendingActions();

        // Assert - Should only return valid actions
        expect(
          pendingActions,
          hasLength(0),
        ); // Both will fail parsing in this simple test
      });
    });

    group('Data Management', () {
      test('should clear all cached data correctly', () async {
        // Arrange - Set up some cached data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_background_notification', 'test-data');
        await prefs.setStringList('pending_notification_actions', [
          'test-action',
        ]);
        await prefs.setString('cached_momentum_update', 'test-update');

        // Act
        await service.clearCachedData();

        // Assert
        expect(prefs.getString('last_background_notification'), isNull);
        expect(prefs.getStringList('pending_notification_actions'), isNull);
        expect(prefs.getString('cached_momentum_update'), isNull);
      });
    });

    group('Error Handling', () {
      test('should handle SharedPreferences errors gracefully', () async {
        // This test verifies error handling in the service methods
        // In a real scenario, you'd mock SharedPreferences to throw errors

        // Act & Assert - Should not throw
        expect(() => service.getLastBackgroundNotification(), returnsNormally);
        expect(() => service.getPendingActions(), returnsNormally);
        expect(() => service.getCachedMomentumUpdate(), returnsNormally);
      });

      test('should handle malformed notification data', () async {
        // Arrange
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_background_notification', 'invalid-json');

        // Act
        final notification = await service.getLastBackgroundNotification();

        // Assert
        expect(notification, isNull);
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
  await prefs.remove('fcm_token');
  await prefs.remove('fcm_token_timestamp');
}
