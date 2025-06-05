import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/momentum/domain/models/momentum_data.dart';
import 'package:app/core/theme/app_theme.dart';

import '../../../helpers/test_helpers.dart';
import '../../../helpers/ai_coaching_test_helpers.dart';

/// AI Coach Momentum Integration Test Template for Epic 1.3
///
/// This template demonstrates how AI coaching services should integrate
/// with momentum tracking functionality.
void main() {
  group('AI Coach Momentum Integration Template', () {
    late MockAICoachingService mockAIService;

    setUp(() async {
      await TestHelpers.setUpTest();
      mockAIService = TestHelpers.createMockAICoachingService();
    });

    group('Momentum Drop Interventions', () {
      testWidgets(
        'should trigger AI intervention when momentum drops below threshold',
        (tester) async {
          // Arrange: User with dropping momentum
          final integrationData = TestHelpers.createAIMomentumIntegrationData(
            momentumState: MomentumState.needsCare,
            percentage: 25.0,
          );

          // Act: AI coaching service processes momentum drop
          final aiContext =
              integrationData['ai_context'] as ConversationContext;
          final response = await mockAIService.generateResponse(
            userId: 'test-user-123',
            userMessage: 'I\'m struggling to maintain my momentum',
            context: aiContext,
          );

          // Assert: AI provides appropriate intervention
          expect(response.responseType, equals(AIResponseType.intervention));
          expect(response.message, contains('momentum'));
          expect(response.suggestedActions, isNotEmpty);
          expect(response.confidenceScore, greaterThan(0.7));

          // Assert: Suggested actions are relevant to momentum recovery
          final hasRelevantSuggestions = response.suggestedActions.any(
            (action) =>
                action.toLowerCase().contains('break') ||
                action.toLowerCase().contains('meditation') ||
                action.toLowerCase().contains('support'),
          );
          expect(hasRelevantSuggestions, isTrue);
        },
      );

      testWidgets(
        'should provide personalized intervention based on user patterns',
        (tester) async {
          // Arrange: User with specific engagement patterns
          final engagementEvents =
              AICoachingTestHelpers.createMockEngagementEvents(
                userId: 'test-user-123',
                eventCount: 10,
              );

          final personalizationProfile = await mockAIService
              .analyzeUserPatterns(
                userId: 'test-user-123',
                events: engagementEvents,
              );

          // Arrange: Momentum drop scenario
          final context = AICoachingTestHelpers.createMockConversationContext(
            userId: 'test-user-123',
            previousTopics: ['momentum', 'wellness'],
          );

          // Act: AI generates personalized intervention
          final response = await mockAIService.generateResponse(
            userId: 'test-user-123',
            userMessage: 'My momentum is really low today',
            context: context,
          );

          // Assert: Response is personalized and appropriate
          AICoachingTestHelpers.validateAIResponse(response);
          expect(response.responseType, equals(AIResponseType.intervention));

          // Assert: Personalization profile influences response
          expect(personalizationProfile.preferredCoachingStyle, isNotNull);
          expect(personalizationProfile.topicPreferences, isNotEmpty);
        },
      );

      test('should handle momentum data integration correctly', () async {
        // Arrange: Various momentum states
        final momentumStates = [
          MomentumState.needsCare,
          MomentumState.steady,
          MomentumState.rising,
        ];

        for (final state in momentumStates) {
          // Act: Generate AI response for each momentum state
          final integrationData = TestHelpers.createAIMomentumIntegrationData(
            momentumState: state,
            percentage: state == MomentumState.needsCare ? 30.0 : 75.0,
          );

          final context = integrationData['ai_context'] as ConversationContext;

          final response = await mockAIService.generateResponse(
            userId: 'test-user-123',
            userMessage: 'How is my momentum looking?',
            context: context,
          );

          // Assert: AI response matches momentum state
          if (state == MomentumState.needsCare) {
            expect(response.responseType, equals(AIResponseType.intervention));
          } else {
            expect(
              response.responseType,
              isIn([AIResponseType.support, AIResponseType.celebration]),
            );
          }
        }
      });
    });

    group('Momentum Celebration and Progress', () {
      testWidgets('should celebrate momentum improvements', (tester) async {
        // Arrange: User with rising momentum
        final momentumData = TestHelpers.createSampleMomentumData(
          state: MomentumState.rising,
          percentage: 85.0,
          message: 'Great progress! Keep it up!',
        );

        final context = AICoachingTestHelpers.createMockConversationContext(
          previousTopics: ['momentum', 'progress'],
        );

        // Act: AI responds to positive momentum
        final response = await mockAIService.generateResponse(
          userId: 'test-user-123',
          userMessage:
              'My momentum has been really good lately! I\'m at ${momentumData.percentage}%',
          context: context,
        );

        // Assert: AI provides celebration response
        expect(response.responseType, equals(AIResponseType.celebration));
        expect(
          response.message.toLowerCase(),
          anyOf([
            contains('congratulations'),
            contains('great'),
            contains('excellent'),
            contains('wonderful'),
          ]),
        );
        expect(response.suggestedActions, isNotEmpty);
      });

      test(
        'should suggest appropriate next steps for momentum maintenance',
        () async {
          // Arrange: Steady momentum state
          final context = AICoachingTestHelpers.createMockConversationContext(
            previousTopics: ['momentum', 'maintenance'],
          );

          // Act: AI provides guidance for momentum maintenance
          final response = await mockAIService.generateResponse(
            userId: 'test-user-123',
            userMessage: 'I want to keep my momentum steady',
            context: context,
          );

          // Assert: AI provides appropriate guidance
          expect(
            response.responseType,
            isIn([AIResponseType.guidance, AIResponseType.support]),
          );

          final hasMaintenanceSuggestions = response.suggestedActions.any(
            (action) =>
                action.toLowerCase().contains('maintain') ||
                action.toLowerCase().contains('continue') ||
                action.toLowerCase().contains('routine'),
          );
          expect(hasMaintenanceSuggestions, isTrue);
        },
      );
    });

    group('Performance Requirements for Momentum Integration', () {
      test(
        'should respond to momentum events within performance limits',
        () async {
          // CRITICAL: AI must respond quickly to momentum changes
          final context = AICoachingTestHelpers.createMockConversationContext();
          final stopwatch = Stopwatch()..start();

          // Act: Generate response for momentum event
          final response = await mockAIService.generateResponse(
            userId: 'test-user-123',
            userMessage: 'My momentum just dropped significantly',
            context: context,
          );

          stopwatch.stop();

          // Assert: Response time meets Epic 1.3 requirements
          expect(
            stopwatch.elapsedMilliseconds,
            lessThan(500),
            reason: 'AI momentum responses must be under 500ms',
          );

          AICoachingTestHelpers.validateAIResponse(response);
        },
      );

      test('should handle concurrent momentum data processing', () async {
        // CRITICAL: AI should handle multiple momentum events simultaneously
        final contexts = List.generate(
          3,
          (index) => AICoachingTestHelpers.createMockConversationContext(
            userId: 'test-user-$index',
          ),
        );

        final futures =
            contexts
                .map(
                  (context) => mockAIService.generateResponse(
                    userId: context.userId,
                    userMessage: 'My momentum changed',
                    context: context,
                  ),
                )
                .toList();

        // Act: Process multiple momentum events concurrently
        final responses = await Future.wait(futures);

        // Assert: All responses are valid
        expect(responses.length, equals(3));
        for (final response in responses) {
          AICoachingTestHelpers.validateAIResponse(response);
        }
      });
    });

    group('Error Handling for Momentum Integration', () {
      test('should handle momentum data unavailability gracefully', () async {
        // Arrange: AI service with error simulation
        final errorService = TestHelpers.createMockAICoachingService(
          shouldThrowError: true,
        );

        final context = AICoachingTestHelpers.createMockConversationContext();

        // Act & Assert: Should handle errors gracefully
        expect(
          () => errorService.generateResponse(
            userId: 'test-user-123',
            userMessage: 'How is my momentum?',
            context: context,
          ),
          throwsA(isA<AICoachingException>()),
        );
      });

      test(
        'should provide fallback responses when momentum integration fails',
        () async {
          // This test demonstrates how the system should handle
          // momentum integration failures with graceful degradation
          final context = AICoachingTestHelpers.createMockConversationContext();

          // Act: Even with potential momentum data issues, AI should respond
          final response = await mockAIService.generateResponse(
            userId: 'test-user-123',
            userMessage: 'I want to improve my wellness',
            context: context,
          );

          // Assert: Fallback response is still helpful
          AICoachingTestHelpers.validateAIResponse(response);
          expect(response.message, isNotEmpty);
          expect(response.suggestedActions, isNotEmpty);
        },
      );
    });

    group('Real-world Integration Scenarios', () {
      test('should handle momentum tracking workflow integration', () async {
        // Simulate a complete momentum tracking + AI coaching workflow

        // Step 1: User checks momentum
        final momentumData = TestHelpers.createSampleMomentumData(
          state: MomentumState.needsCare,
          percentage: 40.0,
        );

        // Step 2: AI analyzes momentum and provides intervention
        final context = AICoachingTestHelpers.createMockConversationContext(
          previousTopics: ['momentum'],
        );

        final interventionResponse = await mockAIService.generateResponse(
          userId: 'test-user-123',
          userMessage: 'My momentum is at ${momentumData.percentage}%',
          context: context,
        );

        // Step 3: User follows AI suggestions
        final followUpResponse = await mockAIService.generateResponse(
          userId: 'test-user-123',
          userMessage: 'I tried the meditation you suggested',
          context: context,
        );

        // Assert: Complete workflow handled correctly
        expect(
          interventionResponse.responseType,
          equals(AIResponseType.intervention),
        );
        expect(
          followUpResponse.responseType,
          isIn([AIResponseType.celebration, AIResponseType.support]),
        );
      });

      test('should integrate momentum patterns with personalization', () async {
        // Arrange: Historical momentum patterns
        final engagementEvents =
            AICoachingTestHelpers.createMockEngagementEvents(
              userId: 'test-user-123',
              eventCount: 15,
            );

        // Act: AI analyzes patterns for personalized momentum support
        final personalizationProfile = await mockAIService.analyzeUserPatterns(
          userId: 'test-user-123',
          events: engagementEvents,
        );

        // Assert: Personalization captures momentum-related preferences
        AICoachingTestHelpers.validatePersonalizationProfile(
          personalizationProfile,
        );
        expect(
          personalizationProfile.engagementPatterns.averageSessionLength,
          isNotNull,
        );
        expect(personalizationProfile.topicPreferences, contains('wellness'));
      });
    });
  });
}

/// Helper class for momentum-specific AI coaching test patterns
class AIMomentumIntegrationTestPatterns {
  /// Test pattern for momentum drop interventions
  static Future<void> testMomentumDropIntervention(
    MockAICoachingService aiService,
    MomentumData momentumData,
  ) async {
    final context = AICoachingTestHelpers.createMockConversationContext(
      previousTopics: ['momentum', 'wellness'],
    );

    final response = await aiService.generateResponse(
      userId: 'test-user-123',
      userMessage: 'My momentum dropped to ${momentumData.percentage}%',
      context: context,
    );

    expect(response.responseType, equals(AIResponseType.intervention));
    expect(response.suggestedActions, isNotEmpty);
  }

  /// Test pattern for momentum celebration
  static Future<void> testMomentumCelebration(
    MockAICoachingService aiService,
    MomentumData momentumData,
  ) async {
    final context = AICoachingTestHelpers.createMockConversationContext(
      previousTopics: ['momentum', 'progress'],
    );

    final response = await aiService.generateResponse(
      userId: 'test-user-123',
      userMessage: 'I reached ${momentumData.percentage}% momentum!',
      context: context,
    );

    expect(response.responseType, equals(AIResponseType.celebration));
    expect(
      response.message.toLowerCase(),
      anyOf([
        contains('congratulations'),
        contains('great'),
        contains('excellent'),
      ]),
    );
  }

  /// Test pattern for personalized momentum guidance
  static Future<void> testPersonalizedMomentumGuidance(
    MockAICoachingService aiService,
    PersonalizationProfile profile,
  ) async {
    final context = AICoachingTestHelpers.createMockConversationContext(
      userId: profile.userId,
      previousTopics: profile.topicPreferences,
    );

    final response = await aiService.generateResponse(
      userId: profile.userId,
      userMessage: 'How can I improve my momentum based on my patterns?',
      context: context,
    );

    expect(
      response.responseType,
      isIn([AIResponseType.guidance, AIResponseType.support]),
    );
    AICoachingTestHelpers.validateAIResponse(response);
  }
}
