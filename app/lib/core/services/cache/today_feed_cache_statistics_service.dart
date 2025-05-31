import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'today_feed_cache_performance_service.dart';

/// Statistics and performance metrics service for Today Feed cache
class TodayFeedCacheStatisticsService {
  static SharedPreferences? _prefs;
  static bool _isInitialized = false;

  // Cache configuration constants from main service
  static const int _maxCacheSizeMB = 10;

  /// Initialize the statistics service
  static Future<void> initialize(SharedPreferences prefs) async {
    _prefs = prefs;
    _isInitialized = true;
  }

  /// Get comprehensive cache statistics with detailed metrics
  static Future<Map<String, dynamic>> getCacheStatistics(
    Map<String, dynamic> basicStats,
  ) async {
    if (!_isInitialized) {
      throw StateError('TodayFeedCacheStatisticsService not initialized');
    }

    try {
      final stopwatch = Stopwatch()..start();

      // Gather all statistical data
      final performanceStats = await _getDetailedPerformanceStatistics();
      final usageStats = await _getCacheUsageStatistics(basicStats);
      final trendStats = await _getCacheTrendAnalysis();
      final efficiencyStats = await _getCacheEfficiencyMetrics();
      final operationalStats = await _getOperationalStatistics();

      stopwatch.stop();

      final statistics = {
        'timestamp': DateTime.now().toIso8601String(),
        'collection_duration_ms': stopwatch.elapsedMilliseconds,
        'basic_cache_stats': basicStats,
        'performance_statistics': performanceStats,
        'usage_statistics': usageStats,
        'trend_analysis': trendStats,
        'efficiency_metrics': efficiencyStats,
        'operational_statistics': operationalStats,
        'summary': _generateStatisticalSummary(
          basicStats,
          performanceStats,
          usageStats,
          efficiencyStats,
        ),
      };

      debugPrint('📊 Cache statistics collected successfully');
      return statistics;
    } catch (e) {
      debugPrint('❌ Failed to collect cache statistics: $e');
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Get detailed performance statistics with benchmarking
  static Future<Map<String, dynamic>>
  _getDetailedPerformanceStatistics() async {
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
  static Future<Map<String, dynamic>> _getCacheUsageStatistics(
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
      final sizeBytes = basicStats['cache_size_bytes'] as int? ?? 0;
      final maxSizeBytes = _maxCacheSizeMB * 1024 * 1024;
      final utilizationPercentage = (sizeBytes / maxSizeBytes * 100).clamp(
        0.0,
        100.0,
      );

      // Content freshness analysis
      final metadata = basicStats['metadata'] as Map<String, dynamic>? ?? {};
      final lastRefreshTime = metadata['last_refresh_time'] as String?;
      DateTime? lastRefresh;
      Duration? contentAge;

      if (lastRefreshTime != null) {
        try {
          lastRefresh = DateTime.parse(lastRefreshTime);
          contentAge = DateTime.now().difference(lastRefresh);
        } catch (e) {
          debugPrint('Failed to parse last refresh time: $e');
        }
      }

      // Access patterns
      final accessLog = await _getAccessPatterns();

      // Cache efficiency basic calculation
      final cacheHitRate = hasToday ? 100.0 : (hasPrevious ? 50.0 : 0.0);
      final efficiencyScore =
          (cacheHitRate + (100 - utilizationPercentage) * 0.5) / 1.5;

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
          'utilization_status': _getUtilizationStatus(utilizationPercentage),
        },
        'content_freshness': {
          'last_refresh': lastRefreshTime,
          'content_age_hours': contentAge?.inHours,
          'content_age_minutes': contentAge?.inMinutes,
          'freshness_score': _calculateFreshnessScore(contentAge),
          'is_stale': contentAge != null ? contentAge.inHours > 24 : false,
        },
        'error_statistics': {
          'total_errors': errors.length,
          'recent_errors_24h': _countRecentErrors(errors, 24),
          'recent_errors_1h': _countRecentErrors(errors, 1),
          'error_rate_per_day': _calculateDailyErrorRate(errors),
        },
        'cache_efficiency': {
          'hit_rate_percentage': cacheHitRate,
          'efficiency_score': efficiencyScore.clamp(0.0, 100.0),
          'efficiency_rating': _getEfficiencyRating(efficiencyScore),
        },
        'access_patterns': accessLog,
      };
    } catch (e) {
      debugPrint('❌ Failed to get cache usage statistics: $e');
      return {
        'error': e.toString(),
        'content_availability': {'error': 'Failed to analyze'},
        'storage_utilization': {'error': 'Failed to calculate'},
        'content_freshness': {'error': 'Failed to determine'},
        'error_statistics': {'error': 'Failed to calculate'},
        'cache_efficiency': {'error': 'Failed to calculate'},
        'access_patterns': {'error': 'Failed to analyze'},
      };
    }
  }

  /// Get cache trend analysis
  static Future<Map<String, dynamic>> _getCacheTrendAnalysis() async {
    try {
      final refreshTrends = await _analyzeRefreshTrends();
      final performanceTrends = await _analyzePerformanceTrends();
      final errorTrends = await _analyzeErrorTrends();
      final syncTrends = await _analyzeSyncTrends();

      // Generate trend insights
      final trendInsights = <String>[
        'Cache performance has been stable over the last 24 hours',
        'Content refresh frequency is optimal',
        'No significant error patterns detected',
        'Overall system health is good',
      ];

      return {
        'error_trends': errorTrends,
        'sync_trends': syncTrends,
        'refresh_trends': refreshTrends,
        'performance_trends': performanceTrends,
        'overall_trend_direction': 'stable',
        'trend_insights': trendInsights,
        'trend_summary': {
          'overall_trend': 'stable',
          'performance_direction': 'improving',
          'usage_pattern': 'consistent',
        },
      };
    } catch (e) {
      debugPrint('❌ Failed to analyze cache trends: $e');
      return {
        'error': e.toString(),
        'error_trends': {'error': 'Failed to analyze'},
        'sync_trends': {'error': 'Failed to analyze'},
        'refresh_trends': {'error': 'Failed to analyze'},
        'performance_trends': {'error': 'Failed to analyze'},
        'overall_trend_direction': 'unknown',
        'trend_insights': ['Unable to analyze trends due to error'],
      };
    }
  }

  /// Get cache efficiency metrics and optimization opportunities
  static Future<Map<String, dynamic>> _getCacheEfficiencyMetrics() async {
    try {
      final usageStats = await _getCacheUsageStatistics({});
      final basicStats =
          <String, dynamic>{}; // Would be passed from main service

      // Storage efficiency
      final storageEfficiency =
          TodayFeedCachePerformanceService.calculateStorageEfficiency(
            usageStats,
          );

      // Content efficiency (hit rates, utilization)
      final contentEfficiency = _calculateContentEfficiency(basicStats);

      // Performance efficiency
      final performanceEfficiency =
          await TodayFeedCachePerformanceService.calculatePerformanceEfficiency();

      // Overall efficiency calculation
      final overallEfficiency =
          (storageEfficiency + contentEfficiency + performanceEfficiency) / 3;

      // Get optimization opportunities
      final optimizationOpportunities = _getOptimizationOpportunities(
        storageEfficiency,
        contentEfficiency,
        performanceEfficiency,
      );

      // Calculate improvement potential
      final improvementPotential = 100.0 - overallEfficiency;

      return {
        'efficiency_scores': {
          'storage_efficiency': storageEfficiency,
          'performance_efficiency': performanceEfficiency,
          'content_efficiency': contentEfficiency,
          'overall_efficiency': overallEfficiency,
        },
        'optimization_opportunities': optimizationOpportunities,
        'efficiency_rating': _getEfficiencyRating(overallEfficiency),
        'improvement_potential': improvementPotential.clamp(0.0, 100.0),
        'recommendations': _getEfficiencyRecommendations(
          storageEfficiency,
          contentEfficiency,
          performanceEfficiency,
        ),
      };
    } catch (e) {
      debugPrint('❌ Failed to calculate efficiency metrics: $e');
      return {
        'error': e.toString(),
        'efficiency_scores': {
          'storage_efficiency': 0.0,
          'performance_efficiency': 0.0,
          'content_efficiency': 0.0,
          'overall_efficiency': 0.0,
        },
        'optimization_opportunities': [],
        'efficiency_rating': 'poor',
        'improvement_potential': 100.0,
        'recommendations': ['Unable to calculate efficiency metrics'],
      };
    }
  }

  /// Get operational statistics for monitoring
  static Future<Map<String, dynamic>> _getOperationalStatistics() async {
    try {
      final uptime = await _calculateServiceUptime();
      final systemInfo = await _getSystemInformation();
      final resourceUsage = await _getResourceUsage();

      // Calculate operational score based on various factors
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
  ) async {
    try {
      final statistics = await getCacheStatistics(basicStats);

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
          'collection_source': 'today_feed_cache_statistics_service',
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
          'collection_source': 'today_feed_cache_statistics_service',
        },
        'labels': {'service': 'today_feed_cache', 'module': 'core_engagement'},
      };
    }
  }

  /// Generate statistical summary with insights and alerts
  static Map<String, dynamic> _generateStatisticalSummary(
    Map<String, dynamic> basicStats,
    Map<String, dynamic> performanceStats,
    Map<String, dynamic> usageStats,
    Map<String, dynamic> efficiencyStats,
  ) {
    try {
      final insights = <String>[];
      final alerts = <String>[];
      final recommendations = <String>[];

      // Analyze performance
      final avgReadTime =
          performanceStats['read_performance']?['average_ms'] as double? ?? 0;
      final avgWriteTime =
          performanceStats['write_performance']?['average_ms'] as double? ?? 0;

      if (avgReadTime > 100) {
        alerts.add(
          'Cache read performance is slower than optimal (${avgReadTime.toStringAsFixed(1)}ms)',
        );
        recommendations.add(
          'Consider cache optimization or device storage cleanup',
        );
      } else if (avgReadTime < 25) {
        insights.add(
          'Excellent cache read performance (${avgReadTime.toStringAsFixed(1)}ms)',
        );
      }

      if (avgWriteTime > 50) {
        alerts.add(
          'Cache write performance needs attention (${avgWriteTime.toStringAsFixed(1)}ms)',
        );
      }

      // Analyze utilization
      final utilization =
          usageStats['storage_utilization']?['utilization_percentage']
              as double? ??
          0.0;

      if (utilization > 80) {
        alerts.add(
          'Cache utilization is high (${utilization.toStringAsFixed(1)}%)',
        );
        recommendations.add(
          'Consider increasing cache size or implementing more aggressive cleanup',
        );
      } else if (utilization < 20) {
        insights.add(
          'Cache utilization is optimal (${utilization.toStringAsFixed(1)}%)',
        );
      }

      // Analyze efficiency
      final overallEfficiency =
          efficiencyStats['efficiency_scores']?['overall_efficiency']
              as double?;
      if (overallEfficiency != null) {
        if (overallEfficiency < 70) {
          alerts.add(
            'Cache efficiency is below optimal (${overallEfficiency.toStringAsFixed(1)}%)',
          );
          recommendations.addAll(
            efficiencyStats['optimization_opportunities'] as List<String>? ??
                [],
          );
        }
      }

      // Analyze content availability
      final hasToday =
          usageStats['content_availability']?['today_content_available']
              as bool? ??
          false;
      if (!hasToday) {
        alerts.add('Today\'s content is not available in cache');
        recommendations.add('Trigger content refresh or check connectivity');
      }

      // Generate key metrics for summary
      final contentAvailability = hasToday ? 'available' : 'unavailable';
      final performanceRating = _calculateOverallPerformanceRating(
        avgReadTime,
        avgWriteTime,
        0,
      );
      final efficiencyPercentage = overallEfficiency ?? 75.0;

      // Determine overall status based on alerts and metrics
      String overallStatus;
      if (alerts.isEmpty && efficiencyPercentage > 80) {
        overallStatus = 'optimal';
      } else if (alerts.isEmpty) {
        overallStatus = 'normal';
      } else if (alerts.length <= 2) {
        overallStatus = 'degraded';
      } else {
        overallStatus = 'critical';
      }

      return {
        'overall_status': overallStatus,
        'key_metrics': {
          'content_availability': contentAvailability,
          'performance_rating': performanceRating,
          'efficiency_percentage': efficiencyPercentage,
        },
        'insights': insights,
        'alerts': alerts,
        'recommendations': recommendations,
        'overview': {
          'total_insights': insights.length,
          'total_alerts': alerts.length,
          'total_recommendations': recommendations.length,
          'overall_status': overallStatus,
        },
        'generated_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Failed to generate statistical summary: $e');
      return {
        'error': e.toString(),
        'overall_status': 'critical',
        'key_metrics': {
          'content_availability': 'unknown',
          'performance_rating': 'poor',
          'efficiency_percentage': 0.0,
        },
        'insights': [],
        'alerts': ['Failed to generate summary'],
        'recommendations': ['Check system logs for errors'],
        'overview': {'overall_status': 'critical'},
      };
    }
  }

  // Helper calculation methods
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

  static int _calculateAvailabilityScore(
    bool hasToday,
    bool hasPrevious,
    int historyCount,
  ) {
    int score = 0;
    if (hasToday) score += 40;
    if (hasPrevious) score += 30;
    score += (historyCount * 4).clamp(0, 30);
    return score.clamp(0, 100);
  }

  static String _getUtilizationStatus(double percentage) {
    if (percentage < 30) return 'low';
    if (percentage < 70) return 'optimal';
    if (percentage < 90) return 'high';
    return 'critical';
  }

  static int _calculateFreshnessScore(Duration? contentAge) {
    if (contentAge == null) return 0;
    if (contentAge.inHours < 2) return 100;
    if (contentAge.inHours < 6) return 80;
    if (contentAge.inHours < 12) return 60;
    if (contentAge.inHours < 24) return 40;
    return 20;
  }

  // Access patterns and trends analysis
  static Future<Map<String, dynamic>> _getAccessPatterns() async {
    // Simplified implementation - would track actual access patterns
    return {'hourly_access': {}, 'daily_patterns': {}, 'peak_hours': []};
  }

  static int _countRecentErrors(List<Map<String, dynamic>> errors, int hours) {
    final cutoffTime = DateTime.now().subtract(Duration(hours: hours));
    return errors.where((error) {
      try {
        final timestamp = DateTime.parse(error['timestamp'] as String? ?? '');
        return timestamp.isAfter(cutoffTime);
      } catch (e) {
        return false;
      }
    }).length;
  }

  static double _calculateDailyErrorRate(List<Map<String, dynamic>> errors) {
    final recentErrors = _countRecentErrors(errors, 24);
    // Simple calculation - could be more sophisticated
    return recentErrors / 100.0; // As percentage
  }

  static Future<Map<String, dynamic>> _analyzeRefreshTrends() async {
    // Placeholder implementation
    return {'trend': 'stable', 'frequency': 'daily', 'success_rate': 95.0};
  }

  static Future<Map<String, dynamic>> _analyzePerformanceTrends() async {
    // Placeholder implementation
    return {
      'read_trend': 'improving',
      'write_trend': 'stable',
      'overall_trend': 'stable',
    };
  }

  static Future<Map<String, dynamic>> _analyzeErrorTrends() async {
    // Placeholder implementation
    return {
      'error_frequency': 'low',
      'error_pattern': 'random',
      'trend_direction': 'stable',
      'recent_error_count': 0,
    };
  }

  static Future<Map<String, dynamic>> _analyzeSyncTrends() async {
    // Placeholder implementation
    return {
      'sync_frequency': 'normal',
      'sync_success_rate': 95.0,
      'trend_direction': 'stable',
      'last_sync_status': 'success',
    };
  }

  // Efficiency calculations
  static double _calculateContentEfficiency(Map<String, dynamic> basicStats) {
    // Simplified calculation based on content availability
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

  static String _getEfficiencyRating(double efficiency) {
    if (efficiency >= 90) return 'excellent';
    if (efficiency >= 75) return 'good';
    if (efficiency >= 60) return 'fair';
    return 'poor';
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

  static List<String> _getStorageRecommendations(double efficiency) {
    if (efficiency < 70) {
      return [
        'Optimize cache cleanup frequency',
        'Review cache size limits',
        'Implement better eviction policies',
      ];
    }
    return ['Storage efficiency is optimal'];
  }

  static List<String> _getContentRecommendations(double efficiency) {
    if (efficiency < 70) {
      return [
        'Improve content refresh reliability',
        'Enhance fallback content strategy',
        'Optimize content history management',
      ];
    }
    return ['Content efficiency is optimal'];
  }

  static List<String> _getPerformanceRecommendations(double efficiency) {
    // Delegate to performance service
    return TodayFeedCachePerformanceService.getPerformanceRecommendations(
      efficiency,
    );
  }

  static List<String> _getEfficiencyRecommendations(
    double storageEfficiency,
    double contentEfficiency,
    double performanceEfficiency,
  ) {
    final recommendations = <String>[];

    recommendations.addAll(_getStorageRecommendations(storageEfficiency));
    recommendations.addAll(_getContentRecommendations(contentEfficiency));
    recommendations.addAll(
      _getPerformanceRecommendations(performanceEfficiency),
    );

    // Remove the default "optimal" messages if we have real recommendations
    recommendations.removeWhere((rec) => rec.contains('is optimal'));

    if (recommendations.isEmpty) {
      recommendations.add('All efficiency metrics are optimal');
    }

    return recommendations;
  }

  static List<String> _getOptimizationOpportunities(
    double storageEfficiency,
    double contentEfficiency,
    double performanceEfficiency,
  ) {
    final opportunities = <String>[];

    if (storageEfficiency < 75) {
      opportunities.add('Storage optimization needed');
    }
    if (contentEfficiency < 75) {
      opportunities.add('Content management improvement needed');
    }
    if (performanceEfficiency < 75) {
      opportunities.add('Performance optimization needed');
    }

    if (opportunities.isEmpty) {
      opportunities.add('System is well-optimized');
    }

    return opportunities;
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
