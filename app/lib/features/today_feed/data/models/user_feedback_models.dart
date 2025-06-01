import '../../domain/models/today_feed_content.dart';

/// Feedback rating levels for content evaluation
enum FeedbackRating {
  veryPoor(1, 'Very Poor', '😞'),
  poor(2, 'Poor', '😐'),
  fair(3, 'Fair', '🙂'),
  good(4, 'Good', '😊'),
  excellent(5, 'Excellent', '🤩');

  const FeedbackRating(this.value, this.label, this.emoji);

  final int value;
  final String label;
  final String emoji;

  static FeedbackRating fromValue(int value) {
    return FeedbackRating.values.firstWhere(
      (rating) => rating.value == value,
      orElse: () => FeedbackRating.fair,
    );
  }
}

/// Feedback categories for specific content aspects
enum FeedbackCategory {
  relevance('Relevance', 'How relevant was this content to your health goals?'),
  clarity('Clarity', 'How clear and easy to understand was the content?'),
  usefulness('Usefulness', 'How useful did you find this information?'),
  engagement('Engagement', 'How engaging and interesting was the content?'),
  accuracy('Accuracy', 'How accurate and trustworthy was the information?'),
  length('Length', 'Was the content the right length for you?');

  const FeedbackCategory(this.label, this.description);

  final String label;
  final String description;
}

/// Length preference feedback options
enum LengthPreference {
  tooShort('Too Short'),
  justRight('Just Right'),
  tooLong('Too Long');

  const LengthPreference(this.label);

  final String label;
}

/// Topic interest level for content personalization
enum TopicInterest {
  veryLow(1, 'Not Interested'),
  low(2, 'Slightly Interested'),
  moderate(3, 'Moderately Interested'),
  high(4, 'Very Interested'),
  veryHigh(5, 'Extremely Interested');

  const TopicInterest(this.value, this.label);

  final int value;
  final String label;

  static TopicInterest fromValue(int value) {
    return TopicInterest.values.firstWhere(
      (interest) => interest.value == value,
      orElse: () => TopicInterest.moderate,
    );
  }
}

/// User feedback data model for content effectiveness measurement
class UserContentFeedback {
  final String id;
  final String userId;
  final String contentId;
  final String contentTitle;
  final String topicCategory;
  final DateTime contentDate;
  final DateTime submittedAt;
  final FeedbackRating overallRating;
  final Map<FeedbackCategory, FeedbackRating> categoryRatings;
  final LengthPreference lengthPreference;
  final TopicInterest topicInterest;
  final String? openTextFeedback;
  final List<String> improvementSuggestions;
  final bool wouldRecommend;
  final Map<String, dynamic>? metadata;

  const UserContentFeedback({
    required this.id,
    required this.userId,
    required this.contentId,
    required this.contentTitle,
    required this.topicCategory,
    required this.contentDate,
    required this.submittedAt,
    required this.overallRating,
    required this.categoryRatings,
    required this.lengthPreference,
    required this.topicInterest,
    this.openTextFeedback,
    required this.improvementSuggestions,
    required this.wouldRecommend,
    this.metadata,
  });

  /// Factory constructor for creating feedback from Today Feed content
  factory UserContentFeedback.forContent({
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
  }) {
    return UserContentFeedback(
      id: _generateFeedbackId(userId, content.id.toString()),
      userId: userId,
      contentId: content.id.toString(),
      contentTitle: content.title,
      topicCategory: content.topicCategory.value,
      contentDate: content.contentDate,
      submittedAt: DateTime.now(),
      overallRating: overallRating,
      categoryRatings: categoryRatings,
      lengthPreference: lengthPreference,
      topicInterest: topicInterest,
      openTextFeedback: openTextFeedback?.trim(),
      improvementSuggestions: improvementSuggestions ?? [],
      wouldRecommend: wouldRecommend,
      metadata: metadata,
    );
  }

  /// Generate unique feedback ID
  static String _generateFeedbackId(String userId, String contentId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'feedback_${userId}_${contentId}_$timestamp';
  }

  /// JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'content_id': contentId,
      'content_title': contentTitle,
      'topic_category': topicCategory,
      'content_date': contentDate.toIso8601String().split('T')[0],
      'submitted_at': submittedAt.toIso8601String(),
      'overall_rating': overallRating.value,
      'category_ratings': categoryRatings.map(
        (key, value) => MapEntry(key.name, value.value),
      ),
      'length_preference': lengthPreference.name,
      'topic_interest': topicInterest.value,
      'open_text_feedback': openTextFeedback,
      'improvement_suggestions': improvementSuggestions,
      'would_recommend': wouldRecommend,
      'metadata': metadata,
    };
  }

  /// JSON deserialization
  factory UserContentFeedback.fromJson(Map<String, dynamic> json) {
    return UserContentFeedback(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      contentId: json['content_id'] as String,
      contentTitle: json['content_title'] as String,
      topicCategory: json['topic_category'] as String,
      contentDate: DateTime.parse(json['content_date'] as String),
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      overallRating: FeedbackRating.fromValue(json['overall_rating'] as int),
      categoryRatings: (json['category_ratings'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          FeedbackCategory.values.firstWhere((c) => c.name == key),
          FeedbackRating.fromValue(value as int),
        ),
      ),
      lengthPreference: LengthPreference.values.firstWhere(
        (p) => p.name == json['length_preference'],
      ),
      topicInterest: TopicInterest.fromValue(json['topic_interest'] as int),
      openTextFeedback: json['open_text_feedback'] as String?,
      improvementSuggestions: List<String>.from(
        json['improvement_suggestions'] as List? ?? [],
      ),
      wouldRecommend: json['would_recommend'] as bool,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Calculate feedback effectiveness score (0.0 to 1.0)
  double get effectivenessScore {
    final overallWeight = 0.4;
    final categoryWeight = 0.4;
    final recommendationWeight = 0.2;

    final overallScore = (overallRating.value - 1) / 4.0;

    final categorySum = categoryRatings.values
        .map((rating) => (rating.value - 1) / 4.0)
        .fold(0.0, (sum, score) => sum + score);
    final categoryScore =
        categoryRatings.isNotEmpty ? categorySum / categoryRatings.length : 0.0;

    final recommendationScore = wouldRecommend ? 1.0 : 0.0;

    return (overallScore * overallWeight) +
        (categoryScore * categoryWeight) +
        (recommendationScore * recommendationWeight);
  }

  /// Check if feedback indicates high satisfaction
  bool get isHighSatisfaction {
    return overallRating.value >= 4 && effectivenessScore >= 0.7;
  }

  /// Check if feedback indicates content needs improvement
  bool get needsImprovement {
    return overallRating.value <= 2 || effectivenessScore <= 0.4;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserContentFeedback &&
        other.id == id &&
        other.userId == userId &&
        other.contentId == contentId;
  }

  @override
  int get hashCode => Object.hash(id, userId, contentId);

  @override
  String toString() {
    return 'UserContentFeedback(id: $id, overall: ${overallRating.label}, '
        'effectiveness: ${effectivenessScore.toStringAsFixed(2)})';
  }
}

/// Aggregated feedback analytics for content effectiveness measurement
class ContentFeedbackAnalytics {
  final String contentId;
  final String contentTitle;
  final String topicCategory;
  final DateTime contentDate;
  final int totalResponses;
  final double averageOverallRating;
  final double effectivenessScore;
  final Map<FeedbackCategory, double> categoryAverages;
  final Map<LengthPreference, int> lengthPreferenceBreakdown;
  final Map<TopicInterest, int> topicInterestBreakdown;
  final double recommendationRate;
  final List<String> commonImprovementSuggestions;
  final Map<String, dynamic> insights;

  const ContentFeedbackAnalytics({
    required this.contentId,
    required this.contentTitle,
    required this.topicCategory,
    required this.contentDate,
    required this.totalResponses,
    required this.averageOverallRating,
    required this.effectivenessScore,
    required this.categoryAverages,
    required this.lengthPreferenceBreakdown,
    required this.topicInterestBreakdown,
    required this.recommendationRate,
    required this.commonImprovementSuggestions,
    required this.insights,
  });

  /// Factory constructor for empty analytics
  factory ContentFeedbackAnalytics.empty(String contentId) {
    return ContentFeedbackAnalytics(
      contentId: contentId,
      contentTitle: '',
      topicCategory: '',
      contentDate: DateTime.now(),
      totalResponses: 0,
      averageOverallRating: 0.0,
      effectivenessScore: 0.0,
      categoryAverages: {},
      lengthPreferenceBreakdown: {},
      topicInterestBreakdown: {},
      recommendationRate: 0.0,
      commonImprovementSuggestions: [],
      insights: {},
    );
  }

  /// JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'content_id': contentId,
      'content_title': contentTitle,
      'topic_category': topicCategory,
      'content_date': contentDate.toIso8601String().split('T')[0],
      'total_responses': totalResponses,
      'average_overall_rating': averageOverallRating,
      'effectiveness_score': effectivenessScore,
      'category_averages': categoryAverages.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'length_preference_breakdown': lengthPreferenceBreakdown.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'topic_interest_breakdown': topicInterestBreakdown.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'recommendation_rate': recommendationRate,
      'common_improvement_suggestions': commonImprovementSuggestions,
      'insights': insights,
    };
  }

  /// Check if content is performing well
  bool get isPerformingWell {
    return averageOverallRating >= 4.0 &&
        effectivenessScore >= 0.7 &&
        recommendationRate >= 0.8;
  }

  /// Check if content needs attention
  bool get needsAttention {
    return averageOverallRating <= 2.5 ||
        effectivenessScore <= 0.5 ||
        recommendationRate <= 0.5;
  }
}

/// Feedback collection result for UI feedback
class FeedbackCollectionResult {
  final bool success;
  final UserContentFeedback? feedback;
  final String message;
  final String? error;

  const FeedbackCollectionResult({
    required this.success,
    this.feedback,
    required this.message,
    this.error,
  });

  factory FeedbackCollectionResult.success(
    UserContentFeedback feedback,
    String message,
  ) {
    return FeedbackCollectionResult(
      success: true,
      feedback: feedback,
      message: message,
    );
  }

  factory FeedbackCollectionResult.error(String error, String message) {
    return FeedbackCollectionResult(
      success: false,
      message: message,
      error: error,
    );
  }
}
