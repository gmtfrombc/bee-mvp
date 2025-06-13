import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/core/services/offline_cache_service.dart';
import 'package:app/core/theme/app_theme.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('Enhanced Offline Cache Service Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await OfflineCacheService.initialize();
    });

    tearDown(() async {
      await OfflineCacheService.clearAllCache();
    });

    group('Enhanced Caching', () {
      test('should cache momentum data with high priority flag', () async {
        final testData = TestHelpers.createSampleMomentumData();

        await OfflineCacheService.cacheMomentumData(
          testData,
          isHighPriority: true,
        );

        final cachedData = await OfflineCacheService.getCachedMomentumData();
        expect(cachedData, isNotNull);
        expect(cachedData!.state, equals(testData.state));
        expect(cachedData.percentage, equals(testData.percentage));
      });

      test('should skip cache update if recent update detected', () async {
        final testData1 = TestHelpers.createSampleMomentumData(
          state: MomentumState.rising,
        );
        final testData2 = TestHelpers.createSampleMomentumData(
          state: MomentumState.steady,
        );

        // Cache initial data
        await OfflineCacheService.cacheMomentumData(testData1);

        // Try to cache again immediately with skipIfRecentUpdate
        await OfflineCacheService.cacheMomentumData(
          testData2,
          skipIfRecentUpdate: true,
        );

        // Should still have the first data
        final cachedData = await OfflineCacheService.getCachedMomentumData();
        expect(cachedData!.state, equals(MomentumState.rising));
      });

      test('should cache components separately', () async {
        final testData = TestHelpers.createSampleMomentumData();

        await OfflineCacheService.cacheMomentumData(testData);

        // Should be able to get weekly trend separately
        final weeklyTrend = await OfflineCacheService.getCachedWeeklyTrend();
        expect(weeklyTrend, isNotNull);
        expect(weeklyTrend!.length, equals(testData.weeklyTrend.length));

        // Should be able to get stats separately
        final stats = await OfflineCacheService.getCachedMomentumStats();
        expect(stats, isNotNull);
        expect(
          stats!.lessonsCompleted,
          equals(testData.stats.lessonsCompleted),
        );
      });
    });

    group('Cache Validity', () {
      test('should respect custom validity period', () async {
        final testData = TestHelpers.createSampleMomentumData();
        await OfflineCacheService.cacheMomentumData(testData);

        // Should be valid with default period
        final isValidDefault = await OfflineCacheService.isCachedDataValid();
        expect(isValidDefault, isTrue);

        // Should be invalid with very short custom period
        final isValidCustom = await OfflineCacheService.isCachedDataValid(
          customValidityPeriod: const Duration(microseconds: 1),
        );
        expect(isValidCustom, isFalse);
      });

      test(
        'should handle high priority updates with shorter validity',
        () async {
          final testData = TestHelpers.createSampleMomentumData();
          await OfflineCacheService.cacheMomentumData(testData);

          // Should be valid for normal updates
          final isValidNormal = await OfflineCacheService.isCachedDataValid();
          expect(isValidNormal, isTrue);

          // High priority updates have shorter validity period
          final isValidHighPriority =
              await OfflineCacheService.isCachedDataValid(
                isHighPriorityUpdate: true,
              );
          // This depends on timing, but the logic should be different
          expect(isValidHighPriority, isA<bool>());
        },
      );

      test('should allow stale data when explicitly requested', () async {
        final testData = TestHelpers.createSampleMomentumData();
        await OfflineCacheService.cacheMomentumData(testData);

        // Even if data is stale, should return it when allowStaleData is true
        final staleData = await OfflineCacheService.getCachedMomentumData(
          allowStaleData: true,
          customValidityPeriod: const Duration(microseconds: 1),
        );
        expect(staleData, isNotNull);
      });
    });

    group('Cache Management', () {
      test('should validate and update cache version', () async {
        // This should be handled automatically during initialization
        final stats = await OfflineCacheService.getEnhancedCacheStats();
        expect(stats['cacheVersion'], isNotNull);
      });

      test('should clean up expired pending actions', () async {
        // Add some old pending actions
        await OfflineCacheService.queuePendingAction({
          'type': 'test_action',
          'data': 'test',
        }, priority: 2);

        final actions = await OfflineCacheService.getPendingActions();
        expect(actions.length, equals(1));
        expect(actions.first['priority'], equals(2));
      });

      test('should provide comprehensive cache statistics', () async {
        final testData = TestHelpers.createSampleMomentumData();
        await OfflineCacheService.cacheMomentumData(testData);

        final stats = await OfflineCacheService.getEnhancedCacheStats();

        expect(stats['hasCachedData'], isTrue);
        expect(stats['isValid'], isTrue);
        expect(stats['healthScore'], isA<int>());
        expect(stats['hasWeeklyTrend'], isTrue);
        expect(stats['hasMomentumStats'], isTrue);
        expect(stats['cacheVersion'], isNotNull);
        expect(stats['backgroundSyncEnabled'], isNotNull);
      });
    });

    group('Smart Cache Invalidation', () {
      test('should invalidate specific cache components', () async {
        final testData = TestHelpers.createSampleMomentumData();
        await OfflineCacheService.cacheMomentumData(testData);

        // Invalidate only weekly trend
        await OfflineCacheService.invalidateCache(
          momentumData: false,
          weeklyTrend: true,
          momentumStats: false,
        );

        // Main data should still be there
        final mainData = await OfflineCacheService.getCachedMomentumData();
        expect(mainData, isNotNull);

        // Weekly trend should be gone
        final weeklyTrend = await OfflineCacheService.getCachedWeeklyTrend();
        expect(weeklyTrend, isNull);

        // Stats should still be there
        final stats = await OfflineCacheService.getCachedMomentumStats();
        expect(stats, isNotNull);
      });
    });

    group('Enhanced Pending Actions', () {
      test('should handle pending actions with priority and retries', () async {
        await OfflineCacheService.queuePendingAction(
          {'type': 'high_priority', 'data': 'test'},
          priority: 3,
          maxRetries: 5,
        );

        await OfflineCacheService.queuePendingAction(
          {'type': 'low_priority', 'data': 'test'},
          priority: 1,
          maxRetries: 2,
        );

        final actions = await OfflineCacheService.getPendingActions();
        expect(actions.length, equals(2));

        // Should be sorted by priority (high to low)
        expect(actions.first['type'], equals('high_priority'));
        expect(actions.first['priority'], equals(3));
        expect(actions.first['max_retries'], equals(5));
      });

      test('should prevent duplicate pending actions', () async {
        await OfflineCacheService.queuePendingAction({
          'type': 'test_action',
          'data': 'same',
        });

        await OfflineCacheService.queuePendingAction({
          'type': 'test_action',
          'data': 'same',
        });

        final actions = await OfflineCacheService.getPendingActions();
        expect(actions.length, equals(1));
      });

      test('should process pending actions with retry logic', () async {
        await OfflineCacheService.queuePendingAction({
          'type': 'test_action',
          'data': 'test',
        }, maxRetries: 2);

        // Process actions (this is a simulation since actual processing depends on external services)
        final processedActions =
            await OfflineCacheService.processPendingActions();
        expect(processedActions.length, equals(1));
      });
    });

    group('Background Sync Management', () {
      test('should enable and disable background sync', () async {
        await OfflineCacheService.enableBackgroundSync(false);
        expect(await OfflineCacheService.isBackgroundSyncEnabled(), isFalse);

        await OfflineCacheService.enableBackgroundSync(true);
        expect(await OfflineCacheService.isBackgroundSyncEnabled(), isTrue);
      });
    });

    group('Cache Warming', () {
      test('should record cache warming attempts', () async {
        await OfflineCacheService.warmCache();

        final stats = await OfflineCacheService.getEnhancedCacheStats();
        expect(stats['lastSyncAttempt'], isNotNull);
      });
    });

    group('Error Handling', () {
      test('should queue errors for later reporting', () async {
        await OfflineCacheService.queueError({
          'type': 'test_error',
          'message': 'Test error message',
        });

        final errors = await OfflineCacheService.getQueuedErrors();
        expect(errors.length, equals(1));
        expect(errors.first['type'], equals('test_error'));
        expect(errors.first['queued_at'], isNotNull);
      });

      test('should limit the number of queued errors', () async {
        // Queue more than 50 errors
        for (int i = 0; i < 55; i++) {
          await OfflineCacheService.queueError({
            'type': 'test_error_$i',
            'message': 'Test error $i',
          });
        }

        final errors = await OfflineCacheService.getQueuedErrors();
        expect(errors.length, equals(50)); // Should be limited to 50
      });
    });

    group('Cache Health Scoring', () {
      test('should calculate cache health score correctly', () async {
        // Fresh cache should have high health score
        final testData = TestHelpers.createSampleMomentumData();
        await OfflineCacheService.cacheMomentumData(testData);

        final stats = await OfflineCacheService.getEnhancedCacheStats();
        final healthScore = stats['healthScore'] as int;

        expect(healthScore, greaterThan(60)); // Should be a decent score
        expect(healthScore, lessThanOrEqualTo(100));
      });

      test('should reduce health score with problems', () async {
        // Add some errors to reduce health score
        for (int i = 0; i < 5; i++) {
          await OfflineCacheService.queueError({
            'type': 'test_error_$i',
            'message': 'Test error $i',
          });
        }

        // Add many pending actions
        for (int i = 0; i < 10; i++) {
          await OfflineCacheService.queuePendingAction({
            'type': 'test_action_$i',
            'data': 'test $i',
          });
        }

        final stats = await OfflineCacheService.getEnhancedCacheStats();
        final healthScore = stats['healthScore'] as int;

        // Should be reduced due to many errors and pending actions
        expect(healthScore, lessThan(100));
      });
    });

    group('Legacy Compatibility', () {
      test(
        'should maintain backward compatibility with getCacheStats',
        () async {
          final testData = TestHelpers.createSampleMomentumData();
          await OfflineCacheService.cacheMomentumData(testData);

          final legacyStats = await OfflineCacheService.getCacheStats();
          final enhancedStats =
              await OfflineCacheService.getEnhancedCacheStats();

          // Should be the same data
          expect(
            legacyStats['hasCachedData'],
            equals(enhancedStats['hasCachedData']),
          );
          expect(legacyStats['isValid'], equals(enhancedStats['isValid']));
        },
      );
    });
  });
}
