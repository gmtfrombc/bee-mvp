import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/today_feed/data/services/user_content_interaction_service.dart';
import 'package:app/features/today_feed/domain/models/today_feed_content.dart';

void main() {
  group('UserContentInteractionService Tests', () {
    late UserContentInteractionService service;

    setUp(() {
      service = UserContentInteractionService();
    });

    tearDown(() {
      service.dispose();
    });

    group('Service Initialization', () {
      test('should create service instance successfully', () {
        expect(service, isNotNull);
        expect(service.getPendingInteractionsCount(), equals(0));
      });
    });

    group('Content ID Handling', () {
      test('should handle content with valid ID', () {
        final testContent = TodayFeedContent.sample().copyWith(
          id: 123,
          title: 'Test Health Insight',
          topicCategory: HealthTopic.nutrition,
        );

        expect(testContent.id, equals(123));
        expect(testContent.title, equals('Test Health Insight'));
        expect(testContent.topicCategory, equals(HealthTopic.nutrition));
      });
    });

    group('Interaction Types', () {
      test('should support all required interaction types', () {
        final requiredTypes = [
          TodayFeedInteractionType.view,
          TodayFeedInteractionType.tap,
          TodayFeedInteractionType.externalLinkClick,
          TodayFeedInteractionType.share,
          TodayFeedInteractionType.bookmark,
        ];

        for (final type in requiredTypes) {
          expect(type.value, isNotEmpty);
          expect(TodayFeedInteractionType.fromString(type.value), equals(type));
        }
      });
    });

    group('Content Model Integration', () {
      test('should work with sample content', () {
        final sampleContent = TodayFeedContent.sample();

        expect(sampleContent.title, isNotEmpty);
        expect(sampleContent.topicCategory, isNotNull);
        expect(sampleContent.contentDate, isNotNull);
        expect(sampleContent.aiConfidenceScore, greaterThanOrEqualTo(0));
        expect(sampleContent.estimatedReadingMinutes, greaterThan(0));
      });

      test('should handle content with different topic categories', () {
        for (final topic in HealthTopic.values) {
          final content = TodayFeedContent.sample().copyWith(
            topicCategory: topic,
            title: 'Test ${topic.value} content',
          );

          expect(content.topicCategory, equals(topic));
          expect(content.title, contains(topic.value));
        }
      });
    });

    group('Error Handling', () {
      test('should handle service disposal gracefully', () {
        final testService = UserContentInteractionService();

        expect(() => testService.dispose(), returnsNormally);
        expect(testService.getPendingInteractionsCount(), equals(0));
      });
    });
  });
}
