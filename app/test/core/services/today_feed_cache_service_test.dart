import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/core/services/today_feed_cache_service.dart';
import 'package:app/features/today_feed/domain/models/today_feed_content.dart';

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

    group('Basic Cache Operations', () {
      test('should initialize successfully', () async {
        // Arrange & Act
        await TodayFeedCacheService.initialize();
        final stats = await TodayFeedCacheService.getCacheStats();

        // Assert
        expect(stats, isNotNull);
        expect(stats['is_initialized'], isTrue);
      });

      test('should cache and retrieve today content', () async {
        // Arrange
        final today = DateTime.now();
        final testContent = TodayFeedContent(
          id: 1,
          title: 'Test Health Topic',
          summary: 'A comprehensive test summary.',
          contentDate: today,
          topicCategory: HealthTopic.nutrition,
          estimatedReadingMinutes: 3,
          aiConfidenceScore: 0.95,
          isCached: false,
          createdAt: today,
          updatedAt: today,
        );

        // Act
        await TodayFeedCacheService.cacheTodayContent(testContent);
        final cachedContent = await TodayFeedCacheService.getTodayContent();

        // Assert
        expect(cachedContent, isNotNull);
        expect(cachedContent!.title, equals(testContent.title));
        expect(cachedContent.isCached, isTrue);
      });

      test('should return null when no content is cached', () async {
        // Act
        final content = await TodayFeedCacheService.getTodayContent();

        // Assert
        expect(content, isNull);
      });

      test('should calculate cache size correctly', () async {
        // Arrange
        final today = DateTime.now();
        final testContent = TodayFeedContent(
          id: 1,
          title: 'Test Content',
          summary: 'Test summary',
          contentDate: today,
          topicCategory: HealthTopic.nutrition,
          estimatedReadingMinutes: 3,
          aiConfidenceScore: 0.95,
          isCached: false,
          createdAt: today,
          updatedAt: today,
        );

        // Act
        await TodayFeedCacheService.cacheTodayContent(testContent);
        final stats = await TodayFeedCacheService.getCacheStats();

        // Assert
        expect(stats['has_today_content'], isTrue);
        expect(stats['cache_size_bytes'], isA<int>());
        expect(stats['cache_size_bytes'], greaterThan(0));
      });

      test('should clear cache successfully', () async {
        // Arrange
        final today = DateTime.now();
        final testContent = TodayFeedContent(
          id: 1,
          title: 'Test Content',
          summary: 'Test summary',
          contentDate: today,
          topicCategory: HealthTopic.nutrition,
          estimatedReadingMinutes: 3,
          aiConfidenceScore: 0.95,
          isCached: false,
          createdAt: today,
          updatedAt: today,
        );

        await TodayFeedCacheService.cacheTodayContent(testContent);

        // Act
        await TodayFeedCacheService.clearAllCache();
        final content = await TodayFeedCacheService.getTodayContent();

        // Assert
        expect(content, isNull);
      });
    });

    group('Cache Statistics', () {
      test('should provide cache statistics', () async {
        // Act
        final stats = await TodayFeedCacheService.getCacheStatistics();

        // Assert
        expect(stats, isNotNull);
        expect(stats, isA<Map<String, dynamic>>());
      });

      test('should provide health metrics', () async {
        // Act
        final health = await TodayFeedCacheService.getCacheHealthStatus();

        // Assert
        expect(health, isNotNull);
        expect(health['overall_status'], isA<String>());
        expect(health['health_score'], isA<int>());
      });

      test('should provide diagnostic info', () async {
        // Act
        final diagnostics = await TodayFeedCacheService.getDiagnosticInfo();

        // Assert
        expect(diagnostics, isNotNull);
        expect(diagnostics['timestamp'], isA<String>());
      });
    });

    group('User Interactions', () {
      test('should queue user interactions', () async {
        // Arrange
        final interaction = {'action': 'content_viewed', 'content_id': 1};

        // Act
        await TodayFeedCacheService.queueInteraction(interaction);
        final pendingInteractions =
            await TodayFeedCacheService.getPendingInteractions();

        // Assert
        expect(pendingInteractions, isNotEmpty);
        expect(pendingInteractions.first['action'], equals('content_viewed'));
      });

      test('should clear pending interactions', () async {
        // Arrange
        final interaction = {'action': 'content_viewed', 'content_id': 1};
        await TodayFeedCacheService.queueInteraction(interaction);

        // Act
        await TodayFeedCacheService.clearPendingInteractions();
        final pendingInteractions =
            await TodayFeedCacheService.getPendingInteractions();

        // Assert
        expect(pendingInteractions, isEmpty);
      });

      test('should mark content as viewed', () async {
        // Arrange
        final today = DateTime.now();
        final testContent = TodayFeedContent(
          id: 1,
          title: 'Test Content',
          summary: 'Test summary',
          contentDate: today,
          topicCategory: HealthTopic.nutrition,
          estimatedReadingMinutes: 3,
          aiConfidenceScore: 0.95,
          isCached: false,
          createdAt: today,
          updatedAt: today,
        );

        // Act
        await TodayFeedCacheService.markContentAsViewed(testContent);
        final pendingInteractions =
            await TodayFeedCacheService.getPendingInteractions();

        // Assert
        expect(pendingInteractions, isNotEmpty);
        expect(pendingInteractions.first['action'], equals('content_viewed'));
        expect(pendingInteractions.first['content_id'], equals(1));
      });
    });

    group('Cache Management', () {
      test('should perform selective cleanup', () async {
        // Act & Assert - Should not throw exception
        expect(
          () async => await TodayFeedCacheService.selectiveCleanup(),
          returnsNormally,
        );
      });

      test('should invalidate content', () async {
        // Arrange
        final today = DateTime.now();
        final testContent = TodayFeedContent(
          id: 1,
          title: 'Test Content',
          summary: 'Test summary',
          contentDate: today,
          topicCategory: HealthTopic.nutrition,
          estimatedReadingMinutes: 3,
          aiConfidenceScore: 0.95,
          isCached: false,
          createdAt: today,
          updatedAt: today,
        );

        await TodayFeedCacheService.cacheTodayContent(testContent);

        // Act
        await TodayFeedCacheService.invalidateContent();
        final content = await TodayFeedCacheService.getTodayContent();

        // Assert
        expect(content, isNull);
      });

      test('should get cache invalidation stats', () async {
        // Act
        final stats = await TodayFeedCacheService.getCacheInvalidationStats();

        // Assert
        expect(stats, isNotNull);
        expect(stats['invalidation_count'], isA<int>());
      });
    });

    group('Fallback Content', () {
      test('should check if fallback content should be used', () async {
        // Act
        final shouldUseFallback =
            await TodayFeedCacheService.shouldUseFallbackContent();

        // Assert
        expect(shouldUseFallback, isA<bool>());
      });

      test('should get fallback content with metadata', () async {
        // Act
        final fallbackContent =
            await TodayFeedCacheService.getFallbackContentWithMetadata();

        // Assert - Can be null if no fallback content available
        expect(fallbackContent, anyOf(isNull, isA<TodayFeedContent>()));
      });
    });

    group('Sync Operations', () {
      test('should sync when online', () async {
        // Act & Assert - Should not throw exception
        expect(
          () async => await TodayFeedCacheService.syncWhenOnline(),
          returnsNormally,
        );
      });

      test('should check if refresh is needed', () async {
        // Act
        final needsRefresh = await TodayFeedCacheService.needsRefresh();

        // Assert
        expect(needsRefresh, isA<bool>());
      });

      test('should force refresh', () async {
        // Act & Assert - Should not throw exception
        expect(
          () async => await TodayFeedCacheService.forceRefresh(),
          returnsNormally,
        );
      });
    });

    group('Background Sync Settings', () {
      test('should set and get background sync preference', () async {
        // Act
        await TodayFeedCacheService.setBackgroundSyncEnabled(false);
        final isEnabled = await TodayFeedCacheService.isBackgroundSyncEnabled();

        // Assert
        expect(isEnabled, isFalse);

        // Reset
        await TodayFeedCacheService.setBackgroundSyncEnabled(true);
        final isEnabledAgain =
            await TodayFeedCacheService.isBackgroundSyncEnabled();
        expect(isEnabledAgain, isTrue);
      });
    });

    group('Content History', () {
      test('should get content history', () async {
        // Act
        final history = await TodayFeedCacheService.getContentHistory();

        // Assert
        expect(history, isA<List>());
      });

      test('should add content to history when caching', () async {
        // Arrange
        final today = DateTime.now();
        final testContent = TodayFeedContent(
          id: 1,
          title: 'Test Content',
          summary: 'Test summary',
          contentDate: today,
          topicCategory: HealthTopic.nutrition,
          estimatedReadingMinutes: 3,
          aiConfidenceScore: 0.95,
          isCached: false,
          createdAt: today,
          updatedAt: today,
        );

        // Act
        await TodayFeedCacheService.cacheTodayContent(testContent);
        final history = await TodayFeedCacheService.getContentHistory();

        // Assert
        expect(history, isNotEmpty);
      });
    });

    group('Performance Metrics', () {
      test('should get all statistics', () async {
        // Act
        final allStats = await TodayFeedCacheService.getAllStatistics();

        // Assert
        expect(allStats, isNotNull);
        expect(allStats['cache'], isNotNull);
        expect(allStats['statistics'], isNotNull);
        expect(allStats['health'], isNotNull);
        expect(allStats['performance'], isNotNull);
      });

      test('should get all health metrics', () async {
        // Act
        final healthMetrics = await TodayFeedCacheService.getAllHealthMetrics();

        // Assert
        expect(healthMetrics, isNotNull);
        expect(healthMetrics['health'], isNotNull);
      });

      test('should get all performance metrics', () async {
        // Act
        final perfMetrics =
            await TodayFeedCacheService.getAllPerformanceMetrics();

        // Assert
        expect(perfMetrics, isNotNull);
        expect(perfMetrics['performance'], isNotNull);
      });

      test('should export metrics for monitoring', () async {
        // Act
        final monitoringMetrics =
            await TodayFeedCacheService.exportMetricsForMonitoring();

        // Assert
        expect(monitoringMetrics, isNotNull);
        expect(monitoringMetrics['metrics'], isNotNull);
      });
    });

    group('Timezone Handling', () {
      test('should get timezone stats', () async {
        // Act
        final timezoneStats = await TodayFeedCacheService.getTimezoneStats();

        // Assert
        expect(timezoneStats, isNotNull);
        expect(timezoneStats, isA<Map<String, dynamic>>());
      });
    });

    group('Cache Integrity', () {
      test('should perform cache integrity check', () async {
        // Act
        final integrityCheck =
            await TodayFeedCacheService.performCacheIntegrityCheck();

        // Assert
        expect(integrityCheck, isNotNull);
        expect(integrityCheck['is_healthy'], isA<bool>());
        expect(integrityCheck['integrity_score'], isA<int>());
      });
    });

    group('Error Handling', () {
      test('should handle corrupted cache data gracefully', () async {
        // Arrange - Simulate corrupted cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('today_feed_content', 'invalid-json-data');

        // Act & Assert - Should not throw exception
        expect(
          () async => await TodayFeedCacheService.getTodayContent(),
          returnsNormally,
        );

        final content = await TodayFeedCacheService.getTodayContent();
        expect(content, isNull);
      });

      test('should handle null content gracefully', () async {
        // Act & Assert
        expect(
          () async => await TodayFeedCacheService.getTodayContent(),
          returnsNormally,
        );

        final content = await TodayFeedCacheService.getTodayContent();
        expect(content, isNull);
      });
    });
  });
}
