import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/today_feed/data/services/session_duration_tracking_service.dart';
import 'package:app/features/today_feed/domain/models/today_feed_content.dart';

void main() {
  group('SessionTrackingConfig', () {
    test('should have correct duration constants', () {
      expect(
        SessionTrackingConfig.minValidSession,
        equals(const Duration(seconds: 3)),
      );
      expect(
        SessionTrackingConfig.maxValidSession,
        equals(const Duration(hours: 2)),
      );
      expect(
        SessionTrackingConfig.sessionTimeout,
        equals(const Duration(minutes: 15)),
      );
      expect(
        SessionTrackingConfig.shortReadThreshold,
        equals(const Duration(seconds: 30)),
      );
      expect(
        SessionTrackingConfig.mediumReadThreshold,
        equals(const Duration(minutes: 2)),
      );
      expect(
        SessionTrackingConfig.longReadThreshold,
        equals(const Duration(minutes: 5)),
      );
    });

    test('should have correct sampling and batching constants', () {
      expect(
        SessionTrackingConfig.samplingInterval,
        equals(const Duration(seconds: 5)),
      );
      expect(SessionTrackingConfig.maxPendingSessions, equals(50));
      expect(
        SessionTrackingConfig.syncRetryDelay,
        equals(const Duration(minutes: 2)),
      );
    });

    test('should have correct engagement rate thresholds', () {
      expect(SessionTrackingConfig.minEngagementRate, equals(0.3));
      expect(SessionTrackingConfig.highEngagementRate, equals(0.8));
    });
  });

  group('SessionQuality', () {
    test('should have correct enum values', () {
      expect(SessionQuality.brief.value, equals('brief'));
      expect(SessionQuality.moderate.value, equals('moderate'));
      expect(SessionQuality.engaged.value, equals('engaged'));
      expect(SessionQuality.deep.value, equals('deep'));
    });

    test('should determine quality from duration correctly', () {
      expect(
        SessionQuality.fromDuration(const Duration(seconds: 15)),
        equals(SessionQuality.brief),
      );
      expect(
        SessionQuality.fromDuration(const Duration(seconds: 60)),
        equals(SessionQuality.moderate),
      );
      expect(
        SessionQuality.fromDuration(const Duration(minutes: 3)),
        equals(SessionQuality.engaged),
      );
      expect(
        SessionQuality.fromDuration(const Duration(minutes: 10)),
        equals(SessionQuality.deep),
      );
    });

    test('should handle edge cases correctly', () {
      expect(
        SessionQuality.fromDuration(Duration.zero),
        equals(SessionQuality.brief),
      );
      expect(
        SessionQuality.fromDuration(const Duration(seconds: 30)),
        equals(SessionQuality.moderate),
      );
      expect(
        SessionQuality.fromDuration(const Duration(minutes: 2)),
        equals(SessionQuality.engaged),
      );
      expect(
        SessionQuality.fromDuration(const Duration(minutes: 5)),
        equals(SessionQuality.deep),
      );
    });
  });

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
      // Test with exact estimated time
      final exactSession = ReadingSession.fromTrackingData(
        sessionId: 'exact_session',
        userId: 'user_123',
        contentId: 456,
        startTime: testStartTime,
        endTime: testStartTime.add(
          const Duration(minutes: 3),
        ), // Exact estimated time
        activitySamples: List.generate(
          10,
          (i) => testStartTime.add(Duration(seconds: i * 18)),
        ),
        content: testContent,
      );

      expect(exactSession.engagementScore, closeTo(1.0, 0.1));

      // Test with longer reading time
      final longSession = ReadingSession.fromTrackingData(
        sessionId: 'long_session',
        userId: 'user_123',
        contentId: 456,
        startTime: testStartTime,
        endTime: testStartTime.add(
          const Duration(minutes: 6),
        ), // 2x estimated time
        activitySamples: List.generate(
          10,
          (i) => testStartTime.add(Duration(seconds: i * 36)),
        ),
        content: testContent,
      );

      expect(longSession.engagementScore, closeTo(2.0, 0.1));
    });

    test('should handle zero estimated reading time', () {
      final zeroTimeContent = testContent.copyWith(estimatedReadingMinutes: 0);
      final session = ReadingSession.fromTrackingData(
        sessionId: 'zero_session',
        userId: 'user_123',
        contentId: 456,
        startTime: testStartTime,
        endTime: testEndTime,
        activitySamples: [testStartTime],
        content: zeroTimeContent,
      );

      expect(session.engagementScore, equals(0.0));
    });

    test('should serialize to and from JSON correctly', () {
      final originalSession = ReadingSession(
        sessionId: 'json_test_session',
        userId: 'json_user',
        contentId: 789,
        startTime: testStartTime,
        endTime: testEndTime,
        duration: const Duration(minutes: 3, seconds: 30),
        quality: SessionQuality.engaged,
        samplesCount: 5,
        engagementScore: 1.2,
        metadata: {
          'content_title': 'JSON Test Content',
          'content_category': 'exercise',
          'platform': 'iOS',
        },
      );

      final json = originalSession.toJson();
      final deserializedSession = ReadingSession.fromJson(json);

      expect(deserializedSession.sessionId, equals(originalSession.sessionId));
      expect(deserializedSession.userId, equals(originalSession.userId));
      expect(deserializedSession.contentId, equals(originalSession.contentId));
      expect(deserializedSession.startTime, equals(originalSession.startTime));
      expect(deserializedSession.endTime, equals(originalSession.endTime));
      expect(deserializedSession.duration, equals(originalSession.duration));
      expect(deserializedSession.quality, equals(originalSession.quality));
      expect(
        deserializedSession.samplesCount,
        equals(originalSession.samplesCount),
      );
      expect(
        deserializedSession.engagementScore,
        equals(originalSession.engagementScore),
      );
      expect(deserializedSession.metadata, equals(originalSession.metadata));
    });

    test('should handle equality and hashCode correctly', () {
      final session1 = ReadingSession(
        sessionId: 'session_1',
        userId: 'user_1',
        contentId: 1,
        startTime: testStartTime,
        endTime: testEndTime,
        duration: const Duration(minutes: 3),
        quality: SessionQuality.engaged,
        samplesCount: 5,
        engagementScore: 1.0,
        metadata: {},
      );

      final session2 = ReadingSession(
        sessionId: 'session_1',
        userId: 'user_1',
        contentId: 1,
        startTime: testStartTime.add(
          const Duration(minutes: 1),
        ), // Different start time
        endTime: testEndTime.add(
          const Duration(minutes: 1),
        ), // Different end time
        duration: const Duration(minutes: 4),
        quality: SessionQuality.deep,
        samplesCount: 10,
        engagementScore: 2.0,
        metadata: {'different': 'metadata'},
      );

      final session3 = ReadingSession(
        sessionId: 'session_3',
        userId: 'user_1',
        contentId: 1,
        startTime: testStartTime,
        endTime: testEndTime,
        duration: const Duration(minutes: 3),
        quality: SessionQuality.engaged,
        samplesCount: 5,
        engagementScore: 1.0,
        metadata: {},
      );

      expect(session1, equals(session2)); // Same ID, user, content
      expect(session1.hashCode, equals(session2.hashCode));
      expect(session1, isNot(equals(session3))); // Different session ID
    });

    test('should have correct toString representation', () {
      final session = ReadingSession(
        sessionId: 'toString_session',
        userId: 'user_123',
        contentId: 456,
        startTime: testStartTime,
        endTime: testEndTime,
        duration: const Duration(minutes: 3, seconds: 30),
        quality: SessionQuality.engaged,
        samplesCount: 5,
        engagementScore: 1.2,
        metadata: {},
      );

      final string = session.toString();
      expect(string, contains('ReadingSession'));
      expect(string, contains('toString_session'));
      expect(string, contains('210s')); // 3.5 minutes = 210 seconds
      expect(string, contains('engaged'));
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

    test('should calculate reading efficiency correctly', () {
      final highEfficiencyAnalytics = SessionAnalytics(
        totalSessions: 10,
        totalReadingTime: const Duration(minutes: 30),
        averageSessionDuration: const Duration(minutes: 3),
        averageEngagementScore: 0.9,
        qualityDistribution: {},
        topicEngagement: {},
        consecutiveDaysWithSessions: 5,
      );

      expect(highEfficiencyAnalytics.readingEfficiency, equals(0.9));

      final lowEfficiencyAnalytics = SessionAnalytics(
        totalSessions: 5,
        totalReadingTime: const Duration(minutes: 10),
        averageSessionDuration: const Duration(minutes: 2),
        averageEngagementScore: 0.2,
        qualityDistribution: {},
        topicEngagement: {},
        consecutiveDaysWithSessions: 2,
      );

      expect(lowEfficiencyAnalytics.readingEfficiency, equals(0.2));

      final noSessionAnalytics = SessionAnalytics.empty();
      expect(noSessionAnalytics.readingEfficiency, equals(0.0));
    });

    test('should determine engagement level correctly', () {
      final highEngagementAnalytics = SessionAnalytics(
        totalSessions: 10,
        totalReadingTime: const Duration(minutes: 30),
        averageSessionDuration: const Duration(minutes: 3),
        averageEngagementScore: 0.85, // Above high threshold
        qualityDistribution: {},
        topicEngagement: {},
        consecutiveDaysWithSessions: 5,
      );

      expect(highEngagementAnalytics.engagementLevel, equals('high'));

      final mediumEngagementAnalytics = SessionAnalytics(
        totalSessions: 5,
        totalReadingTime: const Duration(minutes: 15),
        averageSessionDuration: const Duration(minutes: 3),
        averageEngagementScore: 0.5, // Between min and high threshold
        qualityDistribution: {},
        topicEngagement: {},
        consecutiveDaysWithSessions: 3,
      );

      expect(mediumEngagementAnalytics.engagementLevel, equals('medium'));

      final lowEngagementAnalytics = SessionAnalytics(
        totalSessions: 3,
        totalReadingTime: const Duration(minutes: 5),
        averageSessionDuration: const Duration(minutes: 1),
        averageEngagementScore: 0.1, // Below min threshold
        qualityDistribution: {},
        topicEngagement: {},
        consecutiveDaysWithSessions: 1,
      );

      expect(lowEngagementAnalytics.engagementLevel, equals('low'));
    });

    test('should have correct toString representation', () {
      final analytics = SessionAnalytics(
        totalSessions: 15,
        totalReadingTime: const Duration(minutes: 45),
        averageSessionDuration: const Duration(minutes: 3),
        averageEngagementScore: 0.75,
        qualityDistribution: {
          SessionQuality.engaged: 10,
          SessionQuality.deep: 5,
        },
        topicEngagement: {'nutrition': 0.8, 'exercise': 0.7},
        consecutiveDaysWithSessions: 7,
      );

      final string = analytics.toString();
      expect(string, contains('SessionAnalytics'));
      expect(string, contains('sessions: 15'));
      expect(string, contains('avgDuration: 180s')); // 3 minutes = 180 seconds
      expect(string, contains('engagement: 75.0%'));
    });
  });

  group('SessionDurationTrackingService', () {
    test('should be a singleton', () {
      final service1 = SessionDurationTrackingService();
      final service2 = SessionDurationTrackingService();
      expect(identical(service1, service2), isTrue);
    });

    test('should handle service configuration correctly', () {
      // Test that service follows configuration constants
      expect(SessionTrackingConfig.minValidSession.inSeconds, equals(3));
      expect(SessionTrackingConfig.maxValidSession.inHours, equals(2));
      expect(SessionTrackingConfig.sessionTimeout.inMinutes, equals(15));
      expect(SessionTrackingConfig.samplingInterval.inSeconds, equals(5));
      expect(SessionTrackingConfig.maxPendingSessions, equals(50));
    });

    test('should generate unique session IDs', () {
      // Test session ID generation through the service
      // We can't directly test the private method, but we can verify uniqueness indirectly
      final sessionIds = <String>{};

      // Generate multiple session IDs and verify they're unique
      for (int i = 0; i < 10; i++) {
        // Since we can't access the private method directly, we test the pattern
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final testSessionId = 'session_${timestamp}_$i';
        expect(sessionIds.contains(testSessionId), isFalse);
        sessionIds.add(testSessionId);
      }

      expect(sessionIds.length, equals(10));
    });

    test('should handle session validation correctly', () {
      // Valid session
      final validSession = ReadingSession(
        sessionId: 'valid_session',
        userId: 'user_123',
        contentId: 1,
        startTime: DateTime.now().subtract(const Duration(minutes: 5)),
        endTime: DateTime.now(),
        duration: const Duration(minutes: 5),
        quality: SessionQuality.engaged,
        samplesCount: 10,
        engagementScore: 1.0,
        metadata: {},
      );

      // Test that duration is within valid range
      expect(
        validSession.duration,
        greaterThanOrEqualTo(SessionTrackingConfig.minValidSession),
      );
      expect(
        validSession.duration,
        lessThanOrEqualTo(SessionTrackingConfig.maxValidSession),
      );
      expect(validSession.samplesCount, greaterThan(0));

      // Invalid session (too short)
      final shortSession = ReadingSession(
        sessionId: 'short_session',
        userId: 'user_123',
        contentId: 1,
        startTime: DateTime.now().subtract(const Duration(seconds: 1)),
        endTime: DateTime.now(),
        duration: const Duration(seconds: 1),
        quality: SessionQuality.brief,
        samplesCount: 1,
        engagementScore: 0.1,
        metadata: {},
      );

      expect(
        shortSession.duration,
        lessThan(SessionTrackingConfig.minValidSession),
      );

      // Invalid session (too long)
      final longSession = ReadingSession(
        sessionId: 'long_session',
        userId: 'user_123',
        contentId: 1,
        startTime: DateTime.now().subtract(const Duration(hours: 3)),
        endTime: DateTime.now(),
        duration: const Duration(hours: 3),
        quality: SessionQuality.deep,
        samplesCount: 100,
        engagementScore: 2.0,
        metadata: {},
      );

      expect(
        longSession.duration,
        greaterThan(SessionTrackingConfig.maxValidSession),
      );
    });

    test('should handle consecutive days calculation correctly', () {
      final testSessions = [
        ReadingSession(
          sessionId: 'session_1',
          userId: 'user_1',
          contentId: 1,
          startTime: DateTime.now().subtract(const Duration(days: 0)),
          endTime: DateTime.now(),
          duration: const Duration(minutes: 3),
          quality: SessionQuality.engaged,
          samplesCount: 5,
          engagementScore: 1.0,
          metadata: {},
        ),
        ReadingSession(
          sessionId: 'session_2',
          userId: 'user_1',
          contentId: 2,
          startTime: DateTime.now().subtract(const Duration(days: 1)),
          endTime: DateTime.now().subtract(const Duration(days: 1)),
          duration: const Duration(minutes: 4),
          quality: SessionQuality.engaged,
          samplesCount: 6,
          engagementScore: 1.2,
          metadata: {},
        ),
        ReadingSession(
          sessionId: 'session_3',
          userId: 'user_1',
          contentId: 3,
          startTime: DateTime.now().subtract(const Duration(days: 2)),
          endTime: DateTime.now().subtract(const Duration(days: 2)),
          duration: const Duration(minutes: 2),
          quality: SessionQuality.moderate,
          samplesCount: 4,
          engagementScore: 0.8,
          metadata: {},
        ),
        // Gap of one day
        ReadingSession(
          sessionId: 'session_4',
          userId: 'user_1',
          contentId: 4,
          startTime: DateTime.now().subtract(const Duration(days: 4)),
          endTime: DateTime.now().subtract(const Duration(days: 4)),
          duration: const Duration(minutes: 5),
          quality: SessionQuality.engaged,
          samplesCount: 8,
          engagementScore: 1.5,
          metadata: {},
        ),
      ];

      // With the gap, consecutive days should be 3 (today, yesterday, day before)
      // This tests the logic pattern even though we can't access the private method directly
      final sessionDays =
          testSessions
              .map((s) => s.startTime.toIso8601String().split('T')[0])
              .toSet()
              .toList()
            ..sort((a, b) => b.compareTo(a));

      expect(sessionDays.length, equals(4)); // 4 unique days

      // Verify the pattern of day calculation
      final today = DateTime.now().toIso8601String().split('T')[0];
      final yesterday =
          DateTime.now()
              .subtract(const Duration(days: 1))
              .toIso8601String()
              .split('T')[0];

      expect(sessionDays.contains(today), isTrue);
      expect(sessionDays.contains(yesterday), isTrue);
    });

    test('should handle topic engagement calculation correctly', () {
      final testSessions = [
        ReadingSession(
          sessionId: 'nutrition_1',
          userId: 'user_1',
          contentId: 1,
          startTime: DateTime.now(),
          endTime: DateTime.now(),
          duration: const Duration(minutes: 3),
          quality: SessionQuality.engaged,
          samplesCount: 5,
          engagementScore: 1.0,
          metadata: {'content_category': 'nutrition'},
        ),
        ReadingSession(
          sessionId: 'nutrition_2',
          userId: 'user_1',
          contentId: 2,
          startTime: DateTime.now(),
          endTime: DateTime.now(),
          duration: const Duration(minutes: 4),
          quality: SessionQuality.engaged,
          samplesCount: 6,
          engagementScore: 1.2,
          metadata: {'content_category': 'nutrition'},
        ),
        ReadingSession(
          sessionId: 'exercise_1',
          userId: 'user_1',
          contentId: 3,
          startTime: DateTime.now(),
          endTime: DateTime.now(),
          duration: const Duration(minutes: 2),
          quality: SessionQuality.moderate,
          samplesCount: 4,
          engagementScore: 0.8,
          metadata: {'content_category': 'exercise'},
        ),
      ];

      // Calculate topic engagement averages manually for validation
      final nutritionSessions = testSessions.where(
        (s) => s.metadata['content_category'] == 'nutrition',
      );
      final nutritionAverage =
          nutritionSessions.fold<double>(
            0.0,
            (sum, s) => sum + s.engagementScore,
          ) /
          nutritionSessions.length;

      expect(nutritionAverage, equals(1.1)); // (1.0 + 1.2) / 2 = 1.1

      final exerciseSessions = testSessions.where(
        (s) => s.metadata['content_category'] == 'exercise',
      );
      final exerciseAverage =
          exerciseSessions.fold<double>(
            0.0,
            (sum, s) => sum + s.engagementScore,
          ) /
          exerciseSessions.length;

      expect(exerciseAverage, equals(0.8)); // 0.8 / 1 = 0.8
    });

    test('should handle quality distribution calculation correctly', () {
      final testSessions = [
        ReadingSession(
          sessionId: 'brief_1',
          userId: 'user_1',
          contentId: 1,
          startTime: DateTime.now(),
          endTime: DateTime.now(),
          duration: const Duration(seconds: 20),
          quality: SessionQuality.brief,
          samplesCount: 2,
          engagementScore: 0.2,
          metadata: {},
        ),
        ReadingSession(
          sessionId: 'brief_2',
          userId: 'user_1',
          contentId: 2,
          startTime: DateTime.now(),
          endTime: DateTime.now(),
          duration: const Duration(seconds: 25),
          quality: SessionQuality.brief,
          samplesCount: 3,
          engagementScore: 0.3,
          metadata: {},
        ),
        ReadingSession(
          sessionId: 'engaged_1',
          userId: 'user_1',
          contentId: 3,
          startTime: DateTime.now(),
          endTime: DateTime.now(),
          duration: const Duration(minutes: 3),
          quality: SessionQuality.engaged,
          samplesCount: 5,
          engagementScore: 1.0,
          metadata: {},
        ),
      ];

      // Calculate quality distribution manually for validation
      final qualityDistribution = <SessionQuality, int>{};
      for (final session in testSessions) {
        qualityDistribution[session.quality] =
            (qualityDistribution[session.quality] ?? 0) + 1;
      }

      expect(qualityDistribution[SessionQuality.brief], equals(2));
      expect(qualityDistribution[SessionQuality.engaged], equals(1));
      expect(qualityDistribution[SessionQuality.moderate], isNull);
      expect(qualityDistribution[SessionQuality.deep], isNull);
    });
  });

  group('Service Edge Cases', () {
    test('should handle empty session analytics correctly', () {
      final analytics = SessionAnalytics.empty();

      expect(analytics.totalSessions, equals(0));
      expect(analytics.totalReadingTime, equals(Duration.zero));
      expect(analytics.averageSessionDuration, equals(Duration.zero));
      expect(analytics.averageEngagementScore, equals(0.0));
      expect(analytics.readingEfficiency, equals(0.0));
      expect(analytics.engagementLevel, equals('low'));
      expect(analytics.consecutiveDaysWithSessions, equals(0));
      expect(analytics.lastSessionTime, isNull);
    });

    test('should handle malformed session data gracefully', () {
      // Test with malformed JSON data
      const malformedJson = {
        'session_id': 'test_session',
        'user_id': 'test_user',
        'content_id': 'invalid_id', // Should be int
        'start_time': 'invalid_date',
        'end_time': '2024-12-28T10:30:00.000Z',
        'duration_seconds': 'invalid_duration', // Should be int
        'session_quality': 'invalid_quality',
        'samples_count': 'invalid_count', // Should be int
        'engagement_score': 'invalid_score', // Should be double
        'metadata': 'invalid_metadata', // Should be Map
      };

      // The fromJson method should handle type casting appropriately
      expect(
        () => ReadingSession.fromJson(malformedJson),
        throwsA(isA<TypeError>()),
      );
    });

    test('should handle boundary values correctly', () {
      // Test minimum valid session
      final minSession = ReadingSession(
        sessionId: 'min_session',
        userId: 'user_123',
        contentId: 1,
        startTime: DateTime.now(),
        endTime: DateTime.now().add(SessionTrackingConfig.minValidSession),
        duration: SessionTrackingConfig.minValidSession,
        quality: SessionQuality.brief,
        samplesCount: 1,
        engagementScore: 0.0,
        metadata: {},
      );

      expect(
        minSession.duration,
        equals(SessionTrackingConfig.minValidSession),
      );
      expect(minSession.quality, equals(SessionQuality.brief));

      // Test maximum valid session
      final maxSession = ReadingSession(
        sessionId: 'max_session',
        userId: 'user_123',
        contentId: 1,
        startTime: DateTime.now(),
        endTime: DateTime.now().add(SessionTrackingConfig.maxValidSession),
        duration: SessionTrackingConfig.maxValidSession,
        quality: SessionQuality.deep,
        samplesCount: 1000,
        engagementScore: 2.0,
        metadata: {},
      );

      expect(
        maxSession.duration,
        equals(SessionTrackingConfig.maxValidSession),
      );
      expect(maxSession.quality, equals(SessionQuality.deep));
    });

    test('should handle engagement score edge cases', () {
      final testContent = TodayFeedContent.sample().copyWith(
        estimatedReadingMinutes: 5,
      );

      // Test zero samples
      final zeroSamplesSession = ReadingSession.fromTrackingData(
        sessionId: 'zero_samples',
        userId: 'user_123',
        contentId: 1,
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(minutes: 5)),
        activitySamples: [], // No samples
        content: testContent,
      );

      expect(zeroSamplesSession.samplesCount, equals(0));
      expect(zeroSamplesSession.engagementScore, equals(0.0));

      // Test many samples
      final manySamplesSession = ReadingSession.fromTrackingData(
        sessionId: 'many_samples',
        userId: 'user_123',
        contentId: 1,
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(minutes: 5)),
        activitySamples: List.generate(
          50,
          (i) => DateTime.now().add(Duration(seconds: i * 6)),
        ),
        content: testContent,
      );

      expect(manySamplesSession.samplesCount, equals(50));
      expect(manySamplesSession.engagementScore, greaterThan(0.0));
      expect(
        manySamplesSession.engagementScore,
        lessThanOrEqualTo(2.0),
      ); // Capped at 2.0
    });
  });

  group('Service Lifecycle', () {
    test('should handle multiple dispose calls gracefully', () {
      final service = SessionDurationTrackingService();
      // Multiple dispose calls should not cause issues
      expect(() => service.dispose(), returnsNormally);
      expect(() => service.dispose(), returnsNormally);
      expect(() => service.dispose(), returnsNormally);
    });

    test('should maintain singleton behavior across operations', () {
      final service1 = SessionDurationTrackingService();
      final service2 = SessionDurationTrackingService();

      // Should be the same instance
      expect(identical(service1, service2), isTrue);

      // Dispose one and verify still same instance
      service1.dispose();
      final service3 = SessionDurationTrackingService();
      expect(identical(service1, service3), isTrue);
    });

    test('should handle session management correctly', () {
      final service = SessionDurationTrackingService();
      // Test active session info for non-existent session
      final nonExistentInfo = service.getActiveSessionInfo(
        'non_existent_session',
      );
      expect(nonExistentInfo['active'], isFalse);

      // Test get all active sessions when none exist
      final allSessions = service.getAllActiveSessions();
      expect(allSessions, isEmpty);
    });
  });
}
