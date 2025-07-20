import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// New helpers extracted for component-size refactor
import 'notification_token_manager.dart';
import 'notification_permission_helper.dart';
import '../../../services/firebase_service.dart';
import '../models/notification_models.dart';

/// Unified core service for FCM initialization, permissions, and background processing
/// Consolidates functionality from notification_service.dart, background_notification_handler.dart,
/// and fcm_token_service.dart into a single cohesive service
class NotificationCoreService {
  static NotificationCoreService? _instance;
  static NotificationCoreService get instance =>
      _instance ??= NotificationCoreService._();

  NotificationCoreService._();

  // FCM instance and state
  FirebaseMessaging? _messaging;
  bool _isAvailable = false;

  // Storage keys (token keys moved to NotificationTokenManager)
  static const String _lastNotificationKey = 'last_background_notification';
  static const String _pendingActionsKey = 'pending_notification_actions';

  // Extracted helpers
  NotificationTokenManager? _tokenManager;
  NotificationPermissionHelper? _permissionHelper;

  // Callbacks for notification events
  void Function(RemoteMessage)? _onMessageReceived;
  void Function(RemoteMessage)? _onMessageOpenedApp;
  void Function(String)? _onTokenRefresh;

  /// Initialize the notification core service with Firebase availability checks
  Future<void> initialize({
    void Function(RemoteMessage)? onMessageReceived,
    void Function(RemoteMessage)? onMessageOpenedApp,
    void Function(String)? onTokenRefresh,
  }) async {
    // Check if Firebase is available before attempting to use messaging
    if (!FirebaseService.isAvailable) {
      FirebaseService.logServiceAttempt('Messaging', 'initialization');

      if (kDebugMode) {
        debugPrint(
          '⚠️ NotificationCoreService: Firebase not available, notifications disabled',
        );
        debugPrint('💡 App will continue with local notification fallbacks');
      }

      _isAvailable = false;
      return;
    }

    try {
      _messaging = FirebaseMessaging.instance;
      _tokenManager = NotificationTokenManager(_messaging!);
      _permissionHelper = NotificationPermissionHelper(_messaging!);
      _onMessageReceived = onMessageReceived;
      _onMessageOpenedApp = onMessageOpenedApp;
      _onTokenRefresh = onTokenRefresh;

      await _setupNotificationHandlers();
      await requestPermissions();

      _isAvailable = true;

      if (kDebugMode) {
        debugPrint(
          '✅ NotificationCoreService initialized successfully with Firebase',
        );
      }
    } catch (e) {
      _isAvailable = false;

      if (kDebugMode) {
        debugPrint('❌ NotificationCoreService initialization failed: $e');
        debugPrint('💡 App will continue without push notifications');
      }

      // Don't rethrow - allow app to continue without notifications
    }
  }

  /// Check if notification service is available
  bool get isAvailable => _isAvailable && FirebaseService.isAvailable;

  /// Request notification permissions via helper
  NotificationTokenManager _ensureTokenManager() {
    if (_tokenManager != null) return _tokenManager!;
    if (FirebaseService.isAvailable) {
      _tokenManager = NotificationTokenManager(FirebaseMessaging.instance);
    } else {
      _tokenManager = NotificationTokenManager();
    }
    return _tokenManager!;
  }

  NotificationPermissionHelper _ensurePermissionHelper() {
    if (_permissionHelper != null) return _permissionHelper!;
    if (FirebaseService.isAvailable) {
      _permissionHelper = NotificationPermissionHelper(
        FirebaseMessaging.instance,
      );
    } else {
      _permissionHelper = NotificationPermissionHelper();
    }
    return _permissionHelper!;
  }

  Future<bool> requestPermissions() async {
    if (!isAvailable) {
      FirebaseService.logServiceAttempt('Messaging', 'requestPermissions');
      return false;
    }
    return _ensurePermissionHelper().requestPermissions();
  }

  /// Set up notification message handlers
  Future<void> _setupNotificationHandlers() async {
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        debugPrint(
          'Received foreground message: ${message.notification?.title}',
        );
      }
      _onMessageReceived?.call(message);
    });

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        debugPrint('Notification tapped: ${message.notification?.title}');
      }
      _onMessageOpenedApp?.call(message);
    });

    // Handle token refresh
    _messaging!.onTokenRefresh.listen((String token) {
      if (kDebugMode) debugPrint('FCM Token refreshed: $token');
      _ensureTokenManager().persistRefreshedToken(token);
      _onTokenRefresh?.call(token);
    });

    // Check for notification that launched the app
    final initialMessage = await _messaging!.getInitialMessage();
    if (initialMessage != null) {
      if (kDebugMode) {
        debugPrint(
          'App launched from notification: ${initialMessage.notification?.title}',
        );
      }
      _onMessageOpenedApp?.call(initialMessage);
    }
  }

  /// Get the current FCM token
  Future<String?> getToken() => _ensureTokenManager().getToken();

  /// Delete the current FCM token
  Future<void> deleteToken() => _ensureTokenManager().deleteToken();

  /// Handle background notification processing
  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '🔄 Processing background notification: ${message.notification?.title}',
        );
      }

      // Ensure Firebase is initialized in background isolate
      await _ensureFirebaseInitialized();

      // Extract notification data
      final notificationData = _extractNotificationData(message);
      if (notificationData == null) {
        if (kDebugMode) {
          debugPrint('⚠️ Invalid notification data format');
        }
        return;
      }

      // Store notification for later processing
      await _storeBackgroundNotification(notificationData);

      // Update cached momentum state if applicable
      await _updateCachedMomentumState(notificationData);

      // Store pending action for when app opens
      await _storePendingAction(notificationData);

      if (kDebugMode) {
        debugPrint('✅ Background notification processed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error processing background notification: $e');
      }
    }
  }

  /// Check if notification permissions are granted
  Future<bool> hasPermissions() async {
    if (!isAvailable) {
      FirebaseService.logServiceAttempt('Messaging', 'hasPermissions');
      return false;
    }
    return _ensurePermissionHelper().hasPermissions();
  }

  // Token management methods have been extracted to NotificationTokenManager

  // MARK: - Background Processing Private Methods

  /// Ensure Firebase is initialized in background isolate
  Future<void> _ensureFirebaseInitialized() async {
    try {
      // Skip Firebase initialization in test environment
      const isTestEnvironment =
          kDebugMode &&
          (String.fromEnvironment('ENVIRONMENT', defaultValue: 'development') ==
                  'test' ||
              String.fromEnvironment('flutter.test', defaultValue: 'false') ==
                  'true');

      if (isTestEnvironment) {
        return;
      }

      if (!FirebaseService.isInitialized) {
        await FirebaseService.initialize();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase initialization failed: $e');
      }
    }
  }

  /// Extract and validate notification data
  NotificationData? _extractNotificationData(RemoteMessage message) {
    try {
      final data = message.data;
      if (data.isEmpty) return null;

      // Parse action data with fallback for invalid JSON
      Map<String, dynamic> actionData = <String, dynamic>{};
      if (data['action_data'] != null) {
        try {
          final actionDataString = data['action_data'] as String?;
          if (actionDataString != null) {
            final decoded = json.decode(actionDataString);
            actionData = decoded as Map<String, dynamic>;
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error parsing action_data JSON: $e');
          }
          actionData = <String, dynamic>{};
        }
      }

      return NotificationData(
        notificationId: (data['notification_id'] as String?) ?? '',
        interventionType: (data['intervention_type'] as String?) ?? '',
        actionType: (data['action_type'] as String?) ?? '',
        actionData: actionData,
        title: message.notification?.title ?? '',
        body: message.notification?.body ?? '',
        receivedAt: DateTime.now(),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error extracting notification data: $e');
      }
      return null;
    }
  }

  /// Store notification data for later retrieval
  Future<void> _storeBackgroundNotification(NotificationData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationJson = json.encode(data.toJson());
      await prefs.setString(_lastNotificationKey, notificationJson);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error storing background notification: $e');
      }
    }
  }

  /// Update cached momentum state based on notification
  Future<void> _updateCachedMomentumState(NotificationData data) async {
    try {
      // Only update for momentum-related notifications
      if (!_isMomentumRelatedNotification(data.interventionType)) return;

      final prefs = await SharedPreferences.getInstance();

      // Create basic momentum update based on intervention type
      final momentumUpdate = _createMomentumUpdate(data);
      if (momentumUpdate != null) {
        await prefs.setString(
          'cached_momentum_update',
          json.encode(momentumUpdate),
        );
        if (kDebugMode) {
          debugPrint('📊 Cached momentum state updated');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating cached momentum state: $e');
      }
    }
  }

  /// Store pending action for when app opens
  Future<void> _storePendingAction(NotificationData data) async {
    try {
      if (data.actionType.isEmpty) return;

      final action = PendingNotificationAction(
        notificationId: data.notificationId,
        actionType: data.actionType,
        actionData: data.actionData,
        receivedAt: data.receivedAt,
      );

      final prefs = await SharedPreferences.getInstance();
      final existingActions = prefs.getStringList(_pendingActionsKey) ?? [];
      existingActions.add(json.encode(action.toJson()));
      await prefs.setStringList(_pendingActionsKey, existingActions);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error storing pending action: $e');
      }
    }
  }

  /// Check if notification is momentum-related
  bool _isMomentumRelatedNotification(String interventionType) {
    return interventionType.contains('momentum') ||
        interventionType.contains('score') ||
        interventionType == 'celebration' ||
        interventionType == 'consecutive_needs_care';
  }

  /// Create momentum update from notification data
  Map<String, dynamic>? _createMomentumUpdate(NotificationData data) {
    final now = DateTime.now();

    switch (data.interventionType) {
      case 'momentum_drop':
      case 'score_drop':
        return {
          'state': 'NeedsCare',
          'lastUpdated': now.toIso8601String(),
          'notificationId': data.notificationId,
        };
      case 'consecutive_needs_care':
        return {
          'state': 'NeedsCare',
          'lastUpdated': now.toIso8601String(),
          'notificationId': data.notificationId,
          'priority': 'high',
        };
      case 'celebration':
        return {
          'state': 'Rising',
          'lastUpdated': now.toIso8601String(),
          'notificationId': data.notificationId,
        };
      default:
        return null;
    }
  }

  // MARK: - Data Retrieval Methods (Public API)

  /// Get the last background notification that was received
  Future<NotificationData?> getLastBackgroundNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationJson = prefs.getString(_lastNotificationKey);

      if (notificationJson != null) {
        final data = json.decode(notificationJson) as Map<String, dynamic>;
        return NotificationData.fromJson(data);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting last background notification: $e');
      }
      return null;
    }
  }

  /// Get all pending notification actions
  Future<List<PendingNotificationAction>> getPendingActions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final actionsJson = prefs.getStringList(_pendingActionsKey) ?? [];

      return actionsJson
          .map((actionJson) {
            try {
              final data = json.decode(actionJson) as Map<String, dynamic>;
              return PendingNotificationAction.fromJson(data);
            } catch (e) {
              if (kDebugMode) {
                debugPrint('Error parsing pending action: $e');
              }
              return null;
            }
          })
          .where((action) => action != null)
          .cast<PendingNotificationAction>()
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting pending actions: $e');
      }
      return [];
    }
  }

  /// Get cached momentum update from background processing
  Future<Map<String, dynamic>?> getCachedMomentumUpdate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updateJson = prefs.getString('cached_momentum_update');

      if (updateJson != null) {
        return json.decode(updateJson) as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting cached momentum update: $e');
      }
      return null;
    }
  }

  /// Clear all cached notification data
  Future<void> clearCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastNotificationKey);
      await prefs.remove(_pendingActionsKey);
      await prefs.remove('cached_momentum_update');

      if (kDebugMode) {
        debugPrint('🧹 All cached notification data cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error clearing cached data: $e');
      }
    }
  }
}

/// Background message handler for FCM (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationCoreService.instance.handleBackgroundMessage(message);
}
