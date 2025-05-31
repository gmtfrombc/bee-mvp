import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Performance testing and analysis service for Today Feed cache
class TodayFeedCachePerformanceService {
  static SharedPreferences? _prefs;
  static bool _isInitialized = false;

  // Cache key for testing performance
  static const String _todayContentKey = 'today_feed_content';

  /// Initialize the performance service
  static Future<void> initialize(SharedPreferences prefs) async {
    _prefs = prefs;
    _isInitialized = true;
  }

  /// Calculate comprehensive performance metrics for cache operations
  static Future<Map<String, dynamic>> calculatePerformanceMetrics() async {
    if (!_isInitialized) {
      throw StateError('TodayFeedCachePerformanceService not initialized');
    }

    try {
      final stopwatch = Stopwatch()..start();

      // Test cache read performance
      await _getTodayContent();
      final readTime = stopwatch.elapsedMilliseconds;

      stopwatch.reset();
      stopwatch.start();

      // Test cache write performance with small test data
      final testMetadata = {
        'test': 'performance',
        'timestamp': DateTime.now().toIso8601String(),
      };
      await _prefs!.setString('test_performance_key', jsonEncode(testMetadata));
      final writeTime = stopwatch.elapsedMilliseconds;

      // Clean up test data
      await _prefs!.remove('test_performance_key');

      stopwatch.stop();

      return {
        'average_read_time_ms': readTime,
        'average_write_time_ms': writeTime,
        'performance_rating': calculatePerformanceRating(readTime, writeTime),
        'is_performing_well': readTime < 100 && writeTime < 50,
        'recommendations': generatePerformanceRecommendations(
          readTime,
          writeTime,
        ),
      };
    } catch (e) {
      debugPrint('❌ Failed to calculate performance metrics: $e');
      return {
        'average_read_time_ms': -1,
        'average_write_time_ms': -1,
        'error': e.toString(),
        'is_performing_well': false,
        'recommendations': ['Unable to measure performance due to error'],
      };
    }
  }

  /// Calculate detailed performance statistics with benchmarking
  static Future<Map<String, dynamic>> getDetailedPerformanceStatistics() async {
    if (!_isInitialized) {
      throw StateError('TodayFeedCachePerformanceService not initialized');
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

  /// Calculate performance efficiency score
  static Future<double> calculatePerformanceEfficiency() async {
    try {
      final perfStats = await getDetailedPerformanceStatistics();
      final readTime =
          perfStats['read_performance']?['average_ms'] as double? ?? 100;
      final writeTime =
          perfStats['write_performance']?['average_ms'] as double? ?? 50;

      // Calculate efficiency based on performance thresholds
      final readEfficiency =
          readTime <= 50 ? 100 : (50 / readTime * 100).clamp(20, 100);
      final writeEfficiency =
          writeTime <= 25 ? 100 : (25 / writeTime * 100).clamp(20, 100);

      return (readEfficiency + writeEfficiency) / 2;
    } catch (e) {
      return 75.0; // Default efficiency
    }
  }

  /// Calculate performance rating based on read/write times
  static String calculatePerformanceRating(int readTime, int writeTime) {
    if (readTime < 50 && writeTime < 25) return 'excellent';
    if (readTime < 100 && writeTime < 50) return 'good';
    if (readTime < 200 && writeTime < 100) return 'fair';
    return 'poor';
  }

  /// Generate performance recommendations
  static List<String> generatePerformanceRecommendations(
    int readTime,
    int writeTime,
  ) {
    final recommendations = <String>[];

    if (readTime > 200) {
      recommendations.add(
        'Cache reads are slow (${readTime}ms) - consider clearing cache',
      );
    }
    if (writeTime > 100) {
      recommendations.add(
        'Cache writes are slow (${writeTime}ms) - device storage may be full',
      );
    }
    if (readTime < 50 && writeTime < 25) {
      recommendations.add('Cache performance is excellent');
    }

    return recommendations;
  }

  /// Generate performance recommendations based on efficiency score
  static List<String> getPerformanceRecommendations(double efficiency) {
    if (efficiency < 70) {
      return [
        'Optimize cache read/write operations',
        'Consider async processing improvements',
        'Review device storage performance',
      ];
    }
    return ['Performance efficiency is optimal'];
  }

  /// Calculate storage efficiency based on utilization
  static double calculateStorageEfficiency(Map<String, dynamic> usageStats) {
    try {
      final utilizationStr =
          usageStats['storage_utilization']?['utilization_percentage']
              as String? ??
          '0.0';
      final utilization = double.tryParse(utilizationStr) ?? 0.0;

      // Optimal utilization is between 30-70%
      if (utilization >= 30 && utilization <= 70) {
        return 90.0 + (10.0 * (1 - (utilization - 50).abs() / 20));
      } else if (utilization < 30) {
        return 70.0 + (utilization / 30 * 20); // 70-90%
      } else {
        return 90.0 - ((utilization - 70) / 30 * 40); // 90-50%
      }
    } catch (e) {
      return 50.0; // Default moderate efficiency
    }
  }

  /// Benchmark cache operations and generate comprehensive performance report
  static Future<Map<String, dynamic>> benchmarkCacheOperations() async {
    if (!_isInitialized) {
      throw StateError('TodayFeedCachePerformanceService not initialized');
    }

    try {
      debugPrint('🔄 Starting cache performance benchmark...');

      final performanceMetrics = await calculatePerformanceMetrics();
      final detailedStats = await getDetailedPerformanceStatistics();
      final efficiency = await calculatePerformanceEfficiency();

      final report = {
        'benchmark_timestamp': DateTime.now().toIso8601String(),
        'basic_metrics': performanceMetrics,
        'detailed_statistics': detailedStats,
        'efficiency_score': efficiency,
        'efficiency_rating': _getEfficiencyRating(efficiency),
        'recommendations': getPerformanceRecommendations(efficiency),
        'summary': {
          'overall_performance': performanceMetrics['performance_rating'],
          'efficiency_percentage': efficiency,
          'is_performing_optimally': efficiency >= 80,
        },
      };

      debugPrint('✅ Cache performance benchmark completed');
      return report;
    } catch (e) {
      debugPrint('❌ Failed to benchmark cache operations: $e');
      return {
        'error': e.toString(),
        'benchmark_timestamp': DateTime.now().toIso8601String(),
        'summary': {
          'overall_performance': 'error',
          'efficiency_percentage': 0.0,
          'is_performing_optimally': false,
        },
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
    final sortedValues = List<int>.from(values)..sort();
    final middle = sortedValues.length ~/ 2;
    if (sortedValues.length.isOdd) {
      return sortedValues[middle].toDouble();
    } else {
      return (sortedValues[middle - 1] + sortedValues[middle]) / 2.0;
    }
  }

  static double _calculateStandardDeviation(List<int> values) {
    if (values.isEmpty) return 0.0;
    final mean = _calculateAverage(values);
    final squaredDifferences = values.map((value) => pow(value - mean, 2));
    final variance = squaredDifferences.reduce((a, b) => a + b) / values.length;
    return sqrt(variance);
  }

  static String _getPerformanceRating(double value, List<int> thresholds) {
    if (value <= thresholds[0]) return 'excellent';
    if (value <= thresholds[1]) return 'good';
    if (value <= thresholds[2]) return 'fair';
    return 'poor';
  }

  static String _calculateOverallPerformanceRating(
    double readTime,
    double writeTime,
    double lookupTime,
  ) {
    final scores = [
      _getPerformanceRating(readTime, [50, 100, 200]),
      _getPerformanceRating(writeTime, [25, 50, 100]),
      _getPerformanceRating(lookupTime, [30, 75, 150]),
    ];

    final excellentCount = scores.where((s) => s == 'excellent').length;
    final goodCount = scores.where((s) => s == 'good').length;
    final fairCount = scores.where((s) => s == 'fair').length;

    if (excellentCount >= 2) return 'excellent';
    if (goodCount >= 2) return 'good';
    if (fairCount >= 2) return 'fair';
    return 'poor';
  }

  static List<String> _generatePerformanceInsights(
    double readTime,
    double writeTime,
    double lookupTime,
  ) {
    final insights = <String>[];

    if (readTime < 25) {
      insights.add('Cache read performance is excellent');
    } else if (readTime > 200) {
      insights.add('Cache read performance needs optimization');
    }

    if (writeTime < 10) {
      insights.add('Cache write performance is optimal');
    } else if (writeTime > 100) {
      insights.add('Cache write operations are slow');
    }

    if (lookupTime < 15) {
      insights.add('Cache lookup performance is excellent');
    }

    return insights;
  }

  static String _getEfficiencyRating(double efficiency) {
    if (efficiency >= 90) return 'excellent';
    if (efficiency >= 75) return 'good';
    if (efficiency >= 60) return 'fair';
    return 'poor';
  }

  // Helper method to get today content for testing
  static Future<String?> _getTodayContent() async {
    try {
      return _prefs!.getString(_todayContentKey);
    } catch (e) {
      return null;
    }
  }
}
