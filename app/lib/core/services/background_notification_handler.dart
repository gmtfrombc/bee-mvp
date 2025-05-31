import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../notifications/domain/services/notification_core_service.dart';

/// Service for handling notifications in background isolate
/// Delegates to NotificationCoreService for unified processing
class BackgroundNotificationHandler {
  /// Process notification in background isolate
  static Future<void> processBackgroundNotification(
    RemoteMessage message,
  ) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '🔄 BackgroundNotificationHandler: Processing notification: ${message.notification?.title}',
        );
      }

      // Delegate to the unified core service
      await NotificationCoreService.instance.handleBackgroundMessage(message);

      if (kDebugMode) {
        debugPrint('✅ BackgroundNotificationHandler: Processing completed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '❌ BackgroundNotificationHandler: Error processing notification: $e',
        );
      }
    }
  }
}
