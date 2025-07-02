import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/android_garmin_feature_flag_service.dart';

void main() {
  group('AndroidGarminBetaConfig', () {
    test('should have valid default configuration', () {
      // Happy path: configuration values are sensible
      expect(AndroidGarminBetaConfig.enableGarminBetaDefault, false);
      expect(AndroidGarminBetaConfig.enableDataSourceDetection, true);
      expect(AndroidGarminBetaConfig.enableUserWarnings, true);
      expect(AndroidGarminBetaConfig.garminSourceIdentifiers, isNotEmpty);
      expect(AndroidGarminBetaConfig.warningCooldown.inHours, 24);
    });

    test('should contain expected Garmin identifiers', () {
      // Critical test: Garmin identification patterns
      const identifiers = AndroidGarminBetaConfig.garminSourceIdentifiers;
      expect(identifiers, contains('Garmin Connect'));
      expect(identifiers, contains('Garmin'));
    });
  });

  group('GarminDataStatus', () {
    test('should have all expected status values', () {
      // Happy path: all status values available
      expect(GarminDataStatus.values, hasLength(4));
      expect(GarminDataStatus.values, contains(GarminDataStatus.available));
      expect(GarminDataStatus.values, contains(GarminDataStatus.notDetected));
      expect(GarminDataStatus.values, contains(GarminDataStatus.noData));
      expect(GarminDataStatus.values, contains(GarminDataStatus.unknown));
    });
  });

  group('DataSourceAnalysisResult', () {
    test('should create valid result with all fields', () {
      // Happy path: complete result creation
      final timestamp = DateTime.now();
      final result = DataSourceAnalysisResult(
        status: GarminDataStatus.available,
        detectedSources: ['Garmin Connect', 'Apple Health'],
        hasGarminSource: true,
        totalSamples: 100,
        analysisTimestamp: timestamp,
      );

      expect(result.status, GarminDataStatus.available);
      expect(result.detectedSources, hasLength(2));
      expect(result.hasGarminSource, true);
      expect(result.totalSamples, 100);
      expect(result.analysisTimestamp, timestamp);
      expect(result.isSuccessful, true);
    });

    test('should handle error state correctly', () {
      // Edge case: error result
      final result = DataSourceAnalysisResult(
        status: GarminDataStatus.unknown,
        detectedSources: [],
        hasGarminSource: false,
        totalSamples: 0,
        analysisTimestamp: DateTime.now(),
        errorMessage: 'Test error',
      );

      expect(result.isSuccessful, false);
      expect(result.errorMessage, 'Test error');
    });

    test('should convert to map correctly', () {
      // Happy path: data serialization
      final timestamp = DateTime.now();
      final result = DataSourceAnalysisResult(
        status: GarminDataStatus.notDetected,
        detectedSources: ['Apple Health'],
        hasGarminSource: false,
        totalSamples: 50,
        analysisTimestamp: timestamp,
      );

      final map = result.toMap();
      expect(map['status'], 'notDetected');
      expect(map['detectedSources'], ['Apple Health']);
      expect(map['hasGarminSource'], false);
      expect(map['totalSamples'], 50);
      expect(map['analysisTimestamp'], timestamp.toIso8601String());
    });
  });

  group('Task T2.2.1.8 Requirements Validation', () {
    test('should detect Health Connect data origin patterns', () {
      // Core requirement: data origin detection
      final garminSources = [
        'Garmin Connect',
        'com.garmin.android.apps.connectmobile',
      ];
      final nonGarminSources = ['Apple Health', 'Samsung Health', 'Fitbit'];

      for (final source in garminSources) {
        const identifiers = AndroidGarminBetaConfig.garminSourceIdentifiers;
        final isGarmin = identifiers.any(
          (id) => source.toLowerCase().contains(id.toLowerCase()),
        );
        expect(isGarmin, true, reason: 'Should detect $source as Garmin');
      }

      for (final source in nonGarminSources) {
        const identifiers = AndroidGarminBetaConfig.garminSourceIdentifiers;
        final isGarmin = identifiers.any(
          (id) => source.toLowerCase().contains(id.toLowerCase()),
        );
        expect(isGarmin, false, reason: 'Should not detect $source as Garmin');
      }
    });

    test('should provide warning when Garmin support not enabled', () {
      // Core requirement: warning system configuration
      expect(AndroidGarminBetaConfig.enableUserWarnings, true);
      expect(AndroidGarminBetaConfig.maxWarningsPerDay, greaterThan(0));
      expect(AndroidGarminBetaConfig.warningCooldown.inHours, greaterThan(0));
    });

    test('should support feature flag functionality', () {
      // Core requirement: feature flag system
      expect(AndroidGarminBetaConfig.enableGarminBetaDefault, isA<bool>());
      // Feature should be disabled by default for beta testing
      expect(AndroidGarminBetaConfig.enableGarminBetaDefault, false);
    });
  });
}
