import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'firebase_service.dart';
import '../notifications/domain/services/notification_core_service.dart';

/// Service responsible for managing push notifications and FCM integration
/// Delegates core functionality to NotificationCoreService while managing topics and UI-specific features
class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance =>
      _instance ??= NotificationService._();

  NotificationService._();

  FirebaseMessaging? _messaging;

  // Delegate core functionality to NotificationCoreService
  NotificationCoreService get _coreService => NotificationCoreService.instance;

  /// Initialize the notification service with Firebase availability checks
  Future<void> initialize({
    void Function(RemoteMessage)? onMessageReceived,
    void Function(RemoteMessage)? onMessageOpenedApp,
    void Function(String)? onTokenRefresh,
  }) async {
    // Initialize core service first
    await _coreService.initialize(
      onMessageReceived: onMessageReceived,
      onMessageOpenedApp: onMessageOpenedApp,
      onTokenRefresh: onTokenRefresh,
    );

    // Initialize local messaging instance for topic management
    if (FirebaseService.isAvailable) {
      try {
        _messaging = FirebaseMessaging.instance;

        if (kDebugMode) {
          debugPrint(
            '✅ NotificationService initialized with topic management support',
          );
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ NotificationService topic initialization failed: $e');
        }
      }
    }
  }

  /// Check if notification service is available
  bool get isAvailable => _coreService.isAvailable;

  /// Request notification permissions from the user
  Future<bool> requestPermissions() async {
    return await _coreService.requestPermissions();
  }

  /// Get the current FCM token
  Future<String?> getToken() async {
    return await _coreService.getToken();
  }

  /// Delete the current FCM token
  Future<void> deleteToken() async {
    await _coreService.deleteToken();
  }

  /// Check if notification permissions are granted
  Future<bool> hasPermissions() async {
    return await _coreService.hasPermissions();
  }

  /// Set badge count (iOS specific, will be handled by the OS on modern versions)
  Future<void> setBadgeCount(int count) async {
    if (!isAvailable) {
      FirebaseService.logServiceAttempt('Messaging', 'setBadgeCount');
      return;
    }

    // On iOS 10+ and modern Android, badge counts are managed by the system
    // when notifications are properly configured. This method remains for
    // compatibility but the actual badge management happens automatically.
    if (Platform.isIOS) {
      try {
        await _messaging?.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        // Note: Badge count management will be handled by the OS
        // when notifications are properly configured
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error setting badge count: $e');
        }
      }
    }
  }

  /// Subscribe to a topic for targeted notifications
  Future<void> subscribeToTopic(String topic) async {
    if (!isAvailable) {
      FirebaseService.logServiceAttempt('Messaging', 'subscribeToTopic');
      return;
    }

    try {
      await _messaging?.subscribeToTopic(topic);
      if (kDebugMode) {
        debugPrint('🔥 Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error subscribing to topic $topic: $e');
      }
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    if (!isAvailable) {
      FirebaseService.logServiceAttempt('Messaging', 'unsubscribeFromTopic');
      return;
    }

    try {
      await _messaging?.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        debugPrint('🔥 Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error unsubscribing from topic $topic: $e');
      }
    }
  }

  /// Dispose of the service
  void dispose() {
    _messaging = null;
  }
}
