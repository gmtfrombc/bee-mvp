/// Health Data Upload Coordinator
///
/// Lightweight coordinator that orchestrates health data upload process
/// by coordinating batching, HTTP communication, and result aggregation.
library;

import 'package:flutter/foundation.dart';

import 'wearable_data_models.dart';
import 'health_data_batching_service.dart';
import 'health_data_http_client.dart';

/// Configuration for upload coordinator
class UploadCoordinatorConfig {
  final BatchingConfig batchingConfig;
  final HttpClientConfig httpConfig;

  const UploadCoordinatorConfig({
    this.batchingConfig = BatchingConfig.defaultConfig,
    this.httpConfig = HttpClientConfig.defaultConfig,
  });

  static const UploadCoordinatorConfig defaultConfig =
      UploadCoordinatorConfig();
}

/// Result of a coordinated upload operation
class UploadCoordinatorResult {
  final bool isSuccess;
  final String message;
  final int totalSamplesUploaded;
  final int batchesProcessed;
  final DateTime timestamp;
  final Duration totalTime;

  const UploadCoordinatorResult({
    required this.isSuccess,
    required this.message,
    required this.totalSamplesUploaded,
    required this.batchesProcessed,
    required this.timestamp,
    required this.totalTime,
  });

  factory UploadCoordinatorResult.success({
    required int totalSamplesUploaded,
    required int batchesProcessed,
    required Duration totalTime,
  }) {
    return UploadCoordinatorResult(
      isSuccess: true,
      message: 'Upload coordination completed successfully',
      totalSamplesUploaded: totalSamplesUploaded,
      batchesProcessed: batchesProcessed,
      timestamp: DateTime.now(),
      totalTime: totalTime,
    );
  }

  factory UploadCoordinatorResult.failure({
    required String message,
    int totalSamplesUploaded = 0,
    int batchesProcessed = 0,
    required Duration totalTime,
  }) {
    return UploadCoordinatorResult(
      isSuccess: false,
      message: message,
      totalSamplesUploaded: totalSamplesUploaded,
      batchesProcessed: batchesProcessed,
      timestamp: DateTime.now(),
      totalTime: totalTime,
    );
  }
}

/// Coordinator for health data uploads
class HealthDataUploadCoordinator {
  static final HealthDataUploadCoordinator _instance =
      HealthDataUploadCoordinator._internal();
  factory HealthDataUploadCoordinator() => _instance;
  HealthDataUploadCoordinator._internal();

  final HealthDataBatchingService _batchingService =
      HealthDataBatchingService();
  final HealthDataHttpClient _httpClient = HealthDataHttpClient();

  UploadCoordinatorConfig _config = UploadCoordinatorConfig.defaultConfig;

  /// Current configuration
  UploadCoordinatorConfig get config => _config;

  /// Update coordinator configuration
  void updateConfig(UploadCoordinatorConfig config) {
    _config = config;
    _batchingService.updateConfig(config.batchingConfig);
    _httpClient.updateConfig(config.httpConfig);
    debugPrint('🎯 Upload coordinator config updated');
  }

  /// Upload health samples with full coordination
  Future<UploadCoordinatorResult> uploadSamples({
    required List<HealthSample> samples,
    required String userId,
    Map<String, dynamic>? metadata,
  }) async {
    final startTime = DateTime.now();

    if (samples.isEmpty) {
      return UploadCoordinatorResult.success(
        totalSamplesUploaded: 0,
        batchesProcessed: 0,
        totalTime: DateTime.now().difference(startTime),
      );
    }

    debugPrint(
      '🎯 Coordinating upload of ${samples.length} samples for user $userId',
    );

    try {
      // Step 1: Create batches
      final batches = _batchingService.createBatches(
        samples: samples,
        userId: userId,
        metadata: metadata,
      );

      if (batches.isEmpty) {
        return UploadCoordinatorResult.failure(
          message: 'Failed to create batches from samples',
          totalTime: DateTime.now().difference(startTime),
        );
      }

      debugPrint('🎯 Created ${batches.length} batches for upload');

      // Step 2: Upload each batch
      int totalUploaded = 0;

      for (final batch in batches) {
        // Validate batch before upload
        final validation = _batchingService.validateBatch(batch);
        if (!validation.isValid) {
          debugPrint(
            '⚠️ Batch ${batch.batchId} validation failed: ${validation.issues}',
          );
          continue; // Skip invalid batches
        }

        // Upload the batch
        final result = await _httpClient.uploadBatch(batch);

        if (result.isSuccess) {
          totalUploaded += result.samplesProcessed;
          debugPrint('✅ Batch ${batch.batchId} uploaded successfully');
        } else {
          debugPrint(
            '❌ Batch ${batch.batchId} upload failed: ${result.message}',
          );
        }
      }

      final totalTime = DateTime.now().difference(startTime);

      if (totalUploaded > 0) {
        return UploadCoordinatorResult.success(
          totalSamplesUploaded: totalUploaded,
          batchesProcessed: batches.length,
          totalTime: totalTime,
        );
      } else {
        return UploadCoordinatorResult.failure(
          message: 'No samples were successfully uploaded',
          batchesProcessed: batches.length,
          totalTime: totalTime,
        );
      }
    } catch (e) {
      return UploadCoordinatorResult.failure(
        message: 'Upload coordination failed: $e',
        totalTime: DateTime.now().difference(startTime),
      );
    }
  }
}
