import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'today_feed_content_quality_models.dart';
import 'today_feed_quality_alert_manager.dart';

/// Quality metrics calculation service for Today Feed content
/// Part of the modular content quality system for Epic 1.3 Task T1.3.5.9
class TodayFeedQualityMetricsCalculator {
  static const String _validationHistoryKey = 'today_feed_validation_history';
  static const int _maxValidationHistory = 200;

  static SharedPreferences? _prefs;
  static bool _isInitialized = false;

  /// Initialize the metrics calculator
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;

      debugPrint('✅ TodayFeedQualityMetricsCalculator initialized');
    } catch (e) {
      debugPrint(
        '❌ Failed to initialize TodayFeedQualityMetricsCalculator: $e',
      );
      rethrow;
    }
  }

  /// Record validation result for metrics calculation
  static Future<void> recordValidationHistory(
    QualityValidationResult result,
  ) async {
    if (!_isInitialized) {
      throw StateError('TodayFeedQualityMetricsCalculator not initialized');
    }

    try {
      final history = await _getValidationHistory();
      history.add(result);

      // Keep only recent history
      if (history.length > _maxValidationHistory) {
        history.removeRange(0, history.length - _maxValidationHistory);
      }

      final jsonList = history.map((h) => h.toJson()).toList();
      await _prefs!.setString(_validationHistoryKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('❌ Failed to record validation history: $e');
    }
  }

  /// Get comprehensive quality metrics
  static Future<QualityMetrics> getQualityMetrics() async {
    if (!_isInitialized) {
      throw StateError('TodayFeedQualityMetricsCalculator not initialized');
    }

    try {
      final validationHistory = await _getValidationHistory();
      final alertsSummary =
          await TodayFeedQualityAlertManager.getAlertsSummary();

      final now = DateTime.now();
      final dayAgo = now.subtract(const Duration(days: 1));
      final weekAgo = now.subtract(const Duration(days: 7));

      // Filter validations by time period
      final last24hValidations =
          validationHistory
              .where((v) => v.validatedAt.isAfter(dayAgo))
              .toList();

      final last7dValidations =
          validationHistory
              .where((v) => v.validatedAt.isAfter(weekAgo))
              .toList();

      // Calculate average scores
      final avgQualityScore = _calculateAverageScore(
        last24hValidations,
        (v) => v.overallQualityScore,
      );

      final avgSafetyScore = _calculateAverageScore(
        last24hValidations,
        (v) => v.safetyScore,
      );

      return QualityMetrics(
        timestamp: now,
        totalValidations: validationHistory.length,
        last24hValidations: last24hValidations.length,
        last7dValidations: last7dValidations.length,
        averageQualityScore: avgQualityScore,
        averageSafetyScore: avgSafetyScore,
        activeAlerts: alertsSummary.activeAlerts,
        criticalAlerts: alertsSummary.criticalAlerts,
        qualityTrend: _calculateQualityTrend(last7dValidations),
        safetyTrend: _calculateSafetyTrend(last7dValidations),
        recommendations: _generateSystemRecommendations(
          avgQualityScore,
          avgSafetyScore,
          alertsSummary,
        ),
      );
    } catch (e) {
      debugPrint('❌ Failed to get quality metrics: $e');
      return QualityMetrics.error(e.toString());
    }
  }

  /// Get detailed quality analytics
  static Future<QualityAnalytics> getQualityAnalytics() async {
    if (!_isInitialized) {
      throw StateError('TodayFeedQualityMetricsCalculator not initialized');
    }

    try {
      final validationHistory = await _getValidationHistory();
      final now = DateTime.now();

      // Time-based analysis
      final daily = _groupValidationsByDay(validationHistory, 7);
      final hourly = _groupValidationsByHour(validationHistory, 24);

      // Score distribution analysis
      final qualityDistribution = _calculateScoreDistribution(
        validationHistory,
        (v) => v.overallQualityScore,
      );

      final safetyDistribution = _calculateScoreDistribution(
        validationHistory,
        (v) => v.safetyScore,
      );

      // Performance metrics
      final performanceMetrics = _calculatePerformanceMetrics(
        validationHistory,
      );

      return QualityAnalytics(
        timestamp: now,
        dailyValidations: daily,
        hourlyValidations: hourly,
        qualityScoreDistribution: qualityDistribution,
        safetyScoreDistribution: safetyDistribution,
        performanceMetrics: performanceMetrics,
        issueAnalysis: _analyzeCommonIssues(validationHistory),
        trends: _calculateDetailedTrends(validationHistory),
      );
    } catch (e) {
      debugPrint('❌ Failed to get quality analytics: $e');
      return QualityAnalytics.error(e.toString());
    }
  }

  /// Get validation history
  static Future<List<QualityValidationResult>> getValidationHistory({
    int? limit,
    DateTime? since,
  }) async {
    if (!_isInitialized) {
      throw StateError('TodayFeedQualityMetricsCalculator not initialized');
    }

    try {
      var history = await _getValidationHistory();

      if (since != null) {
        history = history.where((v) => v.validatedAt.isAfter(since)).toList();
      }

      if (limit != null && history.length > limit) {
        history = history.take(limit).toList();
      }

      return history;
    } catch (e) {
      debugPrint('❌ Failed to get validation history: $e');
      return [];
    }
  }

  /// Clear validation history
  static Future<void> clearValidationHistory() async {
    if (!_isInitialized) {
      throw StateError('TodayFeedQualityMetricsCalculator not initialized');
    }

    try {
      await _prefs!.remove(_validationHistoryKey);
      debugPrint('🧹 Validation history cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear validation history: $e');
    }
  }

  /// Dispose of resources
  static Future<void> dispose() async {
    _isInitialized = false;
    debugPrint('🧹 TodayFeedQualityMetricsCalculator disposed');
  }

  // Private helper methods

  /// Get validation history from storage
  static Future<List<QualityValidationResult>> _getValidationHistory() async {
    try {
      final jsonString = _prefs!.getString(_validationHistoryKey);
      if (jsonString == null) return [];

      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((json) => QualityValidationResult.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to get validation history: $e');
      return [];
    }
  }

  /// Calculate average score from validations
  static double _calculateAverageScore(
    List<QualityValidationResult> validations,
    double Function(QualityValidationResult) scoreExtractor,
  ) {
    if (validations.isEmpty) return 0.0;

    final sum = validations.map(scoreExtractor).reduce((a, b) => a + b);

    return sum / validations.length;
  }

  /// Calculate quality trend from historical data
  static String _calculateQualityTrend(
    List<QualityValidationResult> validations,
  ) {
    if (validations.length < 2) return 'insufficient_data';

    final recent = validations.take(validations.length ~/ 2).toList();
    final older = validations.skip(validations.length ~/ 2).toList();

    final recentAvg = _calculateAverageScore(
      recent,
      (v) => v.overallQualityScore,
    );
    final olderAvg = _calculateAverageScore(
      older,
      (v) => v.overallQualityScore,
    );

    if (recentAvg > olderAvg + 0.1) return 'improving';
    if (recentAvg < olderAvg - 0.1) return 'declining';
    return 'stable';
  }

  /// Calculate safety trend from historical data
  static String _calculateSafetyTrend(
    List<QualityValidationResult> validations,
  ) {
    if (validations.length < 2) return 'insufficient_data';

    final recent = validations.take(validations.length ~/ 2).toList();
    final older = validations.skip(validations.length ~/ 2).toList();

    final recentAvg = _calculateAverageScore(recent, (v) => v.safetyScore);
    final olderAvg = _calculateAverageScore(older, (v) => v.safetyScore);

    if (recentAvg > olderAvg + 0.1) return 'improving';
    if (recentAvg < olderAvg - 0.1) return 'declining';
    return 'stable';
  }

  /// Generate system-level recommendations
  static List<String> _generateSystemRecommendations(
    double avgQualityScore,
    double avgSafetyScore,
    AlertsSummary alertsSummary,
  ) {
    final recommendations = <String>[];

    if (avgQualityScore < 0.7) {
      recommendations.add(
        'Review content generation parameters to improve quality',
      );
    }

    if (avgSafetyScore < 0.8) {
      recommendations.add('Strengthen safety validation in content pipeline');
    }

    if (alertsSummary.activeAlerts > 5) {
      recommendations.add(
        'High number of active alerts - consider system review',
      );
    }

    if (alertsSummary.criticalAlerts > 0) {
      recommendations.add('Critical alerts require immediate attention');
    }

    if (recommendations.isEmpty) {
      recommendations.add('Content quality system is performing well');
    }

    return recommendations;
  }

  /// Group validations by day
  static Map<String, int> _groupValidationsByDay(
    List<QualityValidationResult> validations,
    int days,
  ) {
    final result = <String, int>{};
    final now = DateTime.now();

    for (var i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final dayKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final count =
          validations
              .where(
                (v) =>
                    v.validatedAt.year == date.year &&
                    v.validatedAt.month == date.month &&
                    v.validatedAt.day == date.day,
              )
              .length;

      result[dayKey] = count;
    }

    return result;
  }

  /// Group validations by hour
  static Map<int, int> _groupValidationsByHour(
    List<QualityValidationResult> validations,
    int hours,
  ) {
    final result = <int, int>{};
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(hours: hours));

    final recentValidations =
        validations.where((v) => v.validatedAt.isAfter(cutoff)).toList();

    for (var i = 0; i < 24; i++) {
      final count =
          recentValidations.where((v) => v.validatedAt.hour == i).length;
      result[i] = count;
    }

    return result;
  }

  /// Calculate score distribution
  static Map<String, int> _calculateScoreDistribution(
    List<QualityValidationResult> validations,
    double Function(QualityValidationResult) scoreExtractor,
  ) {
    final result = <String, int>{
      '0.0-0.2': 0,
      '0.2-0.4': 0,
      '0.4-0.6': 0,
      '0.6-0.8': 0,
      '0.8-1.0': 0,
    };

    for (final validation in validations) {
      final score = scoreExtractor(validation);

      if (score < 0.2) {
        result['0.0-0.2'] = result['0.0-0.2']! + 1;
      } else if (score < 0.4) {
        result['0.2-0.4'] = result['0.2-0.4']! + 1;
      } else if (score < 0.6) {
        result['0.4-0.6'] = result['0.4-0.6']! + 1;
      } else if (score < 0.8) {
        result['0.6-0.8'] = result['0.6-0.8']! + 1;
      } else {
        result['0.8-1.0'] = result['0.8-1.0']! + 1;
      }
    }

    return result;
  }

  /// Calculate performance metrics
  static Map<String, double> _calculatePerformanceMetrics(
    List<QualityValidationResult> validations,
  ) {
    if (validations.isEmpty) {
      return {
        'pass_rate': 0.0,
        'review_rate': 0.0,
        'avg_quality': 0.0,
        'avg_safety': 0.0,
      };
    }

    final passCount = validations.where((v) => v.isValid).length;
    final reviewCount = validations.where((v) => v.requiresReview).length;

    return {
      'pass_rate': passCount / validations.length,
      'review_rate': reviewCount / validations.length,
      'avg_quality': _calculateAverageScore(
        validations,
        (v) => v.overallQualityScore,
      ),
      'avg_safety': _calculateAverageScore(validations, (v) => v.safetyScore),
    };
  }

  /// Analyze common issues
  static Map<String, int> _analyzeCommonIssues(
    List<QualityValidationResult> validations,
  ) {
    final issueCount = <String, int>{};

    for (final validation in validations) {
      for (final issue in validation.issues) {
        issueCount[issue] = (issueCount[issue] ?? 0) + 1;
      }
    }

    // Return top 10 issues
    final sortedIssues =
        issueCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedIssues.take(10));
  }

  /// Calculate detailed trends
  static Map<String, String> _calculateDetailedTrends(
    List<QualityValidationResult> validations,
  ) {
    return {
      'quality': _calculateQualityTrend(validations),
      'safety': _calculateSafetyTrend(validations),
      'validation_volume': _calculateVolumeTrend(validations),
    };
  }

  /// Calculate validation volume trend
  static String _calculateVolumeTrend(
    List<QualityValidationResult> validations,
  ) {
    if (validations.length < 7) return 'insufficient_data';

    final now = DateTime.now();
    final recentCount =
        validations
            .where(
              (v) =>
                  v.validatedAt.isAfter(now.subtract(const Duration(days: 3))),
            )
            .length;
    final olderCount =
        validations
            .where(
              (v) =>
                  v.validatedAt.isBefore(now.subtract(const Duration(days: 3))),
            )
            .length;

    if (recentCount > olderCount * 1.5) return 'increasing';
    if (recentCount < olderCount * 0.5) return 'decreasing';
    return 'stable';
  }
}

/// Detailed quality analytics data model
@immutable
class QualityAnalytics {
  final DateTime timestamp;
  final Map<String, int> dailyValidations;
  final Map<int, int> hourlyValidations;
  final Map<String, int> qualityScoreDistribution;
  final Map<String, int> safetyScoreDistribution;
  final Map<String, double> performanceMetrics;
  final Map<String, int> issueAnalysis;
  final Map<String, String> trends;
  final String? errorMessage;

  const QualityAnalytics({
    required this.timestamp,
    required this.dailyValidations,
    required this.hourlyValidations,
    required this.qualityScoreDistribution,
    required this.safetyScoreDistribution,
    required this.performanceMetrics,
    required this.issueAnalysis,
    required this.trends,
    this.errorMessage,
  });

  factory QualityAnalytics.error(String errorMessage) {
    return QualityAnalytics(
      timestamp: DateTime.now(),
      dailyValidations: const {},
      hourlyValidations: const {},
      qualityScoreDistribution: const {},
      safetyScoreDistribution: const {},
      performanceMetrics: const {},
      issueAnalysis: const {},
      trends: const {},
      errorMessage: errorMessage,
    );
  }
}
