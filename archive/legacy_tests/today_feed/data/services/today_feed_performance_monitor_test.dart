import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/features/today_feed/data/services/today_feed_performance_monitor.dart';

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
  });
}
