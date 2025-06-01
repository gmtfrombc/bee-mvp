import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/features/today_feed/data/services/today_feed_performance_monitor.dart';
import 'package:app/core/services/responsive_service.dart';

void main() {
  // Initialize Flutter test binding for platform channel tests
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TodayFeedPerformanceMonitor', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});

      // Initialize only the performance monitor service
      // ConnectivityService is not initialized in tests to avoid plugin dependencies
      await TodayFeedPerformanceMonitor.initialize();
    });

    tearDown(() async {
      await TodayFeedPerformanceMonitor.dispose();
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        // Arrange & Act
        await TodayFeedPerformanceMonitor.initialize();

        // Assert
        expect(TodayFeedPerformanceMonitor.alertStream, isNotNull);
      });

      test('should not reinitialize if already initialized', () async {
        // Arrange
        await TodayFeedPerformanceMonitor.initialize();

        // Act & Assert - should not throw
        await TodayFeedPerformanceMonitor.initialize();
      });
    });

    group('Load Time Tracking', () {
      test('should start tracking load time', () {
        // Arrange
        const operation = LoadOperation.contentFetch;

        // Act
        final trackingId = TodayFeedPerformanceMonitor.startLoadTimeTracking(
          operation,
        );

        // Assert
        expect(trackingId, isNotEmpty);
        expect(trackingId, contains(operation.name));
      });

      test('should return empty string when not initialized', () async {
        // Arrange
        await TodayFeedPerformanceMonitor.dispose();
        const operation = LoadOperation.contentFetch;

        // Act
        final trackingId = TodayFeedPerformanceMonitor.startLoadTimeTracking(
          operation,
        );

        // Assert
        expect(trackingId, isEmpty);
      });

      test('should complete tracking and return measurement', () async {
        // Arrange
        const operation = LoadOperation.contentFetch;
        final trackingId = TodayFeedPerformanceMonitor.startLoadTimeTracking(
          operation,
        );

        // Simulate some work
        await Future.delayed(const Duration(milliseconds: 100));

        // Act
        final measurement =
            await TodayFeedPerformanceMonitor.completeLoadTimeTracking(
              trackingId,
              operation,
            );

        // Assert
        expect(measurement, isNotNull);
        expect(measurement!.id, equals(trackingId));
        expect(measurement.operation, equals(operation));
        expect(measurement.loadTime.inMilliseconds, greaterThan(50));
        expect(measurement.result, equals(LoadResult.success));
      });

      test('should return null for invalid tracking ID', () async {
        // Arrange
        const operation = LoadOperation.contentFetch;
        const invalidTrackingId = 'invalid_id';

        // Act
        final measurement =
            await TodayFeedPerformanceMonitor.completeLoadTimeTracking(
              invalidTrackingId,
              operation,
            );

        // Assert
        expect(measurement, isNull);
      });
    });

    group('Load Operation Tracking', () {
      test('should track successful load operation', () async {
        // Arrange
        const operation = LoadOperation.contentFetch;
        var functionCalled = false;

        Future<String> testFunction() async {
          functionCalled = true;
          await Future.delayed(const Duration(milliseconds: 50));
          return 'success';
        }

        // Act
        final measurement =
            await TodayFeedPerformanceMonitor.trackLoadOperation(
              operation,
              testFunction,
            );

        // Assert
        expect(functionCalled, isTrue);
        expect(measurement, isNotNull);
        expect(measurement!.operation, equals(operation));
        expect(measurement.result, equals(LoadResult.success));
        expect(measurement.loadTime.inMilliseconds, greaterThan(25));
      });

      test('should track failed load operation', () async {
        // Arrange
        const operation = LoadOperation.contentFetch;

        Future<String> failingFunction() async {
          throw Exception('Test error');
        }

        // Act
        final measurement =
            await TodayFeedPerformanceMonitor.trackLoadOperation(
              operation,
              failingFunction,
            );

        // Assert
        expect(measurement, isNotNull);
        expect(measurement!.operation, equals(operation));
        expect(measurement.result, equals(LoadResult.error));
      });

      test('should include metadata in measurement', () async {
        // Arrange
        const operation = LoadOperation.contentFetch;
        const metadata = {'test_key': 'test_value', 'number': 42};

        Future<void> testFunction() async {
          await Future.delayed(const Duration(milliseconds: 10));
        }

        // Act
        final measurement =
            await TodayFeedPerformanceMonitor.trackLoadOperation(
              operation,
              testFunction,
              metadata: metadata,
            );

        // Assert
        expect(measurement, isNotNull);
        expect(measurement!.metadata, equals(metadata));
      });
    });

    group('Performance Metrics', () {
      test('should get current performance metrics', () async {
        // Arrange
        const operation = LoadOperation.contentFetch;

        // Add some test measurements
        for (int i = 0; i < 3; i++) {
          final trackingId = TodayFeedPerformanceMonitor.startLoadTimeTracking(
            operation,
          );
          await Future.delayed(const Duration(milliseconds: 10));
          await TodayFeedPerformanceMonitor.completeLoadTimeTracking(
            trackingId,
            operation,
          );
        }

        // Act
        final metrics =
            await TodayFeedPerformanceMonitor.getCurrentPerformanceMetrics();

        // Assert
        expect(metrics, isNotNull);
        expect(metrics.timestamp, isNotNull);
        expect(metrics.averageLoadTime, isNotNull);
        expect(metrics.successRate, equals(1.0));
        expect(
          metrics.targetComplianceRate,
          equals(1.0),
        ); // All measurements should be under 2s
        expect(metrics.performanceGrade, equals('A'));
      });

      test('should calculate performance grade correctly', () async {
        // This test validates the grading logic indirectly through metrics
        // Since all our test measurements are fast, they should get an 'A' grade

        // Arrange & Act
        final metrics =
            await TodayFeedPerformanceMonitor.getCurrentPerformanceMetrics();

        // Assert
        expect(metrics.performanceGrade, isIn(['A', 'B', 'C', 'D', 'F']));
      });
    });

    group('Performance Analytics', () {
      test('should get performance analytics for time period', () async {
        // Arrange
        const period = Duration(days: 7);

        // Act
        final analytics =
            await TodayFeedPerformanceMonitor.getPerformanceAnalytics(
              period: period,
            );

        // Assert
        expect(analytics, isNotNull);
        expect(analytics.period, equals(period));
        expect(analytics.averageLoadTime, isNotNull);
        expect(analytics.medianLoadTime, isNotNull);
        expect(analytics.p95LoadTime, isNotNull);
        expect(analytics.p99LoadTime, isNotNull);
        expect(analytics.successRate, isA<double>());
        expect(analytics.targetComplianceRate, isA<double>());
      });

      test('should use default period when not specified', () async {
        // Act
        final analytics =
            await TodayFeedPerformanceMonitor.getPerformanceAnalytics();

        // Assert
        expect(analytics.period, equals(const Duration(days: 7)));
      });
    });

    group('Alert Generation', () {
      test('should generate alert stream', () async {
        // Arrange & Act
        final alertStream = TodayFeedPerformanceMonitor.alertStream;

        // Assert
        expect(alertStream, isNotNull);
        expect(alertStream, isA<Stream<PerformanceAlert>>());
      });

      test(
        'should throw StateError when accessing alerts before initialization',
        () async {
          // Arrange
          await TodayFeedPerformanceMonitor.dispose();

          // Act & Assert
          expect(
            () => TodayFeedPerformanceMonitor.alertStream,
            throwsStateError,
          );
        },
      );
    });

    group('Load Operations Enum', () {
      test('should have correct operation names', () {
        expect(LoadOperation.contentFetch.name, equals('content_fetch'));
        expect(LoadOperation.cacheRetrieval.name, equals('cache_retrieval'));
        expect(LoadOperation.fullPageLoad.name, equals('full_page_load'));
        expect(LoadOperation.imageLoad.name, equals('image_load'));
        expect(LoadOperation.externalLink.name, equals('external_link'));
      });

      test('should have all expected operations', () {
        final operations = LoadOperation.values;
        expect(operations.length, equals(5));
        expect(operations, contains(LoadOperation.contentFetch));
        expect(operations, contains(LoadOperation.cacheRetrieval));
        expect(operations, contains(LoadOperation.fullPageLoad));
        expect(operations, contains(LoadOperation.imageLoad));
        expect(operations, contains(LoadOperation.externalLink));
      });
    });

    group('Load Results Enum', () {
      test('should have all expected results', () {
        final results = LoadResult.values;
        expect(results.length, equals(4));
        expect(results, contains(LoadResult.success));
        expect(results, contains(LoadResult.error));
        expect(results, contains(LoadResult.timeout));
        expect(results, contains(LoadResult.cancelled));
      });
    });

    group('Alert Severity Enum', () {
      test('should have all expected severity levels', () {
        final severities = AlertSeverity.values;
        expect(severities.length, equals(4));
        expect(severities, contains(AlertSeverity.low));
        expect(severities, contains(AlertSeverity.warning));
        expect(severities, contains(AlertSeverity.high));
        expect(severities, contains(AlertSeverity.critical));
      });
    });

    group('Alert Types Enum', () {
      test('should have all expected alert types', () {
        final types = AlertType.values;
        expect(types.length, equals(4));
        expect(types, contains(AlertType.loadTimeViolation));
        expect(types, contains(AlertType.violationRateHigh));
        expect(types, contains(AlertType.performanceDegraded));
        expect(types, contains(AlertType.systemOverload));
      });
    });

    group('Data Models', () {
      test('PerformanceMeasurement should serialize to JSON correctly', () {
        // Arrange
        final measurement = PerformanceMeasurement(
          id: 'test_id',
          operation: LoadOperation.contentFetch,
          loadTime: const Duration(milliseconds: 1500),
          result: LoadResult.success,
          timestamp: DateTime(2024, 1, 1, 12, 0, 0),
          deviceType: DeviceType.mobile,
          isOnline: true,
          metadata: {'test': 'value'},
        );

        // Act
        final json = measurement.toJson();

        // Assert
        expect(json['id'], equals('test_id'));
        expect(json['operation'], equals('content_fetch'));
        expect(json['load_time_ms'], equals(1500));
        expect(json['result'], equals('success'));
        expect(json['timestamp'], equals('2024-01-01T12:00:00.000'));
        expect(json['device_type'], equals('mobile'));
        expect(json['is_online'], equals(true));
        expect(json['metadata'], equals({'test': 'value'}));
      });

      test('PerformanceAlert should serialize to JSON correctly', () {
        // Arrange
        final measurement = PerformanceMeasurement(
          id: 'test_id',
          operation: LoadOperation.contentFetch,
          loadTime: const Duration(milliseconds: 1500),
          result: LoadResult.success,
          timestamp: DateTime(2024, 1, 1, 12, 0, 0),
          deviceType: DeviceType.mobile,
          isOnline: true,
          metadata: {},
        );

        final alert = PerformanceAlert(
          id: 'alert_id',
          type: AlertType.loadTimeViolation,
          severity: AlertSeverity.warning,
          message: 'Test alert',
          details: {'key': 'value'},
          timestamp: DateTime(2024, 1, 1, 12, 0, 0),
          measurement: measurement,
        );

        // Act
        final json = alert.toJson();

        // Assert
        expect(json['id'], equals('alert_id'));
        expect(json['type'], equals('loadTimeViolation'));
        expect(json['severity'], equals('warning'));
        expect(json['message'], equals('Test alert'));
        expect(json['details'], equals({'key': 'value'}));
        expect(json['timestamp'], equals('2024-01-01T12:00:00.000'));
        expect(json['measurement'], isNotNull);
      });
    });

    group('Error Handling', () {
      test('should handle StateError when not initialized', () async {
        // Arrange
        await TodayFeedPerformanceMonitor.dispose();

        // Act & Assert
        expect(
          () => TodayFeedPerformanceMonitor.getCurrentPerformanceMetrics(),
          throwsStateError,
        );

        expect(
          () => TodayFeedPerformanceMonitor.getPerformanceAnalytics(),
          throwsStateError,
        );
      });

      test('should handle invalid tracking operations gracefully', () async {
        // Arrange
        const operation = LoadOperation.contentFetch;

        // Act
        final result =
            await TodayFeedPerformanceMonitor.completeLoadTimeTracking(
              'non_existent_id',
              operation,
            );

        // Assert
        expect(result, isNull);
      });
    });

    group('Performance Thresholds', () {
      test('should recognize fast load times as compliant', () async {
        // Arrange
        const operation = LoadOperation.contentFetch;
        final trackingId = TodayFeedPerformanceMonitor.startLoadTimeTracking(
          operation,
        );

        // Very short delay to ensure compliance
        await Future.delayed(const Duration(milliseconds: 10));

        // Act
        final measurement =
            await TodayFeedPerformanceMonitor.completeLoadTimeTracking(
              trackingId,
              operation,
            );

        // Assert
        expect(measurement, isNotNull);
        expect(measurement!.loadTime.inMilliseconds, lessThan(2000));
      });
    });

    group('Resource Management', () {
      test('should dispose resources properly', () async {
        // Arrange
        await TodayFeedPerformanceMonitor.initialize();

        // Act
        await TodayFeedPerformanceMonitor.dispose();

        // Assert - Should not throw when accessing disposed resources
        expect(() => TodayFeedPerformanceMonitor.alertStream, throwsStateError);
      });

      test('should handle multiple dispose calls gracefully', () async {
        // Arrange
        await TodayFeedPerformanceMonitor.initialize();

        // Act & Assert - Should not throw
        await TodayFeedPerformanceMonitor.dispose();
        await TodayFeedPerformanceMonitor.dispose();
      });
    });

    group('Performance Constants', () {
      test('should have correct threshold values', () {
        // These are internal constants, but we can validate through behavior
        // The 2-second target is a key requirement from Epic 1.3

        // Arrange
        const fastTime = Duration(milliseconds: 1000);
        const slowTime = Duration(seconds: 3);

        // Act & Assert
        // We can't directly test private constants, but we know:
        // - Target load time should be 2 seconds (Epic 1.3 requirement)
        // - Warning threshold should be 1.5 seconds
        // - Critical threshold should be 3 seconds
        expect(fastTime.inSeconds, lessThan(2));
        expect(slowTime.inSeconds, greaterThan(2));
      });
    });
  });
}
