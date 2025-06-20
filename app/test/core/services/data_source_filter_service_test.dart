import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/services/data_source_filter_service.dart';
import 'package:app/core/services/wearable_data_models.dart';

void main() {
  group('DataSourceFilterService', () {
    late DataSourceFilterService service;

    setUp(() {
      service = DataSourceFilterService();
    });

    group('identifySourceCategory', () {
      test('should detect Garmin sources', () {
        expect(
          service.identifySourceCategory('Garmin Connect'),
          DataSourceCategory.garmin,
        );
        expect(
          service.identifySourceCategory(
            'com.garmin.android.apps.connectmobile',
          ),
          DataSourceCategory.garmin,
        );
      });

      test('should detect Apple sources', () {
        expect(
          service.identifySourceCategory('Health'),
          DataSourceCategory.apple,
        );
        expect(
          service.identifySourceCategory('HealthKit'),
          DataSourceCategory.apple,
        );
        expect(
          service.identifySourceCategory('Apple Watch'),
          DataSourceCategory.apple,
        );
      });

      test('should detect Fitbit sources', () {
        expect(
          service.identifySourceCategory('Fitbit App'),
          DataSourceCategory.fitbit,
        );
      });

      test('should detect Samsung sources', () {
        expect(
          service.identifySourceCategory('Galaxy Watch'),
          DataSourceCategory.samsung,
        );
      });

      test('should detect Google Fit sources', () {
        expect(
          service.identifySourceCategory('Google Fit'),
          DataSourceCategory.googleFit,
        );
      });

      test('should mark unknown sources', () {
        expect(
          service.identifySourceCategory('Some Random Source'),
          DataSourceCategory.unknown,
        );
      });
    });

    group('filterSamples', () {
      List<HealthSample> createTestSamples() {
        return [
          HealthSample(
            id: '1',
            type: WearableDataType.steps,
            value: 1000,
            unit: 'count',
            timestamp: DateTime.now(),
            source: 'Garmin Connect',
          ),
          HealthSample(
            id: '2',
            type: WearableDataType.heartRate,
            value: 70,
            unit: 'bpm',
            timestamp: DateTime.now(),
            source: 'Apple Watch',
          ),
          HealthSample(
            id: '3',
            type: WearableDataType.steps,
            value: 500,
            unit: 'count',
            timestamp: DateTime.now(),
            source: 'Fitbit',
          ),
        ];
      }

      test('filters Garmin-only data correctly', () {
        final samples = createTestSamples();
        final result = service.filterSamples(
          samples,
          DataSourceFilterCriteria.garminOnly,
        );

        expect(result.samples.length, 1);
        expect(result.samples.first.source, 'Garmin Connect');
        expect(result.totalSamples, 3);
        expect(result.filteredSamples, 1);
        expect(result.hasGarminData, true);
      });

      test('excludes Garmin data correctly', () {
        final samples = createTestSamples();
        final result = service.filterSamples(
          samples,
          DataSourceFilterCriteria.excludeGarmin,
        );

        expect(result.samples.length, 2);
        expect(result.samples.every((s) => s.source != 'Garmin Connect'), true);
        expect(result.totalSamples, 3);
        expect(result.filteredSamples, 2);
      });

      test('returns all samples with default criteria', () {
        final samples = createTestSamples();
        final result = service.filterSamples(
          samples,
          DataSourceFilterCriteria.all,
        );

        expect(result.samples.length, 3);
        expect(result.totalSamples, 3);
        expect(result.filteredSamples, 3);
      });
    });

    group('convenience methods', () {
      test('filterGarminOnly returns only Garmin samples', () {
        final samples = [
          HealthSample(
            id: '1',
            type: WearableDataType.steps,
            value: 1000,
            unit: 'count',
            timestamp: DateTime.now(),
            source: 'Garmin Connect',
          ),
          HealthSample(
            id: '2',
            type: WearableDataType.heartRate,
            value: 70,
            unit: 'bpm',
            timestamp: DateTime.now(),
            source: 'Apple Watch',
          ),
        ];

        final filtered = service.filterGarminOnly(samples);
        expect(filtered.length, 1);
        expect(filtered.first.source, 'Garmin Connect');
      });

      test('isGarminSource identifies Garmin samples correctly', () {
        final garminSample = HealthSample(
          id: '1',
          type: WearableDataType.steps,
          value: 1000,
          unit: 'count',
          timestamp: DateTime.now(),
          source: 'Garmin Connect',
        );

        final appleSample = HealthSample(
          id: '2',
          type: WearableDataType.heartRate,
          value: 70,
          unit: 'bpm',
          timestamp: DateTime.now(),
          source: 'Apple Watch',
        );

        expect(service.isGarminSource(garminSample), true);
        expect(service.isGarminSource(appleSample), false);
      });
    });

    group('analyzeSourceDistribution', () {
      test('provides accurate source distribution analysis', () {
        final samples = [
          HealthSample(
            id: '1',
            type: WearableDataType.steps,
            value: 1000,
            unit: 'count',
            timestamp: DateTime.now(),
            source: 'Garmin Connect',
          ),
          HealthSample(
            id: '2',
            type: WearableDataType.steps,
            value: 500,
            unit: 'count',
            timestamp: DateTime.now(),
            source: 'Garmin Connect',
          ),
          HealthSample(
            id: '3',
            type: WearableDataType.heartRate,
            value: 70,
            unit: 'bpm',
            timestamp: DateTime.now(),
            source: 'Apple Watch',
          ),
        ];

        final analysis = service.analyzeSourceDistribution(samples);

        expect(analysis['totalSamples'], 3);
        expect(analysis['sourceBreakdown']['garmin'], 2);
        expect(analysis['sourceBreakdown']['apple'], 1);
        expect(analysis['garminPercentage'], closeTo(0.67, 0.01));
        expect(analysis['hasMultipleSources'], true);
      });
    });
  });
}
