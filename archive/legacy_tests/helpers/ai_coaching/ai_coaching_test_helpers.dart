import 'package:flutter_test/flutter_test.dart';

/// AI Coaching Service Mock for Epic 1.3 Testing
class MockAICoachingService implements AICoachingService {
  final Map<String, dynamic> _mockResponses;
  final bool _shouldSimulateDelay;
  final bool _shouldThrowError;
  final Duration _responseDelay;

  MockAICoachingService({
    Map<String, dynamic>? mockResponses,
    bool shouldSimulateDelay = false,
    bool shouldThrowError = false,
    Duration responseDelay = const Duration(milliseconds: 300),
  }) : _mockResponses = mockResponses ?? _defaultAIResponses,
       _shouldSimulateDelay = shouldSimulateDelay,
       _shouldThrowError = shouldThrowError,
       _responseDelay = responseDelay;

  static final Map<String, dynamic> _defaultAIResponses = {
    'momentum_drop':
        'I noticed your momentum dropped. Let\'s talk about what\'s happening.',
    'celebration': 'Congratulations on your progress! You\'re doing great.',
    'general_support': 'I\'m here to help you with your wellness journey.',
    'check_in': 'How are you feeling today? Let\'s check in on your progress.',
    'goal_setting': 'Let\'s work together to set some achievable goals.',
    'motivation': 'Remember why you started this journey. You\'ve got this!',
  };

  @override
  Future<AICoachResponse> generateResponse({
    required String userId,
    required String userMessage,
    required ConversationContext context,
  }) async {
    if (_shouldThrowError) {
      throw AICoachingException('Mock AI service error for testing');
    }

    if (_shouldSimulateDelay) {
      await Future.delayed(_responseDelay);
    }

    final responseKey = _determineResponseKey(userMessage, context);
    final mockResponse =
        _mockResponses[responseKey] ?? _mockResponses['general_support'];

    return AICoachResponse(
      message: mockResponse,
      confidenceScore: 0.85,
      suggestedActions: _generateSuggestedActions(responseKey),
      conversationId: context.conversationId,
      timestamp: DateTime.now(),
      responseType: _determineResponseType(responseKey),
    );
  }

  @override
  Future<PersonalizationProfile> analyzeUserPatterns({
    required String userId,
    required List<EngagementEvent> events,
  }) async {
    if (_shouldThrowError) {
      throw AICoachingException('Mock personalization service error');
    }

    if (_shouldSimulateDelay) {
      await Future.delayed(_responseDelay);
    }

    return PersonalizationProfile(
      userId: userId,
      preferredCoachingStyle: CoachingStyle.supportive,
      topicPreferences: ['wellness', 'mindfulness', 'goal-setting'],
      communicationPreferences: CommunicationPreferences(
        frequency: NotificationFrequency.moderate,
        timeOfDay: TimeOfDay.evening,
        toneStyle: ToneStyle.encouraging,
      ),
      engagementPatterns: EngagementPatterns(
        averageSessionLength: const Duration(minutes: 5),
        preferredContentTypes: ['tips', 'reflections'],
        peakEngagementHours: [19, 20, 21],
      ),
      lastUpdated: DateTime.now(),
    );
  }

  @override
  Future<ConversationSummary> summarizeConversation({
    required String conversationId,
    required List<ConversationMessage> messages,
  }) async {
    if (_shouldThrowError) {
      throw AICoachingException('Mock conversation summary error');
    }

    if (_shouldSimulateDelay) {
      await Future.delayed(_responseDelay);
    }

    return ConversationSummary(
      conversationId: conversationId,
      summary:
          'User discussed wellness goals and received supportive guidance.',
      keyTopics: ['wellness', 'goals', 'support'],
      actionItems: ['Set daily reminder', 'Practice mindfulness'],
      sentiment: ConversationSentiment.positive,
      duration: const Duration(minutes: 3),
      timestamp: DateTime.now(),
    );
  }

  String _determineResponseKey(
    String userMessage,
    ConversationContext context,
  ) {
    final lowerMessage = userMessage.toLowerCase();

    // Check context topics for additional clues
    final contextTopics =
        context.previousTopics.map((t) => t.toLowerCase()).toList();

    // Support patterns for difficulties and struggles
    if (lowerMessage.contains('confusing') ||
        lowerMessage.contains('hard to understand') ||
        (lowerMessage.contains('found') &&
            lowerMessage.contains('confusing'))) {
      return 'general_support';
    }

    // Momentum drop patterns - specific negative indicators only
    if (lowerMessage.contains('down') ||
        lowerMessage.contains('struggle') ||
        lowerMessage.contains('struggling') ||
        lowerMessage.contains('maintain my momentum') ||
        (lowerMessage.contains('dropped') &&
            lowerMessage.contains('significantly')) ||
        (lowerMessage.contains('momentum is at') &&
            (RegExp(r'[1-4]\d\.?\d*%|[1-4]%').hasMatch(lowerMessage))) ||
        (lowerMessage.contains('momentum') &&
            (lowerMessage.contains('drop') ||
                lowerMessage.contains('really low')))) {
      return 'momentum_drop';
    }

    // Celebration patterns - positive indicators
    if (lowerMessage.contains('great') ||
        lowerMessage.contains('success') ||
        lowerMessage.contains('successful') ||
        lowerMessage.contains('helpful') ||
        lowerMessage.contains('completed') ||
        lowerMessage.contains('finished') ||
        lowerMessage.contains('excellent') ||
        lowerMessage.contains('wonderful') ||
        lowerMessage.contains('reached') ||
        lowerMessage.contains('improvements') ||
        lowerMessage.contains('good lately') ||
        (lowerMessage.contains('finished reading') &&
            lowerMessage.contains('helpful')) ||
        (lowerMessage.contains('momentum') &&
            (lowerMessage.contains('good') ||
                lowerMessage.contains('great') ||
                lowerMessage.contains('really good')))) {
      return 'celebration';
    }

    // Maintenance patterns - for maintaining current momentum
    if ((lowerMessage.contains('keep') && lowerMessage.contains('steady')) ||
        (lowerMessage.contains('maintain') &&
            lowerMessage.contains('momentum'))) {
      return 'maintenance';
    }

    // Goal setting patterns
    if (lowerMessage.contains('goal') ||
        lowerMessage.contains('set') ||
        lowerMessage.contains('plan') ||
        lowerMessage.contains('improve') ||
        lowerMessage.contains('better') ||
        (lowerMessage.contains('apply') && lowerMessage.contains('learned')) ||
        lowerMessage.contains('what should i do')) {
      return 'goal_setting';
    }

    // Momentum question handling - check context for appropriate response
    if (lowerMessage.contains('how') &&
        lowerMessage.contains('momentum') &&
        lowerMessage.contains('looking')) {
      if (contextTopics.contains('needscare') ||
          contextTopics.contains('low') ||
          contextTopics.contains('intervention')) {
        return 'momentum_drop';
      } else if (contextTopics.contains('progress') ||
          contextTopics.contains('improvement') ||
          contextTopics.contains('celebration')) {
        return 'celebration';
      } else if (contextTopics.contains('steady') ||
          contextTopics.contains('maintenance')) {
        return 'general_support';
      } else {
        return 'check_in';
      }
    }

    // Check-in patterns
    if ((lowerMessage.contains('how') && lowerMessage.contains('feeling')) ||
        lowerMessage.contains('check in')) {
      return 'check_in';
    }

    // Motivation patterns
    if (lowerMessage.contains('motivat') ||
        lowerMessage.contains('inspire') ||
        lowerMessage.contains('encourage')) {
      return 'motivation';
    }

    return 'general_support';
  }

  List<String> _generateSuggestedActions(String responseKey) {
    final actionMap = {
      'momentum_drop': [
        'Schedule a wellness break',
        'Try a 5-minute meditation',
        'Reach out for support from friends',
        'Take a short break from your routine',
      ],
      'celebration': [
        'Apply what you learned today',
        'Practice the key concepts',
        'Reflect on your progress',
        'Share your success with others',
      ],
      'goal_setting': [
        'Apply what you learned in small steps',
        'Practice the concepts regularly',
        'Create an action plan with steps',
        'Reflect on how to use this knowledge',
      ],
      'maintenance': [
        'Maintain your current routine',
        'Continue what\'s working well',
        'Stay consistent with your habits',
        'Keep up the good work',
      ],
      'check_in': [
        'Reflect on your day and progress',
        'Note any improvements you\'ve made',
        'Consider what\'s working well',
      ],
      'motivation': [
        'Remember why you started this journey',
        'Focus on your progress so far',
        'Take inspiration from your achievements',
      ],
      'general_support': [
        'Take a break if you need one',
        'Ask for help when things are unclear',
        'Look for simpler explanations',
        'Focus on one step at a time',
      ],
    };

    return actionMap[responseKey] ?? actionMap['general_support']!;
  }

  AIResponseType _determineResponseType(String responseKey) {
    final typeMap = {
      'momentum_drop': AIResponseType.intervention,
      'celebration': AIResponseType.celebration,
      'goal_setting': AIResponseType.guidance,
      'maintenance': AIResponseType.guidance,
      'check_in': AIResponseType.checkIn,
      'motivation': AIResponseType.support,
      'general_support': AIResponseType.support,
    };

    return typeMap[responseKey] ?? AIResponseType.support;
  }
}

/// AI Coaching Test Helper Methods
class AICoachingTestHelpers {
  /// Create a mock AI coaching service with configurable behavior
  static MockAICoachingService createMockAICoachingService({
    Map<String, dynamic>? mockResponses,
    bool shouldSimulateDelay = false,
    bool shouldThrowError = false,
    Duration responseDelay = const Duration(milliseconds: 300),
  }) {
    return MockAICoachingService(
      mockResponses: mockResponses,
      shouldSimulateDelay: shouldSimulateDelay,
      shouldThrowError: shouldThrowError,
      responseDelay: responseDelay,
    );
  }

  /// Create a mock AI response for testing
  static AICoachResponse createMockAIResponse({
    String? message,
    double? confidenceScore,
    List<String>? suggestedActions,
    String? conversationId,
    AIResponseType? responseType,
  }) {
    return AICoachResponse(
      message: message ?? 'This is a test AI coaching response.',
      confidenceScore: confidenceScore ?? 0.85,
      suggestedActions: suggestedActions ?? ['Test action 1', 'Test action 2'],
      conversationId: conversationId ?? 'test-conversation-123',
      timestamp: DateTime.now(),
      responseType: responseType ?? AIResponseType.support,
    );
  }

  /// Create a mock personalization profile for testing
  static PersonalizationProfile createMockPersonalizationProfile({
    String? userId,
    CoachingStyle? preferredStyle,
    List<String>? topicPreferences,
    NotificationFrequency? frequency,
  }) {
    return PersonalizationProfile(
      userId: userId ?? 'test-user-123',
      preferredCoachingStyle: preferredStyle ?? CoachingStyle.supportive,
      topicPreferences: topicPreferences ?? ['wellness', 'mindfulness'],
      communicationPreferences: CommunicationPreferences(
        frequency: frequency ?? NotificationFrequency.moderate,
        timeOfDay: TimeOfDay.evening,
        toneStyle: ToneStyle.encouraging,
      ),
      engagementPatterns: EngagementPatterns(
        averageSessionLength: const Duration(minutes: 5),
        preferredContentTypes: ['tips', 'reflections'],
        peakEngagementHours: [19, 20, 21],
      ),
      lastUpdated: DateTime.now(),
    );
  }

  /// Create a mock conversation context for testing
  static ConversationContext createMockConversationContext({
    String? conversationId,
    String? userId,
    ConversationState? state,
    List<String>? previousTopics,
  }) {
    return ConversationContext(
      conversationId: conversationId ?? 'test-conversation-123',
      userId: userId ?? 'test-user-123',
      state: state ?? ConversationState.active,
      previousTopics: previousTopics ?? ['wellness', 'goals'],
      startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      lastActivity: DateTime.now(),
      messageCount: 3,
    );
  }

  /// Create mock engagement events for testing
  static List<EngagementEvent> createMockEngagementEvents({
    String? userId,
    int eventCount = 5,
  }) {
    return List.generate(eventCount, (index) {
      return EngagementEvent(
        id: 'event-$index',
        userId: userId ?? 'test-user-123',
        eventType:
            EngagementEventType.values[index %
                EngagementEventType.values.length],
        timestamp: DateTime.now().subtract(Duration(days: index)),
        metadata: {
          'session_duration': '${(index + 1) * 2}m',
          'content_type': 'wellness_tip',
        },
      );
    });
  }

  /// Create a mock conversation message for testing
  static ConversationMessage createMockConversationMessage({
    String? messageId,
    String? conversationId,
    bool isFromUser = true,
    String? content,
  }) {
    return ConversationMessage(
      messageId: messageId ?? 'msg-${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId ?? 'test-conversation-123',
      isFromUser: isFromUser,
      content:
          content ??
          (isFromUser
              ? 'Hello, I need some support'
              : 'I\'m here to help you!'),
      timestamp: DateTime.now(),
      metadata: {'source': isFromUser ? 'user_input' : 'ai_generation'},
    );
  }

  /// Create mock conversation summary for testing
  static ConversationSummary createMockConversationSummary({
    String? conversationId,
    String? summary,
    List<String>? keyTopics,
    ConversationSentiment? sentiment,
  }) {
    return ConversationSummary(
      conversationId: conversationId ?? 'test-conversation-123',
      summary:
          summary ??
          'User discussed wellness goals and received supportive guidance.',
      keyTopics: keyTopics ?? ['wellness', 'goals', 'support'],
      actionItems: ['Set daily reminder', 'Practice mindfulness'],
      sentiment: sentiment ?? ConversationSentiment.positive,
      duration: const Duration(minutes: 3),
      timestamp: DateTime.now(),
    );
  }

  /// Validate AI response structure for testing
  static void validateAIResponse(AICoachResponse response) {
    expect(response.message, isNotEmpty);
    expect(response.confidenceScore, inInclusiveRange(0.0, 1.0));
    expect(response.suggestedActions, isNotEmpty);
    expect(response.conversationId, isNotEmpty);
    expect(response.timestamp, isNotNull);
    expect(response.responseType, isNotNull);
  }

  /// Validate personalization profile structure for testing
  static void validatePersonalizationProfile(PersonalizationProfile profile) {
    expect(profile.userId, isNotEmpty);
    expect(profile.preferredCoachingStyle, isNotNull);
    expect(profile.topicPreferences, isNotEmpty);
    expect(profile.communicationPreferences, isNotNull);
    expect(profile.engagementPatterns, isNotNull);
    expect(profile.lastUpdated, isNotNull);
  }
}

// Mock Domain Models for AI Coaching (Epic 1.3)
// These would normally be in their respective domain model files

abstract class AICoachingService {
  Future<AICoachResponse> generateResponse({
    required String userId,
    required String userMessage,
    required ConversationContext context,
  });

  Future<PersonalizationProfile> analyzeUserPatterns({
    required String userId,
    required List<EngagementEvent> events,
  });

  Future<ConversationSummary> summarizeConversation({
    required String conversationId,
    required List<ConversationMessage> messages,
  });
}

class AICoachResponse {
  final String message;
  final double confidenceScore;
  final List<String> suggestedActions;
  final String conversationId;
  final DateTime timestamp;
  final AIResponseType responseType;

  AICoachResponse({
    required this.message,
    required this.confidenceScore,
    required this.suggestedActions,
    required this.conversationId,
    required this.timestamp,
    required this.responseType,
  });
}

class PersonalizationProfile {
  final String userId;
  final CoachingStyle preferredCoachingStyle;
  final List<String> topicPreferences;
  final CommunicationPreferences communicationPreferences;
  final EngagementPatterns engagementPatterns;
  final DateTime lastUpdated;

  PersonalizationProfile({
    required this.userId,
    required this.preferredCoachingStyle,
    required this.topicPreferences,
    required this.communicationPreferences,
    required this.engagementPatterns,
    required this.lastUpdated,
  });
}

class ConversationContext {
  final String conversationId;
  final String userId;
  final ConversationState state;
  final List<String> previousTopics;
  final DateTime startedAt;
  final DateTime lastActivity;
  final int messageCount;

  ConversationContext({
    required this.conversationId,
    required this.userId,
    required this.state,
    required this.previousTopics,
    required this.startedAt,
    required this.lastActivity,
    required this.messageCount,
  });
}

class ConversationSummary {
  final String conversationId;
  final String summary;
  final List<String> keyTopics;
  final List<String> actionItems;
  final ConversationSentiment sentiment;
  final Duration duration;
  final DateTime timestamp;

  ConversationSummary({
    required this.conversationId,
    required this.summary,
    required this.keyTopics,
    required this.actionItems,
    required this.sentiment,
    required this.duration,
    required this.timestamp,
  });
}

class ConversationMessage {
  final String messageId;
  final String conversationId;
  final bool isFromUser;
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  ConversationMessage({
    required this.messageId,
    required this.conversationId,
    required this.isFromUser,
    required this.content,
    required this.timestamp,
    required this.metadata,
  });
}

class CommunicationPreferences {
  final NotificationFrequency frequency;
  final TimeOfDay timeOfDay;
  final ToneStyle toneStyle;

  CommunicationPreferences({
    required this.frequency,
    required this.timeOfDay,
    required this.toneStyle,
  });
}

class EngagementPatterns {
  final Duration averageSessionLength;
  final List<String> preferredContentTypes;
  final List<int> peakEngagementHours;

  EngagementPatterns({
    required this.averageSessionLength,
    required this.preferredContentTypes,
    required this.peakEngagementHours,
  });
}

class EngagementEvent {
  final String id;
  final String userId;
  final EngagementEventType eventType;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  EngagementEvent({
    required this.id,
    required this.userId,
    required this.eventType,
    required this.timestamp,
    required this.metadata,
  });
}

// Enums for AI Coaching System
enum CoachingStyle { supportive, directive, collaborative, analytical }

enum AIResponseType { intervention, celebration, guidance, checkIn, support }

enum ConversationState { active, paused, completed, error }

enum ConversationSentiment { positive, neutral, negative, mixed }

enum NotificationFrequency { low, moderate, high }

enum TimeOfDay { morning, afternoon, evening, night }

enum ToneStyle { encouraging, professional, casual, empathetic }

enum EngagementEventType {
  appOpen,
  lessonComplete,
  coachInteraction,
  goalSet,
  reflectionSubmitted,
  contentViewed,
  actionTaken,
}

class AICoachingException implements Exception {
  final String message;
  AICoachingException(this.message);

  @override
  String toString() => 'AICoachingException: $message';
}
