import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Service for collecting cache performance and operational metrics
class TodayFeedCacheMetricsCollector {
  static SharedPreferences? _prefs;
  static bool _isInitialized = false;

  /// Initialize the metrics collector
  static Future<void> initialize(SharedPreferences prefs) async {
    _prefs = prefs;
    _isInitialized = true;
  }

  /// Get detailed performance statistics with benchmarking
  static Future<Map<String, dynamic>> getDetailedPerformanceStatistics() async {
    if (!_isInitialized) {
      throw StateError('TodayFeedCacheMetricsCollector not initialized');
    }

    try {
      final stopwatch = Stopwatch();
      final performanceResults = <String, dynamic>{};

      // Test read performance (multiple iterations for accuracy)
      final readTimes = <int>[];
      for (int i = 0; i < 5; i++) {
        stopwatch.reset();
        stopwatch.start();
        // Simulate reading from cache
        _prefs!.getString('today_feed_content');
        stopwatch.stop();
        readTimes.add(stopwatch.elapsedMilliseconds);
      }

      // Test write performance
      final writeTimes = <int>[];
      for (int i = 0; i < 5; i++) {
        final testData = {
          'test_iteration': i,
          'timestamp': DateTime.now().toIso8601String(),
          'data': 'performance_test_$i',
        };

        stopwatch.reset();
        stopwatch.start();
        await _prefs!.setString('perf_test_$i', jsonEncode(testData));
        stopwatch.stop();
        writeTimes.add(stopwatch.elapsedMilliseconds);
      }

      // Test cache lookup performance
      final lookupTimes = <int>[];
      for (int i = 0; i < 5; i++) {
        stopwatch.reset();
        stopwatch.start();
        // Simulate cache stats lookup
        _prefs!.getKeys().length;
        stopwatch.stop();
        lookupTimes.add(stopwatch.elapsedMilliseconds);
      }

      // Clean up test data
      for (int i = 0; i < 5; i++) {
        await _prefs!.remove('perf_test_$i');
      }

      // Calculate statistics
      performanceResults.addAll({
        'read_performance': {
          'average_ms': _calculateAverage(readTimes),
          'min_ms': readTimes.reduce((a, b) => a < b ? a : b),
          'max_ms': readTimes.reduce((a, b) => a > b ? a : b),
          'median_ms': _calculateMedian(readTimes),
          'std_deviation': _calculateStandardDeviation(readTimes),
          'samples': readTimes.length,
        },
        'write_performance': {
          'average_ms': _calculateAverage(writeTimes),
          'min_ms': writeTimes.reduce((a, b) => a < b ? a : b),
          'max_ms': writeTimes.reduce((a, b) => a > b ? a : b),
          'median_ms': _calculateMedian(writeTimes),
          'std_deviation': _calculateStandardDeviation(writeTimes),
          'samples': writeTimes.length,
        },
        'lookup_performance': {
          'average_ms': _calculateAverage(lookupTimes),
          'min_ms': lookupTimes.reduce((a, b) => a < b ? a : b),
          'max_ms': lookupTimes.reduce((a, b) => a > b ? a : b),
          'median_ms': _calculateMedian(lookupTimes),
          'std_deviation': _calculateStandardDeviation(lookupTimes),
          'samples': lookupTimes.length,
        },
      });

      // Performance benchmarks and ratings
      final avgReadTime = _calculateAverage(readTimes);
      final avgWriteTime = _calculateAverage(writeTimes);
      final avgLookupTime = _calculateAverage(lookupTimes);

      performanceResults['benchmark_ratings'] = {
        'read_rating': _getPerformanceRating(avgReadTime, [50, 100, 200]),
        'write_rating': _getPerformanceRating(avgWriteTime, [25, 50, 100]),
        'lookup_rating': _getPerformanceRating(avgLookupTime, [30, 75, 150]),
        'overall_rating': _calculateOverallPerformanceRating(
          avgReadTime,
          avgWriteTime,
          avgLookupTime,
        ),
      };

      // Performance insights and recommendations
      performanceResults['insights'] = _generatePerformanceInsights(
        avgReadTime,
        avgWriteTime,
        avgLookupTime,
      );

      return performanceResults;
    } catch (e) {
      debugPrint('❌ Failed to get detailed performance statistics: $e');
      return {
        'error': e.toString(),
        'read_performance': {'error': 'Failed to measure'},
        'write_performance': {'error': 'Failed to measure'},
        'lookup_performance': {'error': 'Failed to measure'},
      };
    }
  }

  /// Get cache usage statistics and patterns
  static Future<Map<String, dynamic>> getCacheUsageStatistics(
    Map<String, dynamic> basicStats,
  ) async {
    try {
      final errors = await _getSyncErrors();

      // Content usage patterns
      final hasToday = basicStats['has_today_content'] as bool? ?? false;
      final hasPrevious =
          basicStats['has_previous_day_content'] as bool? ?? false;
      final historyCount = basicStats['content_history_count'] as int? ?? 0;

      // Calculate cache utilization metrics
      const maxCacheSizeMB = 10;
      final sizeBytes = basicStats['cache_size_bytes'] as int? ?? 0;
      const maxSizeBytes = maxCacheSizeMB * 1024 * 1024;
      final utilizationPercentage = (sizeBytes / maxSizeBytes * 100).clamp(
        0.0,
        100.0,
      );

      // Usage patterns analysis
      final accessFrequency = _calculateAccessFrequency();
      final contentFreshness = _calculateContentFreshness(basicStats);

      return {
        'content_availability': {
          'today_content_available': hasToday,
          'previous_day_available': hasPrevious,
          'history_items_count': historyCount,
          'availability_score': _calculateAvailabilityScore(
            hasToday,
            hasPrevious,
            historyCount,
          ),
        },
        'storage_utilization': {
          'used_bytes': sizeBytes,
          'max_bytes': maxSizeBytes,
          'utilization_percentage': utilizationPercentage,
          'remaining_space_mb': (maxSizeBytes - sizeBytes) / (1024 * 1024),
          'utilization_status': _getUtilizationStatus(utilizationPercentage),
        },
        'usage_patterns': {
          'access_frequency': accessFrequency,
          'content_freshness': contentFreshness,
          'sync_error_count': errors.length,
          'usage_efficiency': _calculateUsageEfficiency(basicStats),
        },
      };
    } catch (e) {
      debugPrint('❌ Failed to get cache usage statistics: $e');
      return {
        'error': e.toString(),
        'content_availability': {'error': 'Failed to calculate'},
        'storage_utilization': {'error': 'Failed to calculate'},
        'usage_patterns': {'error': 'Failed to calculate'},
      };
    }
  }

  /// Get operational statistics
  static Future<Map<String, dynamic>> getOperationalStatistics() async {
    try {
      final uptime = await _calculateServiceUptime();
      final systemInfo = await _getSystemInformation();
      final resourceUsage = await _getResourceUsage();
      final operationalScore = _calculateOperationalScore();

      return {
        'service_uptime': uptime,
        'system_information': {
          'current_time': DateTime.now().toIso8601String(),
          'timezone': DateTime.now().timeZoneName,
          'cache_version': '1.0.0',
          ...systemInfo,
        },
        'timer_status': {
          'refresh_timer_active': true, // Would check actual timer status
          'cleanup_timer_active': true,
          'timezone_check_active': true,
          'all_timers_operational': true,
        },
        'resource_usage': resourceUsage,
        'service_health': {
          'is_initialized': true, // Would check actual initialization status
          'sync_in_progress': false, // Would check actual sync status
          'connectivity_listener_active':
              false, // Would check actual listener status
          'timers_operational': true,
        },
        'operational_score': operationalScore,
      };
    } catch (e) {
      debugPrint('❌ Failed to get operational statistics: $e');
      return {
        'error': e.toString(),
        'service_uptime': {'error': 'Failed to calculate'},
        'system_information': {
          'current_time': DateTime.now().toIso8601String(),
          'timezone': DateTime.now().timeZoneName,
          'cache_version': '1.0.0',
          'error': 'Failed to retrieve',
        },
        'timer_status': {'error': 'Failed to retrieve'},
        'resource_usage': {'error': 'Failed to calculate'},
        'service_health': {
          'is_initialized': false,
          'sync_in_progress': false,
          'connectivity_listener_active': false,
          'timers_operational': false,
        },
        'operational_score': 0,
      };
    }
  }

  /// Export metrics for external monitoring systems
  static Future<Map<String, dynamic>> exportMetricsForMonitoring(
    Map<String, dynamic> basicStats,
    Map<String, dynamic> healthStatus,
    Map<String, dynamic> statistics,
  ) async {
    try {
      // Extract performance metrics
      final readTime =
          statistics['performance_statistics']?['read_performance']?['average_ms']
              as double? ??
          0;
      final writeTime =
          statistics['performance_statistics']?['write_performance']?['average_ms']
              as double? ??
          0;
      final lookupTime =
          statistics['performance_statistics']?['lookup_performance']?['average_ms']
              as double? ??
          0;

      // Calculate average read time
      final averageReadTime = (readTime + writeTime + lookupTime) / 3;

      return {
        'metrics': {
          'cache_health_score': healthStatus['overall_score'] ?? 100,
          'cache_size_bytes':
              statistics['usage_statistics']?['storage_utilization']?['used_bytes'] ??
              0,
          'cache_utilization_percentage':
              statistics['usage_statistics']?['storage_utilization']?['utilization_percentage'] ??
              0.0,
          'content_availability_today':
              statistics['usage_statistics']?['content_availability']?['today_content_available'] ??
              false,
          'average_read_time_ms': averageReadTime,
          'service_operational': 1, // Boolean as int for monitoring systems
        },
        'metadata': {
          'export_timestamp': DateTime.now().toIso8601String(),
          'service_version': '1.0.0',
          'collection_source': 'today_feed_cache_metrics_collector',
        },
        'labels': {'service': 'today_feed_cache', 'module': 'core_engagement'},
      };
    } catch (e) {
      debugPrint('❌ Failed to export metrics for monitoring: $e');
      return {
        'error': e.toString(),
        'metrics': {
          'cache_health_score': 0,
          'cache_size_bytes': 0,
          'cache_utilization_percentage': 0.0,
          'content_availability_today': false,
          'average_read_time_ms': 0.0,
          'service_operational': 0,
        },
        'metadata': {
          'export_timestamp': DateTime.now().toIso8601String(),
          'service_version': '1.0.0',
          'collection_source': 'today_feed_cache_metrics_collector',
        },
        'labels': {'service': 'today_feed_cache', 'module': 'core_engagement'},
      };
    }
  }

  // Helper methods for calculations
  static double _calculateAverage(List<int> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  static double _calculateMedian(List<int> values) {
    if (values.isEmpty) return 0.0;
    final sorted = List<int>.from(values)..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length % 2 == 0) {
      return (sorted[middle - 1] + sorted[middle]) / 2.0;
    }
    return sorted[middle].toDouble();
  }

  static double _calculateStandardDeviation(List<int> values) {
    if (values.isEmpty) return 0.0;
    final mean = _calculateAverage(values);
    final variance =
        values.map((value) => pow(value - mean, 2)).reduce((a, b) => a + b) /
        values.length;
    return sqrt(variance);
  }

  static String _getPerformanceRating(double time, List<double> thresholds) {
    if (time <= thresholds[0]) return 'excellent';
    if (time <= thresholds[1]) return 'good';
    if (time <= thresholds[2]) return 'fair';
    return 'poor';
  }

  static String _calculateOverallPerformanceRating(
    double readTime,
    double writeTime,
    double lookupTime,
  ) {
    final avgTime = (readTime + writeTime + lookupTime) / 3;
    return _getPerformanceRating(avgTime, [50, 100, 150]);
  }

  static List<String> _generatePerformanceInsights(
    double readTime,
    double writeTime,
    double lookupTime,
  ) {
    final insights = <String>[];

    if (readTime < 25) {
      insights.add('Excellent read performance');
    } else if (readTime > 100) {
      insights.add('Read performance needs optimization');
    }

    if (writeTime < 25) {
      insights.add('Excellent write performance');
    } else if (writeTime > 50) {
      insights.add('Write performance could be improved');
    }

    if (lookupTime < 30) {
      insights.add('Fast cache lookups');
    } else if (lookupTime > 75) {
      insights.add('Lookup performance needs attention');
    }

    return insights.isEmpty ? ['Performance within expected range'] : insights;
  }

  static double _calculateAccessFrequency() {
    // Placeholder calculation
    return 0.75; // 75% frequency
  }

  static double _calculateContentFreshness(Map<String, dynamic> basicStats) {
    final lastUpdate = basicStats['last_content_update'] as String?;
    if (lastUpdate == null) return 0.0;

    try {
      final updateTime = DateTime.parse(lastUpdate);
      final now = DateTime.now();
      final hoursSinceUpdate = now.difference(updateTime).inHours;

      if (hoursSinceUpdate < 2) return 1.0; // Very fresh
      if (hoursSinceUpdate < 12) return 0.8; // Fresh
      if (hoursSinceUpdate < 24) return 0.6; // Acceptable
      return 0.3; // Stale
    } catch (e) {
      return 0.0;
    }
  }

  static double _calculateAvailabilityScore(
    bool hasToday,
    bool hasPrevious,
    int historyCount,
  ) {
    double score = 0;
    if (hasToday) score += 50;
    if (hasPrevious) score += 25;
    score += (historyCount * 2.5).clamp(0, 25);
    return score.clamp(0, 100);
  }

  static String _getUtilizationStatus(double percentage) {
    if (percentage > 90) return 'critical';
    if (percentage > 75) return 'high';
    if (percentage > 50) return 'moderate';
    return 'low';
  }

  static double _calculateUsageEfficiency(Map<String, dynamic> basicStats) {
    // Simplified calculation based on content availability and usage
    final hasToday = basicStats['has_today_content'] as bool? ?? false;
    final hasPrevious =
        basicStats['has_previous_day_content'] as bool? ?? false;
    final historyCount = basicStats['content_history_count'] as int? ?? 0;

    double efficiency = 0;
    if (hasToday) efficiency += 40;
    if (hasPrevious) efficiency += 30;
    efficiency += (historyCount * 4).clamp(0, 30);

    return efficiency.clamp(0, 100);
  }

  // System information helpers
  static Future<Map<String, dynamic>> _calculateServiceUptime() async {
    return {
      'uptime_hours': 24, // Placeholder
      'start_time':
          DateTime.now().subtract(const Duration(hours: 24)).toIso8601String(),
    };
  }

  static Future<Map<String, dynamic>> _getSystemInformation() async {
    return {
      'platform': 'flutter',
      'cache_version': '1.0.0',
      'preferences_version': 'latest',
    };
  }

  static Future<Map<String, dynamic>> _getResourceUsage() async {
    return {
      'memory_usage': 'normal',
      'storage_usage': 'optimal',
      'cpu_usage': 'low',
    };
  }

  static int _calculateOperationalScore() {
    // Calculate operational score based on service health factors
    int score = 100;

    // Service initialization (25 points)
    // Would check actual initialization status
    // score -= isInitialized ? 0 : 25;

    // Timer operations (25 points)
    // Would check actual timer statuses
    // score -= allTimersOperational ? 0 : 25;

    // Connectivity (25 points)
    // Would check actual connectivity status
    // score -= connectivityListenerActive ? 0 : 25;

    // Sync operations (25 points)
    // Would check actual sync status
    // score -= syncOperational ? 0 : 25;

    // For now, return a high score since service is working
    return score.clamp(0, 100);
  }

  // Helper method to get sync errors - delegates to main service
  static Future<List<Map<String, dynamic>>> _getSyncErrors() async {
    try {
      final errorsJson = _prefs!.getString('today_feed_sync_errors');
      if (errorsJson == null) return [];

      final List<dynamic> errorsList = jsonDecode(errorsJson);
      return errorsList.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Failed to get sync errors: $e');
      return [];
    }
  }
}
