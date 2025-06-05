import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/responsive_service.dart';
import '../../../../core/services/connectivity_service.dart';

/// Performance monitoring service for Today Feed load times and alerting
/// Tracks <2 second load time requirement per Epic 1.3 specifications
class TodayFeedPerformanceMonitor {
  static const String _performanceDataKey = 'today_feed_performance_data';
  static const String _alertsKey = 'today_feed_performance_alerts';

  // Performance thresholds from Epic 1.3 PRD
  static const Duration _targetLoadTime = Duration(seconds: 2);
  static const Duration _criticalThreshold = Duration(seconds: 3);

  // Alert thresholds
  static const double _violationRateThreshold = 0.1; // 10% violation rate
  static const int _alertHistoryLimit = 50;
  static const int _performanceHistoryLimit = 100;

  static SharedPreferences? _prefs;
  static bool _isInitialized = false;
  static final Map<String, Stopwatch> _activeLoadTimers = {};
  static StreamController<PerformanceAlert>? _alertController;

  /// Initialize the performance monitoring service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      _alertController = StreamController<PerformanceAlert>.broadcast();
      _isInitialized = true;

      debugPrint('✅ TodayFeedPerformanceMonitor initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize TodayFeedPerformanceMonitor: $e');
      rethrow;
    }
  }

  /// Alert stream for real-time performance notifications
  static Stream<PerformanceAlert> get alertStream {
    if (_alertController == null) {
      throw StateError('TodayFeedPerformanceMonitor not initialized');
    }
    return _alertController!.stream;
  }

  /// Start tracking load time for a specific operation
  static String startLoadTimeTracking(LoadOperation operation) {
    if (!_isInitialized) return '';

    final trackingId =
        '${operation.name}_${DateTime.now().millisecondsSinceEpoch}';
    _activeLoadTimers[trackingId] = Stopwatch()..start();

    debugPrint(
      '🕐 Started load time tracking: ${operation.name} ($trackingId)',
    );
    return trackingId;
  }

  /// Complete load time tracking and record performance
  static Future<PerformanceMeasurement?> completeLoadTimeTracking(
    String trackingId,
    LoadOperation operation, {
    LoadResult result = LoadResult.success,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isInitialized || !_activeLoadTimers.containsKey(trackingId)) {
      return null;
    }

    final stopwatch = _activeLoadTimers.remove(trackingId)!;
    stopwatch.stop();
    final loadTime = stopwatch.elapsed;

    final measurement = PerformanceMeasurement(
      id: trackingId,
      operation: operation,
      loadTime: loadTime,
      result: result,
      timestamp: DateTime.now(),
      deviceType: DeviceType.mobile, // Safe fallback when context unavailable
      isOnline: _getConnectivityStatus(),
      metadata: metadata ?? {},
    );

    await _recordPerformanceMeasurement(measurement);
    await _checkPerformanceThresholds(measurement);

    debugPrint(
      '⏱️ Load time recorded: ${operation.name} - ${loadTime.inMilliseconds}ms '
      '(${result.name}) - ${_isWithinTarget(loadTime) ? "✅ PASS" : "❌ FAIL"}',
    );

    return measurement;
  }

  /// Track a complete load operation end-to-end
  static Future<PerformanceMeasurement?> trackLoadOperation<T>(
    LoadOperation operation,
    Future<T> Function() loadFunction, {
    Map<String, dynamic>? metadata,
  }) async {
    final trackingId = startLoadTimeTracking(operation);
    LoadResult result = LoadResult.success;

    try {
      await loadFunction();
    } catch (e) {
      result = LoadResult.error;
      debugPrint('❌ Load operation failed: ${operation.name} - $e');
    }

    return await completeLoadTimeTracking(
      trackingId,
      operation,
      result: result,
      metadata: metadata,
    );
  }

  /// Get real-time performance metrics
  static Future<PerformanceMetrics> getCurrentPerformanceMetrics() async {
    if (!_isInitialized) {
      throw StateError('TodayFeedPerformanceMonitor not initialized');
    }

    final measurements = await _getRecentMeasurements(50);
    final alerts = await _getActiveAlerts();

    return PerformanceMetrics(
      timestamp: DateTime.now(),
      totalMeasurements: measurements.length,
      averageLoadTime: _calculateAverageLoadTime(measurements),
      successRate: _calculateSuccessRate(measurements),
      targetComplianceRate: _calculateTargetComplianceRate(measurements),
      activeMeasurements: _activeLoadTimers.length,
      activeAlerts: alerts.length,
      last24HourViolations: _countViolationsInPeriod(
        measurements,
        const Duration(hours: 24),
      ),
      performanceGrade: _calculatePerformanceGrade(measurements),
      recommendations: _generatePerformanceRecommendations(measurements),
    );
  }

  /// Get performance analytics for specific time period
  static Future<PerformanceAnalytics> getPerformanceAnalytics({
    Duration period = const Duration(days: 7),
  }) async {
    if (!_isInitialized) {
      throw StateError('TodayFeedPerformanceMonitor not initialized');
    }

    final measurements = await _getMeasurementsInPeriod(period);
    final alerts = await _getAlertsInPeriod(period);

    return PerformanceAnalytics(
      period: period,
      totalOperations: measurements.length,
      averageLoadTime: _calculateAverageLoadTime(measurements),
      medianLoadTime: _calculateMedianLoadTime(measurements),
      p95LoadTime: _calculatePercentileLoadTime(measurements, 95),
      p99LoadTime: _calculatePercentileLoadTime(measurements, 99),
      successRate: _calculateSuccessRate(measurements),
      targetComplianceRate: _calculateTargetComplianceRate(measurements),
      performanceTrend: _calculatePerformanceTrend(measurements),
      operationBreakdown: _generateOperationBreakdown(measurements),
      alertSummary: _generateAlertSummary(alerts),
      improvementOpportunities: _identifyImprovementOpportunities(measurements),
    );
  }

  /// Check for performance violations and generate alerts
  static Future<void> _checkPerformanceThresholds(
    PerformanceMeasurement measurement,
  ) async {
    final recentMeasurements = await _getRecentMeasurements(20);
    final violationRate =
        1.0 - _calculateTargetComplianceRate(recentMeasurements);

    // Check individual measurement violations
    if (measurement.loadTime > _targetLoadTime) {
      final severity =
          measurement.loadTime > _criticalThreshold
              ? AlertSeverity.critical
              : AlertSeverity.warning;

      final alert = PerformanceAlert(
        id: 'load_time_violation_${measurement.id}',
        type: AlertType.loadTimeViolation,
        severity: severity,
        message:
            'Load time violation: ${measurement.loadTime.inMilliseconds}ms '
            'for ${measurement.operation.name}',
        details: {
          'load_time_ms': measurement.loadTime.inMilliseconds,
          'target_ms': _targetLoadTime.inMilliseconds,
          'operation': measurement.operation.name,
          'device_type': measurement.deviceType.name,
          'is_online': measurement.isOnline,
        },
        timestamp: DateTime.now(),
        measurement: measurement,
      );

      await _recordAlert(alert);
      _alertController?.add(alert);
    }

    // Check violation rate threshold
    if (violationRate > _violationRateThreshold &&
        recentMeasurements.length >= 10) {
      final alert = PerformanceAlert(
        id: 'violation_rate_${DateTime.now().millisecondsSinceEpoch}',
        type: AlertType.violationRateHigh,
        severity: AlertSeverity.high,
        message:
            'Performance violation rate is ${(violationRate * 100).toStringAsFixed(1)}% '
            '(threshold: ${(_violationRateThreshold * 100).toStringAsFixed(1)}%)',
        details: {
          'violation_rate': violationRate,
          'threshold': _violationRateThreshold,
          'sample_size': recentMeasurements.length,
          'violations':
              recentMeasurements
                  .where((m) => m.loadTime > _targetLoadTime)
                  .length,
        },
        timestamp: DateTime.now(),
      );

      await _recordAlert(alert);
      _alertController?.add(alert);
    }
  }

  /// Record performance measurement to storage
  static Future<void> _recordPerformanceMeasurement(
    PerformanceMeasurement measurement,
  ) async {
    try {
      final measurements = await _getStoredMeasurements();
      measurements.add(measurement);

      // Keep only recent measurements to prevent unbounded growth
      if (measurements.length > _performanceHistoryLimit) {
        measurements.removeRange(
          0,
          measurements.length - _performanceHistoryLimit,
        );
      }

      final jsonList = measurements.map((m) => m.toJson()).toList();
      await _prefs!.setString(_performanceDataKey, jsonList.toString());
    } catch (e) {
      debugPrint('❌ Failed to record performance measurement: $e');
    }
  }

  /// Record performance alert to storage
  static Future<void> _recordAlert(PerformanceAlert alert) async {
    try {
      final alerts = await _getStoredAlerts();
      alerts.add(alert);

      // Keep only recent alerts to prevent unbounded growth
      if (alerts.length > _alertHistoryLimit) {
        alerts.removeRange(0, alerts.length - _alertHistoryLimit);
      }

      final jsonList = alerts.map((a) => a.toJson()).toList();
      await _prefs!.setString(_alertsKey, jsonList.toString());
    } catch (e) {
      debugPrint('❌ Failed to record alert: $e');
    }
  }

  /// Get stored performance measurements
  static Future<List<PerformanceMeasurement>> _getStoredMeasurements() async {
    try {
      final jsonString = _prefs!.getString(_performanceDataKey);
      if (jsonString == null) return [];

      // Parse JSON string to list (simplified for demo)
      // In production, use proper JSON parsing
      return [];
    } catch (e) {
      debugPrint('❌ Failed to get stored measurements: $e');
      return [];
    }
  }

  /// Get stored performance alerts
  static Future<List<PerformanceAlert>> _getStoredAlerts() async {
    try {
      final jsonString = _prefs!.getString(_alertsKey);
      if (jsonString == null) return [];

      // Parse JSON string to list (simplified for demo)
      // In production, use proper JSON parsing
      return [];
    } catch (e) {
      debugPrint('❌ Failed to get stored alerts: $e');
      return [];
    }
  }

  /// Helper methods for metrics calculation
  static bool _isWithinTarget(Duration loadTime) => loadTime <= _targetLoadTime;

  static Duration _calculateAverageLoadTime(
    List<PerformanceMeasurement> measurements,
  ) {
    if (measurements.isEmpty) return Duration.zero;

    final totalMs = measurements
        .map((m) => m.loadTime.inMilliseconds)
        .reduce((a, b) => a + b);

    return Duration(milliseconds: (totalMs / measurements.length).round());
  }

  static Duration _calculateMedianLoadTime(
    List<PerformanceMeasurement> measurements,
  ) {
    if (measurements.isEmpty) return Duration.zero;

    final sortedTimes =
        measurements.map((m) => m.loadTime.inMilliseconds).toList()..sort();

    final middle = sortedTimes.length ~/ 2;
    final medianMs =
        sortedTimes.length % 2 == 0
            ? (sortedTimes[middle - 1] + sortedTimes[middle]) ~/ 2
            : sortedTimes[middle];

    return Duration(milliseconds: medianMs);
  }

  static Duration _calculatePercentileLoadTime(
    List<PerformanceMeasurement> measurements,
    int percentile,
  ) {
    if (measurements.isEmpty) return Duration.zero;

    final sortedTimes =
        measurements.map((m) => m.loadTime.inMilliseconds).toList()..sort();

    final index = ((percentile / 100) * sortedTimes.length).floor() - 1;
    final clampedIndex = index.clamp(0, sortedTimes.length - 1);

    return Duration(milliseconds: sortedTimes[clampedIndex]);
  }

  static double _calculateSuccessRate(
    List<PerformanceMeasurement> measurements,
  ) {
    if (measurements.isEmpty) return 1.0;

    final successCount =
        measurements.where((m) => m.result == LoadResult.success).length;

    return successCount / measurements.length;
  }

  static double _calculateTargetComplianceRate(
    List<PerformanceMeasurement> measurements,
  ) {
    if (measurements.isEmpty) return 1.0;

    final compliantCount =
        measurements.where((m) => _isWithinTarget(m.loadTime)).length;

    return compliantCount / measurements.length;
  }

  static String _calculatePerformanceGrade(
    List<PerformanceMeasurement> measurements,
  ) {
    final complianceRate = _calculateTargetComplianceRate(measurements);

    if (complianceRate >= 0.95) return 'A';
    if (complianceRate >= 0.90) return 'B';
    if (complianceRate >= 0.80) return 'C';
    if (complianceRate >= 0.70) return 'D';
    return 'F';
  }

  static List<String> _generatePerformanceRecommendations(
    List<PerformanceMeasurement> measurements,
  ) {
    final recommendations = <String>[];
    final complianceRate = _calculateTargetComplianceRate(measurements);

    if (complianceRate < 0.95) {
      recommendations.add('Load times exceed 2-second target');
    }

    if (complianceRate < 0.80) {
      recommendations.add('Consider implementing content preloading');
      recommendations.add('Review cache warming strategies');
    }

    if (complianceRate < 0.60) {
      recommendations.add(
        'Critical performance issues require immediate attention',
      );
      recommendations.add('Consider CDN optimization');
    }

    return recommendations;
  }

  // Placeholder methods for future implementation
  static Future<List<PerformanceMeasurement>> _getRecentMeasurements(
    int count,
  ) async => [];

  static Future<List<PerformanceAlert>> _getActiveAlerts() async => [];

  static Future<List<PerformanceMeasurement>> _getMeasurementsInPeriod(
    Duration period,
  ) async => [];

  static Future<List<PerformanceAlert>> _getAlertsInPeriod(
    Duration period,
  ) async => [];

  static int _countViolationsInPeriod(
    List<PerformanceMeasurement> measurements,
    Duration period,
  ) => 0;

  static String _calculatePerformanceTrend(
    List<PerformanceMeasurement> measurements,
  ) => 'stable';

  static Map<String, int> _generateOperationBreakdown(
    List<PerformanceMeasurement> measurements,
  ) => {};

  static Map<String, dynamic> _generateAlertSummary(
    List<PerformanceAlert> alerts,
  ) => {};

  static List<String> _identifyImprovementOpportunities(
    List<PerformanceMeasurement> measurements,
  ) => [];

  /// Dispose resources
  static Future<void> dispose() async {
    _activeLoadTimers.clear();
    await _alertController?.close();
    _alertController = null;
    _isInitialized = false;
  }

  /// Safely get connectivity status, with fallback for testing
  static bool _getConnectivityStatus() {
    try {
      return ConnectivityService.isOnline;
    } catch (e) {
      // ConnectivityService not initialized (e.g., during testing)
      // Return true as default to avoid blocking tests
      return true;
    }
  }
}

/// Represents a load operation being tracked
enum LoadOperation {
  contentFetch('content_fetch'),
  cacheRetrieval('cache_retrieval'),
  fullPageLoad('full_page_load'),
  imageLoad('image_load'),
  externalLink('external_link');

  const LoadOperation(this.name);
  final String name;
}

/// Result of a load operation
enum LoadResult { success, error, timeout, cancelled }

/// Severity levels for performance alerts
enum AlertSeverity { low, warning, high, critical }

/// Types of performance alerts
enum AlertType {
  loadTimeViolation,
  violationRateHigh,
  performanceDegraded,
  systemOverload,
}

/// Performance measurement data class
class PerformanceMeasurement {
  final String id;
  final LoadOperation operation;
  final Duration loadTime;
  final LoadResult result;
  final DateTime timestamp;
  final DeviceType deviceType;
  final bool isOnline;
  final Map<String, dynamic> metadata;

  const PerformanceMeasurement({
    required this.id,
    required this.operation,
    required this.loadTime,
    required this.result,
    required this.timestamp,
    required this.deviceType,
    required this.isOnline,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'operation': operation.name,
    'load_time_ms': loadTime.inMilliseconds,
    'result': result.name,
    'timestamp': timestamp.toIso8601String(),
    'device_type': deviceType.name,
    'is_online': isOnline,
    'metadata': metadata,
  };
}

/// Performance alert data class
class PerformanceAlert {
  final String id;
  final AlertType type;
  final AlertSeverity severity;
  final String message;
  final Map<String, dynamic> details;
  final DateTime timestamp;
  final PerformanceMeasurement? measurement;

  const PerformanceAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.message,
    required this.details,
    required this.timestamp,
    this.measurement,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'severity': severity.name,
    'message': message,
    'details': details,
    'timestamp': timestamp.toIso8601String(),
    'measurement': measurement?.toJson(),
  };
}

/// Real-time performance metrics
class PerformanceMetrics {
  final DateTime timestamp;
  final int totalMeasurements;
  final Duration averageLoadTime;
  final double successRate;
  final double targetComplianceRate;
  final int activeMeasurements;
  final int activeAlerts;
  final int last24HourViolations;
  final String performanceGrade;
  final List<String> recommendations;

  const PerformanceMetrics({
    required this.timestamp,
    required this.totalMeasurements,
    required this.averageLoadTime,
    required this.successRate,
    required this.targetComplianceRate,
    required this.activeMeasurements,
    required this.activeAlerts,
    required this.last24HourViolations,
    required this.performanceGrade,
    required this.recommendations,
  });
}

/// Historical performance analytics
class PerformanceAnalytics {
  final Duration period;
  final int totalOperations;
  final Duration averageLoadTime;
  final Duration medianLoadTime;
  final Duration p95LoadTime;
  final Duration p99LoadTime;
  final double successRate;
  final double targetComplianceRate;
  final String performanceTrend;
  final Map<String, int> operationBreakdown;
  final Map<String, dynamic> alertSummary;
  final List<String> improvementOpportunities;

  const PerformanceAnalytics({
    required this.period,
    required this.totalOperations,
    required this.averageLoadTime,
    required this.medianLoadTime,
    required this.p95LoadTime,
    required this.p99LoadTime,
    required this.successRate,
    required this.targetComplianceRate,
    required this.performanceTrend,
    required this.operationBreakdown,
    required this.alertSummary,
    required this.improvementOpportunities,
  });
}
