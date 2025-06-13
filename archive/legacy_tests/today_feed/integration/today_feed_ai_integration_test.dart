import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/features/today_feed/data/services/today_feed_data_service.dart';
import 'package:app/features/today_feed/domain/models/today_feed_content.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('TodayFeed AI Integration (M1.2.1.4 T1.2.1.4.2)', () {
    setUpAll(() {
      TodayFeedDataService.setTestEnvironment(true);
    });

    // Integration test - End-to-end content generation to user delivery
    test(
      'should complete full content lifecycle from generation to delivery',
      () async {
        // Arrange
        await TodayFeedDataService.initialize();

        // Act - Complete flow: cache clear → generation → retrieval
        await TodayFeedDataService.forceRefreshAndClearCache();
        final generatedContent = await TodayFeedDataService.getTodayContent();

        // Simulate user interaction
        if (generatedContent != null) {
          await TodayFeedDataService.recordInteraction(
            TodayFeedInteractionType.view,
            generatedContent,
          );
        }

        // Retrieve content again to test caching
        final cachedContent = await TodayFeedDataService.getTodayContent();

        // Assert - Verify complete flow worked
        expect(generatedContent, isNotNull);
        expect(cachedContent, isNotNull);

        // Content should be consistent between generations
        if (generatedContent != null && cachedContent != null) {
          expect(
            cachedContent.contentDate.day,
            equals(generatedContent.contentDate.day),
          );
          expect(cachedContent.topicCategory, isA<HealthTopic>());
        }

        // Content should meet quality standards
        final content = generatedContent ?? cachedContent!;
        expect(content.title, isNotEmpty);
        expect(content.summary, isNotEmpty);
        expect(content.title.length, lessThanOrEqualTo(60));
        expect(content.summary.length, lessThanOrEqualTo(200));
        expect(content.aiConfidenceScore, inInclusiveRange(0.0, 1.0));
      },
    );

    // Critical edge case - Database connectivity handling
    test(
      'should handle database operations gracefully in test environment',
      () async {
        // Arrange
        await TodayFeedDataService.initialize();

        // Act - Test database read operations
        final readResult = await TodayFeedDataService.getTodayContent();

        // Test database write operations (interaction recording)
        if (readResult != null) {
          await TodayFeedDataService.recordInteraction(
            TodayFeedInteractionType.tap,
            readResult,
            additionalData: {'integration_test': true},
          );
        }

        // Test cache info retrieval (includes connectivity status)
        final cacheInfo = await TodayFeedDataService.getCacheInfo();

        // Assert - All operations should complete without throwing
        expect(readResult, isNotNull);
        expect(cacheInfo, isA<Map<String, dynamic>>());
        expect(cacheInfo.containsKey('connectivity_status'), isTrue);
      },
    );

    // Critical edge case - Content quality validation throughout pipeline
    test(
      'should maintain content quality through entire AI pipeline',
      () async {
        // Arrange
        await TodayFeedDataService.initialize();

        // Act - Get multiple content samples to test consistency
        final content1 = await TodayFeedDataService.refreshContent();
        await Future.delayed(const Duration(milliseconds: 100)); // Brief delay
        final content2 = await TodayFeedDataService.getTodayContent();

        // Assert - Both content instances should meet quality standards
        for (final content in [content1, content2]) {
          if (content != null) {
            // Length constraints
            expect(content.title.length, greaterThan(0));
            expect(content.title.length, lessThanOrEqualTo(60));
            expect(content.summary.length, greaterThan(0));
            expect(content.summary.length, lessThanOrEqualTo(200));

            // Safety constraints
            expect(content.title.toLowerCase(), isNot(contains('cure')));
            expect(content.title.toLowerCase(), isNot(contains('diagnose')));
            expect(
              content.summary.toLowerCase(),
              isNot(contains('guaranteed')),
            );
            expect(content.summary.toLowerCase(), isNot(contains('miracle')));

            // Data integrity
            expect(content.topicCategory, isA<HealthTopic>());
            expect(content.aiConfidenceScore, inInclusiveRange(0.0, 1.0));
            expect(content.contentDate, isNotNull);
          }
        }
      },
    );
  });
}
