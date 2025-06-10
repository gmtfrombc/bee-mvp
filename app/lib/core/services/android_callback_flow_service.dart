/// Android Health Connect Callback Flow Service
///
/// Implements real-time Health Connect data streaming using coroutine channels
/// with 5-second throttling identical to iOS. Follows PassiveListenerService pattern.
/// Part of Epic 2.2 Task T2.2.2.3
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'wearable_live_models.dart';
import 'wearable_data_models.dart';

/// Configuration for Android callback flow
class AndroidCallbackFlowConfig {
  final Duration throttleInterval;
  final Set<WearableDataType> enabledTypes;
  final Duration subscriptionInterval;
  final int maxBatchSize;
  final Duration lookbackDuration;

  const AndroidCallbackFlowConfig({
    this.throttleInterval = const Duration(seconds: 5),
    this.enabledTypes = const {
      WearableDataType.heartRate,
      WearableDataType.steps,
      WearableDataType.activeEnergyBurned,
    },
    this.subscriptionInterval = const Duration(seconds: 10),
    this.maxBatchSize = 50,
    this.lookbackDuration = const Duration(minutes: 10),
  });
}

/// Result of callback flow setup
sealed class CallbackFlowSetupResult {
  const CallbackFlowSetupResult();
}

class CallbackFlowSuccess extends CallbackFlowSetupResult {
  final Set<WearableDataType> enabledTypes;
  const CallbackFlowSuccess(this.enabledTypes);
}

class CallbackFlowFailure extends CallbackFlowSetupResult {
  final String error;
  final Set<WearableDataType> failedTypes;
  const CallbackFlowFailure(this.error, this.failedTypes);
}

class CallbackFlowUnsupported extends CallbackFlowSetupResult {
  const CallbackFlowUnsupported();
}

/// Android Health Connect callback flow service using coroutine channel pattern
class AndroidCallbackFlowService {
  final Health _health;
  final StreamController<WearableLiveMessage> _messageController;
  final AndroidCallbackFlowConfig _config;

  // Throttling and subscription state
  final Map<WearableDataType, DateTime> _lastDeliveryTimes = {};
  final Map<WearableDataType, DateTime> _lastFetchTimes = {};
  final Map<WearableDataType, List<HealthDataPoint>> _pendingBatches = {};
  final Map<WearableDataType, StreamSubscription?> _subscriptions = {};

  // Service state
  bool _isActive = false;
  Timer? _batchTimer;

  AndroidCallbackFlowService(
    this._health,
    this._messageController, {
    AndroidCallbackFlowConfig? config,
  }) : _config = config ?? const AndroidCallbackFlowConfig();

  /// Check if Android Health Connect callback flow is supported
  bool get isSupported => Platform.isAndroid;

  /// Get current active status
  bool get isActive => _isActive;

  /// Get enabled data types
  Set<WearableDataType> get enabledTypes => _config.enabledTypes;

  /// Setup Health Connect callback flow for enabled health data types
  Future<CallbackFlowSetupResult> setupCallbackFlow() async {
    if (!isSupported) {
      return const CallbackFlowUnsupported();
    }

    try {
      // Check Health Connect availability
      try {
        await _health.configure();
      } catch (e) {
        return CallbackFlowFailure(
          'Health Connect not available on this device: $e',
          <WearableDataType>{},
        );
      }

      final enabledTypes = <WearableDataType>{};
      final failedTypes = <WearableDataType>{};

      // Setup subscriptions for each data type
      for (final dataType in _config.enabledTypes) {
        final success = await _setupDataTypeSubscription(dataType);
        if (success) {
          enabledTypes.add(dataType);
          _initializeDataType(dataType);
        } else {
          failedTypes.add(dataType);
        }
      }

      if (enabledTypes.isNotEmpty) {
        _isActive = true;
        _startBatchProcessor();

        debugPrint(
          'AndroidCallbackFlow: Setup complete for Health Connect '
          '(Throttling: ${_config.throttleInterval.inSeconds}s)',
        );

        return CallbackFlowSuccess(enabledTypes);
      } else {
        return CallbackFlowFailure(
          'No data types have valid Health Connect access',
          failedTypes,
        );
      }
    } catch (e) {
      return CallbackFlowFailure('Setup failed: $e', _config.enabledTypes);
    }
  }

  /// Setup subscription for a specific data type using coroutine channel pattern
  Future<bool> _setupDataTypeSubscription(WearableDataType dataType) async {
    try {
      final healthType = _mapToHealthDataType(dataType);
      if (healthType == null) return false;

      // Check permissions first
      final hasPermission = await _health.hasPermissions([healthType]);
      if (hasPermission != true) return false;

      // Create coroutine-like subscription using periodic polling
      // (Health Connect doesn't expose true push notifications yet)
      final subscription = Stream.periodic(
        _config.subscriptionInterval,
        (_) => _fetchDataTypeUpdates(dataType),
      ).listen((_) {});

      _subscriptions[dataType] = subscription;

      debugPrint('AndroidCallbackFlow: Subscription active for $dataType');
      return true;
    } catch (e) {
      debugPrint(
        'AndroidCallbackFlow: Subscription setup failed for $dataType - $e',
      );
      return false;
    }
  }

  /// Initialize data type for tracking
  void _initializeDataType(WearableDataType dataType) {
    _lastFetchTimes[dataType] = DateTime.now().subtract(
      _config.lookbackDuration,
    );
    _pendingBatches[dataType] = [];
  }

  /// Fetch updates for a specific data type (coroutine channel pattern)
  Future<void> _fetchDataTypeUpdates(WearableDataType dataType) async {
    if (!_isActive) return;

    final healthType = _mapToHealthDataType(dataType);
    if (healthType == null) return;

    final now = DateTime.now();
    final lastFetch =
        _lastFetchTimes[dataType] ?? now.subtract(_config.lookbackDuration);

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
      debugPrint('AndroidCallbackFlow: Failed to fetch $dataType data - $e');
    }
  }

  /// Process new health data with throttling (identical to iOS)
  void _processNewHealthData(
    WearableDataType dataType,
    List<HealthDataPoint> data,
  ) {
    if (!_isActive || data.isEmpty) return;

    final now = DateTime.now();
    final lastDelivery = _lastDeliveryTimes[dataType];

    // Check throttling (identical to iOS 5-second throttling)
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
        'AndroidCallbackFlow: Delivered ${data.length} $dataType samples',
      );
    } catch (e) {
      debugPrint('AndroidCallbackFlow: Failed to deliver $dataType data - $e');
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
      debugPrint('AndroidCallbackFlow: Failed to convert data point - $e');
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
      case WearableDataType.restingHeartRate:
        return HealthDataType.RESTING_HEART_RATE;
      case WearableDataType.heartRateVariability:
        return HealthDataType.HEART_RATE_VARIABILITY_SDNN;
      default:
        return null;
    }
  }

  /// Stop callback flow
  Future<void> stopCallbackFlow() async {
    if (!_isActive) return;

    _isActive = false;

    // Cancel batch timer
    _batchTimer?.cancel();
    _batchTimer = null;

    // Cancel all subscriptions
    for (final subscription in _subscriptions.values) {
      await subscription?.cancel();
    }
    _subscriptions.clear();

    // Clear state
    _pendingBatches.clear();
    _lastDeliveryTimes.clear();
    _lastFetchTimes.clear();

    debugPrint('AndroidCallbackFlow: Stopped callback flow');
  }

  /// Pause callback flow (temporary)
  void pauseCallbackFlow() {
    _batchTimer?.cancel();
    for (final subscription in _subscriptions.values) {
      subscription?.pause();
    }
    debugPrint('AndroidCallbackFlow: Paused callback flow');
  }

  /// Resume callback flow
  void resumeCallbackFlow() {
    if (_isActive) {
      _startBatchProcessor();
      for (final subscription in _subscriptions.values) {
        subscription?.resume();
      }
      debugPrint('AndroidCallbackFlow: Resumed callback flow');
    }
  }

  /// Get current callback flow statistics
  Map<String, dynamic> getCallbackFlowStats() {
    return {
      'isActive': _isActive,
      'isSupported': isSupported,
      'enabledTypes': _config.enabledTypes.map((e) => e.name).toList(),
      'subscriptionInterval': _config.subscriptionInterval.inSeconds,
      'throttleInterval': _config.throttleInterval.inSeconds,
      'activeSubscriptions': _subscriptions.length,
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

  /// Dispose service and clean up resources
  Future<void> dispose() async {
    await stopCallbackFlow();
  }
}
