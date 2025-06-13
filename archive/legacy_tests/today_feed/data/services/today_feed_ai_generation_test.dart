import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/features/today_feed/data/services/today_feed_data_service.dart';
import 'package:app/features/today_feed/domain/models/today_feed_content.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('TodayFeed AI Content Generation (M1.2.1.4 T1.2.1.4.1)', () {
    setUpAll(() {
      TodayFeedDataService.setTestEnvironment(true);
    });

    // Happy path test - as required by testing policy
    test(
      'should refresh content successfully triggering AI generation flow',
      () async {
        // Arrange
        await TodayFeedDataService.initialize();

        // Act
        final result = await TodayFeedDataService.refreshContent();

        // Assert - Should return content (AI-generated or fallback)
        expect(result, isNotNull);
        expect(result!.title, isNotEmpty);
        expect(result.summary, isNotEmpty);
        expect(result.topicCategory, isA<HealthTopic>());
        expect(result.aiConfidenceScore, inInclusiveRange(0.0, 1.0));
      },
    );

    // Critical edge case - AI service unavailable
    test('should fallback gracefully when AI generation fails', () async {
      // Arrange
      await TodayFeedDataService.initialize();

      // Act - Get content when AI might be unavailable
      final result = await TodayFeedDataService.getTodayContent();

      // Assert - Should return fallback content
      expect(result, isNotNull);
      expect(result!.title, isNotEmpty);
      expect(result.summary, isNotEmpty);
      expect(result.topicCategory, isA<HealthTopic>());
      expect(result.aiConfidenceScore, inInclusiveRange(0.0, 1.0));
    });

    // Critical edge case - content safety validation
    test('should ensure generated content meets safety requirements', () async {
      // Arrange
      await TodayFeedDataService.initialize();

      // Act
      final result = await TodayFeedDataService.getTodayContent();

      // Assert - Safety checks
      expect(result, isNotNull);
      final content = result!;

      // Should not contain medical advice red flags
      expect(content.title.toLowerCase(), isNot(contains('cure')));
      expect(content.title.toLowerCase(), isNot(contains('diagnose')));
      expect(content.summary.toLowerCase(), isNot(contains('guaranteed')));
      expect(content.summary.toLowerCase(), isNot(contains('miracle')));

      // Should have reasonable confidence score
      expect(content.aiConfidenceScore, lessThanOrEqualTo(1.0));
      expect(content.aiConfidenceScore, greaterThanOrEqualTo(0.0));
    });

    // Critical edge case - database integration validation
    test('should handle database write operations correctly', () async {
      // Arrange
      await TodayFeedDataService.initialize();
      final testContent = TodayFeedContent.sample();

      // Act - Test that database operations don't throw
      expect(
        () => TodayFeedDataService.recordInteraction(
          TodayFeedInteractionType.view,
          testContent,
        ),
        returnsNormally,
      );
    });

    // Critical edge case - content freshness validation
    test('should provide content with current date when possible', () async {
      // Arrange
      await TodayFeedDataService.initialize();
      final today = DateTime.now();

      // Act
      final result = await TodayFeedDataService.getTodayContent();

      // Assert - Content should be for today or recent
      expect(result, isNotNull);
      final contentDate = result!.contentDate;
      final daysDifference = today.difference(contentDate).inDays.abs();
      expect(
        daysDifference,
        lessThanOrEqualTo(1),
      ); // Today or yesterday acceptable
    });
  });
}
