/// Garmin Fallback Models for T2.2.2.12
///
/// Data models and enums for Garmin fallback functionality.
library;

import 'vitals_notifier_service.dart';

/// Fallback strategy when Garmin data is unavailable
enum GarminFallbackStrategy {
  /// Use other available wearable sources
  alternativeDevices,

  /// Use synthetic data based on user patterns
  syntheticData,

  /// Use historical data patterns
  historicalPatterns,

  /// Disable physiological coaching features
  disablePhysiological,
}

/// Garmin availability status for AI coaching context
enum GarminAvailabilityStatus {
  /// Garmin data is available and flowing
  available,

  /// Garmin temporarily unavailable, fallback active
  temporarilyUnavailable,

  /// Garmin permanently unavailable, using alternatives
  permanentlyUnavailable,

  /// Status unknown, determining fallback
  unknown,
}

/// Fallback data quality indicator
enum FallbackDataQuality {
  /// High quality alternative source available
  high,

  /// Moderate quality synthetic/historical data
  moderate,

  /// Low quality estimated data
  low,

  /// No fallback data available
  none,
}

/// Garmin fallback configuration
class GarminFallbackConfig {
  final Duration availabilityCheckInterval;
  final Duration fallbackActivationDelay;
  final int maxSyntheticDataPoints;
  final bool enableAlternativeDevices;
  final bool enableSyntheticData;
  final bool enableHistoricalPatterns;

  const GarminFallbackConfig({
    this.availabilityCheckInterval = const Duration(minutes: 5),
    this.fallbackActivationDelay = const Duration(minutes: 2),
    this.maxSyntheticDataPoints = 50,
    this.enableAlternativeDevices = true,
    this.enableSyntheticData = true,
    this.enableHistoricalPatterns = true,
  });

  static const GarminFallbackConfig defaultConfig = GarminFallbackConfig();
}

/// Fallback data result for AI coaching
class GarminFallbackResult {
  final GarminAvailabilityStatus status;
  final GarminFallbackStrategy strategy;
  final FallbackDataQuality dataQuality;
  final VitalsData? fallbackData;
  final String message;
  final Map<String, dynamic> metadata;

  const GarminFallbackResult({
    required this.status,
    required this.strategy,
    required this.dataQuality,
    this.fallbackData,
    required this.message,
    this.metadata = const {},
  });

  bool get isUsable => dataQuality != FallbackDataQuality.none;
  bool get requiresNotification =>
      status == GarminAvailabilityStatus.temporarilyUnavailable;
}
