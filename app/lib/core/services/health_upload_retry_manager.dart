/// Health Upload Retry Manager
///
/// Handles retry logic for failed health data uploads with exponential backoff,
/// circuit breaker pattern, and smart retry policies.
library;

import 'dart:math';
import 'package:flutter/foundation.dart';

import 'health_data_http_client.dart';
import 'health_data_batching_service.dart';

/// Configuration for retry behavior
class RetryConfig {
  final int maxAttempts;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;
  final List<int> retryableStatusCodes;

  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(minutes: 5),
    this.retryableStatusCodes = const [408, 429, 500, 502, 503, 504],
  });

  static const RetryConfig defaultConfig = RetryConfig();
}

/// Result of a retry operation
class RetryResult {
  final bool isSuccess;
  final HttpUploadResult finalResult;
  final int totalAttempts;
  final Duration totalTime;

  const RetryResult({
    required this.isSuccess,
    required this.finalResult,
    required this.totalAttempts,
    required this.totalTime,
  });
}

/// Circuit breaker state for managing consecutive failures
enum CircuitBreakerState { closed, open, halfOpen }

/// Circuit breaker for upload operations
class UploadCircuitBreaker {
  final int failureThreshold;
  final Duration recoveryTimeout;

  CircuitBreakerState _state = CircuitBreakerState.closed;
  int _failureCount = 0;
  DateTime? _lastFailureTime;

  UploadCircuitBreaker({
    this.failureThreshold = 5,
    this.recoveryTimeout = const Duration(minutes: 5),
  });

  CircuitBreakerState get state => _state;
  int get failureCount => _failureCount;

  /// Check if upload should be allowed
  bool shouldAllowUpload() {
    if (_state == CircuitBreakerState.closed) {
      return true;
    }

    if (_state == CircuitBreakerState.open) {
      if (_lastFailureTime != null &&
          DateTime.now().difference(_lastFailureTime!) > recoveryTimeout) {
        _state = CircuitBreakerState.halfOpen;
        return true;
      }
      return false;
    }

    // Half-open state - allow one attempt
    return true;
  }

  /// Record successful upload
  void recordSuccess() {
    _failureCount = 0;
    _state = CircuitBreakerState.closed;
  }

  /// Record failed upload
  void recordFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    if (_failureCount >= failureThreshold) {
      _state = CircuitBreakerState.open;
    }
  }

  Map<String, dynamic> getStatus() {
    return {
      'state': _state.name,
      'failureCount': _failureCount,
      'failureThreshold': failureThreshold,
      'lastFailureTime': _lastFailureTime?.toIso8601String(),
      'recoveryTimeoutSeconds': recoveryTimeout.inSeconds,
    };
  }
}

/// Retry manager for health data uploads
class HealthUploadRetryManager {
  static final HealthUploadRetryManager _instance =
      HealthUploadRetryManager._internal();
  factory HealthUploadRetryManager() => _instance;
  HealthUploadRetryManager._internal();

  final HealthDataHttpClient _httpClient = HealthDataHttpClient();
  final UploadCircuitBreaker _circuitBreaker = UploadCircuitBreaker();

  RetryConfig _config = RetryConfig.defaultConfig;
  final Random _random = Random();

  /// Current configuration
  RetryConfig get config => _config;

  /// Circuit breaker status
  Map<String, dynamic> get circuitBreakerStatus => _circuitBreaker.getStatus();

  /// Update retry configuration
  void updateConfig(RetryConfig config) {
    _config = config;
    debugPrint('🔄 Retry manager config updated');
  }

  /// Upload a single batch with retry logic
  Future<RetryResult> uploadBatchWithRetry(HealthDataBatch batch) async {
    final startTime = DateTime.now();

    // Check circuit breaker
    if (!_circuitBreaker.shouldAllowUpload()) {
      final result = HttpUploadResult.failure(
        httpStatusCode: 503,
        message:
            'Circuit breaker open - upload service temporarily unavailable',
        errorCode: 'CIRCUIT_BREAKER_OPEN',
        responseTime: const Duration(milliseconds: 1),
      );

      return RetryResult(
        isSuccess: false,
        finalResult: result,
        totalAttempts: 0,
        totalTime: DateTime.now().difference(startTime),
      );
    }

    HttpUploadResult? lastResult;

    for (int attempt = 1; attempt <= _config.maxAttempts; attempt++) {
      try {
        // Upload batch
        lastResult = await _httpClient.uploadBatch(batch);

        if (lastResult.isSuccess || attempt == _config.maxAttempts) {
          // Success or final attempt
          if (lastResult.isSuccess) {
            _circuitBreaker.recordSuccess();
          } else {
            _circuitBreaker.recordFailure();
          }

          return RetryResult(
            isSuccess: lastResult.isSuccess,
            finalResult: lastResult,
            totalAttempts: attempt,
            totalTime: DateTime.now().difference(startTime),
          );
        }

        // Failed - check if we should retry
        if (!_shouldRetry(lastResult)) {
          _circuitBreaker.recordFailure();

          return RetryResult(
            isSuccess: false,
            finalResult: lastResult,
            totalAttempts: attempt,
            totalTime: DateTime.now().difference(startTime),
          );
        }

        // Calculate delay for next attempt
        final delay = _calculateDelay(attempt);

        debugPrint(
          '🔄 Retry batch ${batch.batchId} attempt $attempt/${_config.maxAttempts} '
          'after ${delay.inMilliseconds}ms delay',
        );

        // Wait before retry
        await Future.delayed(delay);
      } catch (e) {
        debugPrint(
          '❌ Unexpected error during batch retry attempt $attempt: $e',
        );

        lastResult = HttpUploadResult.failure(
          httpStatusCode: 500,
          message: 'Unexpected error: $e',
          errorCode: 'UNEXPECTED_ERROR',
          responseTime: const Duration(milliseconds: 1),
        );

        if (attempt == _config.maxAttempts) {
          _circuitBreaker.recordFailure();
          break;
        }
      }
    }

    _circuitBreaker.recordFailure();

    return RetryResult(
      isSuccess: false,
      finalResult:
          lastResult ??
          HttpUploadResult.failure(
            httpStatusCode: 500,
            message: 'Batch upload failed after all retry attempts',
            errorCode: 'MAX_RETRIES_EXCEEDED',
            responseTime: const Duration(milliseconds: 1),
          ),
      totalAttempts: _config.maxAttempts,
      totalTime: DateTime.now().difference(startTime),
    );
  }

  /// Determine if an upload result should be retried
  bool _shouldRetry(HttpUploadResult result) {
    // Don't retry client errors (4xx) except rate limiting
    if (result.httpStatusCode >= 400 && result.httpStatusCode < 500) {
      return _config.retryableStatusCodes.contains(result.httpStatusCode);
    }

    // Retry server errors (5xx) and network errors
    if (result.httpStatusCode >= 500 || result.httpStatusCode == 0) {
      return true;
    }

    return false;
  }

  /// Calculate delay for retry attempt with exponential backoff and jitter
  Duration _calculateDelay(int attemptNumber) {
    final baseDelay = _config.initialDelay.inMilliseconds;
    final exponentialDelay =
        baseDelay * pow(_config.backoffMultiplier, attemptNumber - 1);

    // Add jitter (±25% randomness)
    final jitterFactor = 0.75 + (_random.nextDouble() * 0.5); // 0.75 to 1.25
    final jitteredDelay = (exponentialDelay * jitterFactor).round();

    // Cap at max delay
    final cappedDelay = min(jitteredDelay, _config.maxDelay.inMilliseconds);

    return Duration(milliseconds: cappedDelay);
  }
}
