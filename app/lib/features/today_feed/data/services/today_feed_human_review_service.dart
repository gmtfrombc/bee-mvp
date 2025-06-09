import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/today_feed_content.dart';
import 'today_feed_content_quality_models.dart';

/// Human review workflow service for Today Feed content
/// Implements M1.2.1.3 Task T1.2.1.3.2 requirements for manual review workflow
///
/// This service handles:
/// - Queuing content for human review when safety validation fails
/// - Tracking review status and notifications
/// - Integration with existing safety monitoring systems
/// - Fallback workflow for questionable content
class TodayFeedHumanReviewService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static bool _isInitialized = false;

  // Review thresholds
  static const double _automaticReviewThreshold = 0.6;
  static const double _escalationThreshold = 0.4;

  /// Initialize the human review service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Verify database tables exist
      await _verifyDatabaseTables();

      _isInitialized = true;
      debugPrint('✅ TodayFeedHumanReviewService initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize TodayFeedHumanReviewService: $e');
      rethrow;
    }
  }

  /// Queue content for human review based on safety validation results
  static Future<ReviewQueueResult> queueContentForReview({
    required TodayFeedContent content,
    required SafetyMonitoringResult safetyResult,
    String? escalationReason,
  }) async {
    if (!_isInitialized) {
      throw StateError('TodayFeedHumanReviewService not initialized');
    }

    try {
      // Determine review priority based on safety score
      final priority = _determinePriority(safetyResult.safetyScore);

      // Check if content should be escalated immediately
      final shouldEscalate = safetyResult.safetyScore < _escalationThreshold;

      // Insert into review queue
      final reviewData = {
        'content_id': content.id,
        'content_date': content.contentDate.toIso8601String().split('T')[0],
        'title': content.title,
        'summary': content.summary,
        'topic_category': content.topicCategory.value,
        'ai_confidence_score': content.aiConfidenceScore,
        'safety_score': safetyResult.safetyScore,
        'flagged_issues': safetyResult.riskFactors,
        'review_status': shouldEscalate ? 'escalated' : 'pending_review',
        'escalation_reason':
            shouldEscalate
                ? (escalationReason ??
                    'Automatic escalation due to critical safety score')
                : null,
      };

      final response =
          await _supabase
              .from('content_review_queue')
              .insert(reviewData)
              .select()
              .single();

      // Generate notifications for review team
      await _notifyReviewTeam(
        reviewItemId: response['id'],
        priority: priority,
        safetyScore: safetyResult.safetyScore,
        issues: safetyResult.riskFactors,
        shouldEscalate: shouldEscalate,
      );

      return ReviewQueueResult.success(
        reviewItemId: response['id'],
        status: shouldEscalate ? ReviewStatus.escalated : ReviewStatus.pending,
        priority: priority,
        estimatedReviewTime: _estimateReviewTime(priority),
        message:
            shouldEscalate
                ? 'Content escalated for immediate clinical review due to critical safety concerns'
                : 'Content queued for human review due to safety validation concerns',
      );
    } catch (e) {
      debugPrint('❌ Failed to queue content for review: $e');
      return ReviewQueueResult.error(
        'failed_to_queue',
        'Unable to queue content for review: ${e.toString()}',
      );
    }
  }

  /// Check review status for content
  static Future<ReviewStatusResult> getReviewStatus({
    required int contentId,
  }) async {
    if (!_isInitialized) {
      throw StateError('TodayFeedHumanReviewService not initialized');
    }

    try {
      final response =
          await _supabase
              .from('content_review_queue')
              .select('''
            id,
            review_status,
            reviewer_id,
            reviewer_email,
            review_notes,
            reviewed_at,
            escalated_at,
            escalation_reason,
            created_at,
            updated_at
          ''')
              .eq('content_id', contentId)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();

      if (response == null) {
        return ReviewStatusResult.notFound();
      }

      final status = _parseReviewStatus(response['review_status']);
      final reviewedAt =
          response['reviewed_at'] != null
              ? DateTime.parse(response['reviewed_at'])
              : null;

      return ReviewStatusResult.found(
        reviewItemId: response['id'],
        status: status,
        reviewerId: response['reviewer_id'],
        reviewerEmail: response['reviewer_email'],
        reviewNotes: response['review_notes'],
        reviewedAt: reviewedAt,
        escalationReason: response['escalation_reason'],
        queuedAt: DateTime.parse(response['created_at']),
        updatedAt: DateTime.parse(response['updated_at']),
      );
    } catch (e) {
      debugPrint('❌ Failed to get review status: $e');
      return ReviewStatusResult.error(
        'status_check_failed',
        'Unable to check review status: ${e.toString()}',
      );
    }
  }

  /// Submit manual review decision
  static Future<ReviewDecisionResult> submitReviewDecision({
    required int reviewItemId,
    required ReviewDecision decision,
    required String reviewerId,
    required String reviewerEmail,
    String? notes,
    String? escalationReason,
  }) async {
    if (!_isInitialized) {
      throw StateError('TodayFeedHumanReviewService not initialized');
    }

    try {
      final updateData = {
        'review_status': decision.value,
        'reviewer_id': reviewerId,
        'reviewer_email': reviewerEmail,
        'review_notes': notes,
        'reviewed_at': DateTime.now().toIso8601String(),
      };

      if (decision == ReviewDecision.escalated && escalationReason != null) {
        updateData['escalation_reason'] = escalationReason;
        updateData['escalated_at'] = DateTime.now().toIso8601String();
      }

      await _supabase
          .from('content_review_queue')
          .update(updateData)
          .eq('id', reviewItemId);

      // Update content status if approved
      if (decision == ReviewDecision.approved) {
        await _approveContent(reviewItemId);
      }

      return ReviewDecisionResult.success(
        decision: decision,
        message: _getDecisionMessage(decision),
      );
    } catch (e) {
      debugPrint('❌ Failed to submit review decision: $e');
      return ReviewDecisionResult.error(
        'decision_failed',
        'Unable to submit review decision: ${e.toString()}',
      );
    }
  }

  /// Get pending reviews for reviewer dashboard
  static Future<List<PendingReview>> getPendingReviews({
    int limit = 50,
    String? priority,
  }) async {
    if (!_isInitialized) {
      throw StateError('TodayFeedHumanReviewService not initialized');
    }

    try {
      dynamic query = _supabase
          .from('pending_reviews_dashboard')
          .select()
          .order('safety_score', ascending: true)
          .order('created_at', ascending: true)
          .limit(limit);

      if (priority != null) {
        query = query.eq('priority_level', priority);
      }

      final response = await query;

      return response
          .map<PendingReview>((data) => PendingReview.fromJson(data))
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to get pending reviews: $e');
      return [];
    }
  }

  /// Check if content requires human review based on validation results
  static bool requiresHumanReview({
    required SafetyMonitoringResult safetyResult,
    required QualityValidationResult qualityResult,
  }) {
    // Critical safety issues always require review
    if (safetyResult.safetyScore < _automaticReviewThreshold) {
      return true;
    }

    // Multiple risk factors require review
    if (safetyResult.riskFactors.length >= 3) {
      return true;
    }

    // Low AI confidence with safety concerns requires review
    if (qualityResult.confidenceScore < 0.5 && safetyResult.safetyScore < 0.8) {
      return true;
    }

    // Medical-related content with any safety flags requires review
    final medicalTopics = ['prevention', 'nutrition'];
    if (safetyResult.riskFactors.isNotEmpty &&
        medicalTopics.any((topic) => safetyResult.contentId.contains(topic))) {
      return true;
    }

    return false;
  }

  /// Generate review summary for analytics
  static Future<ReviewSummary> getReviewSummary({DateTime? since}) async {
    if (!_isInitialized) {
      throw StateError('TodayFeedHumanReviewService not initialized');
    }

    try {
      final sinceDate =
          since ?? DateTime.now().subtract(const Duration(days: 7));

      final response = await _supabase
          .from('review_statistics')
          .select()
          .gte('review_date', sinceDate.toIso8601String().split('T')[0])
          .order('review_date', ascending: false);

      return ReviewSummary.fromStatistics(response);
    } catch (e) {
      debugPrint('❌ Failed to get review summary: $e');
      return ReviewSummary.empty();
    }
  }

  // Private helper methods

  static Future<void> _verifyDatabaseTables() async {
    try {
      // Check if review queue table exists by querying it
      await _supabase.from('content_review_queue').select('id').limit(1);

      debugPrint('✅ Database tables verified for human review');
    } catch (e) {
      throw StateError(
        'Required database tables for human review not found: $e',
      );
    }
  }

  static String _determinePriority(double safetyScore) {
    if (safetyScore < 0.4) return 'urgent';
    if (safetyScore < 0.6) return 'high';
    if (safetyScore < 0.8) return 'medium';
    return 'low';
  }

  static Duration _estimateReviewTime(String priority) {
    switch (priority) {
      case 'urgent':
        return const Duration(hours: 1);
      case 'high':
        return const Duration(hours: 4);
      case 'medium':
        return const Duration(hours: 12);
      default:
        return const Duration(hours: 24);
    }
  }

  static Future<void> _notifyReviewTeam({
    required int reviewItemId,
    required String priority,
    required double safetyScore,
    required List<String> issues,
    required bool shouldEscalate,
  }) async {
    try {
      // This would integrate with your notification system
      // For now, we'll just log the notification
      debugPrint('''
🚨 Content Review Notification:
   Review ID: $reviewItemId
   Priority: $priority
   Safety Score: ${safetyScore.toStringAsFixed(2)}
   Issues: ${issues.join(', ')}
   Escalated: $shouldEscalate
      ''');

      // In a real implementation, this would:
      // 1. Send email notifications to review team
      // 2. Create in-app notifications
      // 3. Integrate with review dashboard
      // 4. Set up SLA tracking
    } catch (e) {
      debugPrint('❌ Failed to notify review team: $e');
      // Don't fail the entire queue operation for notification failures
    }
  }

  static Future<void> _approveContent(int reviewItemId) async {
    try {
      // Get the content details from review queue
      final reviewItem =
          await _supabase
              .from('content_review_queue')
              .select('content_id')
              .eq('id', reviewItemId)
              .single();

      // Update the content status in daily_feed_content table
      if (reviewItem['content_id'] != null) {
        await _supabase
            .from('daily_feed_content')
            .update({
              'is_approved': true,
              'approved_at': DateTime.now().toIso8601String(),
            })
            .eq('id', reviewItem['content_id']);
      }
    } catch (e) {
      debugPrint('❌ Failed to approve content: $e');
      // Log but don't fail the review decision
    }
  }

  static ReviewStatus _parseReviewStatus(String status) {
    switch (status) {
      case 'pending_review':
        return ReviewStatus.pending;
      case 'approved':
        return ReviewStatus.approved;
      case 'rejected':
        return ReviewStatus.rejected;
      case 'escalated':
        return ReviewStatus.escalated;
      case 'auto_approved':
        return ReviewStatus.autoApproved;
      default:
        return ReviewStatus.pending;
    }
  }

  static String _getDecisionMessage(ReviewDecision decision) {
    switch (decision) {
      case ReviewDecision.approved:
        return 'Content approved for publication';
      case ReviewDecision.rejected:
        return 'Content rejected due to safety concerns';
      case ReviewDecision.escalated:
        return 'Content escalated for senior review';
    }
  }
}

// Data models for human review workflow

enum ReviewStatus { pending, approved, rejected, escalated, autoApproved }

enum ReviewDecision { approved, rejected, escalated }

extension ReviewDecisionExtension on ReviewDecision {
  String get value {
    switch (this) {
      case ReviewDecision.approved:
        return 'approved';
      case ReviewDecision.rejected:
        return 'rejected';
      case ReviewDecision.escalated:
        return 'escalated';
    }
  }
}

@immutable
class ReviewQueueResult {
  final bool isSuccess;
  final int? reviewItemId;
  final ReviewStatus? status;
  final String? priority;
  final Duration? estimatedReviewTime;
  final String message;
  final String? errorCode;

  const ReviewQueueResult({
    required this.isSuccess,
    this.reviewItemId,
    this.status,
    this.priority,
    this.estimatedReviewTime,
    required this.message,
    this.errorCode,
  });

  factory ReviewQueueResult.success({
    required int reviewItemId,
    required ReviewStatus status,
    required String priority,
    required Duration estimatedReviewTime,
    required String message,
  }) {
    return ReviewQueueResult(
      isSuccess: true,
      reviewItemId: reviewItemId,
      status: status,
      priority: priority,
      estimatedReviewTime: estimatedReviewTime,
      message: message,
    );
  }

  factory ReviewQueueResult.error(String errorCode, String message) {
    return ReviewQueueResult(
      isSuccess: false,
      message: message,
      errorCode: errorCode,
    );
  }
}

@immutable
class ReviewStatusResult {
  final bool isFound;
  final int? reviewItemId;
  final ReviewStatus? status;
  final String? reviewerId;
  final String? reviewerEmail;
  final String? reviewNotes;
  final DateTime? reviewedAt;
  final String? escalationReason;
  final DateTime? queuedAt;
  final DateTime? updatedAt;
  final String? errorCode;
  final String? errorMessage;

  const ReviewStatusResult({
    required this.isFound,
    this.reviewItemId,
    this.status,
    this.reviewerId,
    this.reviewerEmail,
    this.reviewNotes,
    this.reviewedAt,
    this.escalationReason,
    this.queuedAt,
    this.updatedAt,
    this.errorCode,
    this.errorMessage,
  });

  factory ReviewStatusResult.found({
    required int reviewItemId,
    required ReviewStatus status,
    String? reviewerId,
    String? reviewerEmail,
    String? reviewNotes,
    DateTime? reviewedAt,
    String? escalationReason,
    required DateTime queuedAt,
    required DateTime updatedAt,
  }) {
    return ReviewStatusResult(
      isFound: true,
      reviewItemId: reviewItemId,
      status: status,
      reviewerId: reviewerId,
      reviewerEmail: reviewerEmail,
      reviewNotes: reviewNotes,
      reviewedAt: reviewedAt,
      escalationReason: escalationReason,
      queuedAt: queuedAt,
      updatedAt: updatedAt,
    );
  }

  factory ReviewStatusResult.notFound() {
    return const ReviewStatusResult(isFound: false);
  }

  factory ReviewStatusResult.error(String errorCode, String errorMessage) {
    return ReviewStatusResult(
      isFound: false,
      errorCode: errorCode,
      errorMessage: errorMessage,
    );
  }
}

@immutable
class ReviewDecisionResult {
  final bool isSuccess;
  final ReviewDecision? decision;
  final String message;
  final String? errorCode;

  const ReviewDecisionResult({
    required this.isSuccess,
    this.decision,
    required this.message,
    this.errorCode,
  });

  factory ReviewDecisionResult.success({
    required ReviewDecision decision,
    required String message,
  }) {
    return ReviewDecisionResult(
      isSuccess: true,
      decision: decision,
      message: message,
    );
  }

  factory ReviewDecisionResult.error(String errorCode, String message) {
    return ReviewDecisionResult(
      isSuccess: false,
      message: message,
      errorCode: errorCode,
    );
  }
}

@immutable
class PendingReview {
  final int id;
  final DateTime contentDate;
  final String title;
  final String summary;
  final String topicCategory;
  final double aiConfidenceScore;
  final double safetyScore;
  final List<String> flaggedIssues;
  final String priorityLevel;
  final double hoursPending;
  final DateTime createdAt;

  const PendingReview({
    required this.id,
    required this.contentDate,
    required this.title,
    required this.summary,
    required this.topicCategory,
    required this.aiConfidenceScore,
    required this.safetyScore,
    required this.flaggedIssues,
    required this.priorityLevel,
    required this.hoursPending,
    required this.createdAt,
  });

  factory PendingReview.fromJson(Map<String, dynamic> json) {
    return PendingReview(
      id: json['id'] as int,
      contentDate: DateTime.parse(json['content_date'] as String),
      title: json['title'] as String,
      summary: json['summary'] as String,
      topicCategory: json['topic_category'] as String,
      aiConfidenceScore: (json['ai_confidence_score'] as num).toDouble(),
      safetyScore: (json['safety_score'] as num).toDouble(),
      flaggedIssues: List<String>.from(json['flagged_issues'] ?? []),
      priorityLevel: json['priority_level'] as String,
      hoursPending: (json['hours_pending'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

@immutable
class ReviewSummary {
  final int totalReviews;
  final int pendingReviews;
  final int approvedReviews;
  final int rejectedReviews;
  final int escalatedReviews;
  final int autoApprovedReviews;
  final double averageSafetyScore;
  final double averageReviewTimeHours;
  final DateTime generatedAt;

  const ReviewSummary({
    required this.totalReviews,
    required this.pendingReviews,
    required this.approvedReviews,
    required this.rejectedReviews,
    required this.escalatedReviews,
    required this.autoApprovedReviews,
    required this.averageSafetyScore,
    required this.averageReviewTimeHours,
    required this.generatedAt,
  });

  factory ReviewSummary.fromStatistics(List<Map<String, dynamic>> stats) {
    if (stats.isEmpty) return ReviewSummary.empty();

    final totals = stats.fold<Map<String, dynamic>>(
      {
        'total_reviews': 0,
        'approved_count': 0,
        'rejected_count': 0,
        'escalated_count': 0,
        'auto_approved_count': 0,
        'pending_count': 0,
        'avg_safety_score': 0.0,
        'avg_review_time_hours': 0.0,
      },
      (acc, stat) {
        acc['total_reviews'] += (stat['total_reviews'] ?? 0) as int;
        acc['approved_count'] += (stat['approved_count'] ?? 0) as int;
        acc['rejected_count'] += (stat['rejected_count'] ?? 0) as int;
        acc['escalated_count'] += (stat['escalated_count'] ?? 0) as int;
        acc['auto_approved_count'] += (stat['auto_approved_count'] ?? 0) as int;
        acc['pending_count'] += (stat['pending_count'] ?? 0) as int;

        if (stat['avg_safety_score'] != null) {
          acc['avg_safety_score'] =
              ((acc['avg_safety_score'] as double) +
                  (stat['avg_safety_score'] as double)) /
              2;
        }

        if (stat['avg_review_time_hours'] != null) {
          acc['avg_review_time_hours'] =
              ((acc['avg_review_time_hours'] as double) +
                  (stat['avg_review_time_hours'] as double)) /
              2;
        }

        return acc;
      },
    );

    return ReviewSummary(
      totalReviews: totals['total_reviews'] as int,
      pendingReviews: totals['pending_count'] as int,
      approvedReviews: totals['approved_count'] as int,
      rejectedReviews: totals['rejected_count'] as int,
      escalatedReviews: totals['escalated_count'] as int,
      autoApprovedReviews: totals['auto_approved_count'] as int,
      averageSafetyScore: totals['avg_safety_score'] as double,
      averageReviewTimeHours: totals['avg_review_time_hours'] as double,
      generatedAt: DateTime.now(),
    );
  }

  factory ReviewSummary.empty() {
    return ReviewSummary(
      totalReviews: 0,
      pendingReviews: 0,
      approvedReviews: 0,
      rejectedReviews: 0,
      escalatedReviews: 0,
      autoApprovedReviews: 0,
      averageSafetyScore: 0.0,
      averageReviewTimeHours: 0.0,
      generatedAt: DateTime.now(),
    );
  }
}
