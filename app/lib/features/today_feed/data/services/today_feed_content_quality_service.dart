import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/models/today_feed_content.dart';
import 'today_feed_content_quality_models.dart';
import 'today_feed_content_validator.dart';
import 'today_feed_safety_monitor.dart';
import 'today_feed_quality_alert_manager.dart';
import 'today_feed_quality_metrics_calculator.dart';

/// Main content quality validation and safety monitoring service for Today Feed
/// Implements Epic 1.3 Task T1.3.5.9 requirements by orchestrating modular components
///
/// This service coordinates:
/// - Content validation (format, readability, engagement)
/// - Safety monitoring (medical safety, appropriateness, misinformation)
/// - Alert generation and management
/// - Quality metrics calculation and trending
class TodayFeedContentQualityService {
  // Quality thresholds and configuration
  static const double _minSafetyScore = 0.8;
  static const double _minOverallQualityScore = 0.7;

  static bool _isInitialized = false;

  /// Initialize the content quality service and all components
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize all modular components
      await TodayFeedQualityAlertManager.initialize();
      await TodayFeedQualityMetricsCalculator.initialize();

      _isInitialized = true;
      debugPrint('✅ TodayFeedContentQualityService initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize TodayFeedContentQualityService: $e');
      rethrow;
    }
  }

  /// Alert stream for real-time quality notifications
  static Stream<QualityAlert> get alertStream {
    return TodayFeedQualityAlertManager.alertStream;
  }

  /// Validate content quality comprehensively using modular components
  static Future<QualityValidationResult> validateContentQuality(
    TodayFeedContent content,
  ) async {
    if (!_isInitialized) {
      throw StateError('TodayFeedContentQualityService not initialized');
    }

    try {
      // Step 1: Content validation (format, readability, engagement)
      final validationSummary = TodayFeedContentValidator.validateContent(
        content,
      );

      // Step 2: Safety monitoring
      final safetyResult = await TodayFeedSafetyMonitor.validateContentSafety(
        content,
      );

      // Step 3: Calculate overall quality score
      final overallScore = _calculateOverallQualityScore(
        formatScore: validationSummary.formatResult.formatScore,
        safetyScore: safetyResult.safetyScore,
        readabilityScore: validationSummary.readabilityScore,
        engagementScore: validationSummary.engagementScore,
        confidenceScore: content.aiConfidenceScore,
      );

      // Step 4: Determine if content requires review
      final requiresReview = _determineReviewRequirement(
        safetyScore: safetyResult.safetyScore,
        overallScore: overallScore,
        issues: validationSummary.issues,
        confidenceScore: content.aiConfidenceScore,
      );

      // Step 5: Create comprehensive validation result
      final result = QualityValidationResult(
        contentId: content.id.toString(),
        isValid:
            validationSummary.issues.isEmpty &&
            overallScore >= _minOverallQualityScore,
        overallQualityScore: overallScore,
        safetyScore: safetyResult.safetyScore,
        readabilityScore: validationSummary.readabilityScore,
        engagementScore: validationSummary.engagementScore,
        confidenceScore: content.aiConfidenceScore,
        issues: [...validationSummary.issues, ...safetyResult.issues],
        warnings: [...validationSummary.warnings, ...safetyResult.warnings],
        requiresReview: requiresReview,
        validatedAt: DateTime.now(),
        recommendations: _generateComprehensiveRecommendations(
          validationSummary,
          safetyResult,
          overallScore,
        ),
      );

      // Step 6: Record validation history for metrics
      await TodayFeedQualityMetricsCalculator.recordValidationHistory(result);

      // Step 7: Generate alerts if necessary
      await TodayFeedQualityAlertManager.generateQualityAlerts(result, content);

      return result;
    } catch (e) {
      debugPrint('❌ Content quality validation failed: $e');
      return QualityValidationResult.error(
        contentId: content.id.toString(),
        errorMessage: e.toString(),
      );
    }
  }

  /// Monitor content safety in real-time using safety monitor
  static Future<SafetyMonitoringResult> monitorContentSafety(
    TodayFeedContent content,
  ) async {
    if (!_isInitialized) {
      throw StateError('TodayFeedContentQualityService not initialized');
    }

    try {
      // Delegate to specialized safety monitor
      final result = TodayFeedSafetyMonitor.monitorContentSafety(content);

      // Generate safety alerts if needed
      await TodayFeedQualityAlertManager.generateSafetyAlerts(result, content);

      return result;
    } catch (e) {
      debugPrint('❌ Content safety monitoring failed: $e');
      return SafetyMonitoringResult.error(
        contentId: content.id.toString(),
        errorMessage: e.toString(),
      );
    }
  }

  /// Get real-time quality metrics
  static Future<QualityMetrics> getQualityMetrics() async {
    if (!_isInitialized) {
      throw StateError('TodayFeedContentQualityService not initialized');
    }

    return TodayFeedQualityMetricsCalculator.getQualityMetrics();
  }

  /// Get detailed quality analytics
  static Future<QualityAnalytics> getQualityAnalytics() async {
    if (!_isInitialized) {
      throw StateError('TodayFeedContentQualityService not initialized');
    }

    return TodayFeedQualityMetricsCalculator.getQualityAnalytics();
  }

  /// Get stored quality alerts with optional filtering
  static Future<List<QualityAlert>> getQualityAlerts({
    AlertSeverity? severity,
    AlertType? type,
    bool? resolved,
    String? contentId,
  }) async {
    if (!_isInitialized) {
      throw StateError('TodayFeedContentQualityService not initialized');
    }

    return TodayFeedQualityAlertManager.getQualityAlerts(
      severity: severity,
      type: type,
      resolved: resolved,
      contentId: contentId,
    );
  }

  /// Get alerts summary for dashboard
  static Future<AlertsSummary> getAlertsSummary() async {
    if (!_isInitialized) {
      throw StateError('TodayFeedContentQualityService not initialized');
    }

    return TodayFeedQualityAlertManager.getAlertsSummary();
  }

  /// Resolve a quality alert
  static Future<bool> resolveAlert(String alertId) async {
    if (!_isInitialized) {
      throw StateError('TodayFeedContentQualityService not initialized');
    }

    return TodayFeedQualityAlertManager.resolveAlert(alertId);
  }

  /// Bulk resolve alerts by criteria
  static Future<int> bulkResolveAlerts({
    AlertSeverity? severity,
    AlertType? type,
    String? contentId,
  }) async {
    if (!_isInitialized) {
      throw StateError('TodayFeedContentQualityService not initialized');
    }

    return TodayFeedQualityAlertManager.bulkResolveAlerts(
      severity: severity,
      type: type,
      contentId: contentId,
    );
  }

  /// Get validation history
  static Future<List<QualityValidationResult>> getValidationHistory({
    int? limit,
    DateTime? since,
  }) async {
    if (!_isInitialized) {
      throw StateError('TodayFeedContentQualityService not initialized');
    }

    return TodayFeedQualityMetricsCalculator.getValidationHistory(
      limit: limit,
      since: since,
    );
  }

  /// Generate safety summary for content
  static SafetySummary generateSafetySummary(SafetyMonitoringResult result) {
    return TodayFeedSafetyMonitor.generateSafetySummary(result);
  }

  /// Check if content requires immediate review based on safety
  static bool requiresImmediateReview(SafetyMonitoringResult result) {
    return TodayFeedSafetyMonitor.requiresImmediateReview(result);
  }

  /// Clear validation cache and history
  static Future<void> clearCache() async {
    if (!_isInitialized) {
      throw StateError('TodayFeedContentQualityService not initialized');
    }

    await TodayFeedQualityMetricsCalculator.clearValidationHistory();
    debugPrint('🧹 Content quality cache cleared');
  }

  /// Clear old resolved alerts
  static Future<int> clearOldAlerts({Duration? olderThan}) async {
    if (!_isInitialized) {
      throw StateError('TodayFeedContentQualityService not initialized');
    }

    return TodayFeedQualityAlertManager.clearOldAlerts(olderThan: olderThan);
  }

  /// Perform comprehensive content analysis
  static Future<ContentAnalysisResult> analyzeContent(
    TodayFeedContent content,
  ) async {
    if (!_isInitialized) {
      throw StateError('TodayFeedContentQualityService not initialized');
    }

    try {
      // Parallel execution of validation and safety monitoring
      final validationFuture = validateContentQuality(content);
      final safetyFuture = monitorContentSafety(content);

      final results = await Future.wait([validationFuture, safetyFuture]);
      final validationResult = results[0] as QualityValidationResult;
      final safetyResult = results[1] as SafetyMonitoringResult;

      // Generate comprehensive analysis
      final safetySummary = generateSafetySummary(safetyResult);

      return ContentAnalysisResult(
        contentId: content.id.toString(),
        validationResult: validationResult,
        safetyResult: safetyResult,
        safetySummary: safetySummary,
        overallRecommendation: _generateOverallRecommendation(
          validationResult,
          safetyResult,
        ),
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Content analysis failed: $e');
      return ContentAnalysisResult.error(
        contentId: content.id.toString(),
        errorMessage: e.toString(),
      );
    }
  }

  /// Dispose of resources
  static Future<void> dispose() async {
    await TodayFeedQualityAlertManager.dispose();
    await TodayFeedQualityMetricsCalculator.dispose();
    _isInitialized = false;
    debugPrint('🧹 TodayFeedContentQualityService disposed');
  }

  // Private helper methods

  /// Calculate overall quality score with weighted factors
  static double _calculateOverallQualityScore({
    required double formatScore,
    required double safetyScore,
    required double readabilityScore,
    required double engagementScore,
    required double confidenceScore,
  }) {
    // Weighted scoring system prioritizing safety
    return (formatScore * 0.15) +
        (safetyScore * 0.35) +
        (readabilityScore * 0.20) +
        (engagementScore * 0.15) +
        (confidenceScore * 0.15);
  }

  /// Determine if content requires human review
  static bool _determineReviewRequirement({
    required double safetyScore,
    required double overallScore,
    required List<String> issues,
    required double confidenceScore,
  }) {
    // Require review if safety score is low
    if (safetyScore < _minSafetyScore) return true;

    // Require review if overall quality is low
    if (overallScore < _minOverallQualityScore) return true;

    // Require review if there are critical issues
    if (issues.isNotEmpty) return true;

    // Require review if AI confidence is very low
    if (confidenceScore < 0.5) return true;

    return false;
  }

  /// Generate comprehensive recommendations from all components
  static List<String> _generateComprehensiveRecommendations(
    ContentValidationSummary validationSummary,
    SafetyValidationResult safetyResult,
    double overallScore,
  ) {
    final recommendations = <String>[];

    // Add validation recommendations
    recommendations.addAll(validationSummary.recommendations);

    // Add safety recommendations
    recommendations.addAll(safetyResult.warnings);

    // Add overall quality recommendations
    if (overallScore < 0.5) {
      recommendations.add(
        'Content requires significant improvement before publication',
      );
    } else if (overallScore < _minOverallQualityScore) {
      recommendations.add(
        'Content needs minor improvements to meet quality standards',
      );
    } else if (overallScore >= 0.9) {
      recommendations.add('Excellent content quality - ready for publication');
    }

    // Remove duplicates and return unique recommendations
    return recommendations.toSet().toList();
  }

  /// Generate overall recommendation for content
  static String _generateOverallRecommendation(
    QualityValidationResult validationResult,
    SafetyMonitoringResult safetyResult,
  ) {
    if (!safetyResult.isPassed) {
      return 'REJECT - Content has safety issues that must be addressed';
    }

    if (!validationResult.isValid) {
      return 'REVIEW - Content has quality issues that should be addressed';
    }

    if (validationResult.overallQualityScore >= 0.8 &&
        safetyResult.safetyScore >= 0.9) {
      return 'APPROVE - Content meets high quality and safety standards';
    }

    return 'APPROVE - Content meets minimum quality and safety standards';
  }
}

/// Comprehensive content analysis result
@immutable
class ContentAnalysisResult {
  final String contentId;
  final QualityValidationResult validationResult;
  final SafetyMonitoringResult safetyResult;
  final SafetySummary safetySummary;
  final String overallRecommendation;
  final DateTime timestamp;
  final String? errorMessage;

  const ContentAnalysisResult({
    required this.contentId,
    required this.validationResult,
    required this.safetyResult,
    required this.safetySummary,
    required this.overallRecommendation,
    required this.timestamp,
    this.errorMessage,
  });

  factory ContentAnalysisResult.error({
    required String contentId,
    required String errorMessage,
  }) {
    final now = DateTime.now();
    return ContentAnalysisResult(
      contentId: contentId,
      validationResult: QualityValidationResult.error(
        contentId: contentId,
        errorMessage: errorMessage,
      ),
      safetyResult: SafetyMonitoringResult.error(
        contentId: contentId,
        errorMessage: errorMessage,
      ),
      safetySummary: const SafetySummary(
        riskLevel: SafetyRiskLevel.high,
        safetyScore: 0.0,
        totalChecks: 0,
        passedChecks: 0,
        riskFactorCount: 1,
        requiresReview: true,
        summary: 'Analysis failed due to error',
      ),
      overallRecommendation: 'ERROR - Unable to analyze content',
      timestamp: now,
      errorMessage: errorMessage,
    );
  }
}
