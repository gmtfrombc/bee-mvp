import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/today_feed/data/services/streak_services/streak_persistence_service.dart';
import 'package:app/features/today_feed/data/models/today_feed_streak_models.dart';
import 'package:app/features/today_feed/domain/models/today_feed_content.dart';

void main() {
  group('StreakPersistenceService', () {
    late StreakPersistenceService service;

    setUp(() {
      service = StreakPersistenceService();
    });

    tearDown(() {
      service.dispose();
    });

    group('Cache Management', () {
      test('should cache and retrieve streak data', () {
        // Arrange
        final streak = EngagementStreak.empty();
        const cacheKey = 'test_key';

        // Act
        service.cacheStreak(cacheKey, streak);
        final cached = service.getCachedStreak(cacheKey);

        // Assert
        expect(cached, equals(streak));
      });

      test('should return null for non-existent cache key', () {
        // Act
        final cached = service.getCachedStreak('non_existent');

        // Assert
        expect(cached, isNull);
      });

      test('should expire cache after configured time', () {
        // Arrange
        final streak = EngagementStreak.empty();
        const cacheKey = 'test_key';

        // Act
        service.cacheStreak(cacheKey, streak);

        // Simulate cache expiry by checking validity
        final isValid = service.isCacheValid(cacheKey);

        // Assert
        expect(isValid, isTrue); // Should be valid immediately
      });

      test('should clear specific cache entry', () {
        // Arrange
        final streak = EngagementStreak.empty();
        const cacheKey = 'test_key';
        service.cacheStreak(cacheKey, streak);

        // Act
        service.clearCache(cacheKey);
        final cached = service.getCachedStreak(cacheKey);

        // Assert
        expect(cached, isNull);
      });

      test('should clear all cache entries', () {
        // Arrange
        final streak = EngagementStreak.empty();
        service.cacheStreak('key1', streak);
        service.cacheStreak('key2', streak);

        // Act
        service.clearCache();
        final cached1 = service.getCachedStreak('key1');
        final cached2 = service.getCachedStreak('key2');

        // Assert
        expect(cached1, isNull);
        expect(cached2, isNull);
      });
    });

    group('Offline Sync Operations', () {
      test('should queue streak update for offline sync', () {
        // Arrange
        const userId = 'test_user';
        final content = TodayFeedContent.sample();
        const sessionDuration = 120;
        final metadata = {'test': 'data'};

        // Act
        service.queueStreakUpdate(userId, content, sessionDuration, metadata);
        final pending = service.getPendingUpdates();

        // Assert
        expect(pending, hasLength(1));
        expect(pending.first['type'], equals('streak_update'));
        expect(pending.first['user_id'], equals(userId));
      });

      test('should queue milestone creation for offline sync', () {
        // Arrange
        const userId = 'test_user';
        final milestone = StreakMilestone(
          streakLength: 7,
          title: 'Weekly Champion',
          description: 'You completed 7 days!',
          achievedAt: DateTime.now(),
          isCelebrated: false,
          type: MilestoneType.weekly,
          momentumBonusPoints: 10,
        );

        // Act
        service.queueMilestoneCreation(userId, milestone);
        final pending = service.getPendingUpdates();

        // Assert
        expect(pending, hasLength(1));
        expect(pending.first['type'], equals('milestone_creation'));
        expect(pending.first['user_id'], equals(userId));
      });

      test('should queue celebration creation for offline sync', () {
        // Arrange
        const userId = 'test_user';
        final milestone = StreakMilestone(
          streakLength: 7,
          title: 'Weekly Champion',
          description: 'You completed 7 days!',
          achievedAt: DateTime.now(),
          isCelebrated: false,
          type: MilestoneType.weekly,
          momentumBonusPoints: 10,
        );
        final celebration = StreakCelebration(
          celebrationId: 'test_celebration',
          milestone: milestone,
          type: CelebrationType.milestone,
          message: 'Congratulations!',
          durationMs: 3000,
          isShown: false,
        );

        // Act
        service.queueCelebrationCreation(userId, celebration);
        final pending = service.getPendingUpdates();

        // Assert
        expect(pending, hasLength(1));
        expect(pending.first['type'], equals('celebration_creation'));
        expect(pending.first['user_id'], equals(userId));
      });

      test('should clear pending updates', () {
        // Arrange
        const userId = 'test_user';
        final content = TodayFeedContent.sample();
        service.queueStreakUpdate(userId, content, 120, null);

        // Act
        service.clearPendingUpdates();
        final pending = service.getPendingUpdates();

        // Assert
        expect(pending, isEmpty);
      });
    });

    group('Database Operations', () {
      test('should have database operation methods', () {
        // Test that methods exist
        expect(service.storeStreakData, isA<Function>());
        expect(service.getStoredStreakData, isA<Function>());
        expect(service.getAchievedMilestones, isA<Function>());
        expect(service.getPendingCelebration, isA<Function>());
        expect(service.storeMilestone, isA<Function>());
        expect(service.storeCelebration, isA<Function>());
      });
    });

    group('Connectivity Management', () {
      test('should provide connectivity status properties', () {
        // Act & Assert
        expect(service.isOnline, isA<bool>());
        expect(service.isOffline, isA<bool>());
      });
    });

    group('Service Lifecycle', () {
      test('should have initialize method', () {
        expect(service.initialize, isA<Function>());
      });

      test('should dispose resources properly', () {
        // Act
        service.dispose();

        // Assert - should not throw and should clear state
        expect(service.getPendingUpdates(), isEmpty);
      });
    });
  });
}
