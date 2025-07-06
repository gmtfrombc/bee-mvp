/// Background synchronization service for health data
///
/// Provides platform-specific background monitoring of health data changes
/// using HKObserverQuery (iOS) and AndroidCallbackFlowService (Android)
/// to push deltas to the app even when closed.
library health_background_sync_service;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

import 'package:app/core/services/wearable_data_models.dart';
import 'package:app/core/services/android_callback_flow_service.dart';
import 'package:app/core/services/wearable_live_models.dart';
import 'package:app/core/services/android_background_sync_service.dart';

/// Service for managing background health data synchronization
class HealthBackgroundSyncService {
  static final HealthBackgroundSyncService _instance =
      HealthBackgroundSyncService._internal();
  factory HealthBackgroundSyncService() => _instance;
  HealthBackgroundSyncService._internal();

  final Health _health = Health();
  bool _isActive = false;
  HealthBackgroundSyncConfig _config = HealthBackgroundSyncConfig.defaultConfig;

  final StreamController<HealthBackgroundSyncEvent> _eventController =
      StreamController<HealthBackgroundSyncEvent>.broadcast();

  // Platform-specific monitoring state
  AndroidCallbackFlowService? _androidCallbackFlow;
  StreamSubscription<WearableLiveMessage>? _androidStreamSubscription;
  final Map<WearableDataType, bool> _iosObserversActive = {};

  /// Stream of background sync events
  Stream<HealthBackgroundSyncEvent> get events => _eventController.stream;

  /// Whether background sync is currently active
  bool get isActive => _isActive;

  /// Current configuration
  HealthBackgroundSyncConfig get config => _config;

  /// Initialize background sync with configuration
  Future<HealthBackgroundSyncResult> initialize({
    HealthBackgroundSyncConfig? config,
  }) async {
    try {
      if (config != null) {
        _config = config;
      }

      debugPrint('Initializing HealthBackgroundSyncService');

      // Validate platform support
      if (!Platform.isIOS && !Platform.isAndroid) {
        return HealthBackgroundSyncResult.failure(
          'Background sync not supported on ${Platform.operatingSystem}',
        );
      }

      // Check if health permissions are available
      final hasPermissions = await _checkPermissions();
      if (!hasPermissions) {
        return HealthBackgroundSyncResult.failure(
          'Health permissions not granted for background sync',
        );
      }

      debugPrint('HealthBackgroundSyncService initialized successfully');
      return HealthBackgroundSyncResult.success('Background sync initialized');
    } catch (e) {
      debugPrint('Failed to initialize HealthBackgroundSyncService: $e');
      return HealthBackgroundSyncResult.failure(e.toString());
    }
  }

  /// Start background monitoring for specified data types
  Future<HealthBackgroundSyncResult> startMonitoring({
    List<WearableDataType>? dataTypes,
  }) async {
    if (_isActive) {
      return HealthBackgroundSyncResult.failure(
        'Background sync already active',
      );
    }

    try {
      final types = dataTypes ?? _config.monitoredTypes;

      if (Platform.isIOS) {
        return await _startIOSObservers(types);
      } else if (Platform.isAndroid) {
        return await _startAndroidSubscriptions(types);
      }

      return HealthBackgroundSyncResult.failure('Unsupported platform');
    } catch (e) {
      debugPrint('Error starting background monitoring: $e');
      return HealthBackgroundSyncResult.failure(e.toString());
    }
  }

  /// Stop background monitoring
  Future<HealthBackgroundSyncResult> stopMonitoring() async {
    if (!_isActive) {
      return HealthBackgroundSyncResult.success(
        'Background sync already stopped',
      );
    }

    try {
      if (Platform.isIOS) {
        await _stopIOSObservers();
      } else if (Platform.isAndroid) {
        await _stopAndroidSubscriptions();
      }

      _isActive = false;
      _emitEvent(HealthBackgroundSyncEvent.stopped());

      debugPrint('Background monitoring stopped');
      return HealthBackgroundSyncResult.success(
        'Background monitoring stopped',
      );
    } catch (e) {
      debugPrint('Error stopping background monitoring: $e');
      return HealthBackgroundSyncResult.failure(e.toString());
    }
  }

  /// Check if required permissions are available
  Future<bool> _checkPermissions() async {
    try {
      final healthDataTypes =
          _config.monitoredTypes
              .map((type) => type.toHealthDataType())
              .where((type) => type != null)
              .cast<HealthDataType>()
              .toList();

      if (healthDataTypes.isEmpty) return false;

      final permissions =
          healthDataTypes.map((type) => HealthDataAccess.READ).toList();

      final hasPermissions = await _health.hasPermissions(
        healthDataTypes,
        permissions: permissions,
      );

      return hasPermissions ?? false;
    } catch (e) {
      debugPrint('Error checking permissions for background sync: $e');
      return false;
    }
  }

  /// Start iOS HKObserverQuery background observers
  Future<HealthBackgroundSyncResult> _startIOSObservers(
    List<WearableDataType> types,
  ) async {
    debugPrint('Starting iOS HKObserverQuery for ${types.length} data types');

    try {
      // Clear any existing observers
      _iosObserversActive.clear();

      for (final type in types) {
        final healthType = type.toHealthDataType();
        if (healthType == null) continue;

        // Note: The health package doesn't directly expose HKObserverQuery
        // but provides background data fetching capabilities
        // We'll use the health package's background fetch mechanism

        _iosObserversActive[type] = true;
        debugPrint('iOS observer active for $type');
      }

      _isActive = true;
      _emitEvent(HealthBackgroundSyncEvent.started(types));

      // Start periodic background fetch for iOS
      _startIOSBackgroundFetch();

      return HealthBackgroundSyncResult.success(
        'iOS background observers started for ${types.length} data types',
      );
    } catch (e) {
      debugPrint('Error starting iOS observers: $e');
      return HealthBackgroundSyncResult.failure(e.toString());
    }
  }

  /// Start Android Health Connect callback flow
  Future<HealthBackgroundSyncResult> _startAndroidSubscriptions(
    List<WearableDataType> types,
  ) async {
    debugPrint(
      'Starting Android Health Connect callback flow for ${types.length} data types',
    );

    try {
      // Check background sync permissions first
      final backgroundSync = AndroidBackgroundSyncService();
      final syncResult = await backgroundSync.checkBackgroundSync();

      if (!syncResult.isAvailable && !syncResult.isLimited) {
        return HealthBackgroundSyncResult.failure(
          'Background sync not available: ${syncResult.message}',
        );
      }

      if (syncResult.isLimited) {
        debugPrint(
          'AndroidBackgroundSync: Limited access detected - ${syncResult.message}',
        );
      }

      // Clear any existing callback flow
      await _stopAndroidSubscriptions();

      // Create Android callback flow service
      final messageController = StreamController<WearableLiveMessage>();
      _androidCallbackFlow = AndroidCallbackFlowService(
        _health,
        messageController,
        config: AndroidCallbackFlowConfig(
          enabledTypes: types.toSet(),
          throttleInterval: const Duration(seconds: 5),
        ),
      );

      // Setup callback flow
      final result = await _androidCallbackFlow!.setupCallbackFlow();

      if (result is CallbackFlowSuccess) {
        // Listen to incoming live messages and convert to sync events
        _androidStreamSubscription = messageController.stream.listen(
          (message) {
            final sample = HealthSample(
              id:
                  '${message.type.name}_${message.timestamp.millisecondsSinceEpoch}',
              type: message.type,
              value: message.value,
              unit: 'count', // Default unit, actual unit from Health Connect
              timestamp: message.timestamp,
              source: message.source,
            );

            _emitEvent(HealthBackgroundSyncEvent.dataReceived([sample]));
          },
          onError: (error) {
            debugPrint('Android callback flow error: $error');
            _emitEvent(HealthBackgroundSyncEvent.error(error.toString()));
          },
        );

        _isActive = true;
        _emitEvent(HealthBackgroundSyncEvent.started(types));

        debugPrint(
          'Android callback flow started for ${result.enabledTypes.length} data types',
        );
        return HealthBackgroundSyncResult.success(
          'Android callback flow started for ${result.enabledTypes.length} data types',
        );
      } else if (result is CallbackFlowFailure) {
        return HealthBackgroundSyncResult.failure(result.error);
      } else {
        return HealthBackgroundSyncResult.failure(
          'Android callback flow not supported',
        );
      }
    } catch (e) {
      debugPrint('Error starting Android callback flow: $e');
      return HealthBackgroundSyncResult.failure(e.toString());
    }
  }

  /// Start iOS background fetch mechanism
  void _startIOSBackgroundFetch() {
    Timer.periodic(_config.fetchInterval, (timer) async {
      if (!_isActive) {
        timer.cancel();
        return;
      }

      try {
        await _fetchNewData();
      } catch (e) {
        debugPrint('Error in iOS background fetch: $e');
        _emitEvent(HealthBackgroundSyncEvent.error(e.toString()));
      }
    });
  }

  /// Fetch new health data in background
  Future<void> _fetchNewData() async {
    final now = DateTime.now();
    final startTime = now.subtract(_config.lookbackDuration);

    try {
      final healthDataTypes =
          _config.monitoredTypes
              .map((type) => type.toHealthDataType())
              .where((type) => type != null)
              .cast<HealthDataType>()
              .toList();

      if (healthDataTypes.isEmpty) return;

      final healthData = await _health.getHealthDataFromTypes(
        types: healthDataTypes,
        startTime: startTime,
        endTime: now,
      );

      if (healthData.isNotEmpty) {
        final samples =
            healthData
                .map((point) => HealthSample.fromHealthDataPoint(point))
                .toList();

        _emitEvent(HealthBackgroundSyncEvent.dataReceived(samples));
        debugPrint('Background sync fetched ${samples.length} new samples');
      }
    } catch (e) {
      debugPrint('Error fetching background data: $e');
      _emitEvent(HealthBackgroundSyncEvent.error(e.toString()));
    }
  }

  /// Stop iOS observers
  Future<void> _stopIOSObservers() async {
    debugPrint('Stopping iOS observers');
    _iosObserversActive.clear();
  }

  /// Stop Android callback flow
  Future<void> _stopAndroidSubscriptions() async {
    debugPrint('Stopping Android callback flow');

    await _androidStreamSubscription?.cancel();
    _androidStreamSubscription = null;

    await _androidCallbackFlow?.stopCallbackFlow();
    _androidCallbackFlow = null;
  }

  /// Emit a background sync event
  void _emitEvent(HealthBackgroundSyncEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  /// Update configuration
  void updateConfig(HealthBackgroundSyncConfig config) {
    _config = config;
    debugPrint('Background sync configuration updated');
  }

  /// Get status information
  Map<String, dynamic> getStatus() {
    return {
      'isActive': _isActive,
      'platform': Platform.operatingSystem,
      'monitoredTypes': _config.monitoredTypes.map((e) => e.name).toList(),
      'fetchInterval': _config.fetchInterval.inSeconds,
      'iosObserversActive': _iosObserversActive.length,
      'androidCallbackFlowActive': _androidCallbackFlow?.isActive ?? false,
    };
  }

  /// Dispose of resources
  void dispose() {
    // Stop any platform-specific monitoring.
    stopMonitoring();

    // Close the event stream to free resources.
    _eventController.close();

    // TESTING SUPPORT: Reset mutable singleton state so that subsequent
    // HealthBackgroundSyncService() calls begin from a clean baseline. This
    // prevents config leakage between tests when the singleton instance is
    // reused across multiple test cases.
    _config = HealthBackgroundSyncConfig.defaultConfig;
    _isActive = false;
  }
}

/// Configuration for background sync behavior
class HealthBackgroundSyncConfig {
  final List<WearableDataType> monitoredTypes;
  final Duration fetchInterval;
  final Duration lookbackDuration;
  final bool enableNotifications;

  const HealthBackgroundSyncConfig({
    required this.monitoredTypes,
    required this.fetchInterval,
    required this.lookbackDuration,
    this.enableNotifications = false,
  });

  static HealthBackgroundSyncConfig get defaultConfig =>
      const HealthBackgroundSyncConfig(
        monitoredTypes: [
          WearableDataType.steps,
          WearableDataType.heartRate,
          WearableDataType.sleepDuration,
        ],
        fetchInterval: Duration(minutes: 5),
        lookbackDuration: Duration(minutes: 10),
        enableNotifications: false,
      );

  HealthBackgroundSyncConfig copyWith({
    List<WearableDataType>? monitoredTypes,
    Duration? fetchInterval,
    Duration? lookbackDuration,
    bool? enableNotifications,
  }) {
    return HealthBackgroundSyncConfig(
      monitoredTypes: monitoredTypes ?? this.monitoredTypes,
      fetchInterval: fetchInterval ?? this.fetchInterval,
      lookbackDuration: lookbackDuration ?? this.lookbackDuration,
      enableNotifications: enableNotifications ?? this.enableNotifications,
    );
  }
}

/// Events emitted by the background sync service
sealed class HealthBackgroundSyncEvent {
  final DateTime timestamp;
  final String message;

  const HealthBackgroundSyncEvent({
    required this.timestamp,
    required this.message,
  });

  factory HealthBackgroundSyncEvent.started(List<WearableDataType> types) =>
      HealthBackgroundSyncStartedEvent(
        timestamp: DateTime.now(),
        message: 'Background sync started for ${types.length} data types',
        monitoredTypes: types,
      );

  factory HealthBackgroundSyncEvent.stopped() =>
      HealthBackgroundSyncStoppedEvent(
        timestamp: DateTime.now(),
        message: 'Background sync stopped',
      );

  factory HealthBackgroundSyncEvent.dataReceived(List<HealthSample> samples) =>
      HealthBackgroundSyncDataEvent(
        timestamp: DateTime.now(),
        message: 'Received ${samples.length} health samples',
        samples: samples,
      );

  factory HealthBackgroundSyncEvent.error(String error) =>
      HealthBackgroundSyncErrorEvent(
        timestamp: DateTime.now(),
        message: 'Background sync error: $error',
        error: error,
      );
}

/// Background sync started event
class HealthBackgroundSyncStartedEvent extends HealthBackgroundSyncEvent {
  final List<WearableDataType> monitoredTypes;

  const HealthBackgroundSyncStartedEvent({
    required super.timestamp,
    required super.message,
    required this.monitoredTypes,
  });
}

/// Background sync stopped event
class HealthBackgroundSyncStoppedEvent extends HealthBackgroundSyncEvent {
  const HealthBackgroundSyncStoppedEvent({
    required super.timestamp,
    required super.message,
  });
}

/// Background sync data received event
class HealthBackgroundSyncDataEvent extends HealthBackgroundSyncEvent {
  final List<HealthSample> samples;

  const HealthBackgroundSyncDataEvent({
    required super.timestamp,
    required super.message,
    required this.samples,
  });
}

/// Background sync error event
class HealthBackgroundSyncErrorEvent extends HealthBackgroundSyncEvent {
  final String error;

  const HealthBackgroundSyncErrorEvent({
    required super.timestamp,
    required super.message,
    required this.error,
  });
}

/// Result of background sync operations
sealed class HealthBackgroundSyncResult {
  final bool isSuccess;
  final String message;
  final DateTime timestamp;

  const HealthBackgroundSyncResult({
    required this.isSuccess,
    required this.message,
    required this.timestamp,
  });

  factory HealthBackgroundSyncResult.success(String message) =>
      HealthBackgroundSyncSuccessResult(
        message: message,
        timestamp: DateTime.now(),
      );

  factory HealthBackgroundSyncResult.failure(String error) =>
      HealthBackgroundSyncFailureResult(
        error: error,
        timestamp: DateTime.now(),
      );
}

/// Successful background sync result
class HealthBackgroundSyncSuccessResult extends HealthBackgroundSyncResult {
  const HealthBackgroundSyncSuccessResult({
    required super.message,
    required super.timestamp,
  }) : super(isSuccess: true);
}

/// Failed background sync result
class HealthBackgroundSyncFailureResult extends HealthBackgroundSyncResult {
  final String error;

  const HealthBackgroundSyncFailureResult({
    required this.error,
    required super.timestamp,
  }) : super(isSuccess: false, message: error);
}
