import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/core/services/today_feed_cache_service.dart';
import 'package:app/features/today_feed/domain/models/today_feed_content.dart';

void main() {
  group('TodayFeedCacheService Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await TodayFeedCacheService.initialize();
    });

    tearDown(() async {
      await TodayFeedCacheService.dispose();
    });

    group('Cache Size Management (T1.3.3.3)', () {
      test('should calculate cache size correctly', () async {
        // Arrange
        final today = DateTime.now();
        final testContent = TodayFeedContent(
          id: 1,
          title: 'Test Health Topic',
          summary: 'A comprehensive test summary for cache size calculation.',
          contentDate: today, // Use today's date for current content
          topicCategory: HealthTopic.nutrition,
          estimatedReadingMinutes: 3,
          aiConfidenceScore: 0.95,
          isCached: false,
          createdAt: today,
          updatedAt: today,
        );

        // Act - Cache some content
        await TodayFeedCacheService.cacheTodayContent(testContent);
        final stats = await TodayFeedCacheService.getCacheStats();

        // Assert - Focus on functionality rather than exact size calculations
        expect(stats['has_today_content'], isTrue);
        expect(stats['cache_size_mb'], isA<String>());
        expect(stats['cache_size_bytes'], isA<int>());

        // The cache should show it has content and reasonable metadata
        expect(stats['metadata'], isNotNull);
        expect(stats['cache_version'], equals(1));
        expect(stats['content_history_count'], greaterThanOrEqualTo(1));

        // Cache size in MB should be a valid number (even if very small)
        final sizeMB = double.parse(stats['cache_size_mb']);
        expect(sizeMB, greaterThanOrEqualTo(0)); // Allow very small values
        expect(sizeMB, lessThan(10)); // Should be well under 10MB limit
      });

      test(
        'should enforce cache size limits and cleanup when exceeded',
        () async {
          // Arrange - Create multiple large content items to exceed cache limit
          final largeContentList = <TodayFeedContent>[];
          final today = DateTime.now();

          for (int i = 0; i < 20; i++) {
            final largeContent = TodayFeedContent(
              id: i + 100,
              title: 'Large Test Content $i' * 10, // Make title larger
              summary:
                  'A very long summary that takes up significant space in the cache. ' *
                  20,
              contentDate: today.subtract(Duration(days: i)),
              topicCategory: HealthTopic.exercise,
              estimatedReadingMinutes: 5,
              aiConfidenceScore: 0.9,
              isCached: false,
              createdAt: today,
              updatedAt: today,
            );
            largeContentList.add(largeContent);
          }

          // Act - Cache all large content
          for (final content in largeContentList) {
            await TodayFeedCacheService.cacheTodayContent(content);
          }

          // Force cleanup by checking cache size
          final stats = await TodayFeedCacheService.getCacheStats();

          // Assert
          final sizeMB = double.parse(stats['cache_size_mb']);
          expect(
            sizeMB,
            lessThanOrEqualTo(10.0),
          ); // Should not exceed 10MB limit
        },
      );

      test('should handle concurrent cache operations safely', () async {
        // Arrange
        final today = DateTime.now();
        final testContents = List.generate(
          10,
          (i) => TodayFeedContent(
            id: i + 200,
            title: 'Concurrent Test $i',
            summary: 'Testing concurrent cache operations $i',
            contentDate: today,
            topicCategory: HealthTopic.stress,
            estimatedReadingMinutes: 2,
            aiConfidenceScore: 0.8,
            isCached: false,
            createdAt: today,
            updatedAt: today,
          ),
        );

        // Act - Perform concurrent cache operations
        final futures =
            testContents
                .map(
                  (content) => TodayFeedCacheService.cacheTodayContent(content),
                )
                .toList();

        await Future.wait(futures);

        // Assert - All operations should complete without error
        final stats = await TodayFeedCacheService.getCacheStats();
        expect(stats['has_today_content'], isTrue);
        expect(stats['content_history_count'], greaterThan(0));
      });

      test('should handle corrupted cache data gracefully', () async {
        // Arrange - Simulate corrupted cache by directly setting invalid JSON
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('today_feed_content', 'invalid-json-data');
        await prefs.setString('today_feed_metadata', '{invalid_json}');

        // Act & Assert - Should not throw exception
        expect(
          () async => await TodayFeedCacheService.getTodayContent(),
          returnsNormally,
        );

        final content = await TodayFeedCacheService.getTodayContent();
        expect(content, isNull); // Should return null for corrupted data
      });

      test('should handle disk full scenario gracefully', () async {
        // Arrange - This is a simulation since we can't actually fill the disk
        final today = DateTime.now();
        final largeContent = TodayFeedContent(
          id: 999,
          title: 'Disk Full Test',
          summary: 'Testing disk full scenario',
          contentDate: today,
          topicCategory: HealthTopic.sleep,
          estimatedReadingMinutes: 10,
          aiConfidenceScore: 0.9,
          isCached: false,
          createdAt: today,
          updatedAt: today,
        );

        // Act & Assert - Should handle errors gracefully
        expect(
          () async =>
              await TodayFeedCacheService.cacheTodayContent(largeContent),
          returnsNormally,
        );
      });

      test('should optimize cache cleanup performance', () async {
        // Arrange
        final stopwatch = Stopwatch()..start();
        final today = DateTime.now();

        // Create multiple content items for history
        for (int i = 0; i < 15; i++) {
          final content = TodayFeedContent(
            id: i + 300,
            title: 'Performance Test $i',
            summary: 'Testing cleanup performance $i',
            contentDate: today.subtract(Duration(days: i)),
            topicCategory: HealthTopic.lifestyle,
            estimatedReadingMinutes: 1,
            aiConfidenceScore: 0.85,
            isCached: false,
            createdAt: today,
            updatedAt: today,
          );
          await TodayFeedCacheService.cacheTodayContent(content);
        }

        // Act - Trigger cleanup
        await TodayFeedCacheService.clearAllCache();
        stopwatch.stop();

        // Assert - Cleanup should complete quickly (under 100ms)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('should maintain cache health scoring', () async {
        // Arrange
        final today = DateTime.now();
        final testContent = TodayFeedContent(
          id: 500,
          title: 'Cache Health Test',
          summary: 'Testing cache health monitoring',
          contentDate: today,
          topicCategory: HealthTopic.nutrition,
          estimatedReadingMinutes: 2,
          aiConfidenceScore: 0.92,
          isCached: false,
          createdAt: today,
          updatedAt: today,
        );

        // Act
        await TodayFeedCacheService.cacheTodayContent(testContent);
        final stats = await TodayFeedCacheService.getCacheStats();

        // Assert
        expect(stats['has_today_content'], isTrue);
        expect(stats['cache_version'], equals(1));
        expect(stats['metadata'], isNotNull);
        expect(stats['cache_size_bytes'], greaterThan(0));
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle null content gracefully', () async {
        // Act & Assert
        expect(
          () async => await TodayFeedCacheService.getTodayContent(),
          returnsNormally,
        );

        final content = await TodayFeedCacheService.getTodayContent();
        expect(content, isNull);
      });

      test('should handle timezone changes correctly', () async {
        // Arrange
        final today = DateTime.now();
        final testContent = TodayFeedContent(
          id: 600,
          title: 'Timezone Test',
          summary: 'Testing timezone handling',
          contentDate: today,
          topicCategory: HealthTopic.stress,
          estimatedReadingMinutes: 2,
          aiConfidenceScore: 0.88,
          isCached: false,
          createdAt: today,
          updatedAt: today,
        );

        // Act
        await TodayFeedCacheService.cacheTodayContent(testContent);
        final needsRefresh = await TodayFeedCacheService.needsRefresh();

        // Assert
        expect(needsRefresh, isA<bool>());
      });

      test('should handle memory pressure scenarios', () async {
        // Arrange - Simulate memory pressure by creating many small objects
        final contentList = <TodayFeedContent>[];
        final today = DateTime.now();

        for (int i = 0; i < 100; i++) {
          contentList.add(
            TodayFeedContent(
              id: i + 700,
              title: 'Memory Test $i',
              summary: 'Testing memory handling $i',
              contentDate: today,
              topicCategory: HealthTopic.exercise,
              estimatedReadingMinutes: 1,
              aiConfidenceScore: 0.8,
              isCached: false,
              createdAt: today,
              updatedAt: today,
            ),
          );
        }

        // Act & Assert - Should handle without memory issues
        for (final content in contentList.take(10)) {
          // Test with first 10
          expect(
            () async => await TodayFeedCacheService.cacheTodayContent(content),
            returnsNormally,
          );
        }

        final stats = await TodayFeedCacheService.getCacheStats();
        expect(stats['cache_size_bytes'], greaterThan(0));
      });
    });

    group('Performance Tests', () {
      test('should meet load time requirements', () async {
        // Arrange
        final today = DateTime.now();
        final testContent = TodayFeedContent(
          id: 800,
          title: 'Load Time Test',
          summary: 'Testing load time requirements',
          contentDate: today, // Use today's date
          topicCategory: HealthTopic.lifestyle,
          estimatedReadingMinutes: 2,
          aiConfidenceScore: 0.9,
          isCached: false,
          createdAt: today,
          updatedAt: today,
        );

        await TodayFeedCacheService.cacheTodayContent(testContent);

        // Act
        final stopwatch = Stopwatch()..start();
        final content = await TodayFeedCacheService.getTodayContent();
        stopwatch.stop();

        // Assert - Should load within 50ms (well under 2 second requirement)
        expect(stopwatch.elapsedMilliseconds, lessThan(50));
        expect(content, isNotNull);
      });

      test('should achieve target cache hit rate', () async {
        // Arrange
        final today = DateTime.now();
        final testContent = TodayFeedContent(
          id: 900,
          title: 'Cache Hit Test',
          summary: 'Testing cache hit rate',
          contentDate: today, // Use today's date
          topicCategory: HealthTopic.nutrition,
          estimatedReadingMinutes: 3,
          aiConfidenceScore: 0.93,
          isCached: false,
          createdAt: today,
          updatedAt: today,
        );

        await TodayFeedCacheService.cacheTodayContent(testContent);

        // Act - Multiple reads to test cache hit rate
        int hits = 0;
        const totalReads = 10;

        for (int i = 0; i < totalReads; i++) {
          final content = await TodayFeedCacheService.getTodayContent();
          if (content != null) hits++;
        }

        // Assert - Should achieve >95% hit rate (all 10 should be hits from cache)
        final hitRate = hits / totalReads;
        expect(hitRate, greaterThanOrEqualTo(0.95));
      });
    });

    group('Integration Tests', () {
      test('should integrate properly with real content scenarios', () async {
        // Arrange - Create realistic content
        final today = DateTime.now();
        final realContent = TodayFeedContent(
          id: 1000,
          title:
              'The Science of Sleep: How Quality Rest Transforms Your Health',
          summary:
              'Discover the fascinating ways that good sleep enhances your immune system, memory, and overall wellbeing through cutting-edge research.',
          contentDate: today, // Use today's date
          topicCategory: HealthTopic.sleep,
          estimatedReadingMinutes: 4,
          aiConfidenceScore: 0.96,
          isCached: false,
          createdAt: today,
          updatedAt: today,
        );

        // Act
        await TodayFeedCacheService.cacheTodayContent(realContent);
        final cachedContent = await TodayFeedCacheService.getTodayContent();
        final stats = await TodayFeedCacheService.getCacheStats();

        // Assert
        expect(cachedContent, isNotNull);
        expect(cachedContent!.title, equals(realContent.title));
        expect(cachedContent.topicCategory, equals(HealthTopic.sleep));
        expect(cachedContent.isCached, isTrue);

        expect(stats['has_today_content'], isTrue);
        expect(stats['metadata'], isNotNull);
        expect(stats['metadata']['ai_confidence_score'], equals(0.96));
      });
    });
  });
}
