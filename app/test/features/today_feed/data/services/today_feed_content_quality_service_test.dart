import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/features/today_feed/data/services/today_feed_content_quality_service.dart';
import 'package:app/features/today_feed/domain/models/today_feed_content.dart';

void main() {
  group('TodayFeedContentQualityService Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      // Set test environment to skip database-dependent initialization
      TodayFeedContentQualityService.setTestEnvironment(true);
      await TodayFeedContentQualityService.initialize();
    });

    tearDown(() async {
      await TodayFeedContentQualityService.dispose();
    });

    test('should validate high-quality content correctly', () async {
      final content = _createHighQualityContent();

      final result =
          await TodayFeedContentQualityService.validateContentQuality(content);

      expect(result.isValid, isTrue);
      expect(result.overallQualityScore, greaterThan(0.7));
      expect(result.safetyScore, greaterThan(0.8));
      expect(result.issues, isEmpty);
      expect(result.errorMessage, isNull);
    });

    test('should detect unsafe content correctly', () async {
      final content = _createUnsafeContent();

      final result =
          await TodayFeedContentQualityService.validateContentQuality(content);

      expect(result.safetyScore, lessThan(0.8));
      expect(result.requiresReview, isTrue);
      expect(result.issues, isNotEmpty);
    });

    test('should track quality metrics', () async {
      final content = _createHighQualityContent();
      await TodayFeedContentQualityService.validateContentQuality(content);

      final metrics = await TodayFeedContentQualityService.getQualityMetrics();

      expect(metrics.totalValidations, greaterThanOrEqualTo(1));
      expect(metrics.averageQualityScore, greaterThan(0.0));
      expect(metrics.averageSafetyScore, greaterThan(0.0));
    });
  });
}

// Helper methods
TodayFeedContent _createHighQualityContent() {
  return TodayFeedContent.sample().copyWith(
    id: 1,
    title: 'High Quality Health Insight with Detailed Information',
    summary:
        'This is a comprehensive summary with detailed health information. Research suggests that consulting with healthcare professionals may help you make informed decisions.',
    aiConfidenceScore: 0.95,
    topicCategory: HealthTopic.nutrition,
  );
}

TodayFeedContent _createUnsafeContent() {
  return TodayFeedContent.sample().copyWith(
    id: 3,
    title: 'Potentially Harmful Medical Advice',
    summary: 'This content contains unsafe medical recommendations.',
    aiConfidenceScore: 0.2,
    topicCategory: HealthTopic.prevention,
  );
}
