import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/connectivity_service.dart';
import '../models/today_feed_streak_models.dart';
import '../../domain/models/today_feed_content.dart';
import 'daily_engagement_detection_service.dart';
import 'today_feed_momentum_award_service.dart';
import 'streak_services/streak_persistence_service.dart';
import 'streak_services/streak_calculation_service.dart';
import 'streak_services/streak_milestone_service.dart';
import 'streak_services/streak_analytics_service.dart';

/// Service for tracking consecutive daily engagement streaks
///
/// Implements T1.3.4.10 - Create streak tracking for consecutive daily engagements
///
/// Features:
/// - Comprehensive streak calculation and tracking
/// - Milestone achievement detection and celebration
/// - Visual feedback and animations for streak progress
/// - Analytics and performance insights
/// - Offline support with sync capabilities
/// - Integration with momentum system for bonus rewards
class TodayFeedStreakTrackingService {
  static final TodayFeedStreakTrackingService _instance =
      TodayFeedStreakTrackingService._internal();
  factory TodayFeedStreakTrackingService() => _instance;
  TodayFeedStreakTrackingService._internal();

  // Dependencies
  late final SupabaseClient _supabase;
  late final DailyEngagementDetectionService _engagementService;
  late final TodayFeedMomentumAwardService _momentumService;
  late final StreakPersistenceService _persistenceService;
  late final StreakCalculationService _calculationService;
  late final StreakMilestoneService _milestoneService;
  late final StreakAnalyticsService _analyticsService;
  bool _isInitialized = false;

  // Legacy cache support - to be removed after migration
  final Map<String, EngagementStreak> _streakCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final List<Map<String, dynamic>> _pendingUpdates = [];
  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  Timer? _syncTimer;

  /// Initialize the streak tracking service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _supabase = Supabase.instance.client;
      _engagementService = DailyEngagementDetectionService();
      _momentumService = TodayFeedMomentumAwardService();
      _persistenceService = StreakPersistenceService();
      _calculationService = StreakCalculationService();
      _milestoneService = StreakMilestoneService();
      _analyticsService = StreakAnalyticsService();

      await _engagementService.initialize();
      await _momentumService.initialize();
      await _persistenceService.initialize();
      await _calculationService.initialize();
      await _milestoneService.initialize();
      await _analyticsService.initialize();

      // Set up connectivity monitoring for offline sync
      _setupConnectivityMonitoring();

      _isInitialized = true;
      debugPrint('✅ TodayFeedStreakTrackingService initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize TodayFeedStreakTrackingService: $e');
      rethrow;
    }
  }

  /// Get current engagement streak for user
  Future<EngagementStreak> getCurrentStreak(String userId) async {
    await initialize();

    try {
      // Check cache first using persistence service
      final cacheKey = '${userId}_current_streak';
      final cached = _persistenceService.getCachedStreak(cacheKey);
      if (cached != null) {
        return cached;
      }

      // Calculate current streak using calculation service
      final streak = await _calculationService.calculateCurrentStreak(userId);

      // Cache the result using persistence service
      _persistenceService.cacheStreak(cacheKey, streak);

      debugPrint('✅ Current streak calculated: ${streak.currentStreak} days');
      return streak;
    } catch (e) {
      debugPrint('❌ Failed to get current streak: $e');
      return EngagementStreak.empty();
    }
  }

  /// Update streak on new daily engagement
  Future<StreakUpdateResult> updateStreakOnEngagement({
    required String userId,
    required TodayFeedContent content,
    int? sessionDuration,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    await initialize();

    try {
      // Get current streak
      final currentStreak = await getCurrentStreak(userId);

      // Check if user has already engaged today
      final engagementStatus = await _engagementService
          .checkDailyEngagementStatus(userId);

      if (engagementStatus.hasEngagedToday && currentStreak.isActiveToday) {
        return StreakUpdateResult.success(
          updatedStreak: currentStreak,
          message: 'Streak already updated for today',
        );
      }

      // Calculate updated streak using calculation service
      final updatedStreak = await _calculationService.calculateUpdatedStreak(
        userId,
        currentStreak,
        isNewEngagement: true,
      );

      // Check for new milestones using milestone service
      final newMilestones = _milestoneService.detectNewMilestones(
        currentStreak,
        updatedStreak,
      );

      // Create celebration if milestone achieved
      StreakCelebration? celebration;
      int momentumBonusPoints = 0;

      if (newMilestones.isNotEmpty) {
        final latestMilestone = newMilestones.last;
        celebration = _milestoneService.createCelebration(latestMilestone);
        momentumBonusPoints = latestMilestone.momentumBonusPoints;

        // Award milestone bonus points using milestone service
        if (momentumBonusPoints > 0) {
          await _milestoneService.awardMilestoneBonus(
            userId,
            content,
            latestMilestone,
            sessionDuration,
          );
        }
      }

      // Store streak data using persistence service
      await _persistenceService.storeStreakData(userId, updatedStreak);

      // Update cache using persistence service
      final cacheKey = '${userId}_current_streak';
      _persistenceService.cacheStreak(cacheKey, updatedStreak);

      debugPrint(
        '✅ Streak updated: ${updatedStreak.currentStreak} days'
        '${newMilestones.isNotEmpty ? ' (${newMilestones.length} new milestones)' : ''}',
      );

      return StreakUpdateResult.success(
        updatedStreak: updatedStreak,
        newMilestones: newMilestones,
        celebration: celebration,
        momentumPointsEarned: momentumBonusPoints,
        message: _milestoneService.generateSuccessMessage(
          updatedStreak,
          newMilestones,
        ),
      );
    } catch (e) {
      debugPrint('❌ Failed to update streak: $e');

      // Queue for offline sync if needed using persistence service
      if (_persistenceService.isOffline) {
        _persistenceService.queueStreakUpdate(
          userId,
          content,
          sessionDuration,
          additionalMetadata,
        );

        return StreakUpdateResult.success(
          updatedStreak: await getCurrentStreak(userId),
          message: 'Streak update queued for sync',
        );
      }

      return StreakUpdateResult.failed(
        message: 'Failed to update streak',
        error: e.toString(),
      );
    }
  }

  /// Get streak analytics for user
  Future<StreakAnalytics> getStreakAnalytics(
    String userId, {
    int? analysisPeriodDays,
  }) async {
    await initialize();

    try {
      // Use analytics service for calculation
      final analytics = await _analyticsService.calculateStreakAnalytics(
        userId,
        analysisPeriodDays: analysisPeriodDays,
      );

      debugPrint('✅ Streak analytics calculated');
      return analytics;
    } catch (e) {
      debugPrint('❌ Failed to get streak analytics: $e');
      return StreakAnalytics.empty(userId);
    }
  }

  /// Mark celebration as shown
  Future<bool> markCelebrationAsShown(
    String userId,
    String celebrationId,
  ) async {
    await initialize();

    try {
      await _supabase
          .from('today_feed_streak_celebrations')
          .update({
            'is_shown': true,
            'shown_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('celebration_id', celebrationId);

      // Update cache
      final cacheKey = '${userId}_current_streak';
      final cached = _persistenceService.getCachedStreak(cacheKey);
      if (cached?.pendingCelebration?.celebrationId == celebrationId) {
        final updatedCelebration = cached!.pendingCelebration!.copyWith(
          isShown: true,
          shownAt: DateTime.now(),
        );
        final updatedStreak = cached.copyWith(
          pendingCelebration: updatedCelebration,
        );
        _persistenceService.cacheStreak(cacheKey, updatedStreak);
      }

      debugPrint('✅ Celebration marked as shown: $celebrationId');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to mark celebration as shown: $e');
      return false;
    }
  }

  /// Handle streak break (user missed a day)
  Future<StreakUpdateResult> handleStreakBreak(String userId) async {
    await initialize();

    try {
      final currentStreak = await getCurrentStreak(userId);

      if (currentStreak.currentStreak == 0) {
        return StreakUpdateResult.success(
          updatedStreak: currentStreak,
          message: 'No active streak to break',
        );
      }

      // Calculate broken streak
      final brokenStreak = await _calculationService.calculateUpdatedStreak(
        userId,
        currentStreak,
        isNewEngagement: false,
        isBreak: true,
      );

      // Store streak data
      await _persistenceService.storeStreakData(userId, brokenStreak);

      // Update cache
      final cacheKey = '${userId}_current_streak';
      _persistenceService.cacheStreak(cacheKey, brokenStreak);

      debugPrint(
        '✅ Streak break handled: was ${currentStreak.currentStreak} days',
      );

      return StreakUpdateResult.success(
        updatedStreak: brokenStreak,
        message:
            'Don\'t worry! Every day is a fresh start. Begin again tomorrow!',
      );
    } catch (e) {
      debugPrint('❌ Failed to handle streak break: $e');
      return StreakUpdateResult.failed(
        message: 'Failed to handle streak break',
        error: e.toString(),
      );
    }
  }

  // Private helper methods

 

  /// Get pending celebration - delegated to milestone service
  

  // Offline support

  /// Setup connectivity monitoring
  void _setupConnectivityMonitoring() {
    _connectivitySubscription = ConnectivityService.statusStream.listen((
      status,
    ) {
      if (status == ConnectivityStatus.online) {
        _syncPendingUpdates();
      }
    });
  }

  /// Sync pending updates when connectivity restored
  Future<void> _syncPendingUpdates() async {
    if (_pendingUpdates.isEmpty) return;

    debugPrint('ℹ️ Syncing ${_pendingUpdates.length} pending streak updates');

    final updates = List<Map<String, dynamic>>.from(_pendingUpdates);
    _pendingUpdates.clear();

    for (final update in updates) {
      try {
        if (update['type'] == 'streak_update') {
          final content = TodayFeedContent.fromJson(update['content']);
          await updateStreakOnEngagement(
            userId: update['user_id'],
            content: content,
            sessionDuration: update['session_duration'],
            additionalMetadata: update['additional_metadata'],
          );
        }
      } catch (e) {
        debugPrint('❌ Failed to sync streak update: $e');
        // Re-queue failed updates
        _pendingUpdates.add(update);
      }
    }

    debugPrint('✅ Streak updates sync completed');
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    _streakCache.clear();
    _cacheTimestamps.clear();
    _pendingUpdates.clear();
    debugPrint('✅ TodayFeedStreakTrackingService disposed');
  }
}
