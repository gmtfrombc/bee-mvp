/// Wearable Live Metrics Service for T2.2.2.10
///
/// Focused metrics collection for Grafana live-stream dashboard monitoring.
/// Tracks messages per minute, median latency, and error rate.
library;

import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';

/// Metrics data point for time-series analysis
class WearableLiveMetricPoint {
  final DateTime timestamp;
  final int messageCount;
  final double? latencyMs;
  final bool isError;
  final String? errorType;

  const WearableLiveMetricPoint({
    required this.timestamp,
    required this.messageCount,
    this.latencyMs,
    this.isError = false,
    this.errorType,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'message_count': messageCount,
    'latency_ms': latencyMs,
    'is_error': isError,
    'error_type': errorType,
  };
}

/// Aggregated metrics for dashboard display
class WearableLiveMetrics {
  final DateTime timestamp;
  final double messagesPerMinute;
  final double medianLatencyMs;
  final double errorRate;
  final int totalMessages;
  final int totalErrors;

  const WearableLiveMetrics({
    required this.timestamp,
    required this.messagesPerMinute,
    required this.medianLatencyMs,
    required this.errorRate,
    required this.totalMessages,
    required this.totalErrors,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'messages_per_minute': messagesPerMinute,
    'median_latency_ms': medianLatencyMs,
    'error_rate': errorRate,
    'total_messages': totalMessages,
    'total_errors': totalErrors,
  };
}

/// Metrics collection service for wearable live streaming
class WearableLiveMetricsService {
  static final WearableLiveMetricsService _instance =
      WearableLiveMetricsService._internal();
  factory WearableLiveMetricsService() => _instance;
  WearableLiveMetricsService._internal();

  final Queue<WearableLiveMetricPoint> _metricPoints =
      Queue<WearableLiveMetricPoint>();
  final StreamController<WearableLiveMetrics> _metricsController =
      StreamController<WearableLiveMetrics>.broadcast();

  Timer? _aggregationTimer;
  bool _isInitialized = false;

  /// Stream of aggregated metrics for dashboard
  Stream<WearableLiveMetrics> get metricsStream => _metricsController.stream;

  /// Initialize metrics collection
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Start periodic aggregation every 30 seconds
      _aggregationTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _aggregateMetrics(),
      );

      _isInitialized = true;
      debugPrint('✅ WearableLiveMetricsService initialized');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to initialize WearableLiveMetricsService: $e');
      return false;
    }
  }

  /// Record successful message processing
  void recordMessage({required double latencyMs}) {
    if (!_isInitialized) return;

    _metricPoints.add(
      WearableLiveMetricPoint(
        timestamp: DateTime.now(),
        messageCount: 1,
        latencyMs: latencyMs,
      ),
    );

    _cleanOldMetrics();
  }

  /// Record error event
  void recordError({required String errorType}) {
    if (!_isInitialized) return;

    _metricPoints.add(
      WearableLiveMetricPoint(
        timestamp: DateTime.now(),
        messageCount: 0,
        isError: true,
        errorType: errorType,
      ),
    );

    _cleanOldMetrics();
  }

  /// Record message batch processing
  void recordMessageBatch({
    required int messageCount,
    required double averageLatencyMs,
  }) {
    if (!_isInitialized) return;

    _metricPoints.add(
      WearableLiveMetricPoint(
        timestamp: DateTime.now(),
        messageCount: messageCount,
        latencyMs: averageLatencyMs,
      ),
    );

    _cleanOldMetrics();
  }

  /// Get current metrics for external monitoring
  WearableLiveMetrics getCurrentMetrics() {
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(const Duration(minutes: 1));

    final recentPoints =
        _metricPoints
            .where((point) => point.timestamp.isAfter(oneMinuteAgo))
            .toList();

    final messagesPerMinute =
        recentPoints
            .map((p) => p.messageCount)
            .fold(0, (sum, count) => sum + count)
            .toDouble();

    final latencies =
        recentPoints
            .where((p) => p.latencyMs != null && !p.isError)
            .map((p) => p.latencyMs!)
            .toList();

    final medianLatency = _calculateMedian(latencies);

    final errorCount = recentPoints.where((p) => p.isError).length;
    final totalEvents = recentPoints.length;
    final errorRate = totalEvents > 0 ? errorCount / totalEvents : 0.0;

    return WearableLiveMetrics(
      timestamp: now,
      messagesPerMinute: messagesPerMinute,
      medianLatencyMs: medianLatency,
      errorRate: errorRate,
      totalMessages: messagesPerMinute.toInt(),
      totalErrors: errorCount,
    );
  }

  /// Aggregate and emit metrics
  void _aggregateMetrics() {
    try {
      final metrics = getCurrentMetrics();
      _metricsController.add(metrics);
    } catch (e) {
      debugPrint('❌ Error aggregating metrics: $e');
    }
  }

  /// Calculate median from list of values
  double _calculateMedian(List<double> values) {
    if (values.isEmpty) return 0.0;

    final sorted = List<double>.from(values)..sort();
    final middle = sorted.length ~/ 2;

    if (sorted.length % 2 == 0) {
      return (sorted[middle - 1] + sorted[middle]) / 2.0;
    }
    return sorted[middle];
  }

  /// Remove metrics older than 5 minutes
  void _cleanOldMetrics() {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 5));
    _metricPoints.removeWhere((point) => point.timestamp.isBefore(cutoff));
  }

  /// Dispose resources
  void dispose() {
    _aggregationTimer?.cancel();
    _metricsController.close();
    _metricPoints.clear();
    _isInitialized = false;
  }

  /// Export metrics for Grafana/Prometheus
  Map<String, dynamic> exportForGrafana() {
    final metrics = getCurrentMetrics();
    return {
      'wearable_live_messages_per_minute': metrics.messagesPerMinute,
      'wearable_live_median_latency_ms': metrics.medianLatencyMs,
      'wearable_live_error_rate': metrics.errorRate,
      'wearable_live_total_messages': metrics.totalMessages,
      'wearable_live_total_errors': metrics.totalErrors,
    };
  }
}
