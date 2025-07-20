import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/today_feed_content.dart';
import '../models/today_feed_sharing_models.dart';
import 'user_content_interaction_service.dart';

/// Service responsible for **analytics-only** operations previously embedded
/// inside `TodayFeedSharingService`.
///
/// Responsibilities:
/// • Persist share & bookmark interaction rows via `UserContentInteractionService`.
/// • Persist social bonus analytics rows directly to Supabase.
/// • Generic daily-limit + cooldown enforcement for share / bookmark actions.
///
/// NOTE:  Keeping this logic isolated helps us keep the main sharing service
/// below the component-size hard-fail ceiling of 750 LOC.
class TodayFeedAnalyticsService {
  // --- Singleton boilerplate -------------------------------------------------
  static final TodayFeedAnalyticsService _instance =
      TodayFeedAnalyticsService._internal();
  factory TodayFeedAnalyticsService() => _instance;
  TodayFeedAnalyticsService._internal();

  // -------------------------------------------------------------------------
  late final SupabaseClient _supabase;
  late final UserContentInteractionService _interactionService;
  bool _isInitialized = false;

  /// Tracks the last time a given user performed a specific action.
  /// Used for cooldown enforcement.
  final Map<String, DateTime> _lastActionTimestamp = {};

  Future<void> initialize() async {
    if (_isInitialized) return;

    _supabase = Supabase.instance.client;
    _interactionService = UserContentInteractionService();
    await _interactionService.initialize();

    _isInitialized = true;
  }

  // -------------------------------------------------------------------------
  // Interaction Recording helpers
  // -------------------------------------------------------------------------

  Future<void> recordShareInteraction({
    required String userId,
    required TodayFeedContent content,
    required ShareResult shareResult,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    await initialize();

    try {
      await _interactionService.recordInteraction(
        TodayFeedInteractionType.share,
        content,
        additionalData: {
          'share_status': shareResult.status.name,
          'share_result_raw': shareResult.raw,
          'share_timestamp': DateTime.now().toIso8601String(),
          'momentum_bonus_eligible':
              shareResult.status == ShareResultStatus.success,
          ...?additionalMetadata,
        },
      );

      // Update cooldown map
      _lastActionTimestamp['${userId}_share'] = DateTime.now();
    } catch (e) {
      debugPrint(
        '❌ TodayFeedAnalyticsService: recordShareInteraction failed: $e',
      );
    }
  }

  Future<void> recordBookmarkInteraction({
    required String userId,
    required TodayFeedContent content,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    await initialize();

    try {
      await _interactionService.recordInteraction(
        TodayFeedInteractionType.bookmark,
        content,
        additionalData: {
          'bookmark_timestamp': DateTime.now().toIso8601String(),
          'momentum_bonus_eligible': true,
          ...?additionalMetadata,
        },
      );

      _lastActionTimestamp['${userId}_bookmark'] = DateTime.now();
    } catch (e) {
      debugPrint(
        '❌ TodayFeedAnalyticsService: recordBookmarkInteraction failed: $e',
      );
    }
  }

  /// Persist social-bonus rows for analytics dashboards.
  Future<void> recordBonusAnalytics({
    required String userId,
    required TodayFeedContent content,
    required String bonusType,
    required int pointsAwarded,
  }) async {
    await initialize();

    try {
      await _supabase.from('today_feed_social_bonuses').insert({
        'user_id': userId,
        'content_id': content.id ?? 0,
        'content_date': content.contentDate.toIso8601String().split('T')[0],
        'bonus_type': bonusType,
        'points_awarded': pointsAwarded,
        'awarded_at': DateTime.now().toIso8601String(),
        'content_metadata': {
          'title': content.title,
          'topic_category': content.topicCategory.value,
          'ai_confidence_score': content.aiConfidenceScore,
        },
      });

      debugPrint('✅ TodayFeedAnalyticsService: bonus analytics recorded');
    } catch (e) {
      debugPrint(
        '❌ TodayFeedAnalyticsService: recordBonusAnalytics failed: $e',
      );
    }
  }

  // -------------------------------------------------------------------------
  // Generic daily-limit / cooldown helper
  // -------------------------------------------------------------------------

  Future<ActionLimitResult> checkActionLimits({
    required String userId,
    required String actionType,
    required int maxDaily,
    required Duration cooldownPeriod,
  }) async {
    await initialize();

    try {
      // --- Cooldown ---------------------------------------------------------
      final lastKey = '${userId}_$actionType';
      final lastTime = _lastActionTimestamp[lastKey];
      if (lastTime != null) {
        final delta = DateTime.now().difference(lastTime);
        if (delta < cooldownPeriod) {
          return ActionLimitResult(
            canProceed: false,
            reason:
                'Please wait ${cooldownPeriod.inMinutes - delta.inMinutes} more minutes',
            currentCount: 0,
          );
        }
      }

      // --- Daily limit ------------------------------------------------------
      final todayStart = DateTime.now().copyWith(hour: 0, minute: 0, second: 0);

      final todayActions = await _supabase
          .from('user_content_interactions')
          .select('id')
          .eq('user_id', userId)
          .eq('interaction_type', actionType)
          .gte('interaction_timestamp', todayStart.toIso8601String());

      final currentCount = (todayActions as List).length;

      if (currentCount >= maxDaily) {
        return ActionLimitResult(
          canProceed: false,
          reason: 'Daily $actionType limit reached ($maxDaily per day)',
          currentCount: currentCount,
        );
      }

      return ActionLimitResult(
        canProceed: true,
        reason: 'Action allowed',
        currentCount: currentCount,
      );
    } catch (e) {
      debugPrint('❌ TodayFeedAnalyticsService: checkActionLimits failed: $e');
      return const ActionLimitResult(
        canProceed: true,
        reason: 'Limit check failed, proceeding with action',
        currentCount: 0,
      );
    }
  }

  // -------------------------------------------------------------------------
  // Disposal (primarily for tests)
  // -------------------------------------------------------------------------
  void disposeForTests() {
    _lastActionTimestamp.clear();
    _isInitialized = false;
  }
}
