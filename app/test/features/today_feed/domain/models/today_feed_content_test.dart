import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/today_feed/domain/models/today_feed_content.dart';

void main() {
  group('HealthTopic', () {
    test('should have correct string values', () {
      expect(HealthTopic.nutrition.value, equals('nutrition'));
      expect(HealthTopic.exercise.value, equals('exercise'));
      expect(HealthTopic.sleep.value, equals('sleep'));
      expect(HealthTopic.stress.value, equals('stress'));
      expect(HealthTopic.prevention.value, equals('prevention'));
      expect(HealthTopic.lifestyle.value, equals('lifestyle'));
    });

    test('should create from string correctly', () {
      expect(
        HealthTopic.fromString('nutrition'),
        equals(HealthTopic.nutrition),
      );
      expect(HealthTopic.fromString('sleep'), equals(HealthTopic.sleep));
      expect(
        HealthTopic.fromString('invalid'),
        equals(HealthTopic.lifestyle),
      ); // fallback
    });
  });

  group('TodayFeedInteractionType', () {
    test('should have correct string values', () {
      expect(TodayFeedInteractionType.view.value, equals('view'));
      expect(TodayFeedInteractionType.tap.value, equals('tap'));
      expect(
        TodayFeedInteractionType.externalLinkClick.value,
        equals('external_link_click'),
      );
      expect(TodayFeedInteractionType.share.value, equals('share'));
      expect(TodayFeedInteractionType.bookmark.value, equals('bookmark'));
    });

    test('should create from string correctly', () {
      expect(
        TodayFeedInteractionType.fromString('view'),
        equals(TodayFeedInteractionType.view),
      );
      expect(
        TodayFeedInteractionType.fromString('share'),
        equals(TodayFeedInteractionType.share),
      );
      expect(
        TodayFeedInteractionType.fromString('invalid'),
        equals(TodayFeedInteractionType.view),
      ); // fallback
    });
  });

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
      test('should serialize to JSON correctly', () {
        final json = testContent.toJson();

        expect(json['id'], equals(1));
        expect(json['content_date'], equals('2024-12-28'));
        expect(json['title'], equals("Test Health Content"));
        expect(json['summary'], contains("test summary"));
        expect(json['content_url'], equals("https://example.com/content"));
        expect(json['external_link'], equals("https://example.com/external"));
        expect(json['topic_category'], equals('nutrition'));
        expect(json['ai_confidence_score'], equals(0.85));
        expect(json['estimated_reading_minutes'], equals(3));
        expect(json['has_user_engaged'], isFalse);
        expect(json['is_cached'], isFalse);
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'id': 2,
          'content_date': '2024-12-29',
          'title': 'JSON Test Title',
          'summary': 'JSON test summary for deserialization testing.',
          'content_url': 'https://json.example.com/content',
          'external_link': 'https://json.example.com/external',
          'topic_category': 'exercise',
          'ai_confidence_score': 0.92,
          'created_at': '2024-12-29T08:00:00.000Z',
          'updated_at': '2024-12-29T09:00:00.000Z',
          'image_url': 'https://json.example.com/image.png',
          'estimated_reading_minutes': 4,
          'has_user_engaged': true,
          'is_cached': true,
        };

        final content = TodayFeedContent.fromJson(json);

        expect(content.id, equals(2));
        expect(content.contentDate, equals(DateTime(2024, 12, 29)));
        expect(content.title, equals('JSON Test Title'));
        expect(content.topicCategory, equals(HealthTopic.exercise));
        expect(content.aiConfidenceScore, equals(0.92));
        expect(content.hasUserEngaged, isTrue);
        expect(content.isCached, isTrue);
      });

      test('should handle missing optional fields in JSON', () {
        final json = {
          'content_date': '2024-12-28',
          'title': 'Minimal JSON Test',
          'summary': 'Test with minimal fields.',
          'topic_category': 'sleep',
          'ai_confidence_score': 0.75,
        };

        final content = TodayFeedContent.fromJson(json);

        expect(content.id, isNull);
        expect(content.contentUrl, isNull);
        expect(content.externalLink, isNull);
        expect(content.createdAt, isNull);
        expect(content.updatedAt, isNull);
        expect(content.estimatedReadingMinutes, equals(2)); // default
        expect(content.hasUserEngaged, isFalse); // default
        expect(content.isCached, isFalse); // default
      });

      test('should round-trip serialize/deserialize correctly', () {
        final json = testContent.toJson();
        final deserialized = TodayFeedContent.fromJson(json);

        expect(deserialized.id, equals(testContent.id));
        expect(deserialized.title, equals(testContent.title));
        expect(deserialized.summary, equals(testContent.summary));
        expect(deserialized.topicCategory, equals(testContent.topicCategory));
        expect(
          deserialized.aiConfidenceScore,
          equals(testContent.aiConfidenceScore),
        );
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

    group('Validation Methods', () {
      test('should validate content correctly', () {
        expect(testContent.isValid, isTrue);

        final invalidTitle = testContent.copyWith(
          title:
              "This is a very long title that exceeds the maximum allowed length of 60 characters",
        );
        expect(invalidTitle.isValid, isFalse);

        final invalidSummary = testContent.copyWith(
          summary:
              "This is an extremely long summary that goes way beyond the maximum allowed length of 200 characters. It continues with more text to ensure it exceeds the limit. This should make the validation fail because it's too long for the content summary field.",
        );
        expect(invalidSummary.isValid, isFalse);

        final invalidScore = testContent.copyWith(aiConfidenceScore: 1.5);
        expect(invalidScore.isValid, isFalse);
      });

      test('should check if content is fresh correctly', () {
        final today = DateTime.now();
        final todayContent = testContent.copyWith(contentDate: today);
        expect(todayContent.isFresh, isTrue);

        final oldContent = testContent.copyWith(
          contentDate: today.subtract(const Duration(days: 1)),
        );
        expect(oldContent.isFresh, isFalse);
      });

      test('should check content quality correctly', () {
        expect(testContent.isHighQuality, isTrue); // 0.85 >= 0.7

        final lowQuality = testContent.copyWith(aiConfidenceScore: 0.6);
        expect(lowQuality.isHighQuality, isFalse);
      });

      test('should check for external link correctly', () {
        expect(testContent.hasExternalLink, isTrue);

        final noLink = testContent.copyWith(externalLink: null);
        expect(noLink.hasExternalLink, isFalse);

        final emptyLink = testContent.copyWith(externalLink: "");
        expect(emptyLink.hasExternalLink, isFalse);
      });

      test('should calculate age correctly', () {
        final now = DateTime.now();
        final oldContent = testContent.copyWith(
          contentDate: now.subtract(const Duration(days: 5)),
        );
        expect(oldContent.ageInDays, equals(5));

        final staleContent = testContent.copyWith(
          contentDate: now.subtract(const Duration(days: 10)),
        );
        expect(staleContent.isStale, isTrue);
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

    test('should have correct toString representation', () {
      final string = testContent.toString();
      expect(string, contains('TodayFeedContent'));
      expect(string, contains('id: 1'));
      expect(string, contains('title: Test Health Content'));
      expect(string, contains('topic: nutrition'));
      expect(string, contains('date: 2024-12-28'));
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

    test('should serialize to JSON correctly', () {
      final json = testInteraction.toJson();

      expect(json['id'], equals('interaction_123'));
      expect(json['user_id'], equals('user_456'));
      expect(json['content_id'], equals(789));
      expect(json['interaction_type'], equals('view'));
      expect(
        json['interaction_timestamp'],
        equals(testTimestamp.toIso8601String()),
      );
      expect(json['session_duration'], equals(120));
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'id': 'json_interaction_456',
        'user_id': 'json_user_789',
        'content_id': 123,
        'interaction_type': 'share',
        'interaction_timestamp': '2024-12-28T16:45:00.000Z',
        'session_duration': 90,
      };

      final interaction = TodayFeedInteraction.fromJson(json);

      expect(interaction.id, equals('json_interaction_456'));
      expect(interaction.userId, equals('json_user_789'));
      expect(interaction.contentId, equals(123));
      expect(
        interaction.interactionType,
        equals(TodayFeedInteractionType.share),
      );
      expect(interaction.sessionDuration, equals(90));
    });

    test('should handle missing optional fields in JSON', () {
      final json = {
        'user_id': 'user_123',
        'content_id': 456,
        'interaction_type': 'tap',
        'interaction_timestamp': '2024-12-28T17:00:00.000Z',
      };

      final interaction = TodayFeedInteraction.fromJson(json);

      expect(interaction.id, isNull);
      expect(interaction.sessionDuration, isNull);
      expect(interaction.interactionType, equals(TodayFeedInteractionType.tap));
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

    test('should have correct toString representation', () {
      final string = testInteraction.toString();
      expect(string, contains('TodayFeedInteraction'));
      expect(string, contains('userId: user_456'));
      expect(string, contains('contentId: 789'));
      expect(string, contains('type: view'));
    });
  });
}
