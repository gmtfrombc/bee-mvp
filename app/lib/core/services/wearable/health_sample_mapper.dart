/// Mapper utilities for converting between WearableDataType and
/// platform-specific identifiers (HealthKit, etc.).
///
/// Extracted from `wearable_data_repository.dart`.

library wearable.health_sample_mapper;

import '../wearable_data_models.dart';

/// Converts a [WearableDataType] to the corresponding HealthKit identifier
/// used by the native Swift bridge.
String hkIdentifierFromWearableDataType(WearableDataType type) {
  switch (type) {
    case WearableDataType.steps:
      return 'HKQuantityTypeIdentifierStepCount';
    case WearableDataType.heartRate:
      return 'HKQuantityTypeIdentifierHeartRate';
    case WearableDataType.sleepDuration:
      return 'HKCategoryTypeIdentifierSleepAnalysis';
    case WearableDataType.restingHeartRate:
      return 'HKQuantityTypeIdentifierRestingHeartRate';
    case WearableDataType.activeEnergyBurned:
      return 'HKQuantityTypeIdentifierActiveEnergyBurned';
    case WearableDataType.heartRateVariability:
      return 'HKQuantityTypeIdentifierHeartRateVariabilitySDNN';
    case WearableDataType.weight:
      return 'HKQuantityTypeIdentifierBodyMass';
    case WearableDataType.distanceWalking:
      return 'HKQuantityTypeIdentifierDistanceWalkingRunning';
    case WearableDataType.flightsClimbed:
      return 'HKQuantityTypeIdentifierFlightsClimbed';
    default:
      return 'HKQuantityTypeIdentifierStepCount';
  }
}
