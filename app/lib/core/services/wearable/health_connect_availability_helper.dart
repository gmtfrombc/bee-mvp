/// Utilities for checking Android Health Connect availability
/// and generating detailed availability diagnostics.
///
/// Extracted from `wearable_data_repository.dart` to reduce file size and
/// keep platform-specific checks isolated.
///
/// The helper keeps **no** mutable state – callers must provide a `Health`
/// instance from the `health` package.

library wearable.health_connect_availability_helper;

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:health/health.dart';

import '../wearable_data_models.dart';

/// Static wrapper class – never instantiate.
class HealthConnectAvailabilityHelper {
  const HealthConnectAvailabilityHelper._();

  /// Lightweight boolean check used during repository initialization.
  static Future<bool> isHealthConnectAvailable(Health health) async {
    if (!Platform.isAndroid) return false;

    try {
      // Probe a benign permission call – throws if Health Connect missing.
      final healthDataTypes = [HealthDataType.STEPS];
      final permissions = [HealthDataAccess.READ];
      await health.hasPermissions(healthDataTypes, permissions: permissions);
      return true;
    } on PlatformException catch (e) {
      // Look for common patterns signalling HC absence.
      final patterns = [
        'HEALTH_CONNECT_NOT_AVAILABLE',
        'health_connect_not_installed',
        'HealthConnectClient not available',
        'Health Connect not found',
        'androidx.health.platform',
      ];
      final msg = '${e.code} ${e.message}'.toLowerCase();
      return !patterns.any((p) => msg.contains(p.toLowerCase()));
    } catch (e) {
      // Fallback heuristic – treat as unavailable when errors mention HC.
      final msg = e.toString().toLowerCase();
      final hcHint =
          msg.contains('health connect') ||
          msg.contains('healthconnect') ||
          msg.contains('not installed') ||
          msg.contains('not available');
      return !hcHint;
    }
  }

  /// Rich diagnostic variant used by UI to give user-friendly guidance.
  static Future<HealthConnectAvailabilityResult> detailedAvailability(
    Health health,
  ) async {
    if (!Platform.isAndroid) {
      return const HealthConnectAvailabilityResult(
        isAvailable: false,
        unavailabilityReason: HealthConnectUnavailabilityReason.notAndroid,
        userMessage: 'Health Connect is only available on Android devices.',
        canInstall: false,
      );
    }

    try {
      final healthDataTypes = [HealthDataType.STEPS];
      final permissions = [HealthDataAccess.READ];

      await health.hasPermissions(healthDataTypes, permissions: permissions);

      return const HealthConnectAvailabilityResult(
        isAvailable: true,
        unavailabilityReason: null,
        userMessage: 'Health Connect is available and ready to use.',
        canInstall: false,
      );
    } on PlatformException catch (e) {
      final msg = '${e.code} ${e.message}'.toLowerCase();

      if (msg.contains('not_supported') || msg.contains('unsupported')) {
        return const HealthConnectAvailabilityResult(
          isAvailable: false,
          unavailabilityReason:
              HealthConnectUnavailabilityReason.deviceNotSupported,
          userMessage:
              'Your Android device does not support Health Connect. Minimum Android 9+ required.',
          canInstall: false,
        );
      }
      if (msg.contains('not_installed') ||
          msg.contains('not_available') ||
          msg.contains('health_connect_not_available')) {
        return const HealthConnectAvailabilityResult(
          isAvailable: false,
          unavailabilityReason: HealthConnectUnavailabilityReason.notInstalled,
          userMessage:
              'Health Connect app is not installed. Install it from the Play Store to continue.',
          canInstall: true,
        );
      }
      if (msg.contains('version') || msg.contains('outdated')) {
        return const HealthConnectAvailabilityResult(
          isAvailable: false,
          unavailabilityReason:
              HealthConnectUnavailabilityReason.outdatedVersion,
          userMessage:
              'Health Connect app needs to be updated. Please update from the Play Store.',
          canInstall: true,
        );
      }

      // Unknown – provide generic guidance but mark installable.
      return HealthConnectAvailabilityResult(
        isAvailable: false,
        unavailabilityReason: HealthConnectUnavailabilityReason.unknown,
        userMessage:
            'Health Connect issue detected: ${e.message}. Try installing or updating Health Connect.',
        canInstall: true,
        debugInfo: {'platformException': '${e.code}: ${e.message}'},
      );
    } catch (e) {
      return HealthConnectAvailabilityResult(
        isAvailable: false,
        unavailabilityReason: HealthConnectUnavailabilityReason.unknown,
        userMessage:
            'Cannot access Health Connect. Try installing the Health Connect app.',
        canInstall: true,
        debugInfo: {'generalError': e.toString()},
      );
    }
  }
}
