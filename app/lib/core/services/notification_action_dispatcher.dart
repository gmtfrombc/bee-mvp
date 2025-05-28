import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'background_notification_handler.dart';
import 'notification_deep_link_service.dart';
import '../../features/momentum/presentation/providers/momentum_api_provider.dart';

/// Service for dispatching notification actions and coordinating app state
class NotificationActionDispatcher {
  static NotificationActionDispatcher? _instance;
  static NotificationActionDispatcher get instance {
    _instance ??= NotificationActionDispatcher._();
    return _instance!;
  }

  NotificationActionDispatcher._();

  BuildContext? _appContext;
  WidgetRef? _appRef;
  bool _isInitialized = false;

  /// Initialize the dispatcher with app context and ref
  void initialize({required BuildContext context, required WidgetRef ref}) {
    _appContext = context;
    _appRef = ref;
    _isInitialized = true;

    if (kDebugMode) {
      print('📋 Notification Action Dispatcher initialized');
    }

    // Process any pending actions from background notifications
    _processPendingBackgroundActions();

    // Apply any cached momentum updates
    _applyCachedMomentumUpdates();
  }

  /// Dispose of the dispatcher
  void dispose() {
    _appContext = null;
    _appRef = null;
    _isInitialized = false;
  }

  /// Handle foreground notification received
  Future<void> handleForegroundNotification(RemoteMessage message) async {
    try {
      if (kDebugMode) {
        print(
          '📱 Handling foreground notification: ${message.notification?.title}',
        );
      }

      // Extract notification data
      final notificationData = _extractNotificationData(message);
      if (notificationData == null) return;

      // Show in-app notification
      await _showInAppNotification(notificationData);

      // Update momentum state if needed
      await _updateMomentumFromNotification(notificationData);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling foreground notification: $e');
      }
    }
  }

  /// Handle notification tap (app opened from notification)
  Future<void> handleNotificationTap(RemoteMessage message) async {
    try {
      if (kDebugMode) {
        print('👆 Handling notification tap: ${message.notification?.title}');
      }

      // Extract notification data
      final notificationData = _extractNotificationData(message);
      if (notificationData == null) return;

      // Process deep link action
      await NotificationDeepLinkService.processNotificationDeepLink(
        actionType: notificationData.actionType,
        actionData: notificationData.actionData,
        notificationId: notificationData.notificationId,
        context: _appContext,
        ref: _appRef,
      );

      // Update momentum state if needed
      await _updateMomentumFromNotification(notificationData);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling notification tap: $e');
      }
    }
  }

  /// Process pending actions from background notifications
  Future<void> _processPendingBackgroundActions() async {
    if (!_isInitialized || _appContext == null || _appRef == null) return;

    try {
      await NotificationDeepLinkService.processPendingActions(
        context: _appContext!,
        ref: _appRef!,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error processing pending background actions: $e');
      }
    }
  }

  /// Apply cached momentum updates from background processing
  Future<void> _applyCachedMomentumUpdates() async {
    if (!_isInitialized || _appRef == null) return;

    try {
      await NotificationDeepLinkService.applyCachedMomentumUpdates(_appRef!);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error applying cached momentum updates: $e');
      }
    }
  }

  /// Extract notification data from Firebase message
  NotificationData? _extractNotificationData(RemoteMessage message) {
    try {
      final data = message.data;
      if (data.isEmpty) return null;

      return NotificationData(
        notificationId: data['notification_id'] ?? '',
        interventionType: data['intervention_type'] ?? '',
        actionType: data['action_type'] ?? '',
        actionData:
            data['action_data'] != null
                ? Map<String, dynamic>.from(
                  data['action_data'] is String
                      ? {}
                      : data['action_data'] as Map,
                )
                : <String, dynamic>{},
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

  /// Show in-app notification for foreground messages
  Future<void> _showInAppNotification(NotificationData data) async {
    if (_appContext == null || !_appContext!.mounted) return;

    // Determine notification priority and style
    final isHighPriority =
        data.actionData['priority'] == 'high' ||
        data.interventionType == 'consecutive_needs_care';

    final isCelebration =
        data.interventionType == 'celebration' ||
        data.actionData['celebration'] == true;

    // Choose appropriate in-app notification style
    if (isCelebration) {
      _showCelebrationNotification(data);
    } else if (isHighPriority) {
      _showHighPriorityNotification(data);
    } else {
      _showStandardNotification(data);
    }
  }

  /// Show celebration in-app notification
  void _showCelebrationNotification(NotificationData data) {
    if (_appContext == null || !_appContext!.mounted) return;

    ScaffoldMessenger.of(_appContext!).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.celebration, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(data.body),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () => _handleNotificationAction(data),
        ),
      ),
    );
  }

  /// Show high priority in-app notification
  void _showHighPriorityNotification(NotificationData data) {
    if (_appContext == null || !_appContext!.mounted) return;

    ScaffoldMessenger.of(_appContext!).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.priority_high, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(data.body),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Take Action',
          textColor: Colors.white,
          onPressed: () => _handleNotificationAction(data),
        ),
      ),
    );
  }

  /// Show standard in-app notification
  void _showStandardNotification(NotificationData data) {
    if (_appContext == null || !_appContext!.mounted) return;

    ScaffoldMessenger.of(_appContext!).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(data.body),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Open',
          textColor: Colors.white,
          onPressed: () => _handleNotificationAction(data),
        ),
      ),
    );
  }

  /// Handle notification action from in-app notification
  Future<void> _handleNotificationAction(NotificationData data) async {
    try {
      await NotificationDeepLinkService.processNotificationDeepLink(
        actionType: data.actionType,
        actionData: data.actionData,
        notificationId: data.notificationId,
        context: _appContext,
        ref: _appRef,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling notification action: $e');
      }
    }
  }

  /// Update momentum state based on notification
  Future<void> _updateMomentumFromNotification(NotificationData data) async {
    if (_appRef == null) return;

    try {
      // Only update for momentum-related notifications
      if (!data.interventionType.contains('momentum') &&
          !data.interventionType.contains('score') &&
          !data.interventionType.contains('celebration')) {
        return;
      }

      // Trigger momentum refresh to get latest data
      final momentumNotifier = _appRef!.read(realtimeMomentumProvider.notifier);
      await momentumNotifier.refresh();

      if (kDebugMode) {
        print('📊 Momentum data refreshed from notification');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating momentum from notification: $e');
      }
    }
  }

  /// Check if dispatcher is ready to handle notifications
  bool get isReady => _isInitialized && _appContext != null && _appRef != null;

  /// Get current app context (for debugging)
  BuildContext? get appContext => _appContext;

  /// Process notification when app state changes
  Future<void> onAppStateChanged(AppLifecycleState state) async {
    if (kDebugMode) {
      print('📱 App state changed: $state');
    }

    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground - check for pending actions
        await _processPendingBackgroundActions();
        await _applyCachedMomentumUpdates();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App going to background - no action needed
        break;
    }
  }

  /// Clear all notification-related cached data
  Future<void> clearNotificationCache() async {
    try {
      await BackgroundNotificationHandler.clearCachedData();
      if (kDebugMode) {
        print('🧹 Notification cache cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing notification cache: $e');
      }
    }
  }

  /// Get notification statistics for debugging
  Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      final lastNotification =
          await BackgroundNotificationHandler.getLastBackgroundNotification();
      final pendingActions =
          await BackgroundNotificationHandler.getPendingActions();

      return {
        'hasLastNotification': lastNotification != null,
        'lastNotificationTime': lastNotification?.receivedAt.toIso8601String(),
        'pendingActionsCount': pendingActions.length,
        'isDispatcherReady': isReady,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting notification stats: $e');
      }
      return {'error': e.toString()};
    }
  }
}
