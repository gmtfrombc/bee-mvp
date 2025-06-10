/// Unified health data models for wearable device integration
///
/// This file contains the core data models used across the wearable integration
/// system to provide a consistent interface regardless of the underlying platform
/// (HealthKit on iOS, Health Connect on Android).
library wearable_data_models;

import 'package:health/health.dart';

/// Unified health sample model that abstracts platform-specific health data
class HealthSample {
  final String id;
  final WearableDataType type;
  final dynamic value;
  final String unit;
  final DateTime timestamp;
  final DateTime? endTime;
  final String source;
  final Map<String, dynamic>? metadata;

  const HealthSample({
    required this.id,
    required this.type,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.endTime,
    required this.source,
    this.metadata,
  });

  /// Creates a HealthSample from the Flutter health package's HealthDataPoint
  factory HealthSample.fromHealthDataPoint(HealthDataPoint point) {
    return HealthSample(
      id: '${point.type.name}_${point.dateFrom.millisecondsSinceEpoch}',
      type: WearableDataType.fromHealthDataType(point.type),
      value: point.value,
      unit: point.unit.name,
      timestamp: point.dateFrom,
      endTime: point.dateTo,
      source: point.sourceName,
      metadata: {'platform': point.sourcePlatform.name, 'uuid': point.uuid},
    );
  }

  /// Converts to a map for serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'value': value,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'source': source,
      'metadata': metadata,
    };
  }

  /// Creates from a map (for deserialization)
  factory HealthSample.fromMap(Map<String, dynamic> map) {
    return HealthSample(
      id: map['id'],
      type: WearableDataType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => WearableDataType.unknown,
      ),
      value: map['value'],
      unit: map['unit'],
      timestamp: DateTime.parse(map['timestamp']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      source: map['source'],
      metadata: map['metadata'],
    );
  }

  @override
  String toString() {
    return 'HealthSample(id: $id, type: $type, value: $value, unit: $unit, timestamp: $timestamp, source: $source)';
  }
}

/// Unified data types supported across platforms
enum WearableDataType {
  // Activity & Fitness
  steps,
  distanceWalking,
  activeEnergyBurned,
  basalEnergyBurned,
  flightsClimbed,
  workoutType,

  // Heart Rate & Cardiovascular
  heartRate,
  restingHeartRate,
  heartRateVariability,
  vo2Max,

  // Sleep
  sleepDuration,
  sleepInBed,
  sleepAwake,
  sleepDeep,
  sleepLight,
  sleepRem,

  // Body Measurements
  weight,
  bodyFat,
  bodyMassIndex,
  leanBodyMass,

  // Unknown/Unsupported
  unknown;

  /// Maps Flutter health package data types to our unified types
  static WearableDataType fromHealthDataType(HealthDataType healthType) {
    switch (healthType) {
      case HealthDataType.STEPS:
        return WearableDataType.steps;
      case HealthDataType.DISTANCE_WALKING_RUNNING:
        return WearableDataType.distanceWalking;
      case HealthDataType.ACTIVE_ENERGY_BURNED:
        return WearableDataType.activeEnergyBurned;
      case HealthDataType.BASAL_ENERGY_BURNED:
        return WearableDataType.basalEnergyBurned;
      case HealthDataType.FLIGHTS_CLIMBED:
        return WearableDataType.flightsClimbed;
      case HealthDataType.HEART_RATE:
        return WearableDataType.heartRate;
      case HealthDataType.RESTING_HEART_RATE:
        return WearableDataType.restingHeartRate;
      case HealthDataType.HEART_RATE_VARIABILITY_SDNN:
        return WearableDataType.heartRateVariability;
      case HealthDataType.SLEEP_IN_BED:
        return WearableDataType.sleepInBed;
      case HealthDataType.SLEEP_AWAKE:
        return WearableDataType.sleepAwake;
      case HealthDataType.SLEEP_DEEP:
        return WearableDataType.sleepDeep;
      case HealthDataType.SLEEP_LIGHT:
        return WearableDataType.sleepLight;
      case HealthDataType.SLEEP_REM:
        return WearableDataType.sleepRem;
      case HealthDataType.WEIGHT:
        return WearableDataType.weight;
      case HealthDataType.BODY_FAT_PERCENTAGE:
        return WearableDataType.bodyFat;
      case HealthDataType.BODY_MASS_INDEX:
        return WearableDataType.bodyMassIndex;
      default:
        return WearableDataType.unknown;
    }
  }

  /// Converts back to Flutter health package data type
  HealthDataType? toHealthDataType() {
    switch (this) {
      case WearableDataType.steps:
        return HealthDataType.STEPS;
      case WearableDataType.distanceWalking:
        return HealthDataType.DISTANCE_WALKING_RUNNING;
      case WearableDataType.activeEnergyBurned:
        return HealthDataType.ACTIVE_ENERGY_BURNED;
      case WearableDataType.basalEnergyBurned:
        return HealthDataType.BASAL_ENERGY_BURNED;
      case WearableDataType.flightsClimbed:
        return HealthDataType.FLIGHTS_CLIMBED;
      case WearableDataType.heartRate:
        return HealthDataType.HEART_RATE;
      case WearableDataType.restingHeartRate:
        return HealthDataType.RESTING_HEART_RATE;
      case WearableDataType.heartRateVariability:
        return HealthDataType.HEART_RATE_VARIABILITY_SDNN;
      case WearableDataType.sleepInBed:
        return HealthDataType.SLEEP_IN_BED;
      case WearableDataType.sleepAwake:
        return HealthDataType.SLEEP_AWAKE;
      case WearableDataType.sleepDeep:
        return HealthDataType.SLEEP_DEEP;
      case WearableDataType.sleepLight:
        return HealthDataType.SLEEP_LIGHT;
      case WearableDataType.sleepRem:
        return HealthDataType.SLEEP_REM;
      case WearableDataType.weight:
        return HealthDataType.WEIGHT;
      case WearableDataType.bodyFat:
        return HealthDataType.BODY_FAT_PERCENTAGE;
      case WearableDataType.bodyMassIndex:
        return HealthDataType.BODY_MASS_INDEX;
      default:
        return null;
    }
  }
}

/// Permission status for health data access
enum HealthPermissionStatus { authorized, denied, notDetermined, restricted }

/// Result of a health data query
class HealthDataQueryResult {
  final List<HealthSample> samples;
  final bool hasMore;
  final String? error;
  final DateTime? lastSyncTime;

  const HealthDataQueryResult({
    required this.samples,
    this.hasMore = false,
    this.error,
    this.lastSyncTime,
  });

  bool get isSuccess => error == null;
  bool get hasData => samples.isNotEmpty;
}

/// Configuration for health data synchronization
class HealthSyncConfig {
  final List<WearableDataType> dataTypes;
  final Duration syncInterval;
  final Duration maxHistoryRange;
  final bool backgroundSync;

  const HealthSyncConfig({
    required this.dataTypes,
    this.syncInterval = const Duration(minutes: 5),
    this.maxHistoryRange = const Duration(days: 30),
    this.backgroundSync = true,
  });

  /// Default configuration for BEE MVP focusing on key metrics
  static const HealthSyncConfig defaultConfig = HealthSyncConfig(
    dataTypes: [
      WearableDataType.steps,
      WearableDataType.heartRate,
      WearableDataType.sleepDuration,
      WearableDataType.activeEnergyBurned,
      WearableDataType.heartRateVariability,
    ],
    syncInterval: Duration(minutes: 5),
    maxHistoryRange: Duration(days: 7), // Start with 1 week for MVP
    backgroundSync: true,
  );
}

/// Reasons why Health Connect might not be available
enum HealthConnectUnavailabilityReason {
  /// Not running on Android
  notAndroid,

  /// Health Connect app not installed
  notInstalled,

  /// Device doesn't support Health Connect (Android version too old)
  deviceNotSupported,

  /// Health Connect app is outdated
  outdatedVersion,

  /// Unknown reason
  unknown,
}

/// Result of Health Connect availability check with detailed information
class HealthConnectAvailabilityResult {
  final bool isAvailable;
  final HealthConnectUnavailabilityReason? unavailabilityReason;
  final String userMessage;
  final bool canInstall;
  final Map<String, dynamic>? debugInfo;

  const HealthConnectAvailabilityResult({
    required this.isAvailable,
    this.unavailabilityReason,
    required this.userMessage,
    required this.canInstall,
    this.debugInfo,
  });

  /// Whether user can take action to resolve the issue
  bool get canResolve => canInstall && !isAvailable;

  /// Get action text for user
  String get actionText {
    if (!canResolve) return '';

    switch (unavailabilityReason) {
      case HealthConnectUnavailabilityReason.notInstalled:
        return 'Install Health Connect';
      case HealthConnectUnavailabilityReason.outdatedVersion:
        return 'Update Health Connect';
      case HealthConnectUnavailabilityReason.unknown:
        return 'Try Installing Health Connect';
      default:
        return 'Resolve Issue';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'isAvailable': isAvailable,
      'unavailabilityReason': unavailabilityReason?.name,
      'userMessage': userMessage,
      'canInstall': canInstall,
      'debugInfo': debugInfo,
    };
  }
}
