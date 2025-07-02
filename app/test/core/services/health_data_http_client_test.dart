

import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/health_data_http_client.dart';

void main() {
  group('HealthDataHttpClient', () {
    late HealthDataHttpClient service;

    setUp(() {
      service = HealthDataHttpClient();
    });

    group('Happy Path Tests', () {
      test('should update configuration', () {
        // Setup
        const newConfig = HttpClientConfig(
          requestTimeout: Duration(seconds: 45),
          enableCompression: false,
        );

        // Execute
        service.updateConfig(newConfig);

        // Verify
        expect(
          service.config.requestTimeout,
          equals(const Duration(seconds: 45)),
        );
        expect(service.config.enableCompression, isFalse);
      });
    });

    group('Edge Case Tests', () {
      test('should create success result with factory', () {
        // Execute
        final result = HttpUploadResult.success(
          samplesProcessed: 10,
          responseTime: const Duration(milliseconds: 500),
        );

        // Verify
        expect(result.isSuccess, isTrue);
        expect(result.samplesProcessed, equals(10));
      });

      test('should create failure result with factory', () {
        // Execute
        final result = HttpUploadResult.failure(
          httpStatusCode: 400,
          message: 'Bad Request',
          responseTime: const Duration(milliseconds: 200),
        );

        // Verify
        expect(result.isSuccess, isFalse);
        expect(result.httpStatusCode, equals(400));
      });
    });
  });
}
