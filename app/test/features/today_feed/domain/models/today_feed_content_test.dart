import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/today_feed/domain/models/today_feed_content.dart';

void main() {
  group('TodayFeedContent', () {
    late TodayFeedContent testContent;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 12, 28, 10, 30);
      testContent = TodayFeedContent(
        id: 1,
        contentDate: testDate,
        title: "Test Health Content",
        summary:
            "This is a test summary for health content that provides valuable information.",
        contentUrl: "https://example.com/content",
        externalLink: "https://example.com/external",
        topicCategory: HealthTopic.nutrition,
        aiConfidenceScore: 0.85,
        createdAt: testDate.subtract(const Duration(hours: 1)),
        updatedAt: testDate,
        imageUrl: "https://example.com/image.jpg",
        estimatedReadingMinutes: 3,
        hasUserEngaged: false,
        isCached: false,
      );
    });

    group('Constructors', () {
      test('should create instance with required fields', () {
        final content = TodayFeedContent(
          contentDate: testDate,
          title: "Test Title",
          summary: "Test summary",
          topicCategory: HealthTopic.sleep,
          aiConfidenceScore: 0.7,
        );

        expect(content.title, equals("Test Title"));
        expect(content.topicCategory, equals(HealthTopic.sleep));
        expect(content.estimatedReadingMinutes, equals(2)); // default value
        expect(content.hasUserEngaged, isFalse); // default value
      });

      test('should create sample content correctly', () {
        final sample = TodayFeedContent.sample();

        expect(sample.title, isNotEmpty);
        expect(sample.summary, isNotEmpty);
        expect(sample.topicCategory, equals(HealthTopic.sleep));
        expect(sample.aiConfidenceScore, equals(0.85));
        expect(sample.estimatedReadingMinutes, equals(3));
        expect(sample.hasUserEngaged, isFalse);
      });
    });

    group('JSON Serialization', () {
      test('should serialize and deserialize correctly', () {
        final json = testContent.toJson();
        final deserialized = TodayFeedContent.fromJson(json);

        expect(deserialized.id, equals(testContent.id));
        expect(deserialized.title, equals(testContent.title));
        expect(deserialized.topicCategory, equals(testContent.topicCategory));
      });
    });

    group('copyWith', () {
      test('should copy with new values correctly', () {
        final copied = testContent.copyWith(
          title: "Updated Title",
          aiConfidenceScore: 0.95,
          hasUserEngaged: true,
        );

        expect(copied.title, equals("Updated Title"));
        expect(copied.aiConfidenceScore, equals(0.95));
        expect(copied.hasUserEngaged, isTrue);
        // Unchanged values should remain the same
        expect(copied.id, equals(testContent.id));
        expect(copied.summary, equals(testContent.summary));
        expect(copied.topicCategory, equals(testContent.topicCategory));
      });

      test('should copy with no changes when no parameters provided', () {
        final copied = testContent.copyWith();

        expect(copied.id, equals(testContent.id));
        expect(copied.title, equals(testContent.title));
        expect(copied.summary, equals(testContent.summary));
        expect(copied.topicCategory, equals(testContent.topicCategory));
        expect(copied.aiConfidenceScore, equals(testContent.aiConfidenceScore));
      });
    });

    group('Helper Methods', () {
      test('should format dates correctly', () {
        expect(testContent.formattedDate, equals('Dec 28, 2024'));
        expect(testContent.shortDate, equals('Dec 28'));
      });

      test('should provide topic display names', () {
        expect(testContent.topicDisplayName, equals('Nutrition'));

        final exerciseContent = testContent.copyWith(
          topicCategory: HealthTopic.exercise,
        );
        expect(exerciseContent.topicDisplayName, equals('Exercise'));

        final stressContent = testContent.copyWith(
          topicCategory: HealthTopic.stress,
        );
        expect(stressContent.topicDisplayName, equals('Stress Management'));
      });

      test('should provide confidence level descriptions', () {
        expect(testContent.confidenceLevel, equals('High')); // 0.85

        final mediumContent = testContent.copyWith(aiConfidenceScore: 0.65);
        expect(mediumContent.confidenceLevel, equals('Medium'));

        final lowContent = testContent.copyWith(aiConfidenceScore: 0.4);
        expect(lowContent.confidenceLevel, equals('Low'));
      });

      test('should format reading time correctly', () {
        expect(testContent.readingTimeText, equals('3 min read'));

        final oneMinute = testContent.copyWith(estimatedReadingMinutes: 1);
        expect(oneMinute.readingTimeText, equals('1 min read'));
      });
    });

    group('Equality and HashCode', () {
      test('should be equal for same content', () {
        final content1 = TodayFeedContent(
          id: 1,
          contentDate: testDate,
          title: "Test Title",
          summary: "Test Summary",
          topicCategory: HealthTopic.nutrition,
          aiConfidenceScore: 0.8,
        );

        final content2 = TodayFeedContent(
          id: 1,
          contentDate: testDate,
          title: "Test Title",
          summary: "Test Summary",
          topicCategory: HealthTopic.nutrition,
          aiConfidenceScore: 0.8,
        );

        expect(content1, equals(content2));
        expect(content1.hashCode, equals(content2.hashCode));
      });

      test('should not be equal for different content', () {
        final content1 = testContent;
        final content2 = testContent.copyWith(title: "Different Title");

        expect(content1, isNot(equals(content2)));
        expect(content1.hashCode, isNot(equals(content2.hashCode)));
      });
    });
  });

  group('TodayFeedState', () {
    late TodayFeedContent testContent;

    setUp(() {
      testContent = TodayFeedContent.sample();
    });

    test('should create loading state', () {
      const state = TodayFeedState.loading();

      expect(state.isLoading, isTrue);
      expect(state.isLoaded, isFalse);
      expect(state.isError, isFalse);
      expect(state.isOffline, isFalse);
      expect(state.content, isNull);
    });

    test('should create loaded state', () {
      final state = TodayFeedState.loaded(testContent);

      expect(state.isLoading, isFalse);
      expect(state.isLoaded, isTrue);
      expect(state.isError, isFalse);
      expect(state.isOffline, isFalse);
      expect(state.content, equals(testContent));
    });

    test('should create error state', () {
      const errorMessage = 'Network error occurred';
      const state = TodayFeedState.error(errorMessage);

      expect(state.isLoading, isFalse);
      expect(state.isLoaded, isFalse);
      expect(state.isError, isTrue);
      expect(state.isOffline, isFalse);
      expect(state.content, isNull);
      expect(state.errorMessage, equals(errorMessage));
    });

    test('should create offline state', () {
      final state = TodayFeedState.offline(testContent);

      expect(state.isLoading, isFalse);
      expect(state.isLoaded, isFalse);
      expect(state.isError, isFalse);
      expect(state.isOffline, isTrue);
      expect(state.content, equals(testContent));
    });

    test('should pattern match with when method', () {
      const loadingState = TodayFeedState.loading();
      final loadedState = TodayFeedState.loaded(testContent);
      const errorState = TodayFeedState.error('Error message');
      final offlineState = TodayFeedState.offline(testContent);

      expect(
        loadingState.when(
          loading: () => 'loading',
          loaded: (_) => 'loaded',
          error: (_) => 'error',
          offline: (_) => 'offline',
          fallback: (_) => 'fallback',
        ),
        equals('loading'),
      );

      expect(
        loadedState.when(
          loading: () => 'loading',
          loaded: (content) => 'loaded: ${content.title}',
          error: (_) => 'error',
          offline: (_) => 'offline',
          fallback: (_) => 'fallback',
        ),
        contains('loaded:'),
      );

      expect(
        errorState.when(
          loading: () => 'loading',
          loaded: (_) => 'loaded',
          error: (message) => 'error: $message',
          offline: (_) => 'offline',
          fallback: (_) => 'fallback',
        ),
        equals('error: Error message'),
      );

      expect(
        offlineState.when(
          loading: () => 'loading',
          loaded: (_) => 'loaded',
          error: (_) => 'error',
          offline: (content) => 'offline: ${content.title}',
          fallback: (_) => 'fallback',
        ),
        contains('offline:'),
      );
    });

    test('should have correct equality', () {
      const state1 = TodayFeedState.loading();
      const state2 = TodayFeedState.loading();
      expect(state1, equals(state2));

      final loaded1 = TodayFeedState.loaded(testContent);
      final loaded2 = TodayFeedState.loaded(testContent);
      expect(loaded1, equals(loaded2));

      const error1 = TodayFeedState.error('Same message');
      const error2 = TodayFeedState.error('Same message');
      expect(error1, equals(error2));

      const error3 = TodayFeedState.error('Different message');
      expect(error1, isNot(equals(error3)));
    });
  });

  group('TodayFeedInteraction', () {
    late TodayFeedInteraction testInteraction;
    late DateTime testTimestamp;

    setUp(() {
      testTimestamp = DateTime(2024, 12, 28, 15, 30);
      testInteraction = TodayFeedInteraction(
        id: 'interaction_123',
        userId: 'user_456',
        contentId: 789,
        interactionType: TodayFeedInteractionType.view,
        interactionTimestamp: testTimestamp,
        sessionDuration: 120, // 2 minutes
      );
    });

    test('should create instance correctly', () {
      expect(testInteraction.id, equals('interaction_123'));
      expect(testInteraction.userId, equals('user_456'));
      expect(testInteraction.contentId, equals(789));
      expect(
        testInteraction.interactionType,
        equals(TodayFeedInteractionType.view),
      );
      expect(testInteraction.sessionDuration, equals(120));
    });

    test('should serialize and deserialize JSON correctly', () {
      final json = testInteraction.toJson();
      final deserialized = TodayFeedInteraction.fromJson(json);

      expect(deserialized.id, equals(testInteraction.id));
      expect(deserialized.userId, equals(testInteraction.userId));
      expect(deserialized.contentId, equals(testInteraction.contentId));
    });

    test('should have correct equality', () {
      final interaction1 = TodayFeedInteraction(
        userId: 'user_1',
        contentId: 1,
        interactionType: TodayFeedInteractionType.view,
        interactionTimestamp: testTimestamp,
      );

      final interaction2 = TodayFeedInteraction(
        userId: 'user_1',
        contentId: 1,
        interactionType: TodayFeedInteractionType.view,
        interactionTimestamp: testTimestamp,
      );

      expect(interaction1, equals(interaction2));
      expect(interaction1.hashCode, equals(interaction2.hashCode));

      final differentInteraction = TodayFeedInteraction(
        userId: 'user_2',
        contentId: 1,
        interactionType: TodayFeedInteractionType.view,
        interactionTimestamp: testTimestamp,
      );

      expect(interaction1, isNot(equals(differentInteraction)));
    });
  });
}
