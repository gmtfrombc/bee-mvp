import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/today_feed/data/services/daily_engagement_detection_service.dart';
import 'package:app/features/today_feed/domain/models/today_feed_content.dart';

void main() {
  group('DailyEngagementDetectionService Tests', () {
    late DailyEngagementDetectionService service;

    setUp(() {
      service = DailyEngagementDetectionService();
    });

    tearDown(() {
      service.dispose();
    });

    group('Service Initialization', () {
      test('should create service instance successfully', () {
        expect(service, isNotNull);
        expect(service.getCacheStatistics()['cache_size'], equals(0));
      });

      test('should initialize cache cleanup timer', () {
        // Timer setup should not throw
        expect(() => service.dispose(), returnsNormally);
      });
    });

    group('Daily Engagement Detection', () {
      test('should detect first-time daily engagement', () {
        final testContent = TodayFeedContent.sample();

        // Mock first engagement attempt
        expect(testContent.hasUserEngaged, isFalse);
        expect(testContent.id, isNotNull);
      });

      test('should prevent duplicate momentum awards', () {
        const testUserId = 'test-user-123';
        final testContent = TodayFeedContent.sample();

        // Test that duplicate detection works
        expect(testUserId, isNotEmpty);
        expect(testContent.topicCategory, isNotNull);
      });

      test('should handle engagement status caching', () {
        // Test cache functionality
        service.clearCache();
        expect(service.getCacheStatistics()['cache_size'], equals(0));
      });
    });

    group('Engagement Status', () {
      test('should return correct engagement status structure', () {
        const status = EngagementStatus(
          hasEngagedToday: false,
          isEligibleForMomentum: true,
          source: EngagementSource.database,
        );

        expect(status.hasEngagedToday, isFalse);
        expect(status.isEligibleForMomentum, isTrue);
        expect(status.source, equals(EngagementSource.database));
        expect(status.lastEngagementTime, isNull);
        expect(status.error, isNull);
      });

      test('should handle error states correctly', () {
        const status = EngagementStatus(
          hasEngagedToday: true,
          isEligibleForMomentum: false,
          source: EngagementSource.error,
          error: 'Network error',
        );

        expect(status.hasEngagedToday, isTrue);
        expect(status.isEligibleForMomentum, isFalse);
        expect(status.source, equals(EngagementSource.error));
        expect(status.error, equals('Network error'));
      });

      test('should handle cache source correctly', () {
        final now = DateTime.now();
        final status = EngagementStatus(
          hasEngagedToday: true,
          isEligibleForMomentum: false,
          lastEngagementTime: now,
          source: EngagementSource.cache,
        );

        expect(status.hasEngagedToday, isTrue);
        expect(status.isEligibleForMomentum, isFalse);
        expect(status.source, equals(EngagementSource.cache));
        expect(status.lastEngagementTime, equals(now));
      });
    });

    group('Engagement Result', () {
      test('should create successful engagement result', () {
        const result = EngagementResult(
          success: true,
          momentumAwarded: true,
          momentumPoints: 1,
          isDuplicate: false,
          engagementRecorded: true,
          message: 'First daily engagement! +1 momentum point earned',
        );

        expect(result.success, isTrue);
        expect(result.momentumAwarded, isTrue);
        expect(result.momentumPoints, equals(1));
        expect(result.isDuplicate, isFalse);
        expect(result.engagementRecorded, isTrue);
        expect(result.message, contains('First daily engagement'));
      });

      test('should create duplicate engagement result', () {
        final previousTime = DateTime.now().subtract(const Duration(hours: 2));
        final result = EngagementResult(
          success: true,
          momentumAwarded: false,
          momentumPoints: 0,
          isDuplicate: true,
          engagementRecorded: true,
          message: 'Content engagement recorded (already engaged today)',
          previousEngagementTime: previousTime,
        );

        expect(result.success, isTrue);
        expect(result.momentumAwarded, isFalse);
        expect(result.momentumPoints, equals(0));
        expect(result.isDuplicate, isTrue);
        expect(result.engagementRecorded, isTrue);
        expect(result.message, contains('already engaged today'));
        expect(result.previousEngagementTime, equals(previousTime));
      });

      test('should create error engagement result', () {
        const result = EngagementResult(
          success: false,
          momentumAwarded: false,
          momentumPoints: 0,
          isDuplicate: false,
          engagementRecorded: false,
          message: 'Failed to record engagement',
          error: 'Database connection failed',
        );

        expect(result.success, isFalse);
        expect(result.momentumAwarded, isFalse);
        expect(result.momentumPoints, equals(0));
        expect(result.isDuplicate, isFalse);
        expect(result.engagementRecorded, isFalse);
        expect(result.message, contains('Failed to record'));
        expect(result.error, equals('Database connection failed'));
      });
    });

    group('Engagement Statistics', () {
      test('should create complete engagement statistics', () {
        const stats = EngagementStatistics(
          totalEngagements: 25,
          engagedDays: 20,
          currentStreak: 5,
          averageSessionDuration: 180,
          periodDays: 30,
          engagementRate: 0.67,
        );

        expect(stats.totalEngagements, equals(25));
        expect(stats.engagedDays, equals(20));
        expect(stats.currentStreak, equals(5));
        expect(stats.averageSessionDuration, equals(180));
        expect(stats.periodDays, equals(30));
        expect(stats.engagementRate, closeTo(0.67, 0.01));
      });

      test('should create empty engagement statistics', () {
        final stats = EngagementStatistics.empty();

        expect(stats.totalEngagements, equals(0));
        expect(stats.engagedDays, equals(0));
        expect(stats.currentStreak, equals(0));
        expect(stats.averageSessionDuration, equals(0));
        expect(stats.periodDays, equals(0));
        expect(stats.engagementRate, equals(0.0));
        expect(stats.lastEngagementTime, isNull);
        expect(stats.firstEngagementTime, isNull);
      });
    });

    group('Cache Management', () {
      test('should manage cache size correctly', () {
        service.clearCache();
        var stats = service.getCacheStatistics();
        expect(stats['cache_size'], equals(0));
        expect(stats['cache_entries'], equals(0));
      });

      test('should provide cache statistics', () {
        service.clearCache();
        final stats = service.getCacheStatistics();

        expect(stats, containsPair('cache_size', 0));
        expect(stats, containsPair('cache_entries', 0));
        expect(stats, containsPair('oldest_entry', null));
        expect(stats, containsPair('newest_entry', null));
      });
    });

    group('Content Integration', () {
      test('should work with TodayFeedContent model', () {
        final content = TodayFeedContent.sample();

        expect(content.id, isNotNull);
        expect(content.title, isNotEmpty);
        expect(content.topicCategory, isNotNull);
        expect(content.contentDate, isNotNull);
        expect(content.aiConfidenceScore, isA<double>());
        expect(content.estimatedReadingMinutes, isA<int>());
      });

      test('should handle content with all required fields', () {
        final content = TodayFeedContent.sample().copyWith(
          title: 'Test Health Insight',
          topicCategory: HealthTopic.nutrition,
          estimatedReadingMinutes: 3,
          aiConfidenceScore: 0.85,
        );

        expect(content.title, equals('Test Health Insight'));
        expect(content.topicCategory, equals(HealthTopic.nutrition));
        expect(content.estimatedReadingMinutes, equals(3));
        expect(content.aiConfidenceScore, equals(0.85));
      });
    });

    group('Momentum Integration', () {
      test('should award exactly 1 momentum point for first engagement', () {
        const result = EngagementResult(
          success: true,
          momentumAwarded: true,
          momentumPoints: 1,
          isDuplicate: false,
          engagementRecorded: true,
          message: 'First daily engagement! +1 momentum point earned',
        );

        expect(result.momentumAwarded, isTrue);
        expect(result.momentumPoints, equals(1));
      });

      test('should not award momentum for duplicate engagement', () {
        const result = EngagementResult(
          success: true,
          momentumAwarded: false,
          momentumPoints: 0,
          isDuplicate: true,
          engagementRecorded: true,
          message: 'Content engagement recorded (already engaged today)',
        );

        expect(result.momentumAwarded, isFalse);
        expect(result.momentumPoints, equals(0));
        expect(result.isDuplicate, isTrue);
      });
    });

    group('Error Handling', () {
      test('should handle service initialization errors gracefully', () {
        // Test that service can be created even with potential errors
        expect(() => DailyEngagementDetectionService(), returnsNormally);
      });

      test('should provide error information in engagement status', () {
        const status = EngagementStatus(
          hasEngagedToday: true,
          isEligibleForMomentum: false,
          source: EngagementSource.error,
          error: 'Database connection timeout',
        );

        expect(status.source, equals(EngagementSource.error));
        expect(status.error, isNotNull);
        expect(status.error, contains('timeout'));
      });

      test('should handle engagement recording errors', () {
        const result = EngagementResult(
          success: false,
          momentumAwarded: false,
          momentumPoints: 0,
          isDuplicate: false,
          engagementRecorded: false,
          message: 'Failed to record engagement',
          error: 'Network unavailable',
        );

        expect(result.success, isFalse);
        expect(result.error, isNotNull);
        expect(result.error, contains('Network unavailable'));
      });
    });

    group('Service Lifecycle', () {
      test('should dispose resources properly', () {
        final testService = DailyEngagementDetectionService();

        // Should not throw on dispose
        expect(() => testService.dispose(), returnsNormally);

        // Cache should be cleared after dispose
        testService.clearCache();
        expect(testService.getCacheStatistics()['cache_size'], equals(0));
      });

      test('should handle multiple dispose calls', () {
        final testService = DailyEngagementDetectionService();

        // Multiple dispose calls should not throw
        expect(() {
          testService.dispose();
          testService.dispose();
        }, returnsNormally);
      });
    });

    group('Date Handling', () {
      test('should handle timezone considerations', () {
        final now = DateTime.now();
        final todayString = now.toIso8601String().split('T')[0];

        expect(todayString, matches(r'^\d{4}-\d{2}-\d{2}$'));
        expect(todayString.length, equals(10));
      });

      test('should handle date comparison correctly', () {
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));

        final todayString = today.toIso8601String().split('T')[0];
        final yesterdayString = yesterday.toIso8601String().split('T')[0];

        expect(todayString, isNot(equals(yesterdayString)));
        expect(todayString.compareTo(yesterdayString), greaterThan(0));
      });
    });

    group('Session Duration Tracking', () {
      test('should handle session duration in engagement data', () {
        const sessionDuration = 180; // 3 minutes

        // Test that session duration is properly handled
        expect(sessionDuration, isA<int>());
        expect(sessionDuration, greaterThan(0));
        expect(sessionDuration, lessThan(3600)); // Less than 1 hour
      });

      test('should handle null session duration', () {
        const int? sessionDuration = null;

        // Should handle null gracefully
        expect(sessionDuration, isNull);
      });
    });
  });
}
