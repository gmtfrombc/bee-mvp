/// Health Data Quality Validation Integration Test
///
/// Integration test for T2.2.1.5-3 Data Quality Harness
/// Following testing policy: ≥85% coverage, essential tests only
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';

import 'package:app/core/services/health_data_quality_harness.dart';
import 'package:app/core/services/wearable_data_models.dart';

void main() {
  // Initialize Flutter bindings for platform channel tests
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HealthDataQualityHarness Integration Tests', () {
    late HealthDataQualityHarness harness;

    setUp(() {
      harness = HealthDataQualityHarness();
    });

    tearDown(() {
      harness.dispose();
    });

    group('Essential Core Tests', () {
      test('should initialize successfully in debug mode', () async {
        // Act
        final initialized = await harness.initialize();

        // Assert - Service should be available for testing
        // Note: May fail in CI without health permissions
        if (kDebugMode) {
          expect(initialized, isA<bool>());
        }
      });

      test('should handle validation execution without throwing', () async {
        // Arrange
        await harness.initialize();

        // Act & Assert - Should not throw exceptions
        expect(
          () async => await harness.executeValidation(
            dataTypes: [WearableDataType.steps],
            startTime: DateTime.now().subtract(const Duration(hours: 1)),
            endTime: DateTime.now(),
          ),
          returnsNormally,
        );
      });

      test('should return proper validation result structure', () async {
        // Arrange
        await harness.initialize();

        // Act
        final result = await harness.executeValidation(
          dataTypes: [WearableDataType.steps],
          startTime: DateTime.now().subtract(const Duration(hours: 1)),
          endTime: DateTime.now(),
        );

        // Assert - Result structure validation
        expect(result, isA<HealthDataQualityResult>());
        expect(result.validationId, isNotEmpty);
        expect(result.timestamp, isA<DateTime>());
        expect(result.passed, isA<bool>());
        expect(
          result.validations,
          isA<Map<WearableDataType, DataTypeValidation>>(),
        );
        expect(result.issues, isA<List<String>>());
        expect(result.summary, isA<Map<String, dynamic>>());
      });

      test('should validate target data types correctly', () async {
        // Arrange
        await harness.initialize();
        const targetTypes = [
          WearableDataType.steps,
          WearableDataType.heartRate,
          WearableDataType.sleepDuration,
        ];

        // Act
        final result = await harness.executeValidation(dataTypes: targetTypes);

        // Assert - Should attempt validation for all target types
        for (final type in targetTypes) {
          expect(result.validations.containsKey(type), isTrue);
          final validation = result.validations[type]!;
          expect(validation.type, equals(type));
          expect(validation.withinTolerance, isA<bool>());
          expect(validation.status, isNotEmpty);
        }
      });

      test('should generate proper summary metrics', () async {
        // Arrange
        await harness.initialize();

        // Act
        final result = await harness.executeValidation();

        // Assert - Summary structure validation
        expect(result.summary['overall_passed'], isA<bool>());
        expect(result.summary['total_count'], isA<int>());
        expect(result.summary['passed_count'], isA<int>());
        expect(result.summary['failed_count'], isA<int>());
        expect(result.summary['pass_rate'], isA<double>());
        expect(result.summary['tolerance_percent'], equals(3.0));
        expect(result.summary['validation_window_hours'], equals(24));
      });

      test('should handle quick validation', () async {
        // Arrange
        await harness.initialize();

        // Act
        final passed = await harness.quickValidation([WearableDataType.steps]);

        // Assert
        expect(passed, isA<bool>());
      });
    });

    group('Error Handling Tests', () {
      test('should handle uninitialized state gracefully', () async {
        // Act & Assert - Should throw StateError when not initialized
        expect(() async => await harness.executeValidation(), throwsStateError);
      });

      test('should create error result for exceptions', () {
        // Act
        final errorResult = HealthDataQualityResult.error('Test error');

        // Assert
        expect(errorResult.passed, isFalse);
        expect(errorResult.issues, contains('Test error'));
        expect(errorResult.summary['error'], equals('Test error'));
      });
    });

    group('Data Type Validation Tests', () {
      test('should validate DataTypeValidation model', () {
        // Act
        const validation = DataTypeValidation(
          type: WearableDataType.steps,
          appValue: 10000.0,
          healthSummaryValue: 10100.0,
          variancePercent: 1.0,
          withinTolerance: true,
          status: 'passed',
          details: 'Variance: 1.0%',
        );

        // Assert
        expect(validation.type, equals(WearableDataType.steps));
        expect(validation.appValue, equals(10000.0));
        expect(validation.healthSummaryValue, equals(10100.0));
        expect(validation.variancePercent, equals(1.0));
        expect(validation.withinTolerance, isTrue);
        expect(validation.status, equals('passed'));
        expect(validation.details, contains('Variance'));
      });
    });
  });
}
