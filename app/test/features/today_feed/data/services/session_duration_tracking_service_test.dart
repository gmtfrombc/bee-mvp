import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/today_feed/data/services/session_duration_tracking_service.dart';
import 'package:app/features/today_feed/domain/models/today_feed_content.dart';

void main() {
  group('ReadingSession', () {
    late TodayFeedContent testContent;
    late DateTime testStartTime;
    late DateTime testEndTime;

    setUp(() {
      testStartTime = DateTime(2024, 12, 28, 10, 0, 0);
      testEndTime = DateTime(2024, 12, 28, 10, 3, 30); // 3.5 minutes
      testContent = TodayFeedContent.sample().copyWith(
        id: 123,
        title: 'Test Health Insight',
        topicCategory: HealthTopic.nutrition,
        estimatedReadingMinutes: 3,
        aiConfidenceScore: 0.85,
      );
    });

    test('should create reading session from tracking data correctly', () {
      final activitySamples = [
        testStartTime,
        testStartTime.add(const Duration(seconds: 30)),
        testStartTime.add(const Duration(minutes: 1)),
        testStartTime.add(const Duration(minutes: 2)),
      ];

      final session = ReadingSession.fromTrackingData(
        sessionId: 'test_session_123',
        userId: 'user_456',
        contentId: 123,
        startTime: testStartTime,
        endTime: testEndTime,
        activitySamples: activitySamples,
        content: testContent,
        additionalMetadata: {'test_key': 'test_value'},
      );

      expect(session.sessionId, equals('test_session_123'));
      expect(session.userId, equals('user_456'));
      expect(session.contentId, equals(123));
      expect(session.startTime, equals(testStartTime));
      expect(session.endTime, equals(testEndTime));
      expect(session.duration, equals(const Duration(minutes: 3, seconds: 30)));
      expect(session.quality, equals(SessionQuality.engaged));
      expect(session.samplesCount, equals(4));
      expect(session.engagementScore, greaterThan(0.0));
      expect(session.metadata['content_title'], equals('Test Health Insight'));
      expect(session.metadata['content_category'], equals('nutrition'));
      expect(session.metadata['test_key'], equals('test_value'));
    });

    test('should calculate engagement score correctly', () {
      final exactSession = ReadingSession.fromTrackingData(
        sessionId: 'exact_session',
        userId: 'user_123',
        contentId: 456,
        startTime: testStartTime,
        endTime: testStartTime.add(const Duration(minutes: 3)),
        activitySamples: List.generate(
          10,
          (i) => testStartTime.add(Duration(seconds: i * 18)),
        ),
        content: testContent,
      );

      expect(exactSession.engagementScore, closeTo(1.0, 0.1));
    });
  });

  group('SessionAnalytics', () {
    test('should create empty analytics correctly', () {
      final analytics = SessionAnalytics.empty();

      expect(analytics.totalSessions, equals(0));
      expect(analytics.totalReadingTime, equals(Duration.zero));
      expect(analytics.averageSessionDuration, equals(Duration.zero));
      expect(analytics.averageEngagementScore, equals(0.0));
      expect(analytics.qualityDistribution, isEmpty);
      expect(analytics.topicEngagement, isEmpty);
      expect(analytics.lastSessionTime, isNull);
      expect(analytics.consecutiveDaysWithSessions, equals(0));
    });
  });

  group('SessionDurationTrackingService', () {
    test('should be a singleton', () {
      final service1 = SessionDurationTrackingService();
      final service2 = SessionDurationTrackingService();
      expect(identical(service1, service2), isTrue);
    });
  });
}
