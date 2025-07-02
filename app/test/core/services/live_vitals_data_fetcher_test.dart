/// Live Vitals Data Fetcher Tests
///
/// Essential unit tests for T2.2.1.5-4 core business logic.
/// Following testing policy: ≥85% coverage, essential tests only.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/core/services/live_vitals_data_fetcher.dart';
import 'package:app/core/services/wearable_data_repository.dart';
import 'package:app/core/services/wearable_data_models.dart';

// Mock classes
class MockWearableDataRepository extends Mock
    implements WearableDataRepository {}

void main() {
  group('LiveVitalsDataFetcher', () {
    late LiveVitalsDataFetcher fetcher;
    late MockWearableDataRepository mockRepository;

    setUp(() {
      mockRepository = MockWearableDataRepository();
      fetcher = LiveVitalsDataFetcher(mockRepository);
    });

    group('fetchRecentData', () {
      test('should calculate delta correctly for sequential values', () async {
        // Arrange
        final startTime = DateTime.now().subtract(const Duration(seconds: 5));
        final endTime = DateTime.now();

        final samples = [
          HealthSample(
            id: '1',
            type: WearableDataType.heartRate,
            value: 75.0,
            unit: 'bpm',
            timestamp: startTime,
            source: 'TestDevice',
          ),
          HealthSample(
            id: '2',
            type: WearableDataType.heartRate,
            value: 78.0,
            unit: 'bpm',
            timestamp: endTime,
            source: 'TestDevice',
          ),
        ];

        when(
          () => mockRepository.getHealthData(
            dataTypes: any(named: 'dataTypes'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
          ),
        ).thenAnswer((_) async => HealthDataQueryResult(samples: samples));

        // Act
        final result = await fetcher.fetchRecentData(
          dataTypes: [WearableDataType.heartRate],
          startTime: startTime,
          endTime: endTime,
        );

        // Assert
        expect(result, hasLength(2));
        expect(result[0].delta, isNull); // First value has no delta
        expect(result[1].delta, equals(3.0)); // 78 - 75 = 3
      });

      test('should handle empty data gracefully', () async {
        // Arrange
        when(
          () => mockRepository.getHealthData(
            dataTypes: any(named: 'dataTypes'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
          ),
        ).thenAnswer((_) async => const HealthDataQueryResult(samples: []));

        // Act
        final result = await fetcher.fetchRecentData(
          dataTypes: [WearableDataType.steps],
          startTime: DateTime.now().subtract(const Duration(seconds: 5)),
          endTime: DateTime.now(),
        );

        // Assert
        expect(result, isEmpty);
      });

      test('should handle repository errors gracefully', () async {
        // Arrange
        when(
          () => mockRepository.getHealthData(
            dataTypes: any(named: 'dataTypes'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
          ),
        ).thenAnswer(
          (_) async =>
              const HealthDataQueryResult(samples: [], error: 'Network error'),
        );

        // Act
        final result = await fetcher.fetchRecentData(
          dataTypes: [WearableDataType.heartRate],
          startTime: DateTime.now().subtract(const Duration(seconds: 5)),
          endTime: DateTime.now(),
        );

        // Assert
        expect(result, isEmpty);
      });

      test('should sort results by timestamp', () async {
        // Arrange
        final now = DateTime.now();
        final samples = [
          HealthSample(
            id: '2',
            type: WearableDataType.steps,
            value: 1500.0,
            unit: 'count',
            timestamp: now,
            source: 'TestDevice',
          ),
          HealthSample(
            id: '1',
            type: WearableDataType.steps,
            value: 1000.0,
            unit: 'count',
            timestamp: now.subtract(const Duration(seconds: 2)),
            source: 'TestDevice',
          ),
        ];

        when(
          () => mockRepository.getHealthData(
            dataTypes: any(named: 'dataTypes'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
          ),
        ).thenAnswer((_) async => HealthDataQueryResult(samples: samples));

        // Act
        final result = await fetcher.fetchRecentData(
          dataTypes: [WearableDataType.steps],
          startTime: now.subtract(const Duration(seconds: 5)),
          endTime: now,
        );

        // Assert
        expect(result, hasLength(2));
        expect(
          result[0].timestamp,
          equals(now.subtract(const Duration(seconds: 2))),
        );
        expect(result[1].timestamp, equals(now));
      });

      test('should handle exceptions by returning empty list', () async {
        // Arrange
        when(
          () => mockRepository.getHealthData(
            dataTypes: any(named: 'dataTypes'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
          ),
        ).thenThrow(Exception('Network timeout'));

        // Act
        final result = await fetcher.fetchRecentData(
          dataTypes: [WearableDataType.heartRate],
          startTime: DateTime.now().subtract(const Duration(seconds: 5)),
          endTime: DateTime.now(),
        );

        // Assert - Should return empty list, not throw
        expect(result, isEmpty);
      });
    });

    group('resetDeltas', () {
      test('should clear last values correctly', () async {
        // Arrange
        final sample = HealthSample(
          id: '1',
          type: WearableDataType.heartRate,
          value: 75.0,
          unit: 'bpm',
          timestamp: DateTime.now(),
          source: 'TestDevice',
        );

        when(
          () => mockRepository.getHealthData(
            dataTypes: any(named: 'dataTypes'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
          ),
        ).thenAnswer((_) async => HealthDataQueryResult(samples: [sample]));

        // Act - Populate last values
        await fetcher.fetchRecentData(
          dataTypes: [WearableDataType.heartRate],
          startTime: DateTime.now().subtract(const Duration(seconds: 5)),
          endTime: DateTime.now(),
        );

        expect(fetcher.lastValues, isNotEmpty);

        // Act - Reset
        fetcher.resetDeltas();

        // Assert
        expect(fetcher.lastValues, isEmpty);
      });
    });
  });
}
