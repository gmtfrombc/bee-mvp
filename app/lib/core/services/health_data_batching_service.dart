/// Health Data Batching Service
///
/// Focused service that handles batching logic for health samples.
/// Separates batching concerns from HTTP upload logic.
library;

import 'package:flutter/foundation.dart';
import 'wearable_data_models.dart';

/// Configuration for batching behavior
class BatchingConfig {
  final int maxBatchSize;

  const BatchingConfig({this.maxBatchSize = 50});

  static const BatchingConfig defaultConfig = BatchingConfig();
}

/// Batch of health samples for upload
class HealthDataBatch {
  final String batchId;
  final List<HealthSample> samples;
  final DateTime createdAt;
  final String userId;
  final Map<String, dynamic>? metadata;

  HealthDataBatch({
    required this.batchId,
    required this.samples,
    required this.userId,
    DateTime? createdAt,
    this.metadata,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toUploadPayload() {
    return {
      'batch_id': batchId,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'samples': samples.map((sample) => sample.toMap()).toList(),
      'metadata': {...?metadata, 'sample_count': samples.length},
    };
  }
}

/// Service for batching health data samples
class HealthDataBatchingService {
  static final HealthDataBatchingService _instance =
      HealthDataBatchingService._internal();
  factory HealthDataBatchingService() => _instance;
  HealthDataBatchingService._internal();

  BatchingConfig _config = BatchingConfig.defaultConfig;

  /// Current configuration
  BatchingConfig get config => _config;

  /// Update batching configuration
  void updateConfig(BatchingConfig config) {
    _config = config;
    debugPrint(
      '📦 Batching service config updated: max size ${config.maxBatchSize}',
    );
  }

  /// Create batches from a list of samples
  List<HealthDataBatch> createBatches({
    required List<HealthSample> samples,
    required String userId,
    Map<String, dynamic>? metadata,
  }) {
    if (samples.isEmpty) {
      return [];
    }

    debugPrint(
      '📦 Creating batches for ${samples.length} samples (max batch size: ${_config.maxBatchSize})',
    );

    final batches = <HealthDataBatch>[];

    for (int i = 0; i < samples.length; i += _config.maxBatchSize) {
      final endIndex =
          (i + _config.maxBatchSize < samples.length)
              ? i + _config.maxBatchSize
              : samples.length;

      final batchSamples = samples.sublist(i, endIndex);
      final batchNumber = i ~/ _config.maxBatchSize;
      final batchId = _generateBatchId(userId, batchNumber);

      batches.add(
        HealthDataBatch(
          batchId: batchId,
          samples: batchSamples,
          userId: userId,
          metadata: {
            ...?metadata,
            'batch_number': batchNumber,
            'total_batches': (samples.length / _config.maxBatchSize).ceil(),
          },
        ),
      );
    }

    debugPrint(
      '📦 Created ${batches.length} batches from ${samples.length} samples',
    );
    return batches;
  }

  /// Basic batch validation (only critical checks)
  BatchValidationResult validateBatch(HealthDataBatch batch) {
    final issues = <String>[];

    if (batch.samples.isEmpty) {
      issues.add('Batch contains no samples');
    }

    if (batch.batchId.isEmpty) {
      issues.add('Batch ID is empty');
    }

    if (batch.userId.isEmpty) {
      issues.add('User ID is empty');
    }

    return BatchValidationResult(
      isValid: issues.isEmpty,
      issues: issues,
      batch: batch,
    );
  }

  /// Generate unique batch ID
  String _generateBatchId(String userId, int batchNumber) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${userId}_${timestamp}_$batchNumber';
  }
}

/// Result of batch validation
class BatchValidationResult {
  final bool isValid;
  final List<String> issues;
  final HealthDataBatch batch;

  const BatchValidationResult({
    required this.isValid,
    required this.issues,
    required this.batch,
  });
}
