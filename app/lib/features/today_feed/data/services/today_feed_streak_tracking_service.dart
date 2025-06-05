import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/services/connectivity_service.dart';
import '../models/today_feed_streak_models.dart';
import '../../domain/models/today_feed_content.dart';
import 'daily_engagement_detection_service.dart';
import 'today_feed_momentum_award_service.dart';
import 'streak_services/streak_persistence_service.dart';
import 'streak_services/streak_calculation_service.dart';
import 'streak_services/streak_milestone_service.dart';
import 'streak_services/streak_analytics_service.dart';

/// **Main Coordinator Service for Streak Tracking System**
///
/// This service coordinates between specialized modular services to provide
/// comprehensive streak tracking functionality for consecutive daily engagements.
///
/// **Implements:** T1.3.4.10 - Create streak tracking for consecutive daily engagements
///
/// ## Architecture Overview
///
/// The service uses a modular architecture with 5 specialized services:
/// - **StreakPersistenceService:** Data storage and cache management
/// - **StreakCalculationService:** Core streak calculation algorithms
/// - **StreakMilestoneService:** Milestone detection and celebrations
/// - **StreakAnalyticsService:** Analytics and insights generation
/// - **Main Service (this):** Coordination and public API
///
/// ## Key Features
///
/// - **Comprehensive Tracking:** Accurate streak calculation across timezones
/// - **Milestone System:** Dynamic achievement detection with celebrations
/// - **Visual Feedback:** Rich animations and progress indicators
/// - **Analytics & Insights:** Personalized performance analysis
/// - **Offline Support:** Queue-based sync with automatic retry
/// - **Momentum Integration:** Bonus points for milestone achievements
///
/// ## Usage Example
///
/// ```dart
/// // Initialize service
/// final streakService = TodayFeedStreakTrackingService();
/// await streakService.initialize();
///
/// // Get current streak
/// final streak = await streakService.getCurrentStreak(userId);
/// debugPrint('Current streak: ${streak.currentStreak} days');
///
/// // Update streak on engagement
/// final result = await streakService.updateStreakOnEngagement(
///   userId: userId,
///   content: content,
///   sessionDuration: 300, // 5 minutes
/// );
///
/// if (result.isSuccess && result.newMilestones.isNotEmpty) {
///   // Show celebration for milestone achievement
///   showCelebration(result.celebration);
/// }
///
/// // Get analytics
/// final analytics = await streakService.getStreakAnalytics(userId);
/// debugPrint('Consistency rate: ${analytics.consistencyRate}%');
/// ```
///
/// ## Service Lifecycle
///
/// 1. **Initialization:** Call `initialize()` before first use
/// 2. **Runtime:** All public methods auto-initialize if needed
/// 3. **Disposal:** Call `dispose()` when service no longer needed
///
/// ## Error Handling
///
/// - **Graceful Degradation:** Non-critical failures don't break functionality
/// - **Offline Support:** Updates queued for sync when connectivity restored
/// - **Fallback Mechanisms:** Empty/default values returned on errors
/// - **Comprehensive Logging:** All operations logged for debugging
class TodayFeedStreakTrackingService {
  static final TodayFeedStreakTrackingService _instance =
      TodayFeedStreakTrackingService._internal();
  factory TodayFeedStreakTrackingService() => _instance;
  TodayFeedStreakTrackingService._internal();

  // Dependencies
  late final DailyEngagementDetectionService _engagementService;
  late final TodayFeedMomentumAwardService _momentumService;
  late final StreakPersistenceService _persistenceService;
  late final StreakCalculationService _calculationService;
  late final StreakMilestoneService _milestoneService;
  late final StreakAnalyticsService _analyticsService;
  bool _isInitialized = false;

  // Connectivity monitoring
  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;

  /// **Initialize the streak tracking service and all dependencies**
  ///
  /// Must be called before using any other methods. Subsequent calls are safe
  /// and will be ignored if already initialized.
  ///
  /// **Initialization Order:**
  /// 1. Core engagement and momentum services
  /// 2. Specialized streak services (persistence, calculation, milestone, analytics)
  /// 3. Connectivity monitoring setup
  ///
  /// **Example:**
  /// ```dart
  /// final service = TodayFeedStreakTrackingService();
  /// await service.initialize(); // Safe to call multiple times
  /// ```
  ///
  /// **Throws:** Exception if any critical service fails to initialize
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
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

  /// **Get current engagement streak for user**
  ///
  /// Returns the user's current streak information including:
  /// - Current streak count (consecutive days)
  /// - Longest streak achieved
  /// - Last engagement date
  /// - Active status (engaged today)
  /// - Pending celebrations
  ///
  /// **Features:**
  /// - Smart caching for performance (30-minute TTL)
  /// - Timezone-aware calculations
  /// - Graceful error handling
  ///
  /// **Parameters:**
  /// - `userId`: Unique identifier for the user
  ///
  /// **Returns:** [EngagementStreak] with current status or empty streak on error
  ///
  /// **Example:**
  /// ```dart
  /// final streak = await service.getCurrentStreak('user123');
  /// if (streak.currentStreak > 0) {
  ///   debugPrint('🔥 ${streak.currentStreak} day streak!');
  /// }
  /// ```
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

  /// **Update streak on new daily engagement**
  ///
  /// Processes a user engagement event and updates their streak accordingly.
  /// Handles milestone detection, celebration creation, and momentum integration.
  ///
  /// **Process Flow:**
  /// 1. Check current streak status
  /// 2. Validate daily engagement limit
  /// 3. Calculate updated streak
  /// 4. Detect new milestones
  /// 5. Create celebrations and award bonuses
  /// 6. Store updated data
  ///
  /// **Parameters:**
  /// - `userId`: Unique identifier for the user
  /// - `content`: The content that was engaged with
  /// - `sessionDuration`: Optional session duration in seconds
  /// - `additionalMetadata`: Optional additional data for analytics
  ///
  /// **Returns:** [StreakUpdateResult] with update status and any achievements
  ///
  /// **Example:**
  /// ```dart
  /// final result = await service.updateStreakOnEngagement(
  ///   userId: 'user123',
  ///   content: todayContent,
  ///   sessionDuration: 180, // 3 minutes
  /// );
  ///
  /// if (result.isSuccess) {
  ///   if (result.newMilestones.isNotEmpty) {
  ///     // Show milestone celebration
  ///     showMilestoneAchievement(result.celebration);
  ///   }
  /// }
  /// ```
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
      // Delegate to milestone service for celebration management
      final success = await _milestoneService.markCelebrationAsShown(
        userId,
        celebrationId,
      );

      if (success) {
        // Update cache through persistence service
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
      }

      debugPrint('✅ Celebration marked as shown: $celebrationId');
      return success;
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

      // Calculate broken streak using calculation service
      final brokenStreak = await _calculationService.calculateUpdatedStreak(
        userId,
        currentStreak,
        isNewEngagement: false,
        isBreak: true,
      );

      // Store streak data using persistence service
      await _persistenceService.storeStreakData(userId, brokenStreak);

      // Update cache using persistence service
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

  /// Setup connectivity monitoring for offline sync
  void _setupConnectivityMonitoring() {
    _connectivitySubscription = ConnectivityService.statusStream.listen((
      status,
    ) {
      if (status == ConnectivityStatus.online) {
        // Delegate sync operations to persistence service
        _persistenceService.syncPendingUpdates();
      }
    });
  }

  /// Dispose resources and cleanup
  void dispose() {
    _connectivitySubscription?.cancel();
    _persistenceService.dispose();
    _calculationService.dispose();
    _milestoneService.dispose();
    _analyticsService.dispose();
    debugPrint('✅ TodayFeedStreakTrackingService disposed');
  }
}
