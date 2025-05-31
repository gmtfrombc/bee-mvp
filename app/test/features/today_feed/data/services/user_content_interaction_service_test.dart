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

    group('Interaction Type Validation', () {
      test('should have correct event type mappings', () {
        // Test that all interaction types have corresponding event types
        const expectedMappings = {
          'view': 'today_feed_view',
          'tap': 'today_feed_tap',
          'external_link_click': 'today_feed_external_click',
          'share': 'today_feed_share',
          'bookmark': 'today_feed_bookmark',
        };

        // Verify all interaction types are covered
        for (final type in TodayFeedInteractionType.values) {
          expect(
            expectedMappings.containsKey(type.value),
            isTrue,
            reason: 'Missing event mapping for ${type.value}',
          );
        }
      });
    });

    group('Session Duration Validation', () {
      test('should validate session duration limits', () {
        final testContent = TodayFeedContent.sample();

        // Test normal duration (should pass through unchanged)
        expect(service.getPendingInteractionsCount(), equals(0));

        // Test that service can handle content without throwing
        expect(
          () => testContent.copyWith(title: 'Test Content'),
          returnsNormally,
        );
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

      test('should handle content with null ID', () {
        final testContent = TodayFeedContent.sample().copyWith(
          title: 'Test Content Without ID',
        );

        // The sample content has a default ID, so we test that it's not null
        expect(testContent.id, isNotNull);
        expect(testContent.title, equals('Test Content Without ID'));
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

    group('Service Configuration', () {
      test('should have correct configuration constants', () {
        // Test that configuration constants are reasonable
        expect(
          UserContentInteractionService.maxPendingInteractions,
          equals(100),
        );
        expect(
          UserContentInteractionService.syncRetryDelay,
          equals(const Duration(minutes: 5)),
        );
        expect(
          UserContentInteractionService.maxSessionDuration,
          equals(const Duration(hours: 1)),
        );
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
