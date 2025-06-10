/// Tests for HealthDataBatchingService
///
/// Following the testing policy: one happy-path test and critical edge-case tests only.
/// Target ≥85% coverage for core logic.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/health_data_batching_service.dart';
import 'package:app/core/services/wearable_data_models.dart';

void main() {
  group('HealthDataBatchingService', () {
    late HealthDataBatchingService service;
    late List<HealthSample> testSamples;

    setUp(() {
      service = HealthDataBatchingService();
      testSamples = [
        HealthSample(
          id: 'test-1',
          type: WearableDataType.steps,
          value: 1000,
          unit: 'count',
          timestamp: DateTime.now(),
          source: 'test',
        ),
        HealthSample(
          id: 'test-2',
          type: WearableDataType.heartRate,
          value: 75,
          unit: 'bpm',
          timestamp: DateTime.now(),
          source: 'test',
        ),
      ];
    });

    group('Happy Path Tests', () {
      test('should create batches from samples', () {
        // Execute
        final batches = service.createBatches(
          samples: testSamples,
          userId: 'user123',
        );

        // Verify
        expect(batches, hasLength(1));
        expect(batches.first.samples, hasLength(2));
        expect(batches.first.userId, equals('user123'));
      });
    });

    group('Edge Case Tests', () {
      test('should handle empty samples list', () {
        // Execute
        final batches = service.createBatches(samples: [], userId: 'user123');

        // Verify
        expect(batches, isEmpty);
      });

      test('should split large samples into multiple batches', () {
        // Setup
        final largeSampleList = List.generate(
          75,
          (index) => HealthSample(
            id: 'test-$index',
            type: WearableDataType.steps,
            value: 1000 + index,
            unit: 'count',
            timestamp: DateTime.now(),
            source: 'test',
          ),
        );

        service.updateConfig(const BatchingConfig(maxBatchSize: 30));

        // Execute
        final batches = service.createBatches(
          samples: largeSampleList,
          userId: 'user123',
        );

        // Verify
        expect(batches, hasLength(3)); // 75 samples / 30 per batch = 3 batches
        expect(batches[0].samples, hasLength(30));
        expect(batches[1].samples, hasLength(30));
        expect(batches[2].samples, hasLength(15));
      });

      test('should update configuration', () {
        // Setup
        const newConfig = BatchingConfig(maxBatchSize: 25);

        // Execute
        service.updateConfig(newConfig);

        // Verify
        expect(service.config.maxBatchSize, equals(25));
      });

      test('should validate batches', () {
        // Setup
        final validBatch = HealthDataBatch(
          batchId: 'test-batch',
          samples: testSamples,
          userId: 'user123',
        );

        final invalidBatch = HealthDataBatch(
          batchId: '',
          samples: [],
          userId: '',
        );

        // Execute & Verify
        expect(service.validateBatch(validBatch).isValid, isTrue);
        expect(service.validateBatch(invalidBatch).isValid, isFalse);
      });
    });
  });
}
