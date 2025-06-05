/// **TodayFeedCacheMetricsAggregator - Advanced Metrics Aggregation System**
///
/// Aggregates metrics from all Today Feed cache services into unified reports.
/// Provides high-level analytics, monitoring capabilities, and comprehensive
/// health assessments following ResponsiveService patterns.
///
/// **Architecture Overview:**
/// ```
/// TodayFeedCacheMetricsAggregator
/// ├── Statistics Aggregation (Combined metrics from all services)
/// ├── Health Monitoring (System health assessment and scoring)
/// ├── Performance Analytics (Performance trends and bottlenecks)
/// ├── Service Coordination (Cross-service metric correlation)
/// └── Advanced Reporting (Customizable metric exports)
/// ```
///
/// **Key Features:**
/// - Unified metrics collection from 8 specialized services
/// - Environment-aware aggregation strategies
/// - Health scoring algorithms with trend analysis
/// - Performance bottleneck identification
/// - Custom metric filtering and export capabilities
/// - Real-time status monitoring
///
/// **Usage:**
/// ```dart
/// // Get comprehensive system statistics
/// final stats = await TodayFeedCacheMetricsAggregator.getAllStatistics();
///
/// // Get health assessment
/// final health = await TodayFeedCacheMetricsAggregator.getSystemHealthAssessment();
///
/// // Get performance analytics
/// final performance = await TodayFeedCacheMetricsAggregator.getPerformanceAnalytics();
///
/// // Custom filtered metrics
/// final filtered = await TodayFeedCacheMetricsAggregator.getFilteredMetrics(['cache', 'performance']);
/// ```
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../today_feed_cache_configuration.dart';
import '../today_feed_cache_health_service.dart';
import '../today_feed_cache_maintenance_service.dart';
import '../today_feed_cache_performance_service.dart';
import '../today_feed_cache_statistics_service.dart';
import '../today_feed_content_service.dart';
import '../today_feed_timezone_service.dart';

/// **Today Feed Cache Metrics Aggregator**
///
/// Centralized metrics aggregation system that collects, processes, and analyzes
/// metrics from all cache services. Provides unified reporting and advanced
/// analytics capabilities.
class TodayFeedCacheMetricsAggregator {
  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 1: CORE AGGREGATION METHODS
  // ═══════════════════════════════════════════════════════════════════════════
  //
  // Primary methods for aggregating metrics from all services into unified
  // reports. These methods are extracted from the main service to centralize
  // metrics aggregation logic.

  /// Get comprehensive statistics from all services
  ///
  /// Aggregates metrics from all cache services including content, statistics,
  /// health, performance, timezone, and sync status. Provides complete system
  /// overview for monitoring and analytics.
  static Future<Map<String, dynamic>> getAllStatistics({
    Map<String, dynamic>? cacheMetadata,
    Map<String, dynamic>? syncStatus,
  }) async {
    try {
      final stats = <String, dynamic>{};

      // Use provided metadata or fetch fresh data
      final metadata = cacheMetadata ?? await _getCacheMetadata();
      final sync = syncStatus ?? _getSyncStatus();

      // Aggregate statistics from each service
      stats['cache'] = metadata;
      stats['statistics'] =
          await TodayFeedCacheStatisticsService.getCacheStatistics(metadata);
      stats['health'] = await TodayFeedCacheHealthService.getCacheHealthStatus(
        metadata,
        sync,
      );
      stats['performance'] =
          await TodayFeedCachePerformanceService.getDetailedPerformanceStatistics();
      stats['timezone'] = await TodayFeedTimezoneService.getTimezoneStats();
      stats['sync'] = sync;

      // Add aggregation metadata
      stats['aggregation_info'] = _getAggregationMetadata();

      return stats;
    } catch (e) {
      debugPrint('❌ Failed to aggregate all statistics: $e');
      return {
        'error': e.toString(),
        'aggregation_info': _getAggregationMetadata(),
      };
    }
  }

  /// Get health metrics from all services
  ///
  /// Focuses on health-related metrics across all services to provide
  /// comprehensive system health assessment. Includes performance impact
  /// on health and timezone-related health indicators.
  static Future<Map<String, dynamic>> getAllHealthMetrics({
    Map<String, dynamic>? cacheMetadata,
    Map<String, dynamic>? syncStatus,
  }) async {
    try {
      final health = <String, dynamic>{};

      // Use provided metadata or fetch fresh data
      final metadata = cacheMetadata ?? await _getCacheMetadata();
      final sync = syncStatus ?? _getSyncStatus();

      // Aggregate health metrics from each service
      health['cache'] = metadata;
      health['health'] = await TodayFeedCacheHealthService.getCacheHealthStatus(
        metadata,
        sync,
      );
      health['performance'] =
          await TodayFeedCachePerformanceService.getDetailedPerformanceStatistics();
      health['timezone'] = await TodayFeedTimezoneService.getTimezoneStats();

      // Add health-specific aggregation info
      health['health_summary'] = await _generateHealthSummary(health);
      health['aggregation_info'] = _getAggregationMetadata();

      return health;
    } catch (e) {
      debugPrint('❌ Failed to aggregate health metrics: $e');
      return {
        'error': e.toString(),
        'aggregation_info': _getAggregationMetadata(),
      };
    }
  }

  /// Get performance metrics from all services
  ///
  /// Collects performance-related metrics from cache and statistics services
  /// to provide comprehensive performance analysis and bottleneck identification.
  static Future<Map<String, dynamic>> getAllPerformanceMetrics({
    Map<String, dynamic>? cacheMetadata,
  }) async {
    try {
      final performance = <String, dynamic>{};

      // Use provided metadata or fetch fresh data
      final metadata = cacheMetadata ?? await _getCacheMetadata();

      // Aggregate performance metrics from relevant services
      performance['cache'] = metadata;
      performance['performance'] =
          await TodayFeedCachePerformanceService.getDetailedPerformanceStatistics();
      performance['statistics'] =
          await TodayFeedCacheStatisticsService.getCacheStatistics(metadata);

      // Add performance-specific analysis
      performance['performance_summary'] = await _generatePerformanceSummary(
        performance,
      );
      performance['aggregation_info'] = _getAggregationMetadata();

      return performance;
    } catch (e) {
      debugPrint('❌ Failed to aggregate performance metrics: $e');
      return {
        'error': e.toString(),
        'aggregation_info': _getAggregationMetadata(),
      };
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 2: ADVANCED ANALYTICS & MONITORING
  // ═══════════════════════════════════════════════════════════════════════════
  //
  // Enhanced analytics methods that provide deeper insights into system
  // performance, health trends, and optimization opportunities.

  /// Get comprehensive system health assessment
  ///
  /// Performs deep health analysis across all services with scoring,
  /// trend analysis, and actionable recommendations.
  static Future<Map<String, dynamic>> getSystemHealthAssessment() async {
    try {
      final healthMetrics = await getAllHealthMetrics();
      final assessment = <String, dynamic>{};

      // Calculate overall health score
      assessment['overall_score'] = await _calculateOverallHealthScore(
        healthMetrics,
      );

      // Generate health insights
      assessment['insights'] = await _generateHealthInsights(healthMetrics);

      // Identify critical issues
      assessment['critical_issues'] = _identifyCriticalIssues(healthMetrics);

      // Performance impact on health
      assessment['performance_impact'] = _analyzePerformanceImpact(
        healthMetrics,
      );

      // Recommendations
      assessment['recommendations'] = _generateHealthRecommendations(
        healthMetrics,
      );

      // Trend analysis (if historical data available)
      assessment['trends'] = await _analyzeHealthTrends(healthMetrics);

      assessment['timestamp'] = DateTime.now().toIso8601String();
      assessment['environment'] = TodayFeedCacheConfiguration.environment.name;

      return assessment;
    } catch (e) {
      debugPrint('❌ Failed to generate health assessment: $e');
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Get performance analytics with bottleneck identification
  ///
  /// Provides detailed performance analysis including bottleneck detection,
  /// optimization opportunities, and performance trend analysis.
  static Future<Map<String, dynamic>> getPerformanceAnalytics() async {
    try {
      final performanceMetrics = await getAllPerformanceMetrics();
      final analytics = <String, dynamic>{};

      // Bottleneck analysis
      analytics['bottlenecks'] = _identifyPerformanceBottlenecks(
        performanceMetrics,
      );

      // Optimization opportunities
      analytics['optimizations'] = _identifyOptimizationOpportunities(
        performanceMetrics,
      );

      // Resource utilization analysis
      analytics['resource_utilization'] = _analyzeResourceUtilization(
        performanceMetrics,
      );

      // Performance trends
      analytics['trends'] = await _analyzePerformanceTrends(performanceMetrics);

      // Efficiency metrics
      analytics['efficiency'] = _calculateEfficiencyMetrics(performanceMetrics);

      analytics['timestamp'] = DateTime.now().toIso8601String();
      analytics['environment'] = TodayFeedCacheConfiguration.environment.name;

      return analytics;
    } catch (e) {
      debugPrint('❌ Failed to generate performance analytics: $e');
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Get filtered metrics based on service selection
  ///
  /// Allows filtering metrics to specific services for focused analysis.
  /// Supports custom service combinations and metric categories.
  static Future<Map<String, dynamic>> getFilteredMetrics(
    List<String> serviceFilters, {
    List<String>? metricCategories,
    bool includeAggregationInfo = true,
  }) async {
    try {
      final filteredMetrics = <String, dynamic>{};
      final availableServices = [
        'cache',
        'statistics',
        'health',
        'performance',
        'timezone',
        'sync',
      ];

      // Validate service filters
      final validFilters =
          serviceFilters
              .where((filter) => availableServices.contains(filter))
              .toList();

      if (validFilters.isEmpty) {
        throw ArgumentError(
          'No valid service filters provided. Available: $availableServices',
        );
      }

      // Get base metadata if cache is requested
      Map<String, dynamic>? metadata;
      Map<String, dynamic>? syncStatus;

      if (validFilters.contains('cache') || validFilters.contains('sync')) {
        metadata = await _getCacheMetadata();
        syncStatus = _getSyncStatus();
      }

      // Collect metrics from requested services
      for (final service in validFilters) {
        switch (service) {
          case 'cache':
            filteredMetrics['cache'] = metadata;
            break;
          case 'statistics':
            filteredMetrics['statistics'] =
                await TodayFeedCacheStatisticsService.getCacheStatistics(
                  metadata ?? {},
                );
            break;
          case 'health':
            filteredMetrics['health'] =
                await TodayFeedCacheHealthService.getCacheHealthStatus(
                  metadata ?? {},
                  syncStatus ?? {},
                );
            break;
          case 'performance':
            filteredMetrics['performance'] =
                await TodayFeedCachePerformanceService.getDetailedPerformanceStatistics();
            break;
          case 'timezone':
            filteredMetrics['timezone'] =
                await TodayFeedTimezoneService.getTimezoneStats();
            break;
          case 'sync':
            filteredMetrics['sync'] = syncStatus;
            break;
        }
      }

      // Filter by metric categories if specified
      if (metricCategories != null && metricCategories.isNotEmpty) {
        filteredMetrics.removeWhere(
          (key, value) => !metricCategories.contains(key),
        );
      }

      // Add metadata if requested
      if (includeAggregationInfo) {
        filteredMetrics['aggregation_info'] = _getAggregationMetadata();
        filteredMetrics['filter_info'] = {
          'requested_services': serviceFilters,
          'valid_services': validFilters,
          'metric_categories': metricCategories,
          'available_services': availableServices,
        };
      }

      return filteredMetrics;
    } catch (e) {
      debugPrint('❌ Failed to get filtered metrics: $e');
      return {'error': e.toString(), 'requested_filters': serviceFilters};
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 3: EXPORT & REPORTING CAPABILITIES
  // ═══════════════════════════════════════════════════════════════════════════
  //
  // Methods for exporting metrics in different formats and generating
  // customizable reports for monitoring systems and analytics platforms.

  /// Export metrics for external monitoring systems
  ///
  /// Provides metrics in format suitable for monitoring systems like
  /// Prometheus, Grafana, or custom analytics platforms.
  static Future<Map<String, dynamic>> exportMetricsForMonitoring({
    String format = 'json',
    List<String>? serviceFilters,
    bool includeTimestamps = true,
  }) async {
    try {
      final services =
          serviceFilters ??
          ['cache', 'statistics', 'health', 'performance', 'timezone', 'sync'];
      final metrics = await getFilteredMetrics(services);

      final export = <String, dynamic>{};

      // Format for monitoring system
      export['metrics'] = _formatForMonitoring(metrics, format);
      export['format'] = format;
      export['services_included'] = services;

      if (includeTimestamps) {
        export['exported_at'] = DateTime.now().toIso8601String();
        export['export_timestamp'] = DateTime.now().millisecondsSinceEpoch;
      }

      export['environment'] = TodayFeedCacheConfiguration.environment.name;
      export['version'] = TodayFeedCacheConfiguration.currentCacheVersion;

      return export;
    } catch (e) {
      debugPrint('❌ Failed to export metrics for monitoring: $e');
      return {'error': e.toString(), 'format': format};
    }
  }

  /// Generate comprehensive system report
  ///
  /// Creates detailed report combining all metrics with analysis,
  /// recommendations, and executive summary.
  static Future<Map<String, dynamic>> generateSystemReport({
    bool includeHealthAssessment = true,
    bool includePerformanceAnalytics = true,
    bool includeRecommendations = true,
  }) async {
    try {
      final report = <String, dynamic>{};

      // Executive summary
      report['executive_summary'] = await _generateExecutiveSummary();

      // Complete metrics
      report['complete_metrics'] = await getAllStatistics();

      // Health assessment
      if (includeHealthAssessment) {
        report['health_assessment'] = await getSystemHealthAssessment();
      }

      // Performance analytics
      if (includePerformanceAnalytics) {
        report['performance_analytics'] = await getPerformanceAnalytics();
      }

      // System recommendations
      if (includeRecommendations) {
        report['recommendations'] = await _generateSystemRecommendations();
      }

      // Report metadata
      report['report_info'] = {
        'generated_at': DateTime.now().toIso8601String(),
        'environment': TodayFeedCacheConfiguration.environment.name,
        'version': TodayFeedCacheConfiguration.currentCacheVersion,
        'includes_health': includeHealthAssessment,
        'includes_performance': includePerformanceAnalytics,
        'includes_recommendations': includeRecommendations,
      };

      return report;
    } catch (e) {
      debugPrint('❌ Failed to generate system report: $e');
      return {
        'error': e.toString(),
        'generated_at': DateTime.now().toIso8601String(),
      };
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 4: HELPER METHODS & UTILITIES
  // ═══════════════════════════════════════════════════════════════════════════
  //
  // Private helper methods for metrics collection, analysis, and processing.
  // These methods support the main aggregation functionality.

  /// Get cache metadata for debugging and monitoring
  static Future<Map<String, dynamic>> _getCacheMetadata() async {
    try {
      final cacheSize =
          await TodayFeedCacheMaintenanceService.calculateCacheSize();
      final timezoneInfo = TodayFeedTimezoneService.getCurrentTimezoneInfo();
      final contentMetadata =
          await TodayFeedContentService.getContentMetadata();

      return {
        ...contentMetadata,
        'cache_size_bytes': cacheSize,
        'cache_size_kb': (cacheSize / 1024).toStringAsFixed(1),
        'timezone_info': timezoneInfo,
        'cache_version': TodayFeedCacheConfiguration.currentCacheVersion,
      };
    } catch (e) {
      debugPrint('❌ Failed to get cache metadata: $e');
      return {'error': e.toString()};
    }
  }

  /// Get sync status for debugging and monitoring
  static Map<String, dynamic> _getSyncStatus() {
    return {
      'has_sync_service': true,
      'sync_configuration': TodayFeedCacheConfiguration.environment.name,
      'sync_timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Get aggregation metadata
  static Map<String, dynamic> _getAggregationMetadata() {
    return {
      'aggregated_at': DateTime.now().toIso8601String(),
      'aggregator_version': '1.0.0',
      'environment': TodayFeedCacheConfiguration.environment.name,
      'services_included': [
        'cache',
        'statistics',
        'health',
        'performance',
        'timezone',
        'sync',
      ],
    };
  }

  /// Generate health summary from health metrics
  static Future<Map<String, dynamic>> _generateHealthSummary(
    Map<String, dynamic> healthMetrics,
  ) async {
    try {
      final health = healthMetrics['health'] as Map<String, dynamic>? ?? {};
      final performance =
          healthMetrics['performance'] as Map<String, dynamic>? ?? {};

      return {
        'overall_status': health['status'] ?? 'unknown',
        'health_score': health['health_score'] ?? 0.0,
        'performance_impact': performance['impact_on_health'] ?? 'minimal',
        'critical_metrics': _extractCriticalMetrics(healthMetrics),
        'summary_generated_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Failed to generate health summary: $e');
      return {'error': e.toString()};
    }
  }

  /// Generate performance summary from performance metrics
  static Future<Map<String, dynamic>> _generatePerformanceSummary(
    Map<String, dynamic> performanceMetrics,
  ) async {
    try {
      final performance =
          performanceMetrics['performance'] as Map<String, dynamic>? ?? {};
      final cache = performanceMetrics['cache'] as Map<String, dynamic>? ?? {};

      return {
        'efficiency_score': performance['efficiency_score'] ?? 0.0,
        'cache_utilization': cache['cache_size_kb'] ?? '0.0',
        'optimization_opportunities': _identifyQuickOptimizations(
          performanceMetrics,
        ),
        'performance_trends':
            'stable', // Could be enhanced with historical data
        'summary_generated_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Failed to generate performance summary: $e');
      return {'error': e.toString()};
    }
  }

  /// Calculate overall health score
  static Future<double> _calculateOverallHealthScore(
    Map<String, dynamic> healthMetrics,
  ) async {
    try {
      final health = healthMetrics['health'] as Map<String, dynamic>? ?? {};
      final performance =
          healthMetrics['performance'] as Map<String, dynamic>? ?? {};

      // Use existing health score or calculate basic score
      final healthScore = (health['health_score'] as num?)?.toDouble() ?? 0.75;
      final performanceScore =
          (performance['efficiency_score'] as num?)?.toDouble() ?? 0.8;

      // Weighted average (health 60%, performance 40%)
      return (healthScore * 0.6) + (performanceScore * 0.4);
    } catch (e) {
      debugPrint('❌ Failed to calculate overall health score: $e');
      return 0.5; // Neutral score on error
    }
  }

  /// Generate health insights
  static Future<List<String>> _generateHealthInsights(
    Map<String, dynamic> healthMetrics,
  ) async {
    final insights = <String>[];

    try {
      final health = healthMetrics['health'] as Map<String, dynamic>? ?? {};
      final performance =
          healthMetrics['performance'] as Map<String, dynamic>? ?? {};
      final cache = healthMetrics['cache'] as Map<String, dynamic>? ?? {};

      // Analyze health status
      final status = health['status'] as String? ?? 'unknown';
      if (status == 'healthy') {
        insights.add('System is operating normally with good health metrics');
      } else if (status == 'warning') {
        insights.add('System shows warning signs that may require attention');
      } else if (status == 'critical') {
        insights.add(
          'System has critical issues requiring immediate attention',
        );
      }

      // Analyze cache size
      final cacheSizeKb =
          double.tryParse(cache['cache_size_kb']?.toString() ?? '0') ?? 0.0;
      if (cacheSizeKb > 1000) {
        insights.add(
          'Cache size is large (${cacheSizeKb.toStringAsFixed(1)}KB) - consider cleanup',
        );
      } else if (cacheSizeKb < 10) {
        insights.add(
          'Cache size is very small - system may benefit from warming',
        );
      }

      // Performance insights
      final efficiencyScore =
          (performance['efficiency_score'] as num?)?.toDouble() ?? 0.8;
      if (efficiencyScore < 0.6) {
        insights.add('Performance efficiency is below optimal levels');
      } else if (efficiencyScore > 0.9) {
        insights.add('System is performing efficiently with excellent metrics');
      }
    } catch (e) {
      debugPrint('❌ Failed to generate health insights: $e');
      insights.add(
        'Unable to generate detailed insights due to data processing error',
      );
    }

    return insights.isEmpty
        ? ['System metrics collected successfully']
        : insights;
  }

  /// Identify critical issues
  static List<String> _identifyCriticalIssues(
    Map<String, dynamic> healthMetrics,
  ) {
    final issues = <String>[];

    try {
      final health = healthMetrics['health'] as Map<String, dynamic>? ?? {};
      final status = health['status'] as String? ?? 'unknown';

      if (status == 'critical') {
        issues.add('Critical health status detected');
      }

      if (healthMetrics.containsKey('error')) {
        issues.add('Error in health metrics collection');
      }
    } catch (e) {
      debugPrint('❌ Failed to identify critical issues: $e');
      issues.add('Unable to analyze critical issues');
    }

    return issues;
  }

  /// Analyze performance impact on health
  static Map<String, dynamic> _analyzePerformanceImpact(
    Map<String, dynamic> healthMetrics,
  ) {
    try {
      final performance =
          healthMetrics['performance'] as Map<String, dynamic>? ?? {};
      final efficiencyScore =
          (performance['efficiency_score'] as num?)?.toDouble() ?? 0.8;

      String impact;
      if (efficiencyScore > 0.8) {
        impact = 'positive';
      } else if (efficiencyScore > 0.6) {
        impact = 'neutral';
      } else {
        impact = 'negative';
      }

      return {
        'impact_level': impact,
        'efficiency_score': efficiencyScore,
        'analysis':
            'Performance efficiency is $impact for overall system health',
      };
    } catch (e) {
      debugPrint('❌ Failed to analyze performance impact: $e');
      return {'impact_level': 'unknown', 'error': e.toString()};
    }
  }

  /// Generate health recommendations
  static List<String> _generateHealthRecommendations(
    Map<String, dynamic> healthMetrics,
  ) {
    final recommendations = <String>[];

    try {
      final health = healthMetrics['health'] as Map<String, dynamic>? ?? {};
      final performance =
          healthMetrics['performance'] as Map<String, dynamic>? ?? {};
      final cache = healthMetrics['cache'] as Map<String, dynamic>? ?? {};

      // Health-based recommendations
      final status = health['status'] as String? ?? 'unknown';
      if (status != 'healthy') {
        recommendations.add(
          'Monitor health status and investigate warning indicators',
        );
      }

      // Performance-based recommendations
      final efficiencyScore =
          (performance['efficiency_score'] as num?)?.toDouble() ?? 0.8;
      if (efficiencyScore < 0.7) {
        recommendations.add(
          'Consider performance optimization to improve efficiency',
        );
      }

      // Cache-based recommendations
      final cacheSizeKb =
          double.tryParse(cache['cache_size_kb']?.toString() ?? '0') ?? 0.0;
      if (cacheSizeKb > 1000) {
        recommendations.add('Schedule cache cleanup to reduce memory usage');
      }

      if (recommendations.isEmpty) {
        recommendations.add(
          'System is performing well - continue regular monitoring',
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to generate health recommendations: $e');
      recommendations.add('Unable to generate specific recommendations');
    }

    return recommendations;
  }

  /// Analyze health trends (placeholder for future enhancement)
  static Future<Map<String, dynamic>> _analyzeHealthTrends(
    Map<String, dynamic> healthMetrics,
  ) async {
    return {
      'trend_analysis': 'stable',
      'note': 'Historical trend analysis requires historical data collection',
      'current_status': healthMetrics['health']?['status'] ?? 'unknown',
    };
  }

  /// Identify performance bottlenecks
  static List<String> _identifyPerformanceBottlenecks(
    Map<String, dynamic> performanceMetrics,
  ) {
    final bottlenecks = <String>[];

    try {
      final cache = performanceMetrics['cache'] as Map<String, dynamic>? ?? {};
      final performance =
          performanceMetrics['performance'] as Map<String, dynamic>? ?? {};

      // Cache size bottleneck
      final cacheSizeKb =
          double.tryParse(cache['cache_size_kb']?.toString() ?? '0') ?? 0.0;
      if (cacheSizeKb > 1000) {
        bottlenecks.add('Large cache size may impact memory performance');
      }

      // Efficiency bottleneck
      final efficiencyScore =
          (performance['efficiency_score'] as num?)?.toDouble() ?? 0.8;
      if (efficiencyScore < 0.6) {
        bottlenecks.add(
          'Low efficiency score indicates performance optimization needed',
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to identify performance bottlenecks: $e');
      bottlenecks.add('Unable to analyze performance bottlenecks');
    }

    return bottlenecks.isEmpty
        ? ['No significant performance bottlenecks identified']
        : bottlenecks;
  }

  /// Identify optimization opportunities
  static List<String> _identifyOptimizationOpportunities(
    Map<String, dynamic> performanceMetrics,
  ) {
    final opportunities = <String>[];

    try {
      final cache = performanceMetrics['cache'] as Map<String, dynamic>? ?? {};
      final statistics =
          performanceMetrics['statistics'] as Map<String, dynamic>? ?? {};

      // Cache optimization
      final cacheSizeKb =
          double.tryParse(cache['cache_size_kb']?.toString() ?? '0') ?? 0.0;
      if (cacheSizeKb < 10) {
        opportunities.add(
          'Implement cache warming strategies for better performance',
        );
      } else if (cacheSizeKb > 500) {
        opportunities.add(
          'Implement selective cache cleanup for memory optimization',
        );
      }

      // Statistics-based optimization
      if (statistics.isNotEmpty) {
        opportunities.add(
          'Leverage statistics data for predictive optimization',
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to identify optimization opportunities: $e');
      opportunities.add('Unable to analyze optimization opportunities');
    }

    return opportunities.isEmpty
        ? ['System is well-optimized - monitor for future opportunities']
        : opportunities;
  }

  /// Analyze resource utilization
  static Map<String, dynamic> _analyzeResourceUtilization(
    Map<String, dynamic> performanceMetrics,
  ) {
    try {
      final cache = performanceMetrics['cache'] as Map<String, dynamic>? ?? {};
      final cacheSizeKb =
          double.tryParse(cache['cache_size_kb']?.toString() ?? '0') ?? 0.0;

      // Calculate utilization percentages (basic implementation)
      final maxCacheSizeKb =
          TodayFeedCacheConfiguration.maxCacheSizeBytes / 1024;
      final utilizationPercent = (cacheSizeKb / maxCacheSizeKb * 100).clamp(
        0.0,
        100.0,
      );

      String utilizationLevel;
      if (utilizationPercent > 80) {
        utilizationLevel = 'high';
      } else if (utilizationPercent > 40) {
        utilizationLevel = 'moderate';
      } else {
        utilizationLevel = 'low';
      }

      return {
        'cache_utilization_percent': utilizationPercent.toStringAsFixed(1),
        'cache_utilization_level': utilizationLevel,
        'cache_size_kb': cacheSizeKb.toStringAsFixed(1),
        'max_cache_size_kb': (maxCacheSizeKb).toStringAsFixed(1),
      };
    } catch (e) {
      debugPrint('❌ Failed to analyze resource utilization: $e');
      return {'error': e.toString()};
    }
  }

  /// Analyze performance trends (placeholder for future enhancement)
  static Future<Map<String, dynamic>> _analyzePerformanceTrends(
    Map<String, dynamic> performanceMetrics,
  ) async {
    return {
      'trend_analysis': 'stable',
      'note': 'Historical trend analysis requires historical data collection',
      'current_efficiency':
          performanceMetrics['performance']?['efficiency_score'] ?? 0.8,
    };
  }

  /// Calculate efficiency metrics
  static Map<String, dynamic> _calculateEfficiencyMetrics(
    Map<String, dynamic> performanceMetrics,
  ) {
    try {
      final performance =
          performanceMetrics['performance'] as Map<String, dynamic>? ?? {};
      final cache = performanceMetrics['cache'] as Map<String, dynamic>? ?? {};

      final efficiencyScore =
          (performance['efficiency_score'] as num?)?.toDouble() ?? 0.8;
      final cacheSizeKb =
          double.tryParse(cache['cache_size_kb']?.toString() ?? '0') ?? 0.0;

      // Calculate additional efficiency metrics
      final dataEfficiency =
          cacheSizeKb > 0 ? (efficiencyScore * 100) / cacheSizeKb : 0.0;

      return {
        'overall_efficiency': efficiencyScore,
        'data_efficiency_ratio': dataEfficiency.toStringAsFixed(2),
        'cache_efficiency': cacheSizeKb > 0 ? 'active' : 'minimal',
        'efficiency_grade': _getEfficiencyGrade(efficiencyScore),
      };
    } catch (e) {
      debugPrint('❌ Failed to calculate efficiency metrics: $e');
      return {'error': e.toString()};
    }
  }

  /// Format metrics for monitoring systems
  static Map<String, dynamic> _formatForMonitoring(
    Map<String, dynamic> metrics,
    String format,
  ) {
    // Basic formatting - could be enhanced for specific monitoring systems
    switch (format.toLowerCase()) {
      case 'prometheus':
        return _formatForPrometheus(metrics);
      case 'json':
      default:
        return metrics;
    }
  }

  /// Format metrics for Prometheus (basic implementation)
  static Map<String, dynamic> _formatForPrometheus(
    Map<String, dynamic> metrics,
  ) {
    final formatted = <String, dynamic>{};

    try {
      // Extract key numeric metrics for Prometheus
      final health = metrics['health'] as Map<String, dynamic>? ?? {};
      final performance = metrics['performance'] as Map<String, dynamic>? ?? {};
      final cache = metrics['cache'] as Map<String, dynamic>? ?? {};

      formatted['today_feed_cache_health_score'] =
          health['health_score'] ?? 0.0;
      formatted['today_feed_cache_efficiency_score'] =
          performance['efficiency_score'] ?? 0.0;
      formatted['today_feed_cache_size_kb'] =
          double.tryParse(cache['cache_size_kb']?.toString() ?? '0') ?? 0.0;
      formatted['today_feed_cache_version'] = cache['cache_version'] ?? 0;
    } catch (e) {
      debugPrint('❌ Failed to format for Prometheus: $e');
      formatted['error'] = 1;
    }

    return formatted;
  }

  /// Generate executive summary
  static Future<Map<String, dynamic>> _generateExecutiveSummary() async {
    try {
      final healthMetrics = await getAllHealthMetrics();
      final performanceMetrics = await getAllPerformanceMetrics();

      final health = healthMetrics['health'] as Map<String, dynamic>? ?? {};
      final performance =
          performanceMetrics['performance'] as Map<String, dynamic>? ?? {};

      return {
        'system_status': health['status'] ?? 'unknown',
        'health_score': await _calculateOverallHealthScore(healthMetrics),
        'efficiency_score': performance['efficiency_score'] ?? 0.8,
        'key_insights': await _generateHealthInsights(healthMetrics),
        'critical_issues_count': _identifyCriticalIssues(healthMetrics).length,
        'optimization_opportunities_count':
            _identifyOptimizationOpportunities(performanceMetrics).length,
        'environment': TodayFeedCacheConfiguration.environment.name,
        'summary_generated_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Failed to generate executive summary: $e');
      return {
        'error': e.toString(),
        'summary_generated_at': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Generate system recommendations
  static Future<List<String>> _generateSystemRecommendations() async {
    try {
      final healthMetrics = await getAllHealthMetrics();
      final performanceMetrics = await getAllPerformanceMetrics();

      final recommendations = <String>[];

      // Combine health and performance recommendations
      recommendations.addAll(_generateHealthRecommendations(healthMetrics));
      recommendations.addAll(
        _identifyOptimizationOpportunities(performanceMetrics),
      );

      // Add environment-specific recommendations
      if (TodayFeedCacheConfiguration.isTestEnvironment) {
        recommendations.add(
          'Consider enabling full monitoring for production environment',
        );
      }

      return recommendations.toSet().toList(); // Remove duplicates
    } catch (e) {
      debugPrint('❌ Failed to generate system recommendations: $e');
      return [
        'Unable to generate specific recommendations due to analysis error',
      ];
    }
  }

  /// Extract critical metrics for summary
  static List<String> _extractCriticalMetrics(
    Map<String, dynamic> healthMetrics,
  ) {
    final criticalMetrics = <String>[];

    try {
      final health = healthMetrics['health'] as Map<String, dynamic>? ?? {};
      final cache = healthMetrics['cache'] as Map<String, dynamic>? ?? {};

      criticalMetrics.add('Health Status: ${health['status'] ?? 'unknown'}');
      criticalMetrics.add('Cache Size: ${cache['cache_size_kb'] ?? '0'}KB');

      if (health['health_score'] != null) {
        criticalMetrics.add(
          'Health Score: ${(health['health_score'] as num).toStringAsFixed(2)}',
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to extract critical metrics: $e');
      criticalMetrics.add('Unable to extract critical metrics');
    }

    return criticalMetrics;
  }

  /// Identify quick optimization opportunities
  static List<String> _identifyQuickOptimizations(
    Map<String, dynamic> performanceMetrics,
  ) {
    final optimizations = <String>[];

    try {
      final cache = performanceMetrics['cache'] as Map<String, dynamic>? ?? {};
      final cacheSizeKb =
          double.tryParse(cache['cache_size_kb']?.toString() ?? '0') ?? 0.0;

      if (cacheSizeKb > 500) {
        optimizations.add('Cache cleanup');
      }

      if (cacheSizeKb < 10) {
        optimizations.add('Cache warming');
      }
    } catch (e) {
      debugPrint('❌ Failed to identify quick optimizations: $e');
      optimizations.add('Unable to identify optimizations');
    }

    return optimizations;
  }

  /// Get efficiency grade based on score
  static String _getEfficiencyGrade(double score) {
    if (score >= 0.9) return 'A';
    if (score >= 0.8) return 'B';
    if (score >= 0.7) return 'C';
    if (score >= 0.6) return 'D';
    return 'F';
  }
}
