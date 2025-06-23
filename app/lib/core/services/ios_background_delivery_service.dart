/// iOS Background Health Data Delivery Service
///
/// Implements modern polling-based background health data delivery with 5s throttling.
/// Updated for June 2025 best practices using Flutter health package v13.0.1+.
/// Follows iOS 15.2+ background delivery patterns and budget limitations.
/// Part of Epic 2.2 Task T2.2.2.2
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'wearable_live_models.dart';
import 'wearable_data_models.dart';

/// Configuration for iOS background delivery
/// Updated for iOS 15.2+ background delivery budget limitations (4/hour)
class IOSBackgroundDeliveryConfig {
  final Duration throttleInterval;
  final Set<WearableDataType> enabledTypes;
  final Duration pollingInterval;
  final int maxBatchSize;
  final Duration backgroundLookback;

  const IOSBackgroundDeliveryConfig({
    this.throttleInterval = const Duration(seconds: 5),
    this.enabledTypes = const {
      WearableDataType.heartRate,
      WearableDataType.steps,
      WearableDataType.activeEnergyBurned,
    },
    this.pollingInterval = const Duration(minutes: 15),
    this.maxBatchSize = 50,
    this.backgroundLookback = const Duration(minutes: 10),
  });
}

/// Result of background delivery setup
sealed class BackgroundDeliverySetupResult {
  const BackgroundDeliverySetupResult();
}

class BackgroundDeliverySuccess extends BackgroundDeliverySetupResult {
  final Set<WearableDataType> enabledTypes;
  const BackgroundDeliverySuccess(this.enabledTypes);
}

class BackgroundDeliveryFailure extends BackgroundDeliverySetupResult {
  final String error;
  final Set<WearableDataType> failedTypes;
  const BackgroundDeliveryFailure(this.error, this.failedTypes);
}

class BackgroundDeliveryUnsupported extends BackgroundDeliverySetupResult {
  const BackgroundDeliveryUnsupported();
}

/// iOS background delivery service using polling-based approach
/// Follows modern Flutter 3.32.1 patterns and component guidelines
class IOSBackgroundDeliveryService {
  final Health _health;
  final StreamController<WearableLiveMessage> _messageController;
  final IOSBackgroundDeliveryConfig _config;

  // Throttling and polling state
  final Map<WearableDataType, DateTime> _lastDeliveryTimes = {};
  final Map<WearableDataType, DateTime> _lastFetchTimes = {};
  final Map<WearableDataType, List<HealthDataPoint>> _pendingBatches = {};

  // Service state
  bool _isActive = false;
  Timer? _pollingTimer;
  Timer? _batchTimer;

  IOSBackgroundDeliveryService(
    this._health,
    this._messageController, {
    IOSBackgroundDeliveryConfig? config,
  }) : _config = config ?? const IOSBackgroundDeliveryConfig();

  /// Check if iOS background delivery is supported
  bool get isSupported => Platform.isIOS;

  /// Get current active status
  bool get isActive => _isActive;

  /// Get enabled data types
  Set<WearableDataType> get enabledTypes => _config.enabledTypes;

  /// Setup background delivery for enabled health data types
  /// Updated for iOS 15.2+ background delivery optimizations and budget limitations
  Future<BackgroundDeliverySetupResult> setupBackgroundDelivery() async {
    if (!isSupported) {
      return const BackgroundDeliveryUnsupported();
    }

    try {
      // Check if health permissions are accessible (iOS device with HealthKit)
      // Modern health package v13.0.1+ approach for iOS compatibility check
      try {
        await _health.configure();
      } catch (e) {
        return BackgroundDeliveryFailure(
          'Health data not available on this device: $e',
          <WearableDataType>{},
        );
      }

      final enabledTypes = <WearableDataType>{};
      final failedTypes = <WearableDataType>{};

      // Check permissions for each data type
      for (final dataType in _config.enabledTypes) {
        final success = await _checkDataTypePermissions(dataType);
        if (success) {
          enabledTypes.add(dataType);
          _initializeDataType(dataType);
        } else {
          failedTypes.add(dataType);
        }
      }

      if (enabledTypes.isNotEmpty) {
        _isActive = true;
        _startPollingTimer();
        _startBatchProcessor();

        debugPrint(
          'IOSBackgroundDelivery: Setup complete for iOS 15.2+ '
          '(Budget: ~4 updates/hour, Polling: ${_config.pollingInterval.inMinutes}min)',
        );

        return BackgroundDeliverySuccess(enabledTypes);
      } else {
        return BackgroundDeliveryFailure(
          'No data types have valid permissions',
          failedTypes,
        );
      }
    } catch (e) {
      return BackgroundDeliveryFailure(
        'Setup failed: $e',
        _config.enabledTypes,
      );
    }
  }

  /// Check permissions for a specific data type
  Future<bool> _checkDataTypePermissions(WearableDataType dataType) async {
    try {
      final healthType = _mapToHealthDataType(dataType);
      if (healthType == null) return false;

      final hasPermission = await _health.hasPermissions([healthType]);
      return hasPermission == true;
    } catch (e) {
      debugPrint(
        'IOSBackgroundDelivery: Permission check failed for $dataType - $e',
      );
      return false;
    }
  }

  /// Initialize data type for tracking
  void _initializeDataType(WearableDataType dataType) {
    _lastFetchTimes[dataType] = DateTime.now().subtract(
      _config.backgroundLookback,
    );
    _pendingBatches[dataType] = [];
  }

  /// Start polling timer for background data fetching
  void _startPollingTimer() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_config.pollingInterval, (_) {
      _pollHealthData();
    });
  }

  /// Poll health data for all enabled types
  Future<void> _pollHealthData() async {
    if (!_isActive) return;

    for (final dataType in enabledTypes) {
      try {
        await _pollDataType(dataType);
      } catch (e) {
        debugPrint('IOSBackgroundDelivery: Polling failed for $dataType - $e');
      }
    }
  }

  /// Poll health data for a specific data type
  Future<void> _pollDataType(WearableDataType dataType) async {
    final healthType = _mapToHealthDataType(dataType);
    if (healthType == null) return;

    final now = DateTime.now();
    final lastFetch =
        _lastFetchTimes[dataType] ?? now.subtract(_config.backgroundLookback);

    try {
      final healthData = await _health.getHealthDataFromTypes(
        types: [healthType],
        startTime: lastFetch,
        endTime: now,
      );

      if (healthData.isNotEmpty) {
        _processNewHealthData(dataType, healthData);
        _lastFetchTimes[dataType] = now;
      }
    } catch (e) {
      debugPrint('IOSBackgroundDelivery: Failed to fetch $dataType data - $e');
    }
  }

  /// Process new health data with throttling
  void _processNewHealthData(
    WearableDataType dataType,
    List<HealthDataPoint> data,
  ) {
    if (!_isActive || data.isEmpty) return;

    final now = DateTime.now();
    final lastDelivery = _lastDeliveryTimes[dataType];

    // Check throttling
    if (lastDelivery != null &&
        now.difference(lastDelivery) < _config.throttleInterval) {
      // Add to pending batch
      _pendingBatches[dataType]?.addAll(data);
      return;
    }

    // Process immediately if not throttled
    _deliverHealthData(dataType, data);
    _lastDeliveryTimes[dataType] = now;
  }

  /// Deliver health data to message stream
  void _deliverHealthData(
    WearableDataType dataType,
    List<HealthDataPoint> data,
  ) {
    try {
      for (final point in data) {
        final message = _convertToLiveMessage(dataType, point);
        if (message != null) {
          _messageController.add(message);
        }
      }

      debugPrint(
        'IOSBackgroundDelivery: Delivered ${data.length} $dataType samples',
      );
    } catch (e) {
      debugPrint(
        'IOSBackgroundDelivery: Failed to deliver $dataType data - $e',
      );
    }
  }

  /// Convert HealthDataPoint to WearableLiveMessage
  WearableLiveMessage? _convertToLiveMessage(
    WearableDataType dataType,
    HealthDataPoint point,
  ) {
    try {
      return WearableLiveMessage(
        timestamp: point.dateFrom,
        type: dataType,
        value: _extractValue(point),
        source: point.sourceName,
      );
    } catch (e) {
      debugPrint('IOSBackgroundDelivery: Failed to convert data point - $e');
      return null;
    }
  }

  /// Extract numeric value from HealthDataPoint
  dynamic _extractValue(HealthDataPoint point) {
    try {
      final value = point.value;
      if (value is NumericHealthValue) {
        return value.numericValue;
      }
      return value.toString();
    } catch (e) {
      return null;
    }
  }

  /// Start batch processor for pending data
  void _startBatchProcessor() {
    _batchTimer?.cancel();
    _batchTimer = Timer.periodic(_config.throttleInterval, (_) {
      _processPendingBatches();
    });
  }

  /// Process pending data batches
  void _processPendingBatches() {
    if (!_isActive) return;

    for (final entry in _pendingBatches.entries) {
      final dataType = entry.key;
      final batch = entry.value;

      if (batch.isNotEmpty) {
        // Take up to maxBatchSize items
        final processBatch = batch.take(_config.maxBatchSize).toList();
        batch.removeRange(0, processBatch.length);

        _deliverHealthData(dataType, processBatch);
        _lastDeliveryTimes[dataType] = DateTime.now();
      }
    }
  }

  /// Map WearableDataType to HealthDataType
  HealthDataType? _mapToHealthDataType(WearableDataType dataType) {
    switch (dataType) {
      case WearableDataType.heartRate:
        return HealthDataType.HEART_RATE;
      case WearableDataType.steps:
        return HealthDataType.STEPS;
      case WearableDataType.activeEnergyBurned:
        return HealthDataType.ACTIVE_ENERGY_BURNED;
      case WearableDataType.sleepDuration:
        return HealthDataType.SLEEP_IN_BED;
      case WearableDataType.vo2Max:
        return HealthDataType.WORKOUT;
      case WearableDataType.restingHeartRate:
        return HealthDataType.RESTING_HEART_RATE;
      case WearableDataType.heartRateVariability:
        return HealthDataType.HEART_RATE_VARIABILITY_SDNN;
      default:
        return null;
    }
  }

  /// Stop background delivery
  Future<void> stopBackgroundDelivery() async {
    if (!_isActive) return;

    _isActive = false;

    // Cancel timers
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _batchTimer?.cancel();
    _batchTimer = null;

    // Clear state
    _pendingBatches.clear();
    _lastDeliveryTimes.clear();
    _lastFetchTimes.clear();

    debugPrint('IOSBackgroundDelivery: Stopped background delivery');
  }

  /// Pause background delivery (temporary)
  void pauseBackgroundDelivery() {
    _pollingTimer?.cancel();
    _batchTimer?.cancel();
    debugPrint('IOSBackgroundDelivery: Paused background delivery');
  }

  /// Resume background delivery
  void resumeBackgroundDelivery() {
    if (_isActive) {
      _startPollingTimer();
      _startBatchProcessor();
      debugPrint('IOSBackgroundDelivery: Resumed background delivery');
    }
  }

  /// Get current delivery statistics
  Map<String, dynamic> getDeliveryStats() {
    return {
      'isActive': _isActive,
      'isSupported': isSupported,
      'enabledTypes': _config.enabledTypes.map((e) => e.name).toList(),
      'pollingInterval': _config.pollingInterval.inSeconds,
      'throttleInterval': _config.throttleInterval.inSeconds,
      'pendingBatches': _pendingBatches.map(
        (key, value) => MapEntry(key.name, value.length),
      ),
      'lastDeliveryTimes': _lastDeliveryTimes.map(
        (key, value) => MapEntry(key.name, value.toIso8601String()),
      ),
      'lastFetchTimes': _lastFetchTimes.map(
        (key, value) => MapEntry(key.name, value.toIso8601String()),
      ),
    };
  }

  /// Update configuration
  void updateConfig(IOSBackgroundDeliveryConfig newConfig) {
    // Note: This requires restart to take effect
    debugPrint('IOSBackgroundDelivery: Configuration update requires restart');
  }

  /// Dispose service and clean up resources
  Future<void> dispose() async {
    await stopBackgroundDelivery();
  }
}
