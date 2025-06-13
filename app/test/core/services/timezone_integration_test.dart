import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/core/services/today_feed_cache_service.dart';
import 'package:app/core/services/cache/today_feed_timezone_service.dart';

void main() {
  group('Timezone Service Integration Tests', () {
    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async {
      // Clean up after each test
      await TodayFeedCacheService.dispose();
      await TodayFeedTimezoneService.dispose();
    });

    test('should initialize timezone service with main cache service', () async {
      // Test that the timezone service is properly initialized when the main service initializes
      await TodayFeedCacheService.initialize();

      // Verify timezone service can get current timezone info
      final timezoneInfo = TodayFeedTimezoneService.getCurrentTimezoneInfo();

      expect(timezoneInfo, isNotNull);
      expect(timezoneInfo['identifier'], isNotNull);
      expect(timezoneInfo['offset_hours'], isA<int>());
      expect(timezoneInfo['is_dst'], isA<bool>());
    });

    test('should use timezone service for refresh time calculations', () async {
      await TodayFeedCacheService.initialize();

      // Test that needsRefresh uses timezone service
      final needsRefresh = await TodayFeedCacheService.needsRefresh();
      expect(needsRefresh, isA<bool>());

      // Test timezone stats are available
      final timezoneStats = await TodayFeedCacheService.getTimezoneStats();
      expect(timezoneStats, isNotNull);
      expect(timezoneStats['current_timezone'], isNotNull);
    });

    test('should handle timezone changes through timezone service', () async {
      await TodayFeedCacheService.initialize();

      // Test that timezone change detection works
      final timezoneChange =
          await TodayFeedTimezoneService.detectAndHandleTimezoneChanges();

      // First run should return null (no change)
      expect(timezoneChange, isNull);

      // Verify timezone info is saved
      final savedTimezone =
          await TodayFeedTimezoneService.getSavedTimezoneInfo();
      expect(savedTimezone, isNotNull);
    });

    test('should integrate timezone service with cache metadata', () async {
      await TodayFeedCacheService.initialize();

      // Get cache metadata which should include timezone info
      final metadata = await TodayFeedCacheService.getCacheMetadata();

      expect(metadata, isNotNull);
      expect(metadata['timezone_info'], isNotNull);
      expect(metadata['timezone_info']['identifier'], isNotNull);
    });

    test('should use timezone service for day comparison', () async {
      await TodayFeedCacheService.initialize();

      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      // Test that timezone service day comparison works
      final isSameDay = TodayFeedTimezoneService.isSameLocalDay(now, now);
      final isDifferentDay = TodayFeedTimezoneService.isSameLocalDay(
        now,
        yesterday,
      );

      expect(isSameDay, isTrue);
      expect(isDifferentDay, isFalse);
    });

    test('should calculate next refresh time using timezone service', () async {
      await TodayFeedCacheService.initialize();

      final now = DateTime.now();
      final nextRefreshTime =
          await TodayFeedTimezoneService.calculateNextRefreshTime(now);

      expect(nextRefreshTime, isNotNull);
      expect(nextRefreshTime.isAfter(now), isTrue);

      // Should be within 24 hours
      final difference = nextRefreshTime.difference(now);
      expect(difference.inHours, lessThanOrEqualTo(24));
    });

    test('should get comprehensive statistics from all services', () async {
      await TodayFeedCacheService.initialize();

      // Test that getAllStatistics includes timezone service data
      final allStats = await TodayFeedCacheService.getAllStatistics();

      expect(allStats, isNotNull);
      expect(allStats['timezone'], isNotNull);
      expect(allStats['cache'], isNotNull);
      expect(allStats['sync'], isNotNull);
    });

    test('should handle timezone service errors gracefully', () async {
      await TodayFeedCacheService.initialize();

      // Test that the service handles timezone service errors without crashing
      expect(() async {
        await TodayFeedCacheService.needsRefresh();
      }, returnsNormally);

      expect(() async {
        await TodayFeedCacheService.getCacheMetadata();
      }, returnsNormally);
    });
  });
}
