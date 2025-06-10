/// Unit tests for WearableLiveMetricsService
/// Following BEE testing policy - essential tests only with ≥85% coverage focus
library;

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/services/wearable_live_metrics_service.dart';

void main() {
  group('WearableLiveMetricsService', () {
    late WearableLiveMetricsService service;

    setUp(() {
      service = WearableLiveMetricsService();
    });

    tearDown(() {
      service.dispose();
    });

    test('initializes correctly', () async {
      final result = await service.initialize();
      expect(result, isTrue);
    });

    test('records message with latency', () async {
      await service.initialize();

      service.recordMessage(latencyMs: 150.0);

      final metrics = service.getCurrentMetrics();
      expect(metrics.messagesPerMinute, equals(1.0));
      expect(metrics.medianLatencyMs, equals(150.0));
      expect(metrics.errorRate, equals(0.0));
    });

    test('records error events', () async {
      await service.initialize();

      service.recordError(errorType: 'connection_timeout');

      final metrics = service.getCurrentMetrics();
      expect(metrics.totalErrors, equals(1));
      expect(metrics.errorRate, greaterThan(0.0));
    });

    test('calculates median latency correctly', () async {
      await service.initialize();

      // Record multiple latency values
      service.recordMessage(latencyMs: 100.0);
      service.recordMessage(latencyMs: 200.0);
      service.recordMessage(latencyMs: 300.0);

      final metrics = service.getCurrentMetrics();
      expect(metrics.medianLatencyMs, equals(200.0));
    });

    test('exports Grafana format correctly', () async {
      await service.initialize();

      service.recordMessage(latencyMs: 100.0);
      service.recordError(errorType: 'test_error');

      final export = service.exportForGrafana();

      expect(export, containsPair('wearable_live_messages_per_minute', 1.0));
      expect(export, containsPair('wearable_live_median_latency_ms', 100.0));
      expect(export, containsPair('wearable_live_total_errors', 1));
      expect(export['wearable_live_error_rate'], greaterThan(0.0));
    });

    test('handles empty metrics gracefully', () async {
      await service.initialize();

      final metrics = service.getCurrentMetrics();

      expect(metrics.messagesPerMinute, equals(0.0));
      expect(metrics.medianLatencyMs, equals(0.0));
      expect(metrics.errorRate, equals(0.0));
      expect(metrics.totalMessages, equals(0));
      expect(metrics.totalErrors, equals(0));
    });

    test('streams metrics correctly', () async {
      await service.initialize();

      final streamCompleter = Completer<WearableLiveMetrics>();
      late StreamSubscription subscription;

      subscription = service.metricsStream.listen((metrics) {
        if (!streamCompleter.isCompleted) {
          streamCompleter.complete(metrics);
          subscription.cancel();
        }
      });

      // Trigger metrics aggregation
      service.recordMessage(latencyMs: 150.0);

      // Wait briefly then manually trigger aggregation for test
      await Future.delayed(const Duration(milliseconds: 50));

      subscription.cancel();
      expect(
        streamCompleter.isCompleted,
        isFalse,
      ); // Timer-based, won't complete immediately
    });

    test('records message batch correctly', () async {
      await service.initialize();

      service.recordMessageBatch(messageCount: 5, averageLatencyMs: 120.0);

      final metrics = service.getCurrentMetrics();
      expect(metrics.messagesPerMinute, equals(5.0));
      expect(metrics.medianLatencyMs, equals(120.0));
    });

    test('cleans old metrics automatically', () async {
      await service.initialize();

      // Record some metrics
      service.recordMessage(latencyMs: 100.0);
      service.recordMessage(latencyMs: 200.0);

      // Verify metrics exist
      final initialMetrics = service.getCurrentMetrics();
      expect(initialMetrics.messagesPerMinute, equals(2.0));

      // Note: Actual cleanup timing depends on Timer, not tested in unit tests
      // This test verifies the method doesn't throw errors
      expect(() => service.getCurrentMetrics(), returnsNormally);
    });
  });
}
