import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/today_feed_content.dart';
import '../../../../core/services/connectivity_service.dart';
import 'daily_engagement_detection_service.dart';
import 'realtime_momentum_update_service.dart';

/// Service responsible for awarding momentum points for Today Feed interactions
///
/// Implements T1.3.4.4: Create momentum point award logic for Today Feed interactions
/// Updated for T1.3.4.5: Integrated with real-time momentum meter updates
///
/// This service handles:
/// - Momentum point calculation and awarding
/// - Integration with existing momentum system via engagement events
/// - Duplicate prevention to ensure once-per-day awards
/// - Real-time momentum meter updates via RealtimeMomentumUpdateService
/// - Offline support with pending awards queue
/// - Analytics and tracking for momentum attribution
///
/// Design follows code review checklist:
/// - Single responsibility: only handles momentum point logic
/// - Proper separation of concerns from interaction tracking
/// - Component size under 500 lines per guidelines
/// - Clear interface and error handling
class TodayFeedMomentumAwardService {
  static final TodayFeedMomentumAwardService _instance =
      TodayFeedMomentumAwardService._internal();
  factory TodayFeedMomentumAwardService() => _instance;
  TodayFeedMomentumAwardService._internal();

  // Dependencies
  late final SupabaseClient _supabase;
  late final DailyEngagementDetectionService _engagementService;
  late final RealtimeMomentumUpdateService _realtimeUpdateService;
  ProviderContainer? _providerContainer;
  bool _isInitialized = false;

  // Configuration from PRD specifications
  static const int todayFeedMomentumPoints = 1;
  static const String todayFeedEventType = 'today_feed_daily_engagement';
  static const Duration awardCooldownPeriod = Duration(hours: 24);

  // Pending awards queue for offline support
  final List<Map<String, dynamic>> _pendingAwards = [];
  static const int maxPendingAwards = 50;
  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;

  /// Initialize the service with required dependencies
  Future<void> initialize([ProviderContainer? container]) async {
    if (_isInitialized) return;

    try {
      _supabase = Supabase.instance.client;
      _engagementService = DailyEngagementDetectionService();
      _realtimeUpdateService = RealtimeMomentumUpdateService();
      _providerContainer = container;

      // Initialize engagement detection service
      await _engagementService.initialize();

      // Initialize real-time update service if container available
      if (_providerContainer != null) {
        await _realtimeUpdateService.initialize(_providerContainer!);
      }

      // Set up connectivity monitoring for offline support
      await ConnectivityService.initialize();
      _connectivitySubscription = ConnectivityService.statusStream.listen(
        _onConnectivityChanged,
        onError: (error) {
          debugPrint(
            '❌ TodayFeedMomentumAwardService connectivity error: $error',
          );
        },
      );

      _isInitialized = true;
      debugPrint('✅ TodayFeedMomentumAwardService initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize TodayFeedMomentumAwardService: $e');
      rethrow;
    }
  }

  /// Award momentum points for Today Feed engagement
  ///
  /// Main method implementing T1.3.4.4 momentum point award logic
  /// Updated for T1.3.4.5 with real-time momentum meter updates
  ///
  /// Params:
  /// - [userId]: ID of the user to award points to
  /// - [content]: Today Feed content that was engaged with
  /// - [sessionDuration]: Duration of engagement in seconds
  /// - [interactionMetadata]: Additional interaction data
  ///
  /// Returns: MomentumAwardResult with details about the award
  Future<MomentumAwardResult> awardMomentumPoints({
    required String userId,
    required TodayFeedContent content,
    int? sessionDuration,
    Map<String, dynamic>? interactionMetadata,
  }) async {
    await initialize(_providerContainer);

    try {
      // Validate user authentication
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null || currentUser.id != userId) {
        throw Exception('User not authenticated or ID mismatch');
      }

      // Check if user is eligible for momentum award today
      final eligibilityResult = await _checkAwardEligibility(userId);
      if (!eligibilityResult.isEligible) {
        return MomentumAwardResult.duplicate(
          message: eligibilityResult.reason,
          previousAwardTime: eligibilityResult.lastAwardTime,
        );
      }

      // Record engagement and award momentum points
      final engagementResult = await _recordMomentumEligibleEngagement(
        userId: userId,
        content: content,
        sessionDuration: sessionDuration,
        interactionMetadata: interactionMetadata,
      );

      if (engagementResult.success && engagementResult.momentumAwarded) {
        // Trigger real-time momentum meter update (T1.3.4.5)
        await _triggerRealtimeMomentumUpdate(
          userId: userId,
          pointsAwarded: engagementResult.momentumPoints,
          content: content,
        );

        // Record award analytics
        await _recordAwardAnalytics(
          userId: userId,
          content: content,
          pointsAwarded: engagementResult.momentumPoints,
          sessionDuration: sessionDuration,
        );

        debugPrint(
          '✅ Momentum points awarded: ${engagementResult.momentumPoints}',
        );

        return MomentumAwardResult.success(
          pointsAwarded: engagementResult.momentumPoints,
          message: engagementResult.message,
          awardTime: engagementResult.engagementTime ?? DateTime.now(),
        );
      } else {
        return MomentumAwardResult.failed(
          message: engagementResult.message,
          error: engagementResult.error,
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to award momentum points: $e');

      // Queue award for offline processing
      if (ConnectivityService.isOffline) {
        await _queuePendingAward(
          userId: userId,
          content: content,
          sessionDuration: sessionDuration,
          interactionMetadata: interactionMetadata,
        );

        return MomentumAwardResult.queued(
          message: 'Award queued for when back online',
        );
      }

      return MomentumAwardResult.failed(
        message: 'Failed to award momentum points',
        error: e.toString(),
      );
    }
  }

  /// Check if user is eligible for momentum award today
  Future<AwardEligibilityResult> _checkAwardEligibility(String userId) async {
    try {
      final engagementStatus = await _engagementService
          .checkDailyEngagementStatus(userId);

      if (engagementStatus.hasEngagedToday) {
        return AwardEligibilityResult(
          isEligible: false,
          reason: 'Daily momentum point already awarded',
          lastAwardTime: engagementStatus.lastEngagementTime,
        );
      }

      return const AwardEligibilityResult(
        isEligible: true,
        reason: 'Eligible for first daily momentum award',
      );
    } catch (e) {
      debugPrint('❌ Error checking award eligibility: $e');
      // Conservative approach: assume eligible to avoid blocking legitimate awards
      return const AwardEligibilityResult(
        isEligible: true,
        reason: 'Eligibility check failed, proceeding with award attempt',
      );
    }
  }

  /// Record momentum-eligible engagement through engagement service
  Future<EngagementResult> _recordMomentumEligibleEngagement({
    required String userId,
    required TodayFeedContent content,
    int? sessionDuration,
    Map<String, dynamic>? interactionMetadata,
  }) async {
    return await _engagementService.recordDailyEngagement(
      userId,
      content,
      sessionDuration: sessionDuration,
      additionalMetadata: {
        'momentum_award_attempted': true,
        'award_service_version': '1.0.0',
        'content_engagement_type': 'daily_momentum_eligible',
        ...?interactionMetadata,
      },
    );
  }

  /// Trigger real-time momentum meter update after awarding points
  ///
  /// Implements T1.3.4.5: Real-time momentum meter updates
  Future<void> _triggerRealtimeMomentumUpdate({
    required String userId,
    required int pointsAwarded,
    required TodayFeedContent content,
  }) async {
    try {
      if (_realtimeUpdateService.isReady) {
        // Use new real-time update service for immediate momentum meter updates
        final updateResult = await _realtimeUpdateService.triggerMomentumUpdate(
          userId: userId,
          pointsAwarded: pointsAwarded,
          interactionId:
              'today_feed_${content.id}_${DateTime.now().millisecondsSinceEpoch}',
          enableOptimisticUpdate: true,
        );

        if (updateResult.success) {
          debugPrint(
            '✅ Real-time momentum meter update completed: ${updateResult.message}',
          );
        } else {
          debugPrint(
            '⚠️ Real-time momentum update failed: ${updateResult.message}',
          );
          // Fallback to Edge Function trigger
          await _fallbackMomentumCalculation(userId);
        }
      } else {
        // Fallback to Edge Function if real-time service not available
        await _fallbackMomentumCalculation(userId);
      }
    } catch (e) {
      debugPrint('❌ Failed to trigger real-time momentum update: $e');
      // Fallback to Edge Function trigger
      await _fallbackMomentumCalculation(userId);
    }
  }

  /// Fallback momentum calculation using Edge Function
  Future<void> _fallbackMomentumCalculation(String userId) async {
    try {
      // Note: This triggers the momentum score calculator Edge Function
      // which will process the new engagement event and update the user's momentum
      await _supabase.functions.invoke(
        'momentum-score-calculator',
        body: {
          'user_id': userId,
          'target_date': DateTime.now().toIso8601String().split('T')[0],
          'trigger_source': 'today_feed_momentum_award',
          'realtime_update': true,
        },
      );

      debugPrint('✅ Fallback momentum calculation triggered');
    } catch (e) {
      debugPrint('⚠️ Failed to trigger fallback momentum calculation: $e');
      // Non-blocking error - momentum will be calculated on next sync
    }
  }

  /// Record analytics for momentum award attribution
  Future<void> _recordAwardAnalytics({
    required String userId,
    required TodayFeedContent content,
    required int pointsAwarded,
    int? sessionDuration,
  }) async {
    try {
      await _supabase.from('today_feed_momentum_awards').insert({
        'user_id': userId,
        'content_id': content.id,
        'content_date': content.contentDate.toIso8601String().split('T')[0],
        'content_title': content.title,
        'topic_category': content.topicCategory.value,
        'points_awarded': pointsAwarded,
        'session_duration_seconds': sessionDuration,
        'award_timestamp': DateTime.now().toIso8601String(),
        'service_version': '1.0.0',
        'metadata': {
          'ai_confidence_score': content.aiConfidenceScore,
          'estimated_reading_minutes': content.estimatedReadingMinutes,
          'content_freshness': content.isCached ? 'cached' : 'fresh',
        },
      });

      debugPrint('✅ Momentum award analytics recorded');
    } catch (e) {
      debugPrint('⚠️ Failed to record award analytics: $e');
      // Non-blocking error - award still succeeded
    }
  }

  /// Queue momentum award for offline processing
  Future<void> _queuePendingAward({
    required String userId,
    required TodayFeedContent content,
    int? sessionDuration,
    Map<String, dynamic>? interactionMetadata,
  }) async {
    if (_pendingAwards.length >= maxPendingAwards) {
      debugPrint('⚠️ Pending awards queue full, dropping oldest award');
      _pendingAwards.removeAt(0);
    }

    final pendingAward = {
      'user_id': userId,
      'content_id': content.id,
      'content_date': content.contentDate.toIso8601String(),
      'session_duration': sessionDuration,
      'interaction_metadata': interactionMetadata,
      'queued_at': DateTime.now().toIso8601String(),
      'retry_count': 0,
    };

    _pendingAwards.add(pendingAward);
    debugPrint('📝 Momentum award queued for offline processing');
  }

  /// Handle connectivity changes and process pending awards
  void _onConnectivityChanged(ConnectivityStatus status) {
    if (status == ConnectivityStatus.online && _pendingAwards.isNotEmpty) {
      _processPendingAwards();
    }
  }

  /// Process queued awards when back online
  Future<void> _processPendingAwards() async {
    if (_pendingAwards.isEmpty) return;

    debugPrint(
      '🔄 Processing ${_pendingAwards.length} pending momentum awards',
    );

    final awardsToProcess = List<Map<String, dynamic>>.from(_pendingAwards);
    _pendingAwards.clear();

    for (final award in awardsToProcess) {
      try {
        // Reconstruct content object for processing
        final content = TodayFeedContent(
          id: award['content_id'],
          contentDate: DateTime.parse(award['content_date']),
          title: 'Offline Award', // Simplified for offline processing
          summary: '',
          topicCategory: HealthTopic.lifestyle,
          aiConfidenceScore: 0.8, // Default confidence for offline processing
        );

        final result = await awardMomentumPoints(
          userId: award['user_id'],
          content: content,
          sessionDuration: award['session_duration'],
          interactionMetadata: {
            ...?award['interaction_metadata'],
            'processed_from_offline_queue': true,
            'original_queue_time': award['queued_at'],
          },
        );

        if (result.success) {
          debugPrint(
            '✅ Processed offline momentum award for user ${award['user_id']}',
          );
        } else {
          debugPrint('⚠️ Failed to process offline award: ${result.message}');
        }
      } catch (e) {
        debugPrint('❌ Error processing pending award: $e');
      }
    }
  }

  /// Get momentum award statistics for analytics
  Future<MomentumAwardStatistics> getMomentumAwardStatistics({
    required String userId,
    int daysToAnalyze = 30,
  }) async {
    await initialize();

    try {
      final startDate = DateTime.now().subtract(Duration(days: daysToAnalyze));
      final startDateString = startDate.toIso8601String().split('T')[0];

      final awards = await _supabase
          .from('today_feed_momentum_awards')
          .select('points_awarded, award_timestamp, session_duration_seconds')
          .eq('user_id', userId)
          .gte('award_timestamp', '${startDateString}T00:00:00.000Z')
          .order('award_timestamp', ascending: false);

      final totalAwards = awards.length;
      final totalPointsAwarded = awards.fold<int>(
        0,
        (sum, award) => sum + (award['points_awarded'] as int),
      );

      final averageSessionDuration =
          awards.isNotEmpty
              ? awards
                      .where(
                        (award) => award['session_duration_seconds'] != null,
                      )
                      .fold<int>(
                        0,
                        (sum, award) =>
                            sum +
                            (award['session_duration_seconds'] as int? ?? 0),
                      ) /
                  awards.length
              : 0.0;

      return MomentumAwardStatistics(
        totalAwards: totalAwards,
        totalPointsAwarded: totalPointsAwarded,
        averageSessionDuration: averageSessionDuration,
        awardFrequency: daysToAnalyze > 0 ? totalAwards / daysToAnalyze : 0.0,
        periodDays: daysToAnalyze,
      );
    } catch (e) {
      debugPrint('❌ Failed to get momentum award statistics: $e');
      return MomentumAwardStatistics.empty();
    }
  }

  /// Dispose resources when service is no longer needed
  void dispose() {
    _connectivitySubscription?.cancel();
    _pendingAwards.clear();
    debugPrint('✅ TodayFeedMomentumAwardService disposed');
  }
}

/// Result of momentum point award attempt
class MomentumAwardResult {
  final bool success;
  final int pointsAwarded;
  final String message;
  final DateTime? awardTime;
  final DateTime? previousAwardTime;
  final String? error;
  final bool isQueued;
  final bool isDuplicate;

  const MomentumAwardResult({
    required this.success,
    required this.pointsAwarded,
    required this.message,
    this.awardTime,
    this.previousAwardTime,
    this.error,
    this.isQueued = false,
    this.isDuplicate = false,
  });

  factory MomentumAwardResult.success({
    required int pointsAwarded,
    required String message,
    required DateTime awardTime,
  }) {
    return MomentumAwardResult(
      success: true,
      pointsAwarded: pointsAwarded,
      message: message,
      awardTime: awardTime,
    );
  }

  factory MomentumAwardResult.duplicate({
    required String message,
    DateTime? previousAwardTime,
  }) {
    return MomentumAwardResult(
      success: false,
      pointsAwarded: 0,
      message: message,
      previousAwardTime: previousAwardTime,
      isDuplicate: true,
    );
  }

  factory MomentumAwardResult.failed({required String message, String? error}) {
    return MomentumAwardResult(
      success: false,
      pointsAwarded: 0,
      message: message,
      error: error,
    );
  }

  factory MomentumAwardResult.queued({required String message}) {
    return MomentumAwardResult(
      success: true,
      pointsAwarded: 1, // Will be awarded when processed
      message: message,
      isQueued: true,
    );
  }
}

/// Result of checking award eligibility
class AwardEligibilityResult {
  final bool isEligible;
  final String reason;
  final DateTime? lastAwardTime;

  const AwardEligibilityResult({
    required this.isEligible,
    required this.reason,
    this.lastAwardTime,
  });
}

/// Statistics about momentum awards for analytics
class MomentumAwardStatistics {
  final int totalAwards;
  final int totalPointsAwarded;
  final double averageSessionDuration;
  final double awardFrequency;
  final int periodDays;

  const MomentumAwardStatistics({
    required this.totalAwards,
    required this.totalPointsAwarded,
    required this.averageSessionDuration,
    required this.awardFrequency,
    required this.periodDays,
  });

  factory MomentumAwardStatistics.empty() {
    return const MomentumAwardStatistics(
      totalAwards: 0,
      totalPointsAwarded: 0,
      averageSessionDuration: 0.0,
      awardFrequency: 0.0,
      periodDays: 0,
    );
  }
}
