/// Tests for HealthDataUploadCoordinator
///
/// Following the testing policy: one happy-path test and critical edge-case tests only.
/// Target ≥85% coverage for core logic.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/health_data_upload_service.dart';
import 'package:app/core/services/health_data_batching_service.dart';
import 'package:app/core/services/health_data_http_client.dart';

void main() {
  group('HealthDataUploadCoordinator', () {
    late HealthDataUploadCoordinator service;

    setUp(() {
      service = HealthDataUploadCoordinator();
    });

    group('Happy Path Tests', () {
      test('should update configuration', () {
        // Setup
        const newConfig = UploadCoordinatorConfig(
          batchingConfig: BatchingConfig(maxBatchSize: 25),
          httpConfig: HttpClientConfig(requestTimeout: Duration(seconds: 45)),
        );

        // Execute
        service.updateConfig(newConfig);

        // Verify
        expect(service.config.batchingConfig.maxBatchSize, equals(25));
        expect(
          service.config.httpConfig.requestTimeout,
          equals(const Duration(seconds: 45)),
        );
      });
    });

    group('Edge Case Tests', () {
      test('should handle empty samples list', () async {
        // Execute
        final result = await service.uploadSamples(
          samples: [],
          userId: 'user123',
        );

        // Verify
        expect(result.isSuccess, isTrue);
        expect(result.totalSamplesUploaded, equals(0));
        expect(result.batchesProcessed, equals(0));
      });

      test('should create success result with factory', () {
        // Execute
        final result = UploadCoordinatorResult.success(
          totalSamplesUploaded: 50,
          batchesProcessed: 2,
          totalTime: const Duration(seconds: 5),
        );

        // Verify
        expect(result.isSuccess, isTrue);
        expect(result.totalSamplesUploaded, equals(50));
        expect(result.batchesProcessed, equals(2));
      });

      test('should create failure result with factory', () {
        // Execute
        final result = UploadCoordinatorResult.failure(
          message: 'Upload failed',
          totalTime: const Duration(seconds: 2),
        );

        // Verify
        expect(result.isSuccess, isFalse);
        expect(result.message, equals('Upload failed'));
        expect(result.totalSamplesUploaded, equals(0));
      });
    });
  });
}
