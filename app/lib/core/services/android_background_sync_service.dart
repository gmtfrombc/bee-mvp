/// Android Health Connect Background Sync Service
///
/// Handles Health Connect background data sync permissions and 30-day limitations.
/// Part of Epic 2.2 Task T2.2.2.13
library android_background_sync_service;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:app/core/services/wearable_data_models.dart';

/// Background sync status for Health Connect
enum BackgroundSyncStatus { available, limited, denied, unsupported }

/// Result of background sync check
class BackgroundSyncResult {
  final BackgroundSyncStatus status;
  final String message;
  final Duration? dataLimit;

  const BackgroundSyncResult({
    required this.status,
    required this.message,
    this.dataLimit,
  });

  bool get isAvailable => status == BackgroundSyncStatus.available;
  bool get isLimited => status == BackgroundSyncStatus.limited;
}

/// Android Health Connect Background Sync Service
class AndroidBackgroundSyncService {
  static final AndroidBackgroundSyncService _instance =
      AndroidBackgroundSyncService._internal();
  factory AndroidBackgroundSyncService() => _instance;
  AndroidBackgroundSyncService._internal();

  final Health _health = Health();
  static const Duration _defaultDataLimit = Duration(days: 30);

  /// Check if Health Connect background sync is supported
  Future<bool> isSupported() async {
    if (!Platform.isAndroid) return false;

    try {
      await _health.configure();
      return true;
    } catch (e) {
      debugPrint('AndroidBackgroundSync: Platform check failed - $e');
      return false;
    }
  }

  /// Check background sync permissions and limitations
  Future<BackgroundSyncResult> checkBackgroundSync() async {
    try {
      // Check platform support
      final supported = await isSupported();
      if (!supported) {
        return const BackgroundSyncResult(
          status: BackgroundSyncStatus.unsupported,
          message: 'Health Connect not available',
        );
      }

      // Check basic permissions
      final hasPermissions = await _checkBasicPermissions();
      if (!hasPermissions) {
        return const BackgroundSyncResult(
          status: BackgroundSyncStatus.denied,
          message: 'Health permissions required',
        );
      }

      // Test 30-day data limitation
      final limitResult = await _checkDataLimitation();
      return limitResult;
    } catch (e) {
      debugPrint('AndroidBackgroundSync: Check failed - $e');
      return BackgroundSyncResult(
        status: BackgroundSyncStatus.denied,
        message: 'Check failed: ${e.toString()}',
      );
    }
  }

  /// Request background sync permissions
  Future<BackgroundSyncResult> requestPermissions({
    List<WearableDataType>? dataTypes,
  }) async {
    try {
      final types =
          dataTypes ??
          [
            WearableDataType.steps,
            WearableDataType.heartRate,
            WearableDataType.sleepDuration,
          ];

      final healthTypes =
          types
              .map((type) => type.toHealthDataType())
              .where((type) => type != null)
              .cast<HealthDataType>()
              .toList();

      if (healthTypes.isEmpty) {
        return const BackgroundSyncResult(
          status: BackgroundSyncStatus.denied,
          message: 'No valid data types',
        );
      }

      final permissions =
          healthTypes.map((type) => HealthDataAccess.READ).toList();
      final granted = await _health.requestAuthorization(
        healthTypes,
        permissions: permissions,
      );

      if (granted) {
        return await checkBackgroundSync();
      } else {
        return const BackgroundSyncResult(
          status: BackgroundSyncStatus.denied,
          message: 'User denied permissions',
        );
      }
    } catch (e) {
      debugPrint('AndroidBackgroundSync: Request failed - $e');
      return BackgroundSyncResult(
        status: BackgroundSyncStatus.denied,
        message: 'Request failed: ${e.toString()}',
      );
    }
  }

  /// Check basic health permissions
  Future<bool> _checkBasicPermissions() async {
    try {
      final basicTypes = [HealthDataType.STEPS, HealthDataType.HEART_RATE];
      final hasPermissions = await _health.hasPermissions(basicTypes);
      return hasPermissions ?? false;
    } catch (e) {
      debugPrint('AndroidBackgroundSync: Permission check failed - $e');
      return false;
    }
  }

  /// Check Health Connect 30-day data limitation
  Future<BackgroundSyncResult> _checkDataLimitation() async {
    try {
      final now = DateTime.now();
      final limitDate = now.subtract(_defaultDataLimit);

      // Test access to data beyond 30-day limit
      final testData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: limitDate.subtract(const Duration(days: 1)),
        endTime: limitDate,
      );

      if (testData.isNotEmpty) {
        return const BackgroundSyncResult(
          status: BackgroundSyncStatus.available,
          message: 'Full background access available',
        );
      }

      // Limited to recent data
      return const BackgroundSyncResult(
        status: BackgroundSyncStatus.limited,
        message: 'Background sync limited to 30 days',
        dataLimit: _defaultDataLimit,
      );
    } catch (e) {
      debugPrint('AndroidBackgroundSync: Limitation check failed - $e');
      return const BackgroundSyncResult(
        status: BackgroundSyncStatus.limited,
        message: 'Background data access may be limited',
        dataLimit: _defaultDataLimit,
      );
    }
  }
}
