/// Android Settings Service
///
/// Handles opening Android-specific settings screens including Health Connect
/// permissions and app settings. Provides fallback mechanisms for different
/// Android versions and Health Connect availability.
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service for opening Android-specific settings screens
class AndroidSettingsService {
  static const AndroidSettingsService _instance =
      AndroidSettingsService._internal();
  factory AndroidSettingsService() => _instance;
  const AndroidSettingsService._internal();

  // Method channel for Android-specific functionality
  static const MethodChannel _channel = MethodChannel(
    'com.momentumhealth.beemvp/android_settings',
  );

  /// Open Health Connect specific settings for permanent permission denial
  Future<bool> openHealthConnectSettings() async {
    if (!Platform.isAndroid) return false;

    try {
      // Try Health Connect app settings directly
      final success =
          await _channel.invokeMethod<bool>('openHealthConnectSettings') ??
          false;
      if (success) {
        debugPrint('AndroidSettingsService: Opened Health Connect settings');
        return true;
      }

      // Fallback to app settings if Health Connect settings unavailable
      return await openAppSettings();
    } catch (e) {
      debugPrint(
        'AndroidSettingsService: Error opening Health Connect settings: $e',
      );
      return await openAppSettings();
    }
  }

  /// Open the app's settings page (where permissions can be managed)
  Future<bool> openAppSettings() async {
    if (!Platform.isAndroid) return false;

    try {
      final success =
          await _channel.invokeMethod<bool>('openAppSettings') ?? false;
      if (success) {
        debugPrint('AndroidSettingsService: Opened app settings');
        return true;
      }

      // Last resort fallback
      return await openGeneralSettings();
    } catch (e) {
      debugPrint('AndroidSettingsService: Error opening app settings: $e');
      return await openGeneralSettings();
    }
  }

  /// Open general Android settings as final fallback
  Future<bool> openGeneralSettings() async {
    if (!Platform.isAndroid) return false;

    try {
      final success =
          await _channel.invokeMethod<bool>('openGeneralSettings') ?? false;
      debugPrint('AndroidSettingsService: Opened general settings: $success');
      return success;
    } catch (e) {
      debugPrint('AndroidSettingsService: Error opening general settings: $e');
      return false;
    }
  }

  /// Check if Health Connect settings can be opened
  Future<bool> canOpenHealthConnectSettings() async {
    if (!Platform.isAndroid) return false;

    try {
      return await _channel.invokeMethod<bool>(
            'canOpenHealthConnectSettings',
          ) ??
          false;
    } catch (e) {
      debugPrint(
        'AndroidSettingsService: Error checking Health Connect settings availability: $e',
      );
      return false;
    }
  }

  /// Get user-friendly instructions for enabling permissions manually
  String getPermissionInstructions({bool isHealthConnectAvailable = true}) {
    if (isHealthConnectAvailable) {
      return '''To enable health permissions:

1. Open Health Connect from the button below
2. Find our app (BEE-MVP) in the connected apps list
3. Enable permissions for: Steps, Heart Rate, Sleep, and Active Energy
4. Return to our app and try again

If Health Connect settings don't open, use your device's Settings app:
Settings > Apps > Health Connect > Connected apps > BEE-MVP''';
    } else {
      return '''To enable health permissions:

1. Open your device Settings
2. Go to Apps > BEE-MVP > Permissions
3. Enable all health-related permissions
4. Install Health Connect from Play Store if available
5. Return to our app and try again''';
    }
  }
}
