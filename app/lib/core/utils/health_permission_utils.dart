// New utility helpers extracted from HealthPermissionManager
// Provides mapping, friendly names, and platform-aware message composition.

library health_permission_utils;

import 'dart:io';
import 'package:health/health.dart';
import '../services/wearable_data_models.dart';

/// Get a human-friendly display name for a [WearableDataType].
String friendlyWearableName(WearableDataType type) {
  switch (type) {
    case WearableDataType.steps:
      return 'Steps';
    case WearableDataType.heartRate:
      return 'Heart Rate';
    case WearableDataType.sleepDuration:
      return 'Sleep';
    case WearableDataType.restingHeartRate:
      return 'Resting Heart Rate';
    case WearableDataType.activeEnergyBurned:
      return 'Active Energy';
    case WearableDataType.distanceWalking:
      return 'Walking Distance';
    case WearableDataType.flightsClimbed:
      return 'Flights Climbed';
    case WearableDataType.heartRateVariability:
      return 'Heart Rate Variability';
    case WearableDataType.weight:
      return 'Weight';
    default:
      return type.name;
  }
}

/// Map a [WearableDataType] to the corresponding Flutter [HealthDataType].
/// Falls back to [HealthDataType.STEPS] for unknown mappings to avoid nulls.
HealthDataType mapToHealthDataType(WearableDataType type) {
  return type.toHealthDataType() ?? HealthDataType.STEPS;
}

/// Build a platform-specific toast message for missing health permissions.
String buildMissingPermissionMessage(List<WearableDataType> missing) {
  final names = missing.map(friendlyWearableName).join(', ');
  return Platform.isAndroid
      ? 'Health permissions needed for $names. Enable in Health Connect.'
      : 'Health permissions needed for $names. Enable in Health app.';
}
