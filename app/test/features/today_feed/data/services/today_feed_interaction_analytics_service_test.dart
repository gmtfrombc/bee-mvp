import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/today_feed/data/services/today_feed_interaction_analytics_service.dart';

void main() {
  group('TodayFeedInteractionAnalyticsService', () {
    late TodayFeedInteractionAnalyticsService service;

    setUp(() {
      service = TodayFeedInteractionAnalyticsService();
    });

    test('should create singleton instance', () {
      final instance1 = TodayFeedInteractionAnalyticsService();
      final instance2 = TodayFeedInteractionAnalyticsService();

      expect(instance1, equals(instance2));
      expect(identical(instance1, instance2), isTrue);
    });

    test('should dispose without errors', () {
      expect(() => service.dispose(), returnsNormally);
    });

    test('should create empty user analytics', () {
      final analytics = UserInteractionAnalytics.empty('test-user');

      expect(analytics.userId, equals('test-user'));
      expect(analytics.totalInteractions, equals(0));
      expect(analytics.engagementLevel, equals('low'));
      expect(analytics.topicPreferences, isEmpty);
      expect(analytics.engagementPatterns, isEmpty);
    });

    test('should create empty content performance analytics', () {
      final analytics = ContentPerformanceAnalytics.empty(1);

      expect(analytics.contentId, equals(1));
      expect(analytics.totalViews, equals(0));
      expect(analytics.performanceScore, equals(0.0));
      expect(analytics.interactionBreakdown, isEmpty);
    });
  });
}
