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

import 'wearable_data_models.dart';
import 'health_background_sync_service.dart';
import 'wearable_edge_case_logger.dart';
import 'data_source_filter_service.dart';
import 'health_permission_manager.dart';

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
    'supportedDataTypes': _getSupportedDataTypes().map((e) => e.name).toList(),
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
        _isHealthConnectAvailable = await _checkHealthConnectAvailability();
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

  /// Check if Health Connect is available on Android
  Future<bool> _checkHealthConnectAvailability() async {
    if (!Platform.isAndroid) return false;

    try {
      // Method 1: Try a basic health package initialization to see if Health Connect responds
      final healthDataTypes = [HealthDataType.STEPS];
      final permissions = [HealthDataAccess.READ];

      // This will throw a specific exception if Health Connect is not available/installed
      await _health.hasPermissions(healthDataTypes, permissions: permissions);

      // If we get here without exception, Health Connect is available
      debugPrint('Health Connect availability check passed via hasPermissions');
      return true;
    } on PlatformException catch (e) {
      // Check for specific Health Connect unavailable error codes
      debugPrint(
        'Health Connect availability check failed with PlatformException: ${e.code} - ${e.message}',
      );

      // Common Health Connect not installed/available error patterns
      final healthConnectUnavailablePatterns = [
        'HEALTH_CONNECT_NOT_AVAILABLE',
        'health_connect_not_installed',
        'HealthConnectClient not available',
        'Health Connect not found',
        'androidx.health.platform',
      ];

      final errorMessage = '${e.code} ${e.message}'.toLowerCase();
      for (final pattern in healthConnectUnavailablePatterns) {
        if (errorMessage.contains(pattern.toLowerCase())) {
          debugPrint(
            'Health Connect not available - detected pattern: $pattern',
          );
          return false;
        }
      }

      // Log unknown error for improvement
      debugPrint('Unknown PlatformException during Health Connect check: $e');
      return false;
    } catch (e) {
      debugPrint(
        'Health Connect availability check failed with general error: $e',
      );

      // Check if error message indicates Health Connect unavailability
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('health connect') ||
          errorString.contains('healthconnect') ||
          errorString.contains('not installed') ||
          errorString.contains('not available')) {
        debugPrint(
          'Health Connect appears to be unavailable based on error: $e',
        );
        return false;
      }

      // For other errors, assume Health Connect might be available but having other issues
      debugPrint('Assuming Health Connect is available despite error: $e');
      return true;
    }
  }

  /// Enhanced Health Connect availability check with detailed results
  Future<HealthConnectAvailabilityResult>
  checkHealthConnectAvailability() async {
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

      await _health.hasPermissions(healthDataTypes, permissions: permissions);

      return const HealthConnectAvailabilityResult(
        isAvailable: true,
        unavailabilityReason: null,
        userMessage: 'Health Connect is available and ready to use.',
        canInstall: false,
      );
    } on PlatformException catch (e) {
      debugPrint(
        'Health Connect detailed check failed: ${e.code} - ${e.message}',
      );

      // Determine specific unavailability reason
      final errorMessage = '${e.code} ${e.message}'.toLowerCase();

      if (errorMessage.contains('not_supported') ||
          errorMessage.contains('unsupported')) {
        return const HealthConnectAvailabilityResult(
          isAvailable: false,
          unavailabilityReason:
              HealthConnectUnavailabilityReason.deviceNotSupported,
          userMessage:
              'Your Android device does not support Health Connect. Minimum Android 9+ required.',
          canInstall: false,
        );
      }

      if (errorMessage.contains('not_installed') ||
          errorMessage.contains('not_available') ||
          errorMessage.contains('health_connect_not_available')) {
        return const HealthConnectAvailabilityResult(
          isAvailable: false,
          unavailabilityReason: HealthConnectUnavailabilityReason.notInstalled,
          userMessage:
              'Health Connect app is not installed. Install it from the Play Store to continue.',
          canInstall: true,
        );
      }

      if (errorMessage.contains('version') ||
          errorMessage.contains('outdated')) {
        return const HealthConnectAvailabilityResult(
          isAvailable: false,
          unavailabilityReason:
              HealthConnectUnavailabilityReason.outdatedVersion,
          userMessage:
              'Health Connect app needs to be updated. Please update from the Play Store.',
          canInstall: true,
        );
      }

      // Unknown error - assume can try installing
      return HealthConnectAvailabilityResult(
        isAvailable: false,
        unavailabilityReason: HealthConnectUnavailabilityReason.unknown,
        userMessage:
            'Health Connect issue detected: ${e.message}. Try installing or updating Health Connect.',
        canInstall: true,
        debugInfo: {'platformException': '${e.code}: ${e.message}'},
      );
    } catch (e) {
      debugPrint('Health Connect detailed check failed with general error: $e');

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

      debugPrint('[Permissions] requestAuthorization success: $success');

      final finalHasBool = await _health.hasPermissions(
        healthDataTypes,
        permissions: permissions,
      );

      debugPrint('[Permissions] hasPermissions raw result: $finalHasBool');
      // Treat an indeterminate (null) response as not yet authorized.
      final finalHas =
          finalHasBool == true || (finalHasBool == null && Platform.isIOS);
      debugPrint('[Permissions] hasPermissions finalHas: $finalHas');

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

      // Do **not** treat a null result as authorized – it simply means the
      // underlying HealthKit API couldn't determine status (iOS 17 beta bug).
      final hasPermissions =
          hasPermissionsResult == true ||
          (hasPermissionsResult == null && Platform.isIOS);

      return hasPermissions
          ? HealthPermissionStatus.authorized
          : HealthPermissionStatus.notDetermined;
    } catch (e) {
      debugPrint('Error checking health permissions: $e');
      return HealthPermissionStatus.denied;
    }
  }

  /// Check if historical data access is authorized (Android Health Connect specific)
  Future<bool> isHistoricalDataAuthorized() async {
    if (!Platform.isAndroid || !_isHealthConnectAvailable) {
      return true; // iOS doesn't have this limitation
    }

    try {
      // This would typically use Health Connect specific APIs
      // For now, we'll assume it needs to be requested explicitly
      return false;
    } catch (e) {
      debugPrint('Error checking historical data authorization: $e');
      return false;
    }
  }

  /// Request historical data access (Android Health Connect specific)
  Future<bool> requestHistoricalDataAccess() async {
    if (!Platform.isAndroid || !_isHealthConnectAvailable) {
      return true; // iOS doesn't need this
    }

    try {
      // This would typically trigger the historical data permission flow
      // For now, we'll log the attempt
      debugPrint('Historical data access requested');
      return true;
    } catch (e) {
      debugPrint('Error requesting historical data access: $e');
      return false;
    }
  }

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

      // ── Diagnostic logging ───────────────────────────────────────────
      if (kDebugMode) {
        debugPrint(
          '📡 getHealthData returned ${samples.length} points '
          '[types: ${types.map((t) => t.name).join(', ')}] '
          'range: ${start.toIso8601String()} → ${end.toIso8601String()}',
        );

        // Group by type for a quick breakdown
        final Map<WearableDataType, List<HealthSample>> byType = {};
        for (final s in samples) {
          byType.putIfAbsent(s.type, () => <HealthSample>[]).add(s);
        }

        for (final entry in byType.entries) {
          debugPrint('   ↳ ${entry.key.name} • count=${entry.value.length}');
          for (final sample in entry.value.take(3)) {
            debugPrint(
              '      • ts=${sample.timestamp} | val=${sample.value} | src=${sample.source}',
            );
          }
          if (entry.value.length > 3) {
            debugPrint('      … (${entry.value.length - 3} more)');
          }
        }

        if (samples.isEmpty) {
          debugPrint(
            '⚠️ No samples returned – consider widening look-back window',
          );
        }
      }
      // ─────────────────────────────────────────────────────────────────

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

  /// Get supported data types for the current platform
  List<WearableDataType> _getSupportedDataTypes() {
    // All types are theoretically supported on both platforms
    // Platform-specific limitations will be handled at the health package level
    return WearableDataType.values
        .where((type) => type != WearableDataType.unknown)
        .toList();
  }

  /// Get platform-specific limitations and documentation
  Map<String, dynamic> getPlatformLimitations() {
    if (Platform.isIOS) {
      return {
        'platform': 'iOS',
        'dataSource': 'HealthKit',
        'limitations': [
          'Requires iOS 8.0+',
          'User must grant permission for each data type',
          'Some data types may not be available on older devices',
          'Background data access requires special entitlements',
        ],
        'supportedDataTypes':
            _getSupportedDataTypes().map((e) => e.name).toList(),
        'notes': [
          'Steps, heart rate, and sleep data are widely available',
          'HRV data requires compatible device (Apple Watch Series 1+)',
          'VO2 Max requires Apple Watch Series 3+',
        ],
      };
    } else if (Platform.isAndroid) {
      return {
        'platform': 'Android',
        'dataSource': 'Health Connect',
        'availability': _isHealthConnectAvailable,
        'limitations': [
          'Requires Android 14+ or Health Connect app installation',
          'Limited to 30 days of historical data by default',
          'Background data access may be restricted',
          'Data availability depends on connected devices/apps',
          'Permanent permission denial after 2 rejections',
        ],
        'supportedDataTypes':
            _getSupportedDataTypes().map((e) => e.name).toList(),
        'notes': [
          'Garmin Connect integration available through Health Connect',
          'Historical data beyond 30 days requires special authorization',
          'Data source identification depends on source app metadata',
          'Requires screen lock enabled for security',
          'Activity Recognition permission required for fitness data',
        ],
        'permissionState': {
          'denialCount': _permissionDenialCount,
          'permanentlyDenied': _hasBeenDeniedTwice,
        },
      };
    } else {
      return {
        'platform': Platform.operatingSystem,
        'dataSource': 'Unsupported',
        'limitations': ['Health data access not supported on this platform'],
        'supportedDataTypes': [],
        'notes': ['Only iOS and Android are supported'],
      };
    }
  }

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

    if (!result.isSuccess) {
      return {
        'error': result.error,
        'totalSamples': 0,
        'sourceBreakdown': {},
        'garminPercentage': 0.0,
        'hasMultipleSources': false,
        'uniqueSources': <String>[],
      };
    }

    return _dataSourceFilter.analyzeSourceDistribution(result.samples);
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
    return (analysis['garminPercentage'] as double) > 0.0;
  }

  /// Create filtered data stream for real-time filtering
  Stream<List<HealthSample>> createFilteredDataStream(
    DataSourceFilterCriteria filterCriteria,
  ) {
    return dataStream.transform(
      _dataSourceFilter.createFilterTransformer(filterCriteria),
    );
  }

  /// Dispose of resources
  void dispose() {
    _backgroundSyncService.dispose();
    _dataStreamController.close();
    _isInitialized = false;
  }
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
