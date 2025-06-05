import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../domain/models/notification_models.dart';
import '../domain/services/notification_core_service.dart';
import 'notification_deep_link_service.dart';
import '../../../features/momentum/presentation/providers/momentum_api_provider.dart';

/// Infrastructure service for dispatching notification actions and managing in-app display
/// Handles action routing, in-app notifications, and UI coordination
class NotificationDispatcher {
  static NotificationDispatcher? _instance;
  static NotificationDispatcher get instance {
    _instance ??= NotificationDispatcher._();
    return _instance!;
  }

  NotificationDispatcher._();

  BuildContext? _appContext;
  WidgetRef? _appRef;
  bool _isInitialized = false;

  /// Initialize the dispatcher with app context and ref
  void initialize({required BuildContext context, required WidgetRef ref}) {
    _appContext = context;
    _appRef = ref;
    _isInitialized = true;

    if (kDebugMode) {
      debugPrint('📋 NotificationDispatcher initialized');
    }

    // Process pending actions and updates asynchronously without blocking initialization
    _safeProcessBackgroundOperations();
  }

  /// Safely process background operations with proper context handling
  Future<void> _safeProcessBackgroundOperations() async {
    // Store context reference before async operations
    final context = _appContext;
    final ref = _appRef;

    if (context == null || ref == null) return;

    try {
      // Process any pending actions from background notifications
      await _processPendingBackgroundActions();

      // Apply any cached momentum updates
      await _applyCachedMomentumUpdates();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error in background operations: $e');
      }
    }
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
        debugPrint(
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
        debugPrint('❌ Error handling foreground notification: $e');
      }
    }
  }

  /// Handle notification tap (app opened from notification)
  Future<void> handleNotificationTap(RemoteMessage message) async {
    try {
      if (kDebugMode) {
        debugPrint('👆 Handling notification tap: ${message.notification?.title}');
      }

      // Extract notification data
      final notificationData = _extractNotificationData(message);
      if (notificationData == null) return;

      // Process deep link action via infrastructure service
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
        debugPrint('❌ Error handling notification tap: $e');
      }
    }
  }

  /// Handle app lifecycle state changes
  Future<void> onAppStateChanged(AppLifecycleState state) async {
    if (kDebugMode) {
      debugPrint('📱 App state changed: $state');
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

  /// Process pending actions from background notifications
  Future<void> _processPendingBackgroundActions() async {
    // Store context and ref before async operations
    final context = _appContext;
    final ref = _appRef;

    if (!_isInitialized || context == null || ref == null) return;

    try {
      await NotificationDeepLinkService.processPendingActions(
        context: context,
        ref: ref,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error processing pending background actions: $e');
      }
    }
  }

  /// Apply cached momentum updates from background processing
  Future<void> _applyCachedMomentumUpdates() async {
    // Store ref before async operations
    final ref = _appRef;

    if (!_isInitialized || ref == null) return;

    try {
      await NotificationDeepLinkService.applyCachedMomentumUpdates(ref);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error applying cached momentum updates: $e');
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
        debugPrint('Error extracting notification data: $e');
      }
      return null;
    }
  }

  /// Show in-app notification for foreground messages
  Future<void> _showInAppNotification(NotificationData data) async {
    // Store context before async operations
    final context = _appContext;
    if (context == null || !context.mounted) return;

    // Determine notification priority and style
    final isHighPriority =
        data.actionData['priority'] == 'high' ||
        data.interventionType == 'consecutive_needs_care';

    final isCelebration =
        data.interventionType == 'celebration' ||
        data.actionData['celebration'] == true;

    // Choose appropriate in-app notification style
    if (isCelebration) {
      _showCelebrationNotification(data, context);
    } else if (isHighPriority) {
      _showHighPriorityNotification(data, context);
    } else {
      _showStandardNotification(data, context);
    }
  }

  /// Show celebration in-app notification
  void _showCelebrationNotification(
    NotificationData data,
    BuildContext context,
  ) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
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
  void _showHighPriorityNotification(
    NotificationData data,
    BuildContext context,
  ) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
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
  void _showStandardNotification(NotificationData data, BuildContext context) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
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
    // Store context and ref before async operations
    final context = _appContext;
    final ref = _appRef;

    if (context == null || ref == null) return;

    try {
      await NotificationDeepLinkService.processNotificationDeepLink(
        actionType: data.actionType,
        actionData: data.actionData,
        notificationId: data.notificationId,
        context: context,
        ref: ref,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error handling notification action: $e');
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
      final momentumController = _appRef!.read(momentumControllerProvider);
      await momentumController.refresh();

      if (kDebugMode) {
        debugPrint('📊 Momentum data refreshed from notification');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating momentum from notification: $e');
      }
    }
  }

  /// Clear all notification-related cached data
  Future<void> clearNotificationCache() async {
    try {
      await NotificationCoreService.instance.clearCachedData();
      if (kDebugMode) {
        debugPrint('🧹 Notification cache cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error clearing notification cache: $e');
      }
    }
  }

  /// Get notification statistics for debugging
  Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      final lastNotification =
          await NotificationCoreService.instance
              .getLastBackgroundNotification();
      final pendingActions =
          await NotificationCoreService.instance.getPendingActions();

      return {
        'hasLastNotification': lastNotification != null,
        'lastNotificationTime': lastNotification?.receivedAt.toIso8601String(),
        'pendingActionsCount': pendingActions.length,
        'isDispatcherReady': isReady,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting notification stats: $e');
      }
      return {'error': e.toString()};
    }
  }

  /// Check if dispatcher is ready to handle notifications
  bool get isReady => _isInitialized && _appContext != null && _appRef != null;

  /// Get current app context (for debugging)
  BuildContext? get appContext => _appContext;
}
