import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'firebase_service.dart';
import '../notifications/domain/models/notification_models.dart';

/// Service for handling notifications in background isolate
class BackgroundNotificationHandler {
  static const String _lastNotificationKey = 'last_background_notification';
  static const String _pendingActionsKey = 'pending_notification_actions';

  /// Process notification in background isolate
  static Future<void> processBackgroundNotification(
    RemoteMessage message,
  ) async {
    try {
      if (kDebugMode) {
        print(
          '🔄 Processing background notification: ${message.notification?.title}',
        );
      }

      // Ensure Firebase is initialized in background isolate
      await _ensureFirebaseInitialized();

      // Extract notification data
      final notificationData = _extractNotificationData(message);
      if (notificationData == null) {
        if (kDebugMode) {
          print('⚠️ Invalid notification data format');
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
        print('✅ Background notification processed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error processing background notification: $e');
      }
    }
  }

  /// Ensure Firebase is initialized in background isolate
  static Future<void> _ensureFirebaseInitialized() async {
    try {
      // Skip Firebase initialization in test environment
      // Check both debug mode and if we're in a test context
      final isTestEnvironment =
          kDebugMode &&
          (const String.fromEnvironment(
                    'ENVIRONMENT',
                    defaultValue: 'development',
                  ) ==
                  'test' ||
              const String.fromEnvironment(
                    'flutter.test',
                    defaultValue: 'false',
                  ) ==
                  'true');

      if (isTestEnvironment) {
        return;
      }

      if (!FirebaseService.isInitialized) {
        await FirebaseService.initialize();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Firebase initialization failed: $e');
      }
      // Continue without Firebase in test/development environments
    }
  }

  /// Extract and validate notification data
  static NotificationData? _extractNotificationData(RemoteMessage message) {
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
            print('Error parsing action_data JSON: $e');
          }
          // Continue with empty action data instead of failing
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
        print('Error extracting notification data: $e');
      }
      return null;
    }
  }

  /// Store notification data for later retrieval
  static Future<void> _storeBackgroundNotification(
    NotificationData data,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationJson = json.encode(data.toJson());
      await prefs.setString(_lastNotificationKey, notificationJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error storing background notification: $e');
      }
    }
  }

  /// Update cached momentum state based on notification
  static Future<void> _updateCachedMomentumState(NotificationData data) async {
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
          print('📊 Cached momentum state updated');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating cached momentum state: $e');
      }
    }
  }

  /// Check if notification is momentum-related
  static bool _isMomentumRelatedNotification(String interventionType) {
    return interventionType.contains('momentum') ||
        interventionType.contains('score') ||
        interventionType == 'celebration' ||
        interventionType == 'consecutive_needs_care';
  }

  /// Create momentum update from notification data
  static Map<String, dynamic>? _createMomentumUpdate(NotificationData data) {
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
          'celebration': true,
        };
      default:
        return null;
    }
  }

  /// Store pending action for when app opens
  static Future<void> _storePendingAction(NotificationData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing pending actions
      final existingJson = prefs.getString(_pendingActionsKey);
      List<Map<String, dynamic>> pendingActions = [];

      if (existingJson != null) {
        final existingList = json.decode(existingJson) as List;
        pendingActions = existingList.cast<Map<String, dynamic>>();
      }

      // Add new action
      pendingActions.add({
        'notificationId': data.notificationId,
        'actionType': data.actionType,
        'actionData': data.actionData,
        'receivedAt': data.receivedAt.toIso8601String(),
      });

      // Keep only last 10 actions to avoid storage bloat
      if (pendingActions.length > 10) {
        pendingActions = pendingActions.sublist(pendingActions.length - 10);
      }

      await prefs.setString(_pendingActionsKey, json.encode(pendingActions));
    } catch (e) {
      if (kDebugMode) {
        print('Error storing pending action: $e');
      }
    }
  }

  /// Get last background notification
  static Future<NotificationData?> getLastBackgroundNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationJson = prefs.getString(_lastNotificationKey);

      if (notificationJson != null) {
        final data = json.decode(notificationJson) as Map<String, dynamic>;
        return NotificationData.fromJson(data);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting last background notification: $e');
      }
    }
    return null;
  }

  /// Get and clear pending actions
  static Future<List<PendingNotificationAction>> getPendingActions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final actionsJson = prefs.getString(_pendingActionsKey);

      if (actionsJson != null) {
        final actionsList = json.decode(actionsJson) as List<dynamic>;
        final actions =
            actionsList
                .map(
                  (json) => PendingNotificationAction.fromJson(
                    json as Map<String, dynamic>,
                  ),
                )
                .toList();

        // Clear pending actions after retrieval
        await prefs.remove(_pendingActionsKey);

        return actions;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting pending actions: $e');
      }
    }
    return [];
  }

  /// Get cached momentum update
  static Future<Map<String, dynamic>?> getCachedMomentumUpdate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updateJson = prefs.getString('cached_momentum_update');

      if (updateJson != null) {
        // Clear after retrieval
        await prefs.remove('cached_momentum_update');
        return json.decode(updateJson) as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cached momentum update: $e');
      }
    }
    return null;
  }

  /// Clear all cached data
  static Future<void> clearCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastNotificationKey);
      await prefs.remove(_pendingActionsKey);
      await prefs.remove('cached_momentum_update');
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing cached data: $e');
      }
    }
  }
}
