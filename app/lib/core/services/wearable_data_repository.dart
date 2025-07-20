/// Unified wearable data repository for cross-platform health data access
///
/// This service provides a unified interface for accessing health data from
/// HealthKit (iOS) and Health Connect (Android) using the Flutter health package.
/// It abstracts platform-specific differences and provides consistent data models.
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app/core/utils/logger.dart';

import 'wearable_data_models.dart';
import 'health_background_sync_service.dart';
import 'wearable_edge_case_logger.dart';
import 'data_source_filter_service.dart';
import 'health_permission_manager.dart';
import 'wearable/health_connect_availability_helper.dart';
import 'wearable/health_sample_mapper.dart';
import 'wearable/ios_permission_probe.dart';

/// Repository for accessing wearable device data across platforms
class WearableDataRepository {
  static final WearableDataRepository _instance =
      WearableDataRepository._internal();
  factory WearableDataRepository() => _instance;
  WearableDataRepository._internal();

  final Health _health = Health();
  bool _isInitialized = false;
  HealthSyncConfig _config = HealthSyncConfig.defaultConfig;
  final StreamController<List<HealthSample>> _dataStreamController =
      StreamController<List<HealthSample>>.broadcast();

  final HealthBackgroundSyncService _backgroundSyncService =
      HealthBackgroundSyncService();

  // T2.2.1.5-5: Edge case logging integration
  final WearableEdgeCaseLogger _edgeCaseLogger = WearableEdgeCaseLogger();

  // T2.2.2.11: Data source filtering integration
  final DataSourceFilterService _dataSourceFilter = DataSourceFilterService();

  // Android-specific Health Connect state
  bool _isHealthConnectAvailable = false;
  bool _hasBeenDeniedTwice = false;
  int _permissionDenialCount = 0;

  // iOS-only HealthKit permission bridge (returns tri-state int)
  static const MethodChannel _iosPermissionChannel = MethodChannel(
    'com.bee.health_permission_status',
  );

  // _iosReadProbeChannel moved to wearable/ios_permission_probe.dart

  /// Stream of health data updates
  Stream<List<HealthSample>> get dataStream => _dataStreamController.stream;

  /// Current synchronization configuration
  HealthSyncConfig get config => _config;

  /// Whether the repository is initialized and ready for use
  bool get isInitialized => _isInitialized;

  /// Whether Health Connect is available on this Android device
  bool get isHealthConnectAvailable => _isHealthConnectAvailable;

  /// Whether permissions have been permanently denied (Android specific)
  bool get hasBeenPermanentlyDenied => _hasBeenDeniedTwice;

  /// Platform information for debugging and analytics
  Map<String, dynamic> get platformInfo => {
    'platform': Platform.operatingSystem,
    'isIOS': Platform.isIOS,
    'isAndroid': Platform.isAndroid,
    'supportedDataTypes':
        WearableDataType.values
            .where((t) => t != WearableDataType.unknown)
            .map((e) => e.name)
            .toList(),
    'healthConnectAvailable': _isHealthConnectAvailable,
    'permissionDenialCount': _permissionDenialCount,
    'permanentlyDenied': _hasBeenDeniedTwice,
  };

  /// Initialize the repository with configuration
  Future<bool> initialize({HealthSyncConfig? config}) async {
    try {
      if (config != null) {
        _config = config;
      }

      // T2.2.1.5-5: Initialize edge case logger
      await _edgeCaseLogger.initialize();

      // Check platform capabilities
      if (Platform.isAndroid) {
        _isHealthConnectAvailable =
            await HealthConnectAvailabilityHelper.isHealthConnectAvailable(
              _health,
            );
        debugPrint('Health Connect available: $_isHealthConnectAvailable');

        if (!_isHealthConnectAvailable) {
          debugPrint('Health Connect not available on this device');
          // T2.2.1.5-5: Log Health Connect unavailability
          await _edgeCaseLogger.checkHealthConnectAvailability();
          // Don't fail initialization - allow graceful fallback
        }
      } else if (Platform.isIOS) {
        debugPrint('Initializing for iOS HealthKit');
      }

      _isInitialized = true;
      debugPrint('WearableDataRepository initialized successfully');
      return true;
    } catch (e) {
      debugPrint('Failed to initialize WearableDataRepository: $e');
      return false;
    }
  }

  /// Detailed Health Connect availability diagnostics (helper delegation)
  Future<HealthConnectAvailabilityResult> checkHealthConnectAvailability() =>
      HealthConnectAvailabilityHelper.detailedAvailability(_health);

  /// Request permissions for health data access
  Future<HealthPermissionStatus> requestPermissions({
    List<WearableDataType>? dataTypes,
  }) async {
    if (!_isInitialized) {
      throw StateError('Repository not initialized. Call initialize() first.');
    }

    // Android-specific Health Connect checks
    if (Platform.isAndroid) {
      if (!_isHealthConnectAvailable) {
        return HealthPermissionStatus.denied;
      }

      if (_hasBeenDeniedTwice) {
        debugPrint('Permissions have been permanently denied');
        return HealthPermissionStatus.denied;
      }

      // Request Activity Recognition permission first (required for fitness data)
      final activityRecognitionStatus =
          await Permission.activityRecognition.request();
      if (activityRecognitionStatus.isDenied ||
          activityRecognitionStatus.isPermanentlyDenied) {
        debugPrint('Activity Recognition permission denied');
        // Continue with health permissions anyway
      }
    }

    final types = dataTypes ?? _config.dataTypes;
    final healthDataTypes =
        types
            .map((type) => type.toHealthDataType())
            .where((type) => type != null)
            .cast<HealthDataType>()
            .toList();

    try {
      // Request permissions for both read and write access
      final permissions =
          healthDataTypes.map((type) => HealthDataAccess.READ).toList();

      final success = await _health.requestAuthorization(
        healthDataTypes,
        permissions: permissions,
      );

      _logPermissions('[Permissions] requestAuthorization success: $success');

      final finalHasBool = await _health.hasPermissions(
        healthDataTypes,
        permissions: permissions,
      );

      _logPermissions('[Permissions] hasPermissions raw result: $finalHasBool');
      // The Flutter health plugin may return `null` on iOS 17+ even when
      // permissions are granted OR denied.  We no longer interpret `null`
      // as authorised; instead we treat it as *unknown* and fall back to
      // our bridge/probe detection.
      final finalHas = finalHasBool == true;
      _logPermissions('[Permissions] hasPermissions finalHas: $finalHas');

      if (success || finalHas) {
        _permissionDenialCount = 0;
        return HealthPermissionStatus.authorized;
      }

      _permissionDenialCount++;
      if (Platform.isAndroid && _permissionDenialCount >= 2) {
        _hasBeenDeniedTwice = true;
        debugPrint(
          'Android permissions denied twice - marking as permanently denied',
        );
      }
      await _edgeCaseLogger.checkPermissionRevocation();
      return HealthPermissionStatus.denied;
    } catch (e) {
      debugPrint('Error requesting health permissions: $e');
      _permissionDenialCount++;
      if (Platform.isAndroid && _permissionDenialCount >= 2) {
        _hasBeenDeniedTwice = true;
      }
      await _edgeCaseLogger.checkPermissionRevocation();

      // 🛡️ Auto-repair: if the error indicates missing authorization, trigger
      // a one-shot permission request so the next poll can succeed without
      // manual user intervention.  We do **not** loop endlessly – the caller
      // decides when to re-fetch.
      if (e is PlatformException &&
          e.code == 'HEALTH_ERROR' &&
          (e.message?.toLowerCase().contains('authorization not determined') ??
              false)) {
        try {
          final pm = HealthPermissionManager();
          if (!pm.isInitialized) {
            await pm.initialize();
          }
          await pm.requestPermissions(dataTypes: types);
        } catch (permErr) {
          debugPrint('Auto-permission recovery failed: $permErr');
        }
      }
      return HealthPermissionStatus.denied;
    }
  }

  /// Check current permission status
  Future<HealthPermissionStatus> checkPermissions({
    List<WearableDataType>? dataTypes,
  }) async {
    if (!_isInitialized) {
      return HealthPermissionStatus.notDetermined;
    }

    // Android-specific checks
    if (Platform.isAndroid) {
      if (!_isHealthConnectAvailable) {
        return HealthPermissionStatus.denied;
      }

      if (_hasBeenDeniedTwice) {
        return HealthPermissionStatus.denied;
      }
    }

    final types = dataTypes ?? _config.dataTypes;
    final healthDataTypes =
        types
            .map((type) => type.toHealthDataType())
            .where((type) => type != null)
            .cast<HealthDataType>()
            .toList();

    try {
      final permissions =
          healthDataTypes.map((type) => HealthDataAccess.READ).toList();

      final hasPermissionsResult = await _health.hasPermissions(
        healthDataTypes,
        permissions: permissions,
      );

      // NEW verbose diagnostics – capture raw result per invocation
      if (kDebugMode) {
        _logPermissions(
          '[Permissions] checkPermissions.types=${types.map((e) => e.name).join(', ')} '
          'rawResult=$hasPermissionsResult',
        );
      }

      final hasPermissions = hasPermissionsResult == true;

      if (kDebugMode) {
        _logPermissions(
          '[Permissions] checkPermissions.pluginHas=$hasPermissions',
        );
      }

      // 1. If plugin confirmed – done.
      if (hasPermissions) {
        return HealthPermissionStatus.authorized;
      }

      // 2. iOS fallback – first consult the native Swift bridge.
      if (Platform.isIOS) {
        bool? bridgeAuthorized;
        bool bridgeHasData = false;

        try {
          final hkIds = types.map(hkIdentifierFromWearableDataType).toList();
          final raw = await _iosPermissionChannel.invokeMapMethod<String, bool>(
            'check',
            hkIds,
          );

          if (kDebugMode) {
            _logPermissions('[Permissions] iOS bridge map=$raw');
          }

          if (raw != null && raw.isNotEmpty) {
            bridgeHasData = true;
            bridgeAuthorized = raw.values.any((granted) => granted == true);
          }
        } catch (e) {
          debugPrint('iOS permission bridge failed: $e');
        }

        if (bridgeHasData && bridgeAuthorized == true) {
          return HealthPermissionStatus.authorized;
        }

        // 3. Last resort – lightweight sample probe (covers cases where
        // bridge indicates no write sharing but read access may still be
        // available, as Apple doesn't expose read-scopes via the status API)
        final probeOk = await iosProbeReadAccess();
        if (kDebugMode) {
          _logPermissions('[Permissions] iOS read probe result: $probeOk');
        }
        return probeOk
            ? HealthPermissionStatus.authorized
            : HealthPermissionStatus.notDetermined;
      }

      // ─ Android & other platforms ────────────────────────────────
      return HealthPermissionStatus.notDetermined;
    } catch (e) {
      debugPrint('Error checking health permissions: $e');
      return HealthPermissionStatus.denied;
    }
  }

  // Historical data access helpers removed (unused).

  /// Reset permission denial tracking (for testing or user retry)
  void resetPermissionDenialTracking() {
    _permissionDenialCount = 0;
    _hasBeenDeniedTwice = false;
    debugPrint('Permission denial tracking reset');
  }

  /// Get health data for specified types and time range
  Future<HealthDataQueryResult> getHealthData({
    List<WearableDataType>? dataTypes,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    if (!_isInitialized) {
      return const HealthDataQueryResult(
        samples: [],
        error: 'Repository not initialized',
      );
    }

    // Android-specific checks
    if (Platform.isAndroid && !_isHealthConnectAvailable) {
      return const HealthDataQueryResult(
        samples: [],
        error: 'Health Connect not available on this device',
      );
    }

    final types = dataTypes ?? _config.dataTypes;
    final healthDataTypes =
        types
            .map((type) => type.toHealthDataType())
            .where((type) => type != null)
            .cast<HealthDataType>()
            .toList();

    final now = DateTime.now();
    final start = startTime ?? now.subtract(_config.maxHistoryRange);
    final end = endTime ?? now;

    try {
      final healthData = await _health.getHealthDataFromTypes(
        types: healthDataTypes,
        startTime: start,
        endTime: end,
      );

      final samples =
          healthData
              .map((point) => HealthSample.fromHealthDataPoint(point))
              .toList();

      // Verbose diagnostic logging extracted to helper (removed here).
      if (kDebugMode && _config.verboseLogging) {
        logD('📡 getHealthData returned ${samples.length} points');
      }

      // Emit data to stream
      _dataStreamController.add(samples);

      return HealthDataQueryResult(
        samples: samples,
        lastSyncTime: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error fetching health data: $e');

      // T2.2.1.5-5: Log edge cases for data fetch failures
      await _edgeCaseLogger.checkConnectivityIssues();
      await _edgeCaseLogger.checkPermissionRevocation();

      // 🛡️ Auto-repair: if the error indicates missing authorization, trigger
      // a one-shot permission request so the next poll can succeed without
      // manual user intervention.  We do **not** loop endlessly – the caller
      // decides when to re-fetch.
      if (e is PlatformException &&
          e.code == 'HEALTH_ERROR' &&
          (e.message?.toLowerCase().contains('authorization not determined') ??
              false)) {
        try {
          final pm = HealthPermissionManager();
          if (!pm.isInitialized) {
            await pm.initialize();
          }
          await pm.requestPermissions(dataTypes: types);
        } catch (permErr) {
          debugPrint('Auto-permission recovery failed: $permErr');
        }
      }

      return HealthDataQueryResult(samples: const [], error: e.toString());
    }
  }

  /// Get the most recent sample for a specific data type
  Future<HealthSample?> getLatestSample(WearableDataType type) async {
    final result = await getHealthData(
      dataTypes: [type],
      startTime: DateTime.now().subtract(const Duration(days: 1)),
      endTime: DateTime.now(),
    );

    return result.samples.isNotEmpty ? result.samples.first : null;
  }

  /// Get aggregated data for a specific time period
  Future<Map<WearableDataType, dynamic>> getAggregatedData({
    List<WearableDataType>? dataTypes,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    final result = await getHealthData(
      dataTypes: dataTypes,
      startTime: startTime,
      endTime: endTime,
    );

    if (!result.isSuccess) {
      return {};
    }

    final Map<WearableDataType, dynamic> aggregated = {};

    for (final type in dataTypes ?? _config.dataTypes) {
      final samplesForType =
          result.samples.where((s) => s.type == type).toList();

      if (samplesForType.isEmpty) continue;

      switch (type) {
        case WearableDataType.steps:
        case WearableDataType.distanceWalking:
        case WearableDataType.activeEnergyBurned:
        case WearableDataType.flightsClimbed:
          // Sum for cumulative metrics
          aggregated[type] = samplesForType
              .map((s) => (s.value as num).toDouble())
              .fold(0.0, (sum, value) => sum + value);
          break;

        case WearableDataType.heartRate:
        case WearableDataType.restingHeartRate:
        case WearableDataType.heartRateVariability:
          // Average for rate metrics
          if (samplesForType.isNotEmpty) {
            final values =
                samplesForType.map((s) => (s.value as num).toDouble()).toList();
            aggregated[type] = values.reduce((a, b) => a + b) / values.length;
          }
          break;

        case WearableDataType.sleepDuration:
        case WearableDataType.sleepInBed:
          // Total duration for sleep metrics
          aggregated[type] = samplesForType
              .map((s) => (s.value as num).toDouble())
              .fold(0.0, (sum, value) => sum + value);
          break;

        default:
          // For other types, just take the most recent value
          aggregated[type] = samplesForType.first.value;
      }
    }

    return aggregated;
  }

  /// Start background synchronization
  Future<bool> startBackgroundSync() async {
    if (!_isInitialized || !_config.backgroundSync) {
      return false;
    }

    try {
      // Initialize background sync service
      final initResult = await _backgroundSyncService.initialize(
        config: HealthBackgroundSyncConfig(
          monitoredTypes: _config.dataTypes,
          fetchInterval: const Duration(minutes: 5),
          lookbackDuration: const Duration(minutes: 10),
          enableNotifications: false,
        ),
      );

      if (!initResult.isSuccess) {
        debugPrint(
          'Failed to initialize background sync: ${initResult.message}',
        );
        return false;
      }

      // Start monitoring
      final startResult = await _backgroundSyncService.startMonitoring(
        dataTypes: _config.dataTypes,
      );

      if (startResult.isSuccess) {
        // Listen to background sync events and forward data to our stream
        _backgroundSyncService.events.listen((event) {
          if (event is HealthBackgroundSyncDataEvent) {
            _dataStreamController.add(event.samples);
          }
        });

        debugPrint('Background sync started successfully');
        return true;
      } else {
        debugPrint('Failed to start background sync: ${startResult.message}');
        return false;
      }
    } catch (e) {
      debugPrint('Error starting background sync: $e');
      return false;
    }
  }

  /// Stop background synchronization
  Future<bool> stopBackgroundSync() async {
    try {
      final result = await _backgroundSyncService.stopMonitoring();
      debugPrint('Background sync stopped: ${result.message}');
      return result.isSuccess;
    } catch (e) {
      debugPrint('Error stopping background sync: $e');
      return false;
    }
  }

  // `_getSupportedDataTypes` helper removed – logic inlined where needed.

  // `getPlatformLimitations` removed (unused)

  /// Get edge case logs for analysis (T2.2.1.5-5)
  Future<List<EdgeCaseLogEntry>> getEdgeCaseLogs({
    Duration? since,
    WearableEdgeCase? filterType,
  }) async {
    return await _edgeCaseLogger.getRecentLogs(
      since: since,
      filterType: filterType,
    );
  }

  /// Generate mitigation report for edge cases (T2.2.1.5-5)
  Future<Map<String, dynamic>> generateEdgeCaseMitigationReport() async {
    return await _edgeCaseLogger.generateMitigationReport();
  }

  /// Perform comprehensive edge case check (T2.2.1.5-5)
  Future<void> performEdgeCaseCheck({DateTime? serverTime}) async {
    await _edgeCaseLogger.performComprehensiveCheck(serverTime: serverTime);
  }

  // T2.2.2.11: Data source filtering methods

  /// Get health data filtered by source category
  Future<HealthDataQueryResult> getHealthDataFiltered({
    List<WearableDataType>? dataTypes,
    DateTime? startTime,
    DateTime? endTime,
    DataSourceFilterCriteria? filterCriteria,
  }) async {
    final result = await getHealthData(
      dataTypes: dataTypes,
      startTime: startTime,
      endTime: endTime,
    );

    if (!result.isSuccess || filterCriteria == null) {
      return result;
    }

    final filterResult = _dataSourceFilter.filterSamples(
      result.samples,
      filterCriteria,
    );

    return HealthDataQueryResult(
      samples: filterResult.samples,
      hasMore: result.hasMore,
      error: result.error,
      lastSyncTime: result.lastSyncTime,
    );
  }

  /// Get only Garmin-sourced health data
  Future<HealthDataQueryResult> getGarminHealthData({
    List<WearableDataType>? dataTypes,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    return getHealthDataFiltered(
      dataTypes: dataTypes,
      startTime: startTime,
      endTime: endTime,
      filterCriteria: DataSourceFilterCriteria.garminOnly,
    );
  }

  /// Analyze data source distribution for current health data
  Future<Map<String, dynamic>> analyzeDataSources({
    List<WearableDataType>? dataTypes,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    final result = await getHealthData(
      dataTypes: dataTypes,
      startTime: startTime,
      endTime: endTime,
    );
    return result.isSuccess
        ? _dataSourceFilter.analyzeSourceDistribution(result.samples)
        : {'error': result.error, 'totalSamples': 0};
  }

  /// Check if Garmin data is available in current health data
  Future<bool> hasGarminData({
    List<WearableDataType>? dataTypes,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    final analysis = await analyzeDataSources(
      dataTypes: dataTypes,
      startTime: startTime,
      endTime: endTime,
    );
    return (analysis['garminPercentage'] ?? 0) > 0;
  }

  // `createFilteredDataStream` removed (unused).

  /// Dispose of resources
  void dispose() {
    _backgroundSyncService.dispose();
    _dataStreamController.close();
    _isInitialized = false;
  }

  /// Request authorization for a batch of HealthKit/Health Connect types
  Future<bool> requestPermissionsRaw(
    List<HealthDataType> types,
    List<HealthDataAccess> access,
  ) => _health.requestAuthorization(types, permissions: access);

  /// Check permission status for given types (returns true if all granted).
  Future<bool?> hasPermissionsRaw(
    List<HealthDataType> types,
    List<HealthDataAccess> access,
  ) => _health.hasPermissions(types, permissions: access);

  // (helper stubs removed – no longer needed after refactor)
  // _iosProbeReadAccess moved to wearable/ios_permission_probe.dart
}

/// Extension to add convenience methods to WearableDataRepository
extension WearableDataRepositoryExtensions on WearableDataRepository {
  /// Quick check if the repository is ready for data operations
  bool get isReady =>
      isInitialized && (Platform.isIOS || isHealthConnectAvailable);

  /// Get user-friendly error message for current state
  String? get statusMessage {
    if (!isInitialized) return 'Health data access not initialized';
    if (Platform.isAndroid && !isHealthConnectAvailable) {
      return 'Health Connect app not installed or not available';
    }
    if (hasBeenPermanentlyDenied) {
      return 'Health permissions permanently denied. Please enable in Settings.';
    }
    return null;
  }

  /// Get detailed Health Connect availability with user guidance
  Future<HealthConnectAvailabilityResult> getDetailedAvailability() async {
    return await checkHealthConnectAvailability();
  }

  /// Check if Health Connect issue can be resolved by user action
  Future<bool> canResolveHealthConnectIssue() async {
    if (Platform.isIOS || isHealthConnectAvailable) return false;

    final result = await checkHealthConnectAvailability();
    return result.canResolve;
  }
}

// Detailed permission logging extracted to helper; no-op stub to retain call sites.
void _logPermissions(String _) {}
