/// Tests for HealthUploadRetryManager
///
/// Following the testing policy: one happy-path test and critical edge-case tests only.
/// Target ≥85% coverage for core logic.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/health_upload_retry_manager.dart';
import 'package:app/core/services/health_data_http_client.dart';

void main() {
  group('HealthUploadRetryManager', () {
    late HealthUploadRetryManager service;

    setUp(() {
      service = HealthUploadRetryManager();
    });

    group('Happy Path Tests', () {
      test('should update configuration', () {
        // Setup
        const newConfig = RetryConfig(
          maxAttempts: 5,
          initialDelay: Duration(seconds: 2),
          backoffMultiplier: 3.0,
        );

        // Execute
        service.updateConfig(newConfig);

        // Verify
        expect(service.config.maxAttempts, equals(5));
        expect(service.config.initialDelay, equals(const Duration(seconds: 2)));
        expect(service.config.backoffMultiplier, equals(3.0));
      });
    });

    group('Edge Case Tests', () {
      test('should provide circuit breaker status', () {
        // Execute
        final status = service.circuitBreakerStatus;

        // Verify
        expect(status, isA<Map<String, dynamic>>());
        expect(status['state'], isA<String>());
        expect(status['failureCount'], isA<int>());
      });

      test('should create retry result', () {
        // Setup
        final httpResult = HttpUploadResult.success(
          samplesProcessed: 10,
          responseTime: const Duration(milliseconds: 500),
        );

        // Execute
        final result = RetryResult(
          isSuccess: true,
          finalResult: httpResult,
          totalAttempts: 1,
          totalTime: const Duration(seconds: 1),
        );

        // Verify
        expect(result.isSuccess, isTrue);
        expect(result.totalAttempts, equals(1));
        expect(result.finalResult, equals(httpResult));
      });
    });

    group('Circuit Breaker Tests', () {
      test('should allow uploads when circuit is closed', () {
        // Setup
        final circuitBreaker = UploadCircuitBreaker();

        // Execute & Verify
        expect(circuitBreaker.shouldAllowUpload(), isTrue);
        expect(circuitBreaker.state, equals(CircuitBreakerState.closed));
      });

      test('should track failures and successes', () {
        // Setup
        final circuitBreaker = UploadCircuitBreaker(failureThreshold: 2);

        // Execute - Record failure
        circuitBreaker.recordFailure();

        // Verify
        expect(circuitBreaker.failureCount, equals(1));
        expect(circuitBreaker.state, equals(CircuitBreakerState.closed));

        // Execute - Record success
        circuitBreaker.recordSuccess();

        // Verify
        expect(circuitBreaker.failureCount, equals(0));
        expect(circuitBreaker.state, equals(CircuitBreakerState.closed));
      });
    });
  });
}
