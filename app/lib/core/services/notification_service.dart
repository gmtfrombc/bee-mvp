import 'dart:io';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_service.dart';

/// Service responsible for managing push notifications and FCM integration
class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance =>
      _instance ??= NotificationService._();

  NotificationService._();

  FirebaseMessaging? _messaging;

  // Callbacks for notification events
  void Function(RemoteMessage)? _onMessageReceived;
  void Function(RemoteMessage)? _onMessageOpenedApp;
  void Function(String)? _onTokenRefresh;

  /// Initialize the notification service
  Future<void> initialize({
    void Function(RemoteMessage)? onMessageReceived,
    void Function(RemoteMessage)? onMessageOpenedApp,
    void Function(String)? onTokenRefresh,
  }) async {
    // Ensure Firebase is initialized first
    if (!FirebaseService.isInitialized) {
      await FirebaseService.initialize();
    }

    _messaging = FirebaseMessaging.instance;
    _onMessageReceived = onMessageReceived;
    _onMessageOpenedApp = onMessageOpenedApp;
    _onTokenRefresh = onTokenRefresh;

    await _setupNotificationHandlers();
    await _requestNotificationPermissions();

    if (kDebugMode) {
      print('NotificationService initialized successfully');
    }
  }

  /// Request notification permissions from the user
  Future<bool> _requestNotificationPermissions() async {
    try {
      // Request FCM permissions
      final settings = await _messaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // Check system-level notification permissions
      final systemPermission = await Permission.notification.request();

      final hasPermission =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (kDebugMode) {
        print('FCM Authorization Status: ${settings.authorizationStatus}');
        print('System Permission Status: $systemPermission');
      }

      return hasPermission && systemPermission.isGranted;
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting notification permissions: $e');
      }
      return false;
    }
  }

  /// Set up notification message handlers
  Future<void> _setupNotificationHandlers() async {
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Received foreground message: ${message.notification?.title}');
      }
      _onMessageReceived?.call(message);
    });

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Notification tapped: ${message.notification?.title}');
      }
      _onMessageOpenedApp?.call(message);
    });

    // Handle token refresh
    _messaging!.onTokenRefresh.listen((String token) {
      if (kDebugMode) {
        print('FCM Token refreshed: $token');
      }
      _onTokenRefresh?.call(token);
    });

    // Check for notification that launched the app
    final initialMessage = await _messaging!.getInitialMessage();
    if (initialMessage != null) {
      if (kDebugMode) {
        print(
          'App launched from notification: ${initialMessage.notification?.title}',
        );
      }
      _onMessageOpenedApp?.call(initialMessage);
    }
  }

  /// Get the current FCM token
  Future<String?> getToken() async {
    try {
      if (_messaging == null) {
        throw Exception('NotificationService not initialized');
      }

      final token = await _messaging!.getToken();
      if (kDebugMode) {
        print('FCM Token: $token');
      }
      return token;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
      return null;
    }
  }

  /// Delete the current FCM token
  Future<void> deleteToken() async {
    try {
      await _messaging?.deleteToken();
      if (kDebugMode) {
        print('FCM Token deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting FCM token: $e');
      }
    }
  }

  /// Check if notification permissions are granted
  Future<bool> hasPermissions() async {
    try {
      final settings = await _messaging?.getNotificationSettings();
      final systemPermission = await Permission.notification.status;

      return (settings?.authorizationStatus == AuthorizationStatus.authorized ||
              settings?.authorizationStatus ==
                  AuthorizationStatus.provisional) &&
          systemPermission.isGranted;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking notification permissions: $e');
      }
      return false;
    }
  }

  /// Handle deep links from notifications
  Future<void> handleDeepLink(
    String route, {
    Map<String, dynamic>? params,
  }) async {
    try {
      // This will be implemented when we add deep linking in T1.1.4.6
      if (kDebugMode) {
        print('Handling deep link: $route with params: $params');
      }
      // TODO: Implement navigation logic
    } catch (e) {
      if (kDebugMode) {
        print('Error handling deep link: $e');
      }
    }
  }

  /// Update notification badge count (iOS)
  Future<void> setBadgeCount(int count) async {
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
          print('Error setting badge count: $e');
        }
      }
    }
  }

  /// Subscribe to a topic for targeted notifications
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging?.subscribeToTopic(topic);
      if (kDebugMode) {
        print('Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error subscribing to topic $topic: $e');
      }
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging?.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        print('Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error unsubscribing from topic $topic: $e');
      }
    }
  }

  /// Dispose of the service
  void dispose() {
    _messaging = null;
    _onMessageReceived = null;
    _onMessageOpenedApp = null;
    _onTokenRefresh = null;
  }
}

/// Background message handler (must be top-level function)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Import the background handler service
  // Note: Import must be at the top of the file, but we'll handle processing here
  try {
    // Ensure Firebase is initialized in background isolate
    if (!FirebaseService.isInitialized) {
      await FirebaseService.initialize();
    }

    if (kDebugMode) {
      print('🔄 Background message received: ${message.notification?.title}');
      print('📱 Message data: ${message.data}');
    }

    // Use the comprehensive background notification handler
    await _processBackgroundNotificationComprehensive(message);

    if (kDebugMode) {
      print('✅ Background message processing completed');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Error in background message handler: $e');
    }
  }
}

/// Comprehensive background notification processing
Future<void> _processBackgroundNotificationComprehensive(
  RemoteMessage message,
) async {
  try {
    // Extract notification data
    final data = message.data;
    if (data.isEmpty) {
      if (kDebugMode) {
        print('⚠️ Background notification has no data');
      }
      return;
    }

    // Store notification for later processing
    await _storeBackgroundNotificationLocal(message);

    // Update cached momentum state if applicable
    await _updateCachedMomentumStateLocal(message);

    // Store pending action for when app opens
    await _storePendingActionLocal(message);

    if (kDebugMode) {
      print('📊 Background notification processed and cached');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Error in comprehensive background processing: $e');
    }
  }
}

/// Store notification data locally (background isolate compatible)
Future<void> _storeBackgroundNotificationLocal(RemoteMessage message) async {
  try {
    // We'll use shared preferences directly since we're in background isolate
    final prefs = await SharedPreferences.getInstance();

    final notificationData = {
      'notificationId': message.data['notification_id'] ?? '',
      'interventionType': message.data['intervention_type'] ?? '',
      'actionType': message.data['action_type'] ?? '',
      'actionData': message.data['action_data'] ?? '{}',
      'title': message.notification?.title ?? '',
      'body': message.notification?.body ?? '',
      'receivedAt': DateTime.now().toIso8601String(),
    };

    await prefs.setString(
      'last_background_notification',
      json.encode(notificationData),
    );
  } catch (e) {
    if (kDebugMode) {
      print('Error storing background notification locally: $e');
    }
  }
}

/// Update cached momentum state locally (background isolate compatible)
Future<void> _updateCachedMomentumStateLocal(RemoteMessage message) async {
  try {
    final interventionType = message.data['intervention_type'] ?? '';

    // Only update for momentum-related notifications
    if (!interventionType.contains('momentum') &&
        !interventionType.contains('score') &&
        !interventionType.contains('celebration')) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // Create basic momentum update based on intervention type
    Map<String, dynamic>? momentumUpdate;

    switch (interventionType) {
      case 'momentum_drop':
      case 'score_drop':
        momentumUpdate = {
          'state': 'NeedsCare',
          'lastUpdated': now.toIso8601String(),
          'notificationId': message.data['notification_id'] ?? '',
        };
        break;
      case 'consecutive_needs_care':
        momentumUpdate = {
          'state': 'NeedsCare',
          'lastUpdated': now.toIso8601String(),
          'notificationId': message.data['notification_id'] ?? '',
          'priority': 'high',
        };
        break;
      case 'celebration':
        momentumUpdate = {
          'state': 'Rising',
          'lastUpdated': now.toIso8601String(),
          'notificationId': message.data['notification_id'] ?? '',
          'celebration': true,
        };
        break;
    }

    if (momentumUpdate != null) {
      await prefs.setString(
        'cached_momentum_update',
        json.encode(momentumUpdate),
      );
      if (kDebugMode) {
        print('📊 Cached momentum state updated in background');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error updating cached momentum state locally: $e');
    }
  }
}

/// Store pending action locally (background isolate compatible)
Future<void> _storePendingActionLocal(RemoteMessage message) async {
  try {
    final prefs = await SharedPreferences.getInstance();

    // Get existing pending actions
    final existingJson = prefs.getString('pending_notification_actions');
    List<Map<String, dynamic>> pendingActions = [];

    if (existingJson != null) {
      final existingList = json.decode(existingJson) as List;
      pendingActions = existingList.cast<Map<String, dynamic>>();
    }

    // Add new action
    pendingActions.add({
      'notificationId': message.data['notification_id'] ?? '',
      'actionType': message.data['action_type'] ?? '',
      'actionData': message.data['action_data'] ?? '{}',
      'receivedAt': DateTime.now().toIso8601String(),
    });

    // Keep only last 10 actions to avoid storage bloat
    if (pendingActions.length > 10) {
      pendingActions = pendingActions.sublist(pendingActions.length - 10);
    }

    await prefs.setString(
      'pending_notification_actions',
      json.encode(pendingActions),
    );
  } catch (e) {
    if (kDebugMode) {
      print('Error storing pending action locally: $e');
    }
  }
}
