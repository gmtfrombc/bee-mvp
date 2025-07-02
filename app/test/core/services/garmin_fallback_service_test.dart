/// Unit tests for GarminFallbackService
/// Following BEE testing policy: essential tests only, clean output

import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/garmin_fallback_models.dart';

void main() {
  group('Garmin Fallback Models', () {
    test('default config values are set correctly', () {
      const config = GarminFallbackConfig.defaultConfig;

      expect(config.enableSyntheticData, isTrue);
      expect(config.enableAlternativeDevices, isTrue);
      expect(config.maxSyntheticDataPoints, 50);
      expect(config.availabilityCheckInterval, const Duration(minutes: 5));
      expect(config.fallbackActivationDelay, const Duration(minutes: 2));
    });

    test('fallback strategy enum has expected values', () {
      const strategies = GarminFallbackStrategy.values;

      expect(strategies, contains(GarminFallbackStrategy.alternativeDevices));
      expect(strategies, contains(GarminFallbackStrategy.syntheticData));
      expect(strategies, contains(GarminFallbackStrategy.historicalPatterns));
      expect(strategies, contains(GarminFallbackStrategy.disablePhysiological));
      expect(strategies.length, 4);
    });

    test('availability status enum has expected values', () {
      const statuses = GarminAvailabilityStatus.values;

      expect(statuses, contains(GarminAvailabilityStatus.available));
      expect(
        statuses,
        contains(GarminAvailabilityStatus.temporarilyUnavailable),
      );
      expect(
        statuses,
        contains(GarminAvailabilityStatus.permanentlyUnavailable),
      );
      expect(statuses, contains(GarminAvailabilityStatus.unknown));
      expect(statuses.length, 4);
    });

    test('fallback data quality enum has expected values', () {
      const qualities = FallbackDataQuality.values;

      expect(qualities, contains(FallbackDataQuality.high));
      expect(qualities, contains(FallbackDataQuality.moderate));
      expect(qualities, contains(FallbackDataQuality.low));
      expect(qualities, contains(FallbackDataQuality.none));
      expect(qualities.length, 4);
    });

    test('fallback result has expected properties', () {
      const result = GarminFallbackResult(
        status: GarminAvailabilityStatus.available,
        strategy: GarminFallbackStrategy.alternativeDevices,
        dataQuality: FallbackDataQuality.high,
        message: 'Test result',
      );

      expect(result.isUsable, isTrue);
      expect(result.requiresNotification, isFalse);
      expect(result.metadata, isEmpty);
      expect(result.fallbackData, isNull);
    });

    test('fallback result isUsable returns false for none quality', () {
      const result = GarminFallbackResult(
        status: GarminAvailabilityStatus.permanentlyUnavailable,
        strategy: GarminFallbackStrategy.disablePhysiological,
        dataQuality: FallbackDataQuality.none,
        message: 'No data available',
      );

      expect(result.isUsable, isFalse);
      expect(result.requiresNotification, isFalse);
    });

    test(
      'fallback result requiresNotification for temporarily unavailable',
      () {
        const result = GarminFallbackResult(
          status: GarminAvailabilityStatus.temporarilyUnavailable,
          strategy: GarminFallbackStrategy.syntheticData,
          dataQuality: FallbackDataQuality.moderate,
          message: 'Using synthetic data',
        );

        expect(result.requiresNotification, isTrue);
        expect(result.isUsable, isTrue);
      },
    );
  });
}
