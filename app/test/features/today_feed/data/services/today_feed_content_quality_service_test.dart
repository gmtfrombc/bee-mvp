import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/features/today_feed/data/services/today_feed_content_quality_service.dart';
import 'package:app/features/today_feed/data/services/today_feed_content_quality_models.dart';
import 'package:app/features/today_feed/domain/models/today_feed_content.dart';

void main() {
  group('TodayFeedContentQualityService Integration Tests', () {
    setUp(() async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});

      // Initialize the service
      await TodayFeedContentQualityService.initialize();
    });

    tearDown(() async {
      await TodayFeedContentQualityService.dispose();
    });

    group('Service Integration', () {
      test('should initialize all modular components successfully', () async {
        // Service should be initialized without errors
        expect(TodayFeedContentQualityService.alertStream, isNotNull);
      });

      test('should validate high-quality content correctly', () async {
        final content = _createHighQualityContent();

        final result =
            await TodayFeedContentQualityService.validateContentQuality(
              content,
            );

        expect(result.isValid, isTrue);
        expect(result.overallQualityScore, greaterThan(0.7));
        expect(result.safetyScore, greaterThan(0.8));
        expect(result.issues, isEmpty);
        expect(result.errorMessage, isNull);
      });

      test('should validate low-quality content correctly', () async {
        final content = _createLowQualityContent();

        final result =
            await TodayFeedContentQualityService.validateContentQuality(
              content,
            );

        // Low quality content with short title/summary may still be valid if no critical issues
        // but should have low scores and require review
        expect(result.overallQualityScore, lessThan(0.7));
        expect(result.requiresReview, isTrue);
        // Note: Content may still be technically "valid" if it meets basic format requirements
      });

      test('should detect unsafe content correctly', () async {
        final content = _createUnsafeContent();

        final result =
            await TodayFeedContentQualityService.validateContentQuality(
              content,
            );

        expect(result.safetyScore, lessThan(0.8));
        expect(result.requiresReview, isTrue);
        expect(result.issues, isNotEmpty);
      });

      test('should generate alerts for problematic content', () async {
        final content = _createUnsafeContent();

        // Listen for alerts - this could be either quality or safety alerts
        final alertsFuture =
            TodayFeedContentQualityService.alertStream.take(1).toList();

        await TodayFeedContentQualityService.validateContentQuality(content);

        final alerts = await alertsFuture.timeout(const Duration(seconds: 5));
        expect(alerts, isNotEmpty);
        // Accept either quality or safety alerts as both are valid for unsafe content
        expect(
          alerts.first.type,
          isIn([AlertType.qualityIssue, AlertType.safetyIssue]),
        );
      });

      test('should perform comprehensive content analysis', () async {
        final content = _createHighQualityContent();

        final analysis = await TodayFeedContentQualityService.analyzeContent(
          content,
        );

        expect(analysis.contentId, equals(content.id.toString()));
        expect(analysis.validationResult, isNotNull);
        expect(analysis.safetyResult, isNotNull);
        expect(analysis.safetySummary, isNotNull);
        expect(analysis.overallRecommendation, contains('APPROVE'));
        expect(analysis.errorMessage, isNull);
      });

      test('should track quality metrics over time', () async {
        // Validate multiple pieces of content
        final contents = [
          _createHighQualityContent(),
          _createLowQualityContent(),
          _createMediumQualityContent(),
        ];

        for (final content in contents) {
          await TodayFeedContentQualityService.validateContentQuality(content);
        }

        final metrics =
            await TodayFeedContentQualityService.getQualityMetrics();

        expect(metrics.totalValidations, greaterThanOrEqualTo(3));
        expect(metrics.averageQualityScore, greaterThan(0.0));
        expect(metrics.averageSafetyScore, greaterThan(0.0));
        expect(metrics.errorMessage, isNull);
      });

      test('should provide detailed analytics', () async {
        // Generate some validation history
        final content = _createHighQualityContent();
        await TodayFeedContentQualityService.validateContentQuality(content);

        final analytics =
            await TodayFeedContentQualityService.getQualityAnalytics();

        expect(analytics.performanceMetrics, isNotEmpty);
        expect(analytics.trends, isNotEmpty);
        expect(analytics.timestamp, isNotNull);
        expect(analytics.errorMessage, isNull);
      });

      test('should manage alerts correctly', () async {
        final content = _createUnsafeContent();

        // Generate alerts
        await TodayFeedContentQualityService.validateContentQuality(content);

        // Get alerts
        final alerts = await TodayFeedContentQualityService.getQualityAlerts();
        expect(alerts, isNotEmpty);

        // Get alerts summary
        final summary = await TodayFeedContentQualityService.getAlertsSummary();
        expect(summary.totalAlerts, greaterThan(0));

        // Resolve an alert
        if (alerts.isNotEmpty) {
          final resolved = await TodayFeedContentQualityService.resolveAlert(
            alerts.first.id,
          );
          expect(resolved, isTrue);
        }
      });

      test('should handle validation history correctly', () async {
        final content = _createHighQualityContent();

        // Generate validation history
        await TodayFeedContentQualityService.validateContentQuality(content);

        final history =
            await TodayFeedContentQualityService.getValidationHistory(
              limit: 10,
            );
        expect(history, isNotEmpty);
        expect(history.first.contentId, equals(content.id.toString()));
      });

      test('should generate appropriate safety summaries', () async {
        final content = _createUnsafeContent();

        final safetyResult =
            await TodayFeedContentQualityService.monitorContentSafety(content);
        final summary = TodayFeedContentQualityService.generateSafetySummary(
          safetyResult,
        );

        expect(summary.riskLevel, isNotNull);
        expect(summary.safetyScore, equals(safetyResult.safetyScore));
        expect(summary.requiresReview, isTrue);
        expect(summary.summary, isNotEmpty);
      });
    });

    group('Error Handling', () {
      test('should handle invalid content gracefully', () async {
        final content = _createInvalidContent();

        final result =
            await TodayFeedContentQualityService.validateContentQuality(
              content,
            );

        expect(result.isValid, isFalse);
        expect(result.issues, isNotEmpty);
      });

      test('should handle content analysis errors gracefully', () async {
        final content = _createInvalidContent();

        final analysis = await TodayFeedContentQualityService.analyzeContent(
          content,
        );

        expect(analysis.contentId, equals(content.id.toString()));
        // Empty content gets REVIEW recommendation since it's a quality issue, not safety
        expect(analysis.overallRecommendation, contains('REVIEW'));
      });
    });

    group('Performance', () {
      test('should validate content within reasonable time', () async {
        final content = _createHighQualityContent();

        final stopwatch = Stopwatch()..start();
        await TodayFeedContentQualityService.validateContentQuality(content);
        stopwatch.stop();

        // Should complete within 5 seconds
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      });

      test('should handle parallel validations correctly', () async {
        final contents = List.generate(5, (i) => _createHighQualityContent());

        final futures = contents.map(
          (content) =>
              TodayFeedContentQualityService.validateContentQuality(content),
        );

        final results = await Future.wait(futures);
        expect(results.length, equals(5));
        expect(results.every((r) => r.errorMessage == null), isTrue);
      });
    });

    group('Data Models', () {
      test('should create ContentAnalysisResult correctly', () {
        final result = ContentAnalysisResult.error(
          contentId: 'test',
          errorMessage: 'Test error',
        );

        expect(result.contentId, equals('test'));
        expect(result.errorMessage, equals('Test error'));
        expect(result.overallRecommendation, contains('ERROR'));
      });

      test('should handle QualityValidationResult correctly', () {
        final result = QualityValidationResult.error(
          contentId: 'test',
          errorMessage: 'Test error',
        );

        expect(result.contentId, equals('test'));
        expect(result.isValid, isFalse);
        expect(result.errorMessage, equals('Test error'));
      });
    });
  });
}

// Helper methods to create test content

TodayFeedContent _createHighQualityContent() {
  return TodayFeedContent(
    id: DateTime.now().millisecondsSinceEpoch,
    contentDate: DateTime.now(),
    title: 'How Simple Walking Can Improve Your Health',
    summary:
        'Research shows that regular walking may help improve cardiovascular health and mental wellbeing. Consider adding a daily walk to your routine.',
    topicCategory: HealthTopic.exercise,
    aiConfidenceScore: 0.85,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    hasUserEngaged: false,
    isCached: false,
  );
}

TodayFeedContent _createLowQualityContent() {
  return TodayFeedContent(
    id: DateTime.now().millisecondsSinceEpoch + 1,
    contentDate: DateTime.now(),
    title:
        'Bad Title That Is Way Too Long And Exceeds Sixty Characters Limit Making It Poor Quality',
    summary: 'Very short bad summary with no value or insight.',
    topicCategory: HealthTopic.lifestyle,
    aiConfidenceScore: 0.3,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    hasUserEngaged: false,
    isCached: false,
  );
}

TodayFeedContent _createMediumQualityContent() {
  return TodayFeedContent(
    id: DateTime.now().millisecondsSinceEpoch + 2,
    contentDate: DateTime.now(),
    title: 'Tips for Better Sleep',
    summary: 'Some tips for getting better sleep each night.',
    topicCategory: HealthTopic.sleep,
    aiConfidenceScore: 0.65,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    hasUserEngaged: false,
    isCached: false,
  );
}

TodayFeedContent _createUnsafeContent() {
  return TodayFeedContent(
    id: DateTime.now().millisecondsSinceEpoch + 3,
    contentDate: DateTime.now(),
    title: 'Cure Your Disease Instantly with This Secret Medicine',
    summary:
        'This dangerous medication will cure everything. You should take it immediately without consulting your doctor.',
    topicCategory: HealthTopic.prevention,
    aiConfidenceScore: 0.7,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    hasUserEngaged: false,
    isCached: false,
  );
}

TodayFeedContent _createInvalidContent() {
  return TodayFeedContent(
    id: DateTime.now().millisecondsSinceEpoch + 4,
    contentDate: DateTime.now(),
    title: '',
    summary: '',
    topicCategory: HealthTopic.lifestyle,
    aiConfidenceScore: 0.1,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    hasUserEngaged: false,
    isCached: false,
  );
}
