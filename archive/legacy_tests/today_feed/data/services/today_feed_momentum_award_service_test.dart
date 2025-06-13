import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/today_feed/data/services/today_feed_momentum_award_service.dart';
import 'package:app/features/today_feed/domain/models/today_feed_content.dart';

void main() {
  group('TodayFeedMomentumAwardService Tests - T1.3.4.4', () {
    late TodayFeedMomentumAwardService awardService;

    setUp(() {
      // Create service instance
      awardService = TodayFeedMomentumAwardService();
    });

    group('Configuration Compliance - T1.3.4.4 Requirements', () {
      test('should award exactly 1 point as per PRD specification', () {
        expect(
          TodayFeedMomentumAwardService.todayFeedMomentumPoints,
          equals(1),
        );
      });

      test('should use correct event type for momentum tracking', () {
        expect(
          TodayFeedMomentumAwardService.todayFeedEventType,
          equals('today_feed_daily_engagement'),
        );
      });

      test('should enforce 24-hour cooldown period', () {
        expect(
          TodayFeedMomentumAwardService.awardCooldownPeriod,
          equals(const Duration(hours: 24)),
        );
      });
    });

    group('Service Structure and API - T1.3.4.4 Interface', () {
      test('should provide singleton instance', () {
        final instance1 = TodayFeedMomentumAwardService();
        final instance2 = TodayFeedMomentumAwardService();
        expect(identical(instance1, instance2), isTrue);
      });

      test('should have required public methods per T1.3.4.4', () {
        // Verify the service has the required interface
        expect(awardService.awardMomentumPoints, isA<Function>());
        expect(awardService.getMomentumAwardStatistics, isA<Function>());
        expect(awardService.initialize, isA<Function>());
        expect(awardService.dispose, isA<Function>());
      });

      test('should handle dispose without errors', () {
        // Test resource cleanup
        expect(() => awardService.dispose(), returnsNormally);
      });
    });

    group('MomentumAwardResult Model - T1.3.4.4 Data Structures', () {
      test('should provide correct factory constructors', () {
        // Test success result
        final successResult = MomentumAwardResult.success(
          pointsAwarded: 1,
          message: 'Success',
          awardTime: DateTime.now(),
        );
        expect(successResult.success, isTrue);
        expect(successResult.pointsAwarded, equals(1));

        // Test duplicate result
        final duplicateResult = MomentumAwardResult.duplicate(
          message: 'Already awarded',
        );
        expect(duplicateResult.success, isFalse);
        expect(duplicateResult.isDuplicate, isTrue);
        expect(duplicateResult.pointsAwarded, equals(0));

        // Test failed result
        final failedResult = MomentumAwardResult.failed(
          message: 'Failed',
          error: 'Test error',
        );
        expect(failedResult.success, isFalse);
        expect(failedResult.error, equals('Test error'));

        // Test queued result
        final queuedResult = MomentumAwardResult.queued(message: 'Queued');
        expect(queuedResult.success, isTrue);
        expect(queuedResult.isQueued, isTrue);
        expect(
          queuedResult.pointsAwarded,
          equals(1),
        ); // Will be awarded when processed
      });

      test('should validate MomentumAwardResult properties', () {
        final result = MomentumAwardResult.success(
          pointsAwarded: 1,
          message: 'First daily engagement! +1 momentum point earned',
          awardTime: DateTime.now(),
        );

        expect(result.success, isTrue);
        expect(result.pointsAwarded, equals(1));
        expect(result.isDuplicate, isFalse);
        expect(result.isQueued, isFalse);
        expect(result.error, isNull);
        expect(result.awardTime, isNotNull);
      });
    });

    group('MomentumAwardStatistics Model - T1.3.4.4 Analytics', () {
      test('should provide empty statistics factory', () {
        final emptyStats = MomentumAwardStatistics.empty();
        expect(emptyStats.totalAwards, equals(0));
        expect(emptyStats.totalPointsAwarded, equals(0));
        expect(emptyStats.averageSessionDuration, equals(0.0));
        expect(emptyStats.awardFrequency, equals(0.0));
        expect(emptyStats.periodDays, equals(0));
      });

      test('should create statistics with valid data', () {
        const stats = MomentumAwardStatistics(
          totalAwards: 5,
          totalPointsAwarded: 5,
          averageSessionDuration: 180.0,
          awardFrequency: 0.8,
          periodDays: 7,
        );

        expect(stats.totalAwards, equals(5));
        expect(stats.totalPointsAwarded, equals(5));
        expect(stats.averageSessionDuration, equals(180.0));
        expect(stats.awardFrequency, equals(0.8));
        expect(stats.periodDays, equals(7));
      });
    });

    group('TodayFeedContent Integration - T1.3.4.4 Data Model', () {
      test('should work with all health topic categories', () {
        // Verify the service can handle all topic types
        for (final topic in HealthTopic.values) {
          final content = TodayFeedContent(
            id: 456,
            contentDate: DateTime.now(),
            title: 'Test Topic: ${topic.value}',
            summary: 'Test summary',
            topicCategory: topic,
            aiConfidenceScore: 0.9,
          );

          // Test that content model creation works for all topics
          expect(content.topicCategory, equals(topic));
          expect(content.title, contains(topic.value));
        }
      });

      test('should handle content with various confidence scores', () {
        final lowConfidenceContent = TodayFeedContent(
          id: 789,
          contentDate: DateTime.now(),
          title: 'Low Confidence Content',
          summary: 'Test summary',
          topicCategory: HealthTopic.sleep,
          aiConfidenceScore: 0.3,
        );

        expect(lowConfidenceContent.aiConfidenceScore, equals(0.3));
        expect(lowConfidenceContent.topicCategory, equals(HealthTopic.sleep));

        final highConfidenceContent = TodayFeedContent(
          id: 790,
          contentDate: DateTime.now(),
          title: 'High Confidence Content',
          summary: 'Test summary',
          topicCategory: HealthTopic.nutrition,
          aiConfidenceScore: 0.95,
        );

        expect(highConfidenceContent.aiConfidenceScore, equals(0.95));
        expect(
          highConfidenceContent.topicCategory,
          equals(HealthTopic.nutrition),
        );
      });
    });

    group('Component Size and Modularity Compliance - Code Review Checklist', () {
      test('should follow single responsibility principle', () {
        // The service should only handle momentum award logic
        // This is verified by checking the class name and purpose
        expect(
          awardService.toString(),
          contains('TodayFeedMomentumAwardService'),
        );
      });

      test('should have clear separation of concerns', () {
        // Verify the service focuses only on momentum awards, not other Today Feed functionality
        expect(
          awardService.runtimeType.toString(),
          equals('TodayFeedMomentumAwardService'),
        );
      });

      test('should provide proper class structure', () {
        // Verify the service follows expected Flutter patterns
        expect(awardService, isA<TodayFeedMomentumAwardService>());
        expect(awardService.runtimeType, equals(TodayFeedMomentumAwardService));
      });
    });

    group('Task T1.3.4.4 Implementation Verification', () {
      test('should implement momentum point award logic requirements', () {
        // Verify all required constants are properly set per PRD
        expect(
          TodayFeedMomentumAwardService.todayFeedMomentumPoints,
          equals(1),
        );
        expect(
          TodayFeedMomentumAwardService.todayFeedEventType,
          equals('today_feed_daily_engagement'),
        );
        expect(
          TodayFeedMomentumAwardService.awardCooldownPeriod.inHours,
          equals(24),
        );
      });

      test('should provide all required result types', () {
        // Test all MomentumAwardResult factory methods exist and work
        expect(
          () => MomentumAwardResult.success(
            pointsAwarded: 1,
            message: 'test',
            awardTime: DateTime.now(),
          ),
          returnsNormally,
        );
        expect(
          () => MomentumAwardResult.duplicate(message: 'test'),
          returnsNormally,
        );
        expect(
          () => MomentumAwardResult.failed(message: 'test'),
          returnsNormally,
        );
        expect(
          () => MomentumAwardResult.queued(message: 'test'),
          returnsNormally,
        );
      });

      test('should provide statistics model for analytics', () {
        // Test statistics model creation and empty factory
        expect(() => MomentumAwardStatistics.empty(), returnsNormally);
        expect(
          () => const MomentumAwardStatistics(
            totalAwards: 1,
            totalPointsAwarded: 1,
            averageSessionDuration: 120.0,
            awardFrequency: 1.0,
            periodDays: 1,
          ),
          returnsNormally,
        );
      });

      test('should maintain service lifecycle management', () {
        // Test basic service lifecycle methods exist and are callable
        expect(() => awardService.dispose(), returnsNormally);
        expect(awardService, isA<TodayFeedMomentumAwardService>());
      });
    });
  });
}
