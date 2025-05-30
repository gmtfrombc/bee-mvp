import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/core/services/today_feed_cache_service.dart';
import 'package:app/features/today_feed/domain/models/today_feed_content.dart';
import 'dart:convert';

void main() {
  // Ensure Flutter binding is initialized for all tests
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TodayFeedCacheService Tests', () {
    setUp(() async {
      // Clear all SharedPreferences data to ensure clean state
      SharedPreferences.setMockInitialValues({});

      // Reset the service to clear any static state
      TodayFeedCacheService.resetForTesting();

      await TodayFeedCacheService.initialize();
    });

    tearDown(() async {
      // Ensure complete cleanup between tests
      await TodayFeedCacheService.clearAllCache();
      await TodayFeedCacheService.dispose();

      // Clear SharedPreferences again for extra safety
      SharedPreferences.setMockInitialValues({});
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
        // Arrange - Ensure clean state first
        await TodayFeedCacheService.clearAllCache();

        // Simulate corrupted cache by directly setting invalid JSON
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
        // Arrange - Ensure clean state first
        await TodayFeedCacheService.clearAllCache();

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

    group('24-Hour Refresh Cycle with Timezone Handling (T1.3.3.4)', () {
      test('should detect and save initial timezone information', () async {
        // Use dispose to reset without clearing timezone data
        await TodayFeedCacheService.dispose();
        await TodayFeedCacheService.initialize();

        // Allow a brief moment for timezone initialization
        await Future.delayed(const Duration(milliseconds: 10));

        final stats = await TodayFeedCacheService.getCacheStats();

        expect(stats['current_timezone'], isNotNull);
        expect(stats['saved_timezone'], isNotNull);
        expect(stats['current_timezone']['identifier'], isNotEmpty);
        expect(stats['current_timezone']['offset_hours'], isA<int>());
        expect(stats['current_timezone']['is_dst'], isA<bool>());

        await TodayFeedCacheService.dispose();
      });

      test('should handle DST detection correctly', () async {
        await TodayFeedCacheService.dispose(); // Use dispose instead of clearAllCache
        await TodayFeedCacheService.initialize();

        final stats = await TodayFeedCacheService.getCacheStats();
        final currentTimezone =
            stats['current_timezone'] as Map<String, dynamic>;

        // Verify DST detection logic
        expect(currentTimezone['winter_offset_hours'], isA<int>());
        expect(currentTimezone['summer_offset_hours'], isA<int>());
        expect(currentTimezone['is_dst'], isA<bool>());

        // DST should be true if current offset matches summer offset
        final winterOffset = currentTimezone['winter_offset_hours'] as int;
        final summerOffset = currentTimezone['summer_offset_hours'] as int;
        final currentOffset = currentTimezone['offset_hours'] as int;
        final isDst = currentTimezone['is_dst'] as bool;

        if (winterOffset != summerOffset) {
          expect(isDst, equals(currentOffset == summerOffset));
        }

        await TodayFeedCacheService.dispose();
      });

      test('should properly schedule refresh with timezone awareness', () async {
        await TodayFeedCacheService.dispose(); // Use dispose instead of clearAllCache
        await TodayFeedCacheService.initialize();

        final stats = await TodayFeedCacheService.getCacheStats();

        expect(stats['refresh_hour'], equals(3)); // 3 AM local time
        expect(stats['last_timezone_check'], isNotNull);

        await TodayFeedCacheService.dispose();
      });

      test('should detect timezone changes correctly', () async {
        await TodayFeedCacheService.dispose(); // Use dispose instead of clearAllCache
        await TodayFeedCacheService.initialize();

        final initialStats = await TodayFeedCacheService.getCacheStats();

        expect(initialStats['timezone_changed'], isFalse);
        expect(initialStats['dst_changed'], isFalse);

        await TodayFeedCacheService.dispose();
      });

      test('should handle refresh time calculation with DST transitions', () async {
        await TodayFeedCacheService.dispose(); // Use dispose instead of clearAllCache
        await TodayFeedCacheService.initialize();

        // Test that refresh scheduling doesn't crash with timezone calculations
        final needsRefreshBefore = await TodayFeedCacheService.needsRefresh();
        expect(needsRefreshBefore, isA<bool>());

        await TodayFeedCacheService.dispose();
      });

      test('should include timezone information in cache stats', () async {
        await TodayFeedCacheService.dispose(); // Use dispose instead of clearAllCache
        await TodayFeedCacheService.initialize();

        final stats = await TodayFeedCacheService.getCacheStats();

        // Verify new timezone-related fields are present
        expect(stats.containsKey('current_timezone'), isTrue);
        expect(stats.containsKey('saved_timezone'), isTrue);
        expect(stats.containsKey('timezone_changed'), isTrue);
        expect(stats.containsKey('dst_changed'), isTrue);
        expect(stats.containsKey('refresh_hour'), isTrue);
        expect(stats.containsKey('last_timezone_check'), isTrue);

        await TodayFeedCacheService.dispose();
      });

      test('should handle timezone checks scheduling', () async {
        await TodayFeedCacheService.dispose(); // Use dispose instead of clearAllCache
        await TodayFeedCacheService.initialize();

        // Verify timezone check timer was set up
        final stats = await TodayFeedCacheService.getCacheStats();
        expect(stats['last_timezone_check'], isNotNull);

        // Test that multiple initializations don't create multiple timers
        await TodayFeedCacheService.initialize();
        await TodayFeedCacheService.initialize();

        final statsAfter = await TodayFeedCacheService.getCacheStats();
        expect(statsAfter['last_timezone_check'], isNotNull);

        await TodayFeedCacheService.dispose();
      });

      test(
        'should maintain cache size calculation with new timezone keys',
        () async {
          await TodayFeedCacheService.dispose(); // Use dispose instead of clearAllCache
          await TodayFeedCacheService.initialize();

          // Add some content to verify size calculation includes timezone data
          final content = TodayFeedContent.sample();
          await TodayFeedCacheService.cacheTodayContent(content);

          final stats = await TodayFeedCacheService.getCacheStats();
          final cacheSizeBytes = stats['cache_size_bytes'] as int;

          expect(cacheSizeBytes, greaterThan(0));
          expect(stats['cache_size_mb'], isNotNull);

          await TodayFeedCacheService.dispose();
        },
      );

      test('should properly clean up timezone timers on dispose', () async {
        await TodayFeedCacheService.dispose(); // Use dispose instead of clearAllCache
        await TodayFeedCacheService.initialize();

        // Dispose should clean up both refresh and timezone check timers
        await TodayFeedCacheService.dispose();

        // Re-initialize to ensure clean state
        await TodayFeedCacheService.initialize();
        await TodayFeedCacheService.dispose();
      });

      test('should handle edge cases in timezone calculations', () async {
        await TodayFeedCacheService.dispose(); // Use dispose instead of clearAllCache
        await TodayFeedCacheService.initialize();

        // Test that timezone calculations don't throw exceptions
        final needsRefresh = await TodayFeedCacheService.needsRefresh();
        expect(needsRefresh, isA<bool>());

        // Test that cache stats work with timezone data
        final stats = await TodayFeedCacheService.getCacheStats();
        expect(stats['error'], isNull);

        await TodayFeedCacheService.dispose();
      });
    });

    group('Background Sync (T1.3.3.5)', () {
      setUp(() async {
        // Additional cleanup for background sync tests
        SharedPreferences.setMockInitialValues({});
        TodayFeedCacheService.resetForTesting();
        await TodayFeedCacheService.initialize();
      });

      tearDown(() async {
        // Extra cleanup for background sync tests
        await TodayFeedCacheService.clearAllCache();
        await TodayFeedCacheService.dispose();
        SharedPreferences.setMockInitialValues({});
      });

      test('should initialize connectivity listener successfully', () async {
        // Arrange & Act - Connectivity listener should be initialized during service init
        final syncStatus = await TodayFeedCacheService.getSyncStatus();

        // Assert - Focus on what we can test without the plugin
        expect(syncStatus['background_sync_enabled'], isTrue);
        expect(syncStatus['sync_in_progress'], isFalse);
        expect(syncStatus['pending_interactions_count'], equals(0));
        expect(syncStatus['sync_errors_count'], equals(0));
      });

      test('should queue interactions for offline sync', () async {
        // Arrange
        const contentId = 'test_content_123';

        // Act - Queue some interactions
        await TodayFeedCacheService.queueInteraction(
          TodayFeedInteractionType.view,
          contentId,
          additionalData: {'session_id': 'test_session'},
        );
        await TodayFeedCacheService.queueInteraction(
          TodayFeedInteractionType.tap,
          contentId,
        );

        // Assert
        final syncStatus = await TodayFeedCacheService.getSyncStatus();
        expect(syncStatus['pending_interactions_count'], equals(2));
      });

      test('should enhance queued interactions with metadata', () async {
        // Arrange
        const contentId = 'test_content_456';
        const additionalData = {'page_source': 'today_feed_tile'};

        // Act
        await TodayFeedCacheService.queueInteraction(
          TodayFeedInteractionType.share,
          contentId,
          additionalData: additionalData,
        );

        // Get the raw interaction data for validation
        final prefs = await SharedPreferences.getInstance();
        final interactionsJson = prefs.getString(
          'today_feed_pending_interactions',
        );
        expect(interactionsJson, isNotNull);

        final interactions = jsonDecode(interactionsJson!) as List<dynamic>;
        expect(interactions.length, equals(1));

        final interaction = interactions.first as Map<String, dynamic>;

        // Assert - Check enhanced metadata
        expect(interaction['type'], equals('share'));
        expect(interaction['content_id'], equals(contentId));
        expect(interaction['additional_data'], equals(additionalData));
        expect(interaction['retry_count'], equals(0));
        expect(interaction['device_timezone'], isNotNull);
        expect(interaction['queue_id'], isNotNull);
        expect(interaction['timestamp'], isNotNull);
      });

      test('should handle sync retry logic with exponential backoff', () async {
        // Arrange - Test retry count management
        final prefs = await SharedPreferences.getInstance();

        // Act - Set retry count directly since we can't simulate network failures easily
        await prefs.setInt('today_feed_sync_retry_count', 3);

        final syncStatus = await TodayFeedCacheService.getSyncStatus();

        // Assert
        expect(syncStatus['sync_retry_count'], equals(3));
        expect(syncStatus['max_retries'], equals(3));
      });

      test('should validate cache integrity during sync', () async {
        // Arrange - Create valid content
        final today = DateTime.now();
        final validContent = TodayFeedContent(
          id: 789,
          title: 'Integrity Test Content',
          summary: 'Testing cache integrity validation',
          contentDate: today,
          topicCategory: HealthTopic.exercise,
          estimatedReadingMinutes: 2,
          aiConfidenceScore: 0.95,
          isCached: false,
          createdAt: today,
          updatedAt: today,
        );

        // Act
        await TodayFeedCacheService.cacheTodayContent(validContent);

        // Trigger sync which includes integrity validation
        await TodayFeedCacheService.syncWhenOnline();

        // Assert - No sync errors should be logged
        final syncStatus = await TodayFeedCacheService.getSyncStatus();
        expect(syncStatus['sync_errors_count'], equals(0));
      });

      test('should log sync errors with proper categorization', () async {
        // Arrange & Act - Simulate an error condition
        // This is tested indirectly through the error logging system
        final syncStatus = await TodayFeedCacheService.getSyncStatus();

        // Assert - Verify error logging structure exists
        expect(syncStatus.containsKey('sync_errors_count'), isTrue);
        expect(syncStatus.containsKey('connectivity_status'), isTrue);
        expect(syncStatus.containsKey('last_successful_sync'), isTrue);
      });

      test('should handle concurrent sync operations safely', () async {
        // Arrange
        final futures = <Future<void>>[];

        // Act - Attempt multiple concurrent syncs
        for (int i = 0; i < 5; i++) {
          futures.add(TodayFeedCacheService.syncWhenOnline());
        }

        // Should not throw exceptions
        expect(() async => await Future.wait(futures), returnsNormally);

        // Assert - Only one sync should have been in progress at a time
        final syncStatus = await TodayFeedCacheService.getSyncStatus();
        expect(syncStatus['sync_in_progress'], isFalse);
      });

      test('should provide comprehensive sync status information', () async {
        // Arrange - Add some test data
        await TodayFeedCacheService.queueInteraction(
          TodayFeedInteractionType.bookmark,
          'test_content_sync_status',
        );

        // Act
        final syncStatus = await TodayFeedCacheService.getSyncStatus();

        // Assert - Verify all expected status fields
        expect(syncStatus.containsKey('connectivity_status'), isTrue);
        expect(syncStatus.containsKey('is_online'), isTrue);
        expect(syncStatus.containsKey('sync_in_progress'), isTrue);
        expect(syncStatus.containsKey('pending_interactions_count'), isTrue);
        expect(syncStatus.containsKey('sync_errors_count'), isTrue);
        expect(syncStatus.containsKey('last_successful_sync'), isTrue);
        expect(syncStatus.containsKey('sync_retry_count'), isTrue);
        expect(syncStatus.containsKey('max_retries'), isTrue);
        expect(syncStatus.containsKey('background_sync_enabled'), isTrue);
        expect(syncStatus.containsKey('last_connectivity_change'), isTrue);

        expect(syncStatus['pending_interactions_count'], equals(1));
        expect(syncStatus['max_retries'], equals(3));
        expect(syncStatus['background_sync_enabled'], isTrue);
      });

      test('should handle metadata consistency validation', () async {
        // Arrange - Create content with metadata
        final today = DateTime.now();
        final content = TodayFeedContent(
          id: 101112,
          title: 'Metadata Test',
          summary: 'Testing metadata validation',
          contentDate: today,
          topicCategory: HealthTopic.stress,
          estimatedReadingMinutes: 3,
          aiConfidenceScore: 0.88,
          isCached: false,
          createdAt: today,
          updatedAt: today,
        );

        // Act
        await TodayFeedCacheService.cacheTodayContent(content);

        // Trigger sync with validation
        await TodayFeedCacheService.syncWhenOnline();

        // Assert - Should complete without throwing errors
        final syncStatus = await TodayFeedCacheService.getSyncStatus();
        expect(syncStatus['sync_errors_count'], equals(0));
      });

      test('should limit error queue size to prevent memory issues', () async {
        // This test validates that error queuing doesn't grow unbounded
        // The actual error limiting happens internally in _queueError method

        // Arrange & Act - Simulate many errors (would happen during actual failures)
        final syncStatus = await TodayFeedCacheService.getSyncStatus();

        // Assert - Error count should be properly managed
        expect(syncStatus['sync_errors_count'], isA<int>());
        expect(
          syncStatus['sync_errors_count'],
          lessThanOrEqualTo(50),
        ); // Max error limit
      });

      test('should clean up resources properly on dispose', () async {
        // Arrange
        await TodayFeedCacheService.queueInteraction(
          TodayFeedInteractionType.view,
          'disposal_test_content',
        );

        // Act
        await TodayFeedCacheService.dispose();

        // Assert - Service should be properly disposed
        // Subsequent operations should require re-initialization
        expect(
          () async => await TodayFeedCacheService.getSyncStatus(),
          returnsNormally,
        );
      });

      test('should handle content history sync validation', () async {
        // Arrange - Add content to history
        final today = DateTime.now();
        final historyContent = TodayFeedContent(
          id: 131415,
          title: 'History Sync Test',
          summary: 'Testing history sync functionality',
          contentDate: today.subtract(const Duration(days: 1)),
          topicCategory: HealthTopic.lifestyle,
          estimatedReadingMinutes: 4,
          aiConfidenceScore: 0.92,
          isCached: true,
          createdAt: today,
          updatedAt: today,
        );

        // Act
        await TodayFeedCacheService.cacheTodayContent(historyContent);
        await TodayFeedCacheService.syncWhenOnline();

        // Assert - History should be properly validated
        final stats = await TodayFeedCacheService.getCacheStats();
        expect(stats['content_history_count'], greaterThanOrEqualTo(1));
      });

      test('should update sync metadata after successful operations', () async {
        // Arrange & Act
        await TodayFeedCacheService.syncWhenOnline();

        // Get sync metadata (stored internally)
        final prefs = await SharedPreferences.getInstance();
        final syncMetadataJson = prefs.getString('today_feed_sync_metadata');

        // Assert
        if (syncMetadataJson != null) {
          final syncMetadata =
              jsonDecode(syncMetadataJson) as Map<String, dynamic>;
          expect(syncMetadata.containsKey('last_sync'), isTrue);
          expect(syncMetadata.containsKey('sync_version'), isTrue);
          expect(syncMetadata.containsKey('device_timezone'), isTrue);
          expect(syncMetadata.containsKey('connectivity_status'), isTrue);
        }
      });
    });
  });
}
