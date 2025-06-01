import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/today_feed_content.dart';
import '../models/user_feedback_models.dart';
import '../../../../core/services/connectivity_service.dart';

/// Configuration for user feedback collection system
class FeedbackCollectionConfig {
  // Rate limiting
  static const Duration feedbackCooldown = Duration(hours: 24);
  static const int maxFeedbackPerDay = 3;
  static const int maxPendingFeedback = 20;

  // Analytics
  static const Duration analyticsWindow = Duration(days: 30);
  static const int minResponsesForAnalytics = 5;

  // Synchronization
  static const Duration syncRetryDelay = Duration(minutes: 5);
  static const int maxSyncRetries = 3;
}

/// Service for collecting and managing user feedback on Today Feed content
/// Implements T1.3.5.10: Create user feedback collection for content effectiveness measurement
class UserFeedbackCollectionService {
  static UserFeedbackCollectionService? _instance;
  static UserFeedbackCollectionService get instance {
    _instance ??= UserFeedbackCollectionService._internal();
    return _instance!;
  }

  UserFeedbackCollectionService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Pending feedback queue for offline support
  final List<UserContentFeedback> _pendingFeedback = [];
  final Map<String, DateTime> _feedbackCooldowns = {};

  Timer? _syncTimer;
  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  bool _isInitialized = false;

  /// Initialize the feedback collection service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Set up connectivity monitoring for offline sync
      _connectivitySubscription = ConnectivityService.statusStream.listen((
        status,
      ) {
        if (status == ConnectivityStatus.online &&
            _pendingFeedback.isNotEmpty) {
          _syncPendingFeedback();
        }
      });

      // Set up periodic sync
      _syncTimer = Timer.periodic(
        FeedbackCollectionConfig.syncRetryDelay,
        (_) => _syncPendingFeedback(),
      );

      _isInitialized = true;
      debugPrint('✅ UserFeedbackCollectionService initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize UserFeedbackCollectionService: $e');
      rethrow;
    }
  }

  /// Collect user feedback for Today Feed content
  Future<FeedbackCollectionResult> collectFeedback({
    required String userId,
    required TodayFeedContent content,
    required FeedbackRating overallRating,
    required Map<FeedbackCategory, FeedbackRating> categoryRatings,
    required LengthPreference lengthPreference,
    required TopicInterest topicInterest,
    String? openTextFeedback,
    List<String>? improvementSuggestions,
    required bool wouldRecommend,
    Map<String, dynamic>? metadata,
  }) async {
    await initialize();

    try {
      // Check rate limiting
      final rateLimitCheck = _checkRateLimit(userId, content.id.toString());
      if (!rateLimitCheck.success) {
        return FeedbackCollectionResult.error(
          'rate_limit_exceeded',
          rateLimitCheck.message,
        );
      }

      // Create feedback object
      final feedback = UserContentFeedback.forContent(
        userId: userId,
        content: content,
        overallRating: overallRating,
        categoryRatings: categoryRatings,
        lengthPreference: lengthPreference,
        topicInterest: topicInterest,
        openTextFeedback: openTextFeedback,
        improvementSuggestions: improvementSuggestions ?? [],
        wouldRecommend: wouldRecommend,
        metadata: {
          'app_version': '1.0.0', // TODO: Get from package info
          'platform': defaultTargetPlatform.name,
          'collection_timestamp': DateTime.now().toIso8601String(),
          'ai_confidence_score': content.aiConfidenceScore,
          'estimated_reading_minutes': content.estimatedReadingMinutes,
          ...?metadata,
        },
      );

      // Try to submit immediately if online
      if (ConnectivityService.isOnline) {
        try {
          await _submitFeedbackToDatabase(feedback);
          _updateRateLimit(userId, content.id.toString());

          return FeedbackCollectionResult.success(
            feedback,
            'Thank you for your feedback! It helps us improve your content.',
          );
        } catch (e) {
          debugPrint('❌ Failed to submit feedback immediately: $e');
          // Fall through to offline queue
        }
      }

      // Queue for offline sync
      await _queueFeedbackForSync(feedback);
      _updateRateLimit(userId, content.id.toString());

      return FeedbackCollectionResult.success(
        feedback,
        'Feedback saved! It will be submitted when you\'re back online.',
      );
    } catch (e) {
      debugPrint('❌ Failed to collect feedback: $e');
      return FeedbackCollectionResult.error(
        e.toString(),
        'Failed to save your feedback. Please try again.',
      );
    }
  }

  /// Get feedback analytics for specific content
  Future<ContentFeedbackAnalytics> getContentAnalytics(String contentId) async {
    await initialize();

    try {
      final response = await _supabase
          .from('user_content_feedback')
          .select('*')
          .eq('content_id', contentId)
          .order('submitted_at', ascending: false);

      if (response.isEmpty) {
        return ContentFeedbackAnalytics.empty(contentId);
      }

      final feedbackList =
          response.map((json) => UserContentFeedback.fromJson(json)).toList();

      return _calculateContentAnalytics(feedbackList);
    } catch (e) {
      debugPrint('❌ Failed to get content analytics: $e');
      return ContentFeedbackAnalytics.empty(contentId);
    }
  }

  /// Get user's feedback history
  Future<List<UserContentFeedback>> getUserFeedbackHistory(
    String userId, {
    int? limit,
    DateTime? since,
  }) async {
    await initialize();

    try {
      dynamic query = _supabase
          .from('user_content_feedback')
          .select('*')
          .eq('user_id', userId)
          .order('submitted_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      if (since != null) {
        query = query.gte('submitted_at', since.toIso8601String());
      }

      final response = await query;

      return response
          .map((json) => UserContentFeedback.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to get user feedback history: $e');
      return [];
    }
  }

  /// Get aggregated feedback analytics across all content
  Future<Map<String, dynamic>> getAggregatedAnalytics({
    DateTime? startDate,
    DateTime? endDate,
    String? topicCategory,
  }) async {
    await initialize();

    try {
      dynamic query = _supabase
          .from('user_content_feedback')
          .select('*')
          .order('submitted_at', ascending: false);

      if (startDate != null) {
        query = query.gte('submitted_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('submitted_at', endDate.toIso8601String());
      }

      if (topicCategory != null) {
        query = query.eq('topic_category', topicCategory);
      }

      final response = await query;

      if (response.isEmpty) {
        return _getEmptyAggregatedAnalytics();
      }

      final feedbackList =
          response.map((json) => UserContentFeedback.fromJson(json)).toList();

      return _calculateAggregatedAnalytics(feedbackList);
    } catch (e) {
      debugPrint('❌ Failed to get aggregated analytics: $e');
      return _getEmptyAggregatedAnalytics();
    }
  }

  /// Check if user can provide feedback (rate limiting)
  FeedbackCollectionResult _checkRateLimit(String userId, String contentId) {
    final feedbackKey = '${userId}_$contentId';
    final lastFeedbackTime = _feedbackCooldowns[feedbackKey];

    if (lastFeedbackTime != null) {
      final timeSinceLastFeedback = DateTime.now().difference(lastFeedbackTime);
      if (timeSinceLastFeedback < FeedbackCollectionConfig.feedbackCooldown) {
        final remainingHours =
            FeedbackCollectionConfig.feedbackCooldown.inHours -
            timeSinceLastFeedback.inHours;

        return FeedbackCollectionResult.error(
          'rate_limit_exceeded',
          'You can provide feedback again in $remainingHours hours.',
        );
      }
    }

    return FeedbackCollectionResult.success(
      UserContentFeedback.forContent(
        userId: userId,
        content: TodayFeedContent(
          id: int.parse(contentId),
          contentDate: DateTime.now(),
          title: '',
          summary: '',
          topicCategory: HealthTopic.nutrition,
          aiConfidenceScore: 0.0,
        ),
        overallRating: FeedbackRating.fair,
        categoryRatings: {},
        lengthPreference: LengthPreference.justRight,
        topicInterest: TopicInterest.moderate,
        wouldRecommend: false,
      ),
      'Rate limit check passed',
    );
  }

  /// Update rate limiting tracking
  void _updateRateLimit(String userId, String contentId) {
    final feedbackKey = '${userId}_$contentId';
    _feedbackCooldowns[feedbackKey] = DateTime.now();
  }

  /// Submit feedback to database
  Future<void> _submitFeedbackToDatabase(UserContentFeedback feedback) async {
    await _supabase.from('user_content_feedback').insert(feedback.toJson());

    debugPrint('✅ Feedback submitted to database: ${feedback.id}');
  }

  /// Queue feedback for offline sync
  Future<void> _queueFeedbackForSync(UserContentFeedback feedback) async {
    if (_pendingFeedback.length >=
        FeedbackCollectionConfig.maxPendingFeedback) {
      // Remove oldest pending feedback
      _pendingFeedback.removeAt(0);
    }

    _pendingFeedback.add(feedback);
    debugPrint('📦 Feedback queued for sync: ${feedback.id}');
  }

  /// Sync pending feedback when connectivity is restored
  Future<void> _syncPendingFeedback() async {
    if (_pendingFeedback.isEmpty || !ConnectivityService.isOnline) return;

    final feedbackToSync = List<UserContentFeedback>.from(_pendingFeedback);
    final successfullySync = <UserContentFeedback>[];

    for (final feedback in feedbackToSync) {
      try {
        await _submitFeedbackToDatabase(feedback);
        successfullySync.add(feedback);
      } catch (e) {
        debugPrint('❌ Failed to sync feedback ${feedback.id}: $e');
        // Keep in queue for retry
      }
    }

    // Remove successfully synced feedback
    for (final feedback in successfullySync) {
      _pendingFeedback.remove(feedback);
    }

    if (successfullySync.isNotEmpty) {
      debugPrint('✅ Synced ${successfullySync.length} pending feedback items');
    }
  }

  /// Calculate analytics for specific content
  ContentFeedbackAnalytics _calculateContentAnalytics(
    List<UserContentFeedback> feedbackList,
  ) {
    if (feedbackList.isEmpty) {
      return ContentFeedbackAnalytics.empty(feedbackList.first.contentId);
    }

    final firstFeedback = feedbackList.first;
    final totalResponses = feedbackList.length;

    // Calculate averages
    final averageOverallRating =
        feedbackList
            .map((f) => f.overallRating.value.toDouble())
            .reduce((a, b) => a + b) /
        totalResponses;

    final effectivenessScore =
        feedbackList.map((f) => f.effectivenessScore).reduce((a, b) => a + b) /
        totalResponses;

    // Calculate category averages
    final categoryAverages = <FeedbackCategory, double>{};
    for (final category in FeedbackCategory.values) {
      final ratings =
          feedbackList
              .where((f) => f.categoryRatings.containsKey(category))
              .map((f) => f.categoryRatings[category]!.value.toDouble())
              .toList();

      if (ratings.isNotEmpty) {
        categoryAverages[category] =
            ratings.reduce((a, b) => a + b) / ratings.length;
      }
    }

    // Calculate breakdowns
    final lengthPreferenceBreakdown = <LengthPreference, int>{};
    final topicInterestBreakdown = <TopicInterest, int>{};

    for (final feedback in feedbackList) {
      lengthPreferenceBreakdown[feedback.lengthPreference] =
          (lengthPreferenceBreakdown[feedback.lengthPreference] ?? 0) + 1;

      topicInterestBreakdown[feedback.topicInterest] =
          (topicInterestBreakdown[feedback.topicInterest] ?? 0) + 1;
    }

    // Calculate recommendation rate
    final recommendationCount =
        feedbackList.where((f) => f.wouldRecommend).length;
    final recommendationRate = recommendationCount / totalResponses;

    // Extract common improvement suggestions
    final allSuggestions =
        feedbackList.expand((f) => f.improvementSuggestions).toList();
    final suggestionCounts = <String, int>{};
    for (final suggestion in allSuggestions) {
      suggestionCounts[suggestion] = (suggestionCounts[suggestion] ?? 0) + 1;
    }

    final commonSuggestions =
        suggestionCounts.entries
            .where((entry) => entry.value >= 2)
            .map((entry) => entry.key)
            .take(5)
            .toList();

    // Generate insights
    final insights = _generateContentInsights(
      averageOverallRating,
      effectivenessScore,
      recommendationRate,
      categoryAverages,
      totalResponses,
    );

    return ContentFeedbackAnalytics(
      contentId: firstFeedback.contentId,
      contentTitle: firstFeedback.contentTitle,
      topicCategory: firstFeedback.topicCategory,
      contentDate: firstFeedback.contentDate,
      totalResponses: totalResponses,
      averageOverallRating: averageOverallRating,
      effectivenessScore: effectivenessScore,
      categoryAverages: categoryAverages,
      lengthPreferenceBreakdown: lengthPreferenceBreakdown,
      topicInterestBreakdown: topicInterestBreakdown,
      recommendationRate: recommendationRate,
      commonImprovementSuggestions: commonSuggestions,
      insights: insights,
    );
  }

  /// Calculate aggregated analytics across all content
  Map<String, dynamic> _calculateAggregatedAnalytics(
    List<UserContentFeedback> feedbackList,
  ) {
    if (feedbackList.isEmpty) {
      return _getEmptyAggregatedAnalytics();
    }

    final totalResponses = feedbackList.length;

    // Overall metrics
    final averageOverallRating =
        feedbackList
            .map((f) => f.overallRating.value.toDouble())
            .reduce((a, b) => a + b) /
        totalResponses;

    final averageEffectivenessScore =
        feedbackList.map((f) => f.effectivenessScore).reduce((a, b) => a + b) /
        totalResponses;

    // Topic category breakdown
    final topicBreakdown = <String, Map<String, dynamic>>{};
    final contentGroups = <String, List<UserContentFeedback>>{};

    for (final feedback in feedbackList) {
      contentGroups.putIfAbsent(feedback.topicCategory, () => []).add(feedback);
    }

    for (final entry in contentGroups.entries) {
      final topicFeedback = entry.value;
      final topicAvgRating =
          topicFeedback
              .map((f) => f.overallRating.value.toDouble())
              .reduce((a, b) => a + b) /
          topicFeedback.length;

      topicBreakdown[entry.key] = {
        'total_responses': topicFeedback.length,
        'average_rating': topicAvgRating,
        'recommendation_rate':
            topicFeedback.where((f) => f.wouldRecommend).length /
            topicFeedback.length,
      };
    }

    // Content performance distribution
    final highPerformingContent =
        feedbackList.where((f) => f.isHighSatisfaction).length;
    final needsImprovementContent =
        feedbackList.where((f) => f.needsImprovement).length;

    return {
      'period': {
        'start_date': feedbackList.last.submittedAt.toIso8601String(),
        'end_date': feedbackList.first.submittedAt.toIso8601String(),
        'total_responses': totalResponses,
      },
      'overall_metrics': {
        'average_overall_rating': averageOverallRating,
        'average_effectiveness_score': averageEffectivenessScore,
        'recommendation_rate':
            feedbackList.where((f) => f.wouldRecommend).length / totalResponses,
      },
      'topic_breakdown': topicBreakdown,
      'content_performance': {
        'high_satisfaction_rate': highPerformingContent / totalResponses,
        'needs_improvement_rate': needsImprovementContent / totalResponses,
        'satisfactory_rate':
            (totalResponses - highPerformingContent - needsImprovementContent) /
            totalResponses,
      },
      'insights': _generateAggregatedInsights(
        averageOverallRating,
        averageEffectivenessScore,
        topicBreakdown,
      ),
    };
  }

  /// Generate content-specific insights
  Map<String, dynamic> _generateContentInsights(
    double avgRating,
    double effectivenessScore,
    double recommendationRate,
    Map<FeedbackCategory, double> categoryAverages,
    int totalResponses,
  ) {
    final insights = <String>[];
    final recommendations = <String>[];

    if (avgRating >= 4.0) {
      insights.add('High user satisfaction with overall content quality');
    } else if (avgRating <= 2.5) {
      insights.add('Users are not satisfied with content quality');
      recommendations.add('Review content generation and topic selection');
    }

    if (effectivenessScore >= 0.8) {
      insights.add('Content is highly effective for user engagement');
    } else if (effectivenessScore <= 0.5) {
      insights.add('Content effectiveness is below expectations');
      recommendations.add('Improve content relevance and clarity');
    }

    if (recommendationRate >= 0.8) {
      insights.add('Users highly likely to recommend this content');
    } else if (recommendationRate <= 0.5) {
      insights.add('Low recommendation rate indicates content issues');
      recommendations.add(
        'Focus on creating more valuable and engaging content',
      );
    }

    // Category-specific insights
    final lowestCategory = categoryAverages.entries.reduce(
      (a, b) => a.value < b.value ? a : b,
    );

    if (lowestCategory.value < 3.0) {
      insights.add('${lowestCategory.key.label} needs improvement');
      recommendations.add(
        'Focus on improving ${lowestCategory.key.label.toLowerCase()}',
      );
    }

    return {
      'insights': insights,
      'recommendations': recommendations,
      'confidence_level':
          totalResponses >= FeedbackCollectionConfig.minResponsesForAnalytics
              ? 'high'
              : 'low',
    };
  }

  /// Generate aggregated insights across all content
  Map<String, dynamic> _generateAggregatedInsights(
    double avgRating,
    double avgEffectiveness,
    Map<String, Map<String, dynamic>> topicBreakdown,
  ) {
    final insights = <String>[];
    final recommendations = <String>[];

    // Overall performance insights
    if (avgRating >= 4.0 && avgEffectiveness >= 0.7) {
      insights.add('Content system performing excellently across all metrics');
    } else if (avgRating <= 3.0 || avgEffectiveness <= 0.6) {
      insights.add('Content system needs improvement');
      recommendations.add('Review content generation and curation processes');
    }

    // Topic performance insights
    if (topicBreakdown.isNotEmpty) {
      final bestTopic = topicBreakdown.entries.reduce(
        (a, b) =>
            (a.value['average_rating'] as double) >
                    (b.value['average_rating'] as double)
                ? a
                : b,
      );

      final worstTopic = topicBreakdown.entries.reduce(
        (a, b) =>
            (a.value['average_rating'] as double) <
                    (b.value['average_rating'] as double)
                ? a
                : b,
      );

      insights.add('Best performing topic: ${bestTopic.key}');

      if ((worstTopic.value['average_rating'] as double) < 3.0) {
        insights.add('${worstTopic.key} topic needs attention');
        recommendations.add(
          'Improve ${worstTopic.key} content quality and relevance',
        );
      }
    }

    return {
      'insights': insights,
      'recommendations': recommendations,
      'generated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Get empty aggregated analytics structure
  Map<String, dynamic> _getEmptyAggregatedAnalytics() {
    return {
      'period': {'start_date': null, 'end_date': null, 'total_responses': 0},
      'overall_metrics': {
        'average_overall_rating': 0.0,
        'average_effectiveness_score': 0.0,
        'recommendation_rate': 0.0,
      },
      'topic_breakdown': <String, Map<String, dynamic>>{},
      'content_performance': {
        'high_satisfaction_rate': 0.0,
        'needs_improvement_rate': 0.0,
        'satisfactory_rate': 0.0,
      },
      'insights': {
        'insights': <String>[],
        'recommendations': [
          'Collect more feedback data for meaningful insights',
        ],
        'generated_at': DateTime.now().toIso8601String(),
      },
    };
  }

  /// Get pending feedback count for UI display
  int get pendingFeedbackCount => _pendingFeedback.length;

  /// Check if user has pending feedback
  bool get hasPendingFeedback => _pendingFeedback.isNotEmpty;

  /// Dispose of resources
  void dispose() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    _pendingFeedback.clear();
    _feedbackCooldowns.clear();
    _isInitialized = false;
    debugPrint('🧹 UserFeedbackCollectionService disposed');
  }
}
