/// Garmin Fallback Provider for T2.2.2.12
///
/// Riverpod providers for Garmin fallback service integration.
/// Enables AI coaching system to access fallback data gracefully.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/garmin_fallback_service.dart';
import '../services/garmin_fallback_models.dart';
import '../services/android_garmin_feature_flag_service.dart';
import '../services/wearable_data_repository.dart';
import '../services/vitals_notifier_service.dart';

/// Provider for GarminFallbackService instance
final garminFallbackServiceProvider = Provider<GarminFallbackService>((ref) {
  final garminService = AndroidGarminFeatureFlagService();
  final repository = WearableDataRepository();
  return GarminFallbackService(garminService, repository);
});

/// Provider for fallback status stream
final garminFallbackStreamProvider = StreamProvider<GarminFallbackResult>((
  ref,
) {
  final service = ref.watch(garminFallbackServiceProvider);
  return service.fallbackStream;
});

/// Provider for current fallback status
final currentGarminStatusProvider = Provider<GarminAvailabilityStatus>((ref) {
  final service = ref.watch(garminFallbackServiceProvider);
  return service.currentStatus;
});

/// Provider for active fallback strategy
final activeFallbackStrategyProvider = Provider<GarminFallbackStrategy>((ref) {
  final service = ref.watch(garminFallbackServiceProvider);
  return service.activeStrategy;
});

/// Provider for fallback vitals data
final fallbackVitalsDataProvider = FutureProvider<VitalsData?>((ref) async {
  final service = ref.watch(garminFallbackServiceProvider);
  return await service.getFallbackVitalsData();
});

/// Provider for fallback status check
final fallbackStatusCheckProvider = FutureProvider<GarminFallbackResult>((
  ref,
) async {
  final service = ref.watch(garminFallbackServiceProvider);
  return await service.checkFallbackStatus();
});

/// Provider for AI coaching integration
/// Returns true if physiological coaching should be disabled
final shouldDisablePhysiologicalCoachingProvider = Provider<bool>((ref) {
  final status = ref.watch(currentGarminStatusProvider);
  final strategy = ref.watch(activeFallbackStrategyProvider);

  return status != GarminAvailabilityStatus.available &&
      strategy == GarminFallbackStrategy.disablePhysiological;
});

/// Provider for coaching context message
final garminCoachingContextProvider = Provider<String>((ref) {
  final status = ref.watch(currentGarminStatusProvider);
  final strategy = ref.watch(activeFallbackStrategyProvider);

  switch (status) {
    case GarminAvailabilityStatus.available:
      return 'Using real-time health data for personalized coaching';
    case GarminAvailabilityStatus.temporarilyUnavailable:
      return _getTemporaryUnavailableMessage(strategy);
    case GarminAvailabilityStatus.permanentlyUnavailable:
      return _getPermanentUnavailableMessage(strategy);
    case GarminAvailabilityStatus.unknown:
      return 'Checking health data availability...';
  }
});

/// Helper function for temporary unavailable messages
String _getTemporaryUnavailableMessage(GarminFallbackStrategy strategy) {
  switch (strategy) {
    case GarminFallbackStrategy.alternativeDevices:
      return 'Using alternative health data sources for coaching';
    case GarminFallbackStrategy.syntheticData:
      return 'Using estimated health patterns for coaching guidance';
    case GarminFallbackStrategy.historicalPatterns:
      return 'Using your historical health patterns for coaching';
    case GarminFallbackStrategy.disablePhysiological:
      return 'Focusing on engagement-based coaching while health data reconnects';
  }
}

/// Helper function for permanent unavailable messages
String _getPermanentUnavailableMessage(GarminFallbackStrategy strategy) {
  switch (strategy) {
    case GarminFallbackStrategy.alternativeDevices:
      return 'Using available health devices for coaching insights';
    case GarminFallbackStrategy.syntheticData:
      return 'Using general health patterns for coaching guidance';
    case GarminFallbackStrategy.historicalPatterns:
      return 'Using your past health patterns for personalized coaching';
    case GarminFallbackStrategy.disablePhysiological:
      return 'Providing engagement-focused coaching without health data';
  }
}
