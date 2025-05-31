import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'today_feed_cache_metrics_collector.dart';
import 'today_feed_cache_health_analyzer.dart';
import 'today_feed_cache_report_generator.dart';

/// Main statistics service that coordinates cache metrics collection and analysis
/// Delegates specialized tasks to extracted service components
class TodayFeedCacheStatisticsService {
  static SharedPreferences? _prefs;
  static bool _isInitialized = false;

  /// Initialize the statistics service and all sub-components
  static Future<void> initialize(SharedPreferences prefs) async {
    _prefs = prefs;
    _isInitialized = true;

    // Initialize all extracted components
    await TodayFeedCacheMetricsCollector.initialize(prefs);
    await TodayFeedCacheHealthAnalyzer.initialize(prefs);
    await TodayFeedCacheReportGenerator.initialize(prefs);
  }

  /// Get comprehensive cache statistics with detailed metrics
  /// This is the main entry point that coordinates all statistics gathering
  static Future<Map<String, dynamic>> getCacheStatistics(
    Map<String, dynamic> basicStats,
  ) async {
    if (!_isInitialized) {
      throw StateError('TodayFeedCacheStatisticsService not initialized');
    }

    try {
      debugPrint('📊 Collecting comprehensive cache statistics...');

      // Delegate to the report generator which coordinates all components
      return await TodayFeedCacheReportGenerator.generateCacheStatisticsReport(
        basicStats,
      );
    } catch (e) {
      debugPrint('❌ Failed to collect cache statistics: $e');
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Get detailed performance statistics with benchmarking
  /// Delegates to metrics collector
  static Future<Map<String, dynamic>> getDetailedPerformanceStatistics() async {
    return TodayFeedCacheMetricsCollector.getDetailedPerformanceStatistics();
  }

  /// Get cache usage statistics and patterns
  /// Delegates to metrics collector
  static Future<Map<String, dynamic>> getCacheUsageStatistics(
    Map<String, dynamic> basicStats,
  ) async {
    return TodayFeedCacheMetricsCollector.getCacheUsageStatistics(basicStats);
  }

  /// Get cache trend analysis
  /// Delegates to health analyzer
  static Future<Map<String, dynamic>> getCacheTrendAnalysis() async {
    return TodayFeedCacheHealthAnalyzer.getCacheTrendAnalysis();
  }

  /// Get cache efficiency metrics
  /// Delegates to health analyzer
  static Future<Map<String, dynamic>> getCacheEfficiencyMetrics() async {
    return TodayFeedCacheHealthAnalyzer.getCacheEfficiencyMetrics();
  }

  /// Get operational statistics
  /// Delegates to metrics collector
  static Future<Map<String, dynamic>> getOperationalStatistics() async {
    return TodayFeedCacheMetricsCollector.getOperationalStatistics();
  }

  /// Export metrics for external monitoring systems
  /// Delegates to metrics collector
  static Future<Map<String, dynamic>> exportMetricsForMonitoring(
    Map<String, dynamic> basicStats,
    Map<String, dynamic> healthStatus,
  ) async {
    try {
      final statistics = await getCacheStatistics(basicStats);
      return await TodayFeedCacheMetricsCollector.exportMetricsForMonitoring(
        basicStats,
        healthStatus,
        statistics,
      );
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
  /// Delegates to health analyzer
  static Map<String, dynamic> generateStatisticalSummary(
    Map<String, dynamic> basicStats,
    Map<String, dynamic> performanceStats,
    Map<String, dynamic> usageStats,
    Map<String, dynamic> efficiencyStats,
  ) {
    return TodayFeedCacheHealthAnalyzer.generateStatisticalSummary(
      basicStats,
      performanceStats,
      usageStats,
      efficiencyStats,
    );
  }

  /// Generate diagnostic report for troubleshooting
  /// Delegates to report generator
  static Future<Map<String, dynamic>> generateDiagnosticReport(
    Map<String, dynamic> basicStats,
    Map<String, dynamic> healthStatus,
  ) async {
    return TodayFeedCacheReportGenerator.generateDiagnosticReport(
      basicStats,
      healthStatus,
    );
  }

  /// Generate performance monitoring report
  /// Delegates to report generator
  static Future<Map<String, dynamic>> generatePerformanceReport(
    Map<String, dynamic> basicStats,
  ) async {
    return TodayFeedCacheReportGenerator.generatePerformanceReport(basicStats);
  }

  /// Generate executive summary report
  /// Delegates to report generator
  static Future<Map<String, dynamic>> generateExecutiveSummary(
    Map<String, dynamic> basicStats,
    Map<String, dynamic> healthStatus,
  ) async {
    return TodayFeedCacheReportGenerator.generateExecutiveSummary(
      basicStats,
      healthStatus,
    );
  }

  /// Generate custom report with specified parameters
  /// Delegates to report generator
  static Future<Map<String, dynamic>> generateCustomReport({
    required Map<String, dynamic> basicStats,
    Map<String, dynamic>? healthStatus,
    bool includePerformance = true,
    bool includeUsage = true,
    bool includeTrends = true,
    bool includeEfficiency = true,
    bool includeOperational = true,
    bool includeDiagnostics = false,
    List<String>? customSections,
  }) async {
    return TodayFeedCacheReportGenerator.generateCustomReport(
      basicStats: basicStats,
      healthStatus: healthStatus,
      includePerformance: includePerformance,
      includeUsage: includeUsage,
      includeTrends: includeTrends,
      includeEfficiency: includeEfficiency,
      includeOperational: includeOperational,
      includeDiagnostics: includeDiagnostics,
      customSections: customSections,
    );
  }

  /// Quick health check method for immediate status assessment
  static Future<Map<String, dynamic>> quickHealthCheck(
    Map<String, dynamic> basicStats,
  ) async {
    try {
      final hasToday = basicStats['has_today_content'] as bool? ?? false;
      final sizeBytes = basicStats['cache_size_bytes'] as int? ?? 0;
      const maxSizeBytes = 10 * 1024 * 1024; // 10MB
      final utilization = (sizeBytes / maxSizeBytes * 100).clamp(0.0, 100.0);

      // Quick performance test
      final stopwatch = Stopwatch()..start();
      _prefs?.getString('today_feed_content');
      stopwatch.stop();
      final quickReadTime = stopwatch.elapsedMilliseconds;

      final healthScore = _calculateQuickHealthScore(
        hasToday,
        utilization,
        quickReadTime,
      );

      return {
        'quick_health_check': {
          'timestamp': DateTime.now().toIso8601String(),
          'overall_health': _getHealthRating(healthScore),
          'health_score': healthScore,
          'content_available': hasToday,
          'utilization_percentage': utilization,
          'quick_read_time_ms': quickReadTime,
        },
        'recommendations': _getQuickRecommendations(
          hasToday,
          utilization,
          quickReadTime,
        ),
      };
    } catch (e) {
      debugPrint('❌ Failed to perform quick health check: $e');
      return {
        'error': e.toString(),
        'quick_health_check': {
          'timestamp': DateTime.now().toIso8601String(),
          'overall_health': 'unknown',
          'health_score': 0,
        },
      };
    }
  }

  /// Get basic cache metrics without detailed analysis
  static Future<Map<String, dynamic>> getBasicMetrics(
    Map<String, dynamic> basicStats,
  ) async {
    try {
      final hasToday = basicStats['has_today_content'] as bool? ?? false;
      final hasPrevious =
          basicStats['has_previous_day_content'] as bool? ?? false;
      final historyCount = basicStats['content_history_count'] as int? ?? 0;
      final sizeBytes = basicStats['cache_size_bytes'] as int? ?? 0;

      return {
        'basic_metrics': {
          'timestamp': DateTime.now().toIso8601String(),
          'content_status': {
            'today_available': hasToday,
            'previous_available': hasPrevious,
            'history_count': historyCount,
          },
          'storage_info': {
            'size_bytes': sizeBytes,
            'size_mb': (sizeBytes / (1024 * 1024)).toStringAsFixed(2),
            'utilization_percentage': ((sizeBytes / (10 * 1024 * 1024)) * 100)
                .clamp(0.0, 100.0),
          },
          'service_status': {
            'initialized': _isInitialized,
            'components_ready': await _checkComponentsReady(),
          },
        },
      };
    } catch (e) {
      debugPrint('❌ Failed to get basic metrics: $e');
      return {
        'error': e.toString(),
        'basic_metrics': {'timestamp': DateTime.now().toIso8601String()},
      };
    }
  }

  /// Check if all service components are properly initialized
  static Future<bool> _checkComponentsReady() async {
    try {
      // Test each component by calling a lightweight method
      await TodayFeedCacheMetricsCollector.getOperationalStatistics();
      await TodayFeedCacheHealthAnalyzer.getCacheEfficiencyMetrics();
      return true;
    } catch (e) {
      debugPrint('⚠️ Some components not ready: $e');
      return false;
    }
  }

  /// Calculate quick health score based on key indicators
  static int _calculateQuickHealthScore(
    bool hasToday,
    double utilization,
    int readTime,
  ) {
    int score = 0;

    // Content availability (40 points)
    if (hasToday) score += 40;

    // Storage utilization (30 points)
    if (utilization < 50) {
      score += 30;
    } else if (utilization < 75) {
      score += 20;
    } else if (utilization < 90) {
      score += 10;
    }

    // Performance (30 points)
    if (readTime < 25) {
      score += 30;
    } else if (readTime < 50) {
      score += 20;
    } else if (readTime < 100) {
      score += 10;
    }

    return score.clamp(0, 100);
  }

  /// Get health rating based on score
  static String _getHealthRating(int score) {
    if (score >= 85) return 'excellent';
    if (score >= 70) return 'good';
    if (score >= 50) return 'fair';
    return 'poor';
  }

  /// Get quick recommendations based on health check results
  static List<String> _getQuickRecommendations(
    bool hasToday,
    double utilization,
    int readTime,
  ) {
    final recommendations = <String>[];

    if (!hasToday) {
      recommendations.add('Refresh today\'s content immediately');
    }

    if (utilization > 80) {
      recommendations.add('Consider cache cleanup to reduce storage usage');
    }

    if (readTime > 100) {
      recommendations.add(
        'Performance optimization needed for cache operations',
      );
    }

    if (recommendations.isEmpty) {
      recommendations.add('Cache is operating normally');
    }

    return recommendations;
  }

  /// Legacy compatibility method - maintains backward compatibility
  @Deprecated(
    'Use getCacheStatistics instead. This method will be removed in version 3.0.0',
  )
  static Future<Map<String, dynamic>> getStatistics(
    Map<String, dynamic> basicStats,
  ) async {
    debugPrint(
      '⚠️ Using deprecated getStatistics method. Use getCacheStatistics instead.',
    );
    return getCacheStatistics(basicStats);
  }

  /// Service information and version details
  static Map<String, dynamic> getServiceInfo() {
    return {
      'service_name': 'TodayFeedCacheStatisticsService',
      'version': '2.0.0',
      'architecture': 'modular',
      'components': [
        'TodayFeedCacheMetricsCollector',
        'TodayFeedCacheHealthAnalyzer',
        'TodayFeedCacheReportGenerator',
      ],
      'capabilities': [
        'Performance metrics collection',
        'Health analysis and trend tracking',
        'Comprehensive report generation',
        'Monitoring system integration',
        'Diagnostic troubleshooting',
      ],
      'initialization_status': _isInitialized,
      'last_refactored': '2024-12-30',
      'size_reduction':
          'Reduced from 981 lines to ~500 lines via component extraction',
    };
  }
}
