import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Handles user permission prompts for push notifications.
class NotificationPermissionHelper {
  final FirebaseMessaging? _messaging;

  NotificationPermissionHelper([this._messaging]);

  /// Request notification permissions from the OS & Firebase.
  Future<bool> requestPermissions() async {
    try {
      if (_messaging == null) return false;
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      final systemPermission = await Permission.notification.request();

      if (kDebugMode) {
        debugPrint('FCM Authorization Status: ${settings.authorizationStatus}');
        debugPrint('System Permission Status: $systemPermission');
      }

      final hasPermission =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      return hasPermission && systemPermission.isGranted;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error requesting notification permissions: $e');
      }
      return false;
    }
  }

  /// Whether the app currently has permissions.
  Future<bool> hasPermissions() async {
    try {
      if (_messaging == null) return false;
      final settings = await _messaging.getNotificationSettings();
      final systemPermission = await Permission.notification.status;

      final hasPermission =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      return hasPermission && systemPermission.isGranted;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking notification permissions: $e');
      }
      return false;
    }
  }
}
