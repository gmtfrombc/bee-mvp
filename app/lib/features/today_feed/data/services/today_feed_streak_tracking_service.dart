import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/connectivity_service.dart';
import '../models/today_feed_streak_models.dart';
import '../../domain/models/today_feed_content.dart';
import 'daily_engagement_detection_service.dart';
import 'today_feed_momentum_award_service.dart';

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
  bool _isInitialized = false;

  // Configuration - using ResponsiveService approach for non-hardcoded values
  static const Map<String, dynamic> _config = {
    'milestone_thresholds': [1, 3, 7, 14, 21, 30, 60, 90, 180, 365],
    'milestone_bonus_points': [1, 2, 5, 10, 15, 25, 50, 75, 100, 200],
    'celebration_duration_ms': 3000,
    'max_streak_history_days': 365,
    'cache_expiry_minutes': 30,
    'sync_retry_max_attempts': 3,
    'analytics_period_days': 90,
  };

  // Cache and offline support
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

      await _engagementService.initialize();
      await _momentumService.initialize();

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
      // Check cache first
      final cacheKey = '${userId}_current_streak';
      final cached = _getCachedStreak(cacheKey);
      if (cached != null) {
        return cached;
      }

      // Calculate current streak from engagement data
      final streak = await _calculateCurrentStreak(userId);

      // Cache the result
      _cacheStreak(cacheKey, streak);

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

      // Calculate updated streak
      final updatedStreak = await _calculateUpdatedStreak(
        userId,
        currentStreak,
        isNewEngagement: true,
      );

      // Check for new milestones
      final newMilestones = _detectNewMilestones(currentStreak, updatedStreak);

      // Create celebration if milestone achieved
      StreakCelebration? celebration;
      int momentumBonusPoints = 0;

      if (newMilestones.isNotEmpty) {
        final latestMilestone = newMilestones.last;
        celebration = _createCelebration(latestMilestone);
        momentumBonusPoints = latestMilestone.momentumBonusPoints;

        // Award milestone bonus points
        if (momentumBonusPoints > 0) {
          await _awardMilestoneBonus(
            userId,
            content,
            latestMilestone,
            sessionDuration,
          );
        }
      }

      // Store streak data
      await _storeStreakData(userId, updatedStreak);

      // Update cache
      final cacheKey = '${userId}_current_streak';
      _cacheStreak(cacheKey, updatedStreak);

      debugPrint(
        '✅ Streak updated: ${updatedStreak.currentStreak} days'
        '${newMilestones.isNotEmpty ? ' (${newMilestones.length} new milestones)' : ''}',
      );

      return StreakUpdateResult.success(
        updatedStreak: updatedStreak,
        newMilestones: newMilestones,
        celebration: celebration,
        momentumPointsEarned: momentumBonusPoints,
        message: _generateSuccessMessage(updatedStreak, newMilestones),
      );
    } catch (e) {
      debugPrint('❌ Failed to update streak: $e');

      // Queue for offline sync if needed
      if (ConnectivityService.isOffline) {
        _queueStreakUpdate(
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

    final periodDays = analysisPeriodDays ?? _config['analytics_period_days'];

    try {
      final startDate = DateTime.now().subtract(Duration(days: periodDays));

      // Get engagement events for analysis period
      final engagementEvents = await _supabase
          .from('engagement_events')
          .select('created_at, event_date')
          .eq('user_id', userId)
          .eq('event_type', 'today_feed_daily_engagement')
          .gte('created_at', startDate.toIso8601String())
          .order('created_at', ascending: false);

      // Calculate analytics
      final analytics = _calculateStreakAnalytics(
        userId,
        engagementEvents,
        periodDays,
      );

      debugPrint('✅ Streak analytics calculated for $periodDays days');
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
      final cached = _getCachedStreak(cacheKey);
      if (cached?.pendingCelebration?.celebrationId == celebrationId) {
        final updatedCelebration = cached!.pendingCelebration!.copyWith(
          isShown: true,
          shownAt: DateTime.now(),
        );
        final updatedStreak = cached.copyWith(
          pendingCelebration: updatedCelebration,
        );
        _cacheStreak(cacheKey, updatedStreak);
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
      final brokenStreak = await _calculateUpdatedStreak(
        userId,
        currentStreak,
        isNewEngagement: false,
        isBreak: true,
      );

      // Store streak data
      await _storeStreakData(userId, brokenStreak);

      // Update cache
      final cacheKey = '${userId}_current_streak';
      _cacheStreak(cacheKey, brokenStreak);

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

  /// Calculate current streak from engagement data
  Future<EngagementStreak> _calculateCurrentStreak(String userId) async {
    final maxHistoryDays = _config['max_streak_history_days'];
    final startDate = DateTime.now().subtract(Duration(days: maxHistoryDays));

    // Get engagement events
    final engagementEvents = await _supabase
        .from('engagement_events')
        .select('created_at, event_date')
        .eq('user_id', userId)
        .eq('event_type', 'today_feed_daily_engagement')
        .gte('created_at', startDate.toIso8601String())
        .order('created_at', ascending: false);

    // Get stored streak data
    final storedStreak = await _getStoredStreakData(userId);

    // Calculate streak metrics
    final streakMetrics = _calculateStreakMetrics(engagementEvents);

    // Get achieved milestones
    final milestones = await _getAchievedMilestones(userId);

    // Check for pending celebration
    final pendingCelebration = await _getPendingCelebration(userId);

    // Determine status
    final status = StreakStatus.fromStreakLength(streakMetrics.currentStreak);

    return EngagementStreak(
      currentStreak: streakMetrics.currentStreak,
      longestStreak: max(
        streakMetrics.longestStreak,
        storedStreak?['longest_streak'] ?? 0,
      ),
      streakStartDate: streakMetrics.streakStartDate,
      lastEngagementDate: streakMetrics.lastEngagementDate,
      isActiveToday: streakMetrics.isActiveToday,
      status: status,
      achievedMilestones: milestones,
      pendingCelebration: pendingCelebration,
      consistencyRate: streakMetrics.consistencyRate,
      totalEngagementDays: streakMetrics.totalEngagementDays,
    );
  }

  /// Calculate updated streak after engagement or break
  Future<EngagementStreak> _calculateUpdatedStreak(
    String userId,
    EngagementStreak currentStreak, {
    required bool isNewEngagement,
    bool isBreak = false,
  }) async {
    if (isBreak) {
      return currentStreak.copyWith(
        currentStreak: 0,
        status: StreakStatus.broken,
        isActiveToday: false,
        streakStartDate: null,
      );
    }

    if (!isNewEngagement) return currentStreak;

    final newStreakLength =
        currentStreak.isActiveToday
            ? currentStreak.currentStreak
            : currentStreak.currentStreak + 1;

    final newLongestStreak = max(newStreakLength, currentStreak.longestStreak);
    final newStatus = StreakStatus.fromStreakLength(newStreakLength);

    DateTime? newStreakStartDate = currentStreak.streakStartDate;
    if (newStreakLength == 1) {
      newStreakStartDate = DateTime.now();
    }

    return currentStreak.copyWith(
      currentStreak: newStreakLength,
      longestStreak: newLongestStreak,
      streakStartDate: newStreakStartDate,
      lastEngagementDate: DateTime.now(),
      isActiveToday: true,
      status: newStatus,
    );
  }

  /// Calculate streak metrics from engagement events
  ({
    int currentStreak,
    int longestStreak,
    DateTime? streakStartDate,
    DateTime? lastEngagementDate,
    bool isActiveToday,
    double consistencyRate,
    int totalEngagementDays,
  })
  _calculateStreakMetrics(List<Map<String, dynamic>> events) {
    if (events.isEmpty) {
      return (
        currentStreak: 0,
        longestStreak: 0,
        streakStartDate: null,
        lastEngagementDate: null,
        isActiveToday: false,
        consistencyRate: 0.0,
        totalEngagementDays: 0,
      );
    }

    // Group by day
    final engagementDays = <String>{};
    DateTime? lastEngagement;

    for (final event in events) {
      final eventDate = DateTime.parse(event['created_at']);
      final dayString = eventDate.toIso8601String().split('T')[0];
      engagementDays.add(dayString);

      if (lastEngagement == null || eventDate.isAfter(lastEngagement)) {
        lastEngagement = eventDate;
      }
    }

    // Calculate current streak
    final sortedDays = engagementDays.toList()..sort((a, b) => b.compareTo(a));
    final today = DateTime.now().toIso8601String().split('T')[0];

    int currentStreak = 0;
    DateTime? expectedDate = DateTime.now();
    DateTime? streakStartDate;

    for (final dayString in sortedDays) {
      final expectedDateString = expectedDate!.toIso8601String().split('T')[0];

      if (dayString == expectedDateString) {
        currentStreak++;
        if (currentStreak == 1) {
          streakStartDate = DateTime.parse('${dayString}T00:00:00Z');
        }
        expectedDate = expectedDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    // Calculate longest streak
    int longestStreak = 0;
    int tempStreak = 0;
    String? previousDay;

    for (int i = sortedDays.length - 1; i >= 0; i--) {
      final currentDay = sortedDays[i];

      if (previousDay == null) {
        tempStreak = 1;
      } else {
        final currentDate = DateTime.parse('${currentDay}T00:00:00Z');
        final previousDate = DateTime.parse('${previousDay}T00:00:00Z');
        final difference = currentDate.difference(previousDate).inDays;

        if (difference == 1) {
          tempStreak++;
        } else {
          longestStreak = max(longestStreak, tempStreak);
          tempStreak = 1;
        }
      }

      previousDay = currentDay;
    }
    longestStreak = max(longestStreak, tempStreak);

    // Calculate consistency rate (engagement days / total days in period)
    final totalDays =
        DateTime.now()
            .difference(DateTime.parse('${sortedDays.last}T00:00:00Z'))
            .inDays +
        1;
    final consistencyRate = engagementDays.length / totalDays;

    return (
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      streakStartDate: streakStartDate,
      lastEngagementDate: lastEngagement,
      isActiveToday: sortedDays.isNotEmpty && sortedDays.first == today,
      consistencyRate: consistencyRate,
      totalEngagementDays: engagementDays.length,
    );
  }

  /// Detect new milestones achieved
  List<StreakMilestone> _detectNewMilestones(
    EngagementStreak currentStreak,
    EngagementStreak updatedStreak,
  ) {
    final newMilestones = <StreakMilestone>[];
    final thresholds = List<int>.from(_config['milestone_thresholds']);
    final bonusPoints = List<int>.from(_config['milestone_bonus_points']);

    // Check each threshold
    for (int i = 0; i < thresholds.length; i++) {
      final threshold = thresholds[i];
      final bonus = bonusPoints[i];

      // Check if milestone is newly achieved
      if (updatedStreak.currentStreak >= threshold &&
          currentStreak.currentStreak < threshold) {
        final milestone = _createMilestone(threshold, bonus);
        newMilestones.add(milestone);
      }
    }

    return newMilestones;
  }

  /// Create milestone for threshold
  StreakMilestone _createMilestone(int threshold, int bonusPoints) {
    final milestoneData = _getMilestoneData(threshold);

    return StreakMilestone(
      streakLength: threshold,
      title: milestoneData.title,
      description: milestoneData.description,
      achievedAt: DateTime.now(),
      isCelebrated: false,
      type: milestoneData.type,
      momentumBonusPoints: bonusPoints,
    );
  }

  /// Get milestone data for threshold
  ({String title, String description, MilestoneType type}) _getMilestoneData(
    int threshold,
  ) {
    switch (threshold) {
      case 1:
        return (
          title: 'First Step!',
          description:
              'You started your journey - every expert was once a beginner!',
          type: MilestoneType.firstDay,
        );
      case 3:
        return (
          title: 'Building Momentum',
          description: 'Three days strong! You\'re forming a great habit!',
          type: MilestoneType.special,
        );
      case 7:
        return (
          title: 'One Week Wonder!',
          description: 'A full week of engagement - you\'re on fire! 🔥',
          type: MilestoneType.weekly,
        );
      case 14:
        return (
          title: 'Two Week Champion!',
          description: 'Fourteen days of consistency - you\'re unstoppable!',
          type: MilestoneType.biweekly,
        );
      case 21:
        return (
          title: 'Habit Master',
          description:
              'Three weeks! Your healthy habits are becoming second nature!',
          type: MilestoneType.special,
        );
      case 30:
        return (
          title: 'Monthly Marvel!',
          description:
              'One month of daily engagement - you\'re a true champion! 🏆',
          type: MilestoneType.monthly,
        );
      case 60:
        return (
          title: 'Consistency King/Queen',
          description:
              'Two months of dedication - your commitment is inspiring!',
          type: MilestoneType.special,
        );
      case 90:
        return (
          title: 'Quarterly Champion',
          description:
              'Three months of excellence - you\'ve mastered consistency! 🌟',
          type: MilestoneType.quarterly,
        );
      case 180:
        return (
          title: 'Half-Year Hero',
          description:
              'Six months of daily engagement - you\'re extraordinary! ⭐',
          type: MilestoneType.special,
        );
      case 365:
        return (
          title: 'Yearly Legend!',
          description:
              'One full year - you\'ve achieved something truly remarkable! 🎉',
          type: MilestoneType.special,
        );
      default:
        return (
          title: 'Streak Milestone',
          description: '$threshold days of amazing consistency!',
          type: MilestoneType.special,
        );
    }
  }

  /// Create celebration for milestone
  StreakCelebration _createCelebration(StreakMilestone milestone) {
    final celebrationId =
        'celebration_${milestone.streakLength}_${DateTime.now().millisecondsSinceEpoch}';

    return StreakCelebration(
      celebrationId: celebrationId,
      milestone: milestone,
      type: _getCelebrationTypeForMilestone(milestone),
      message: _getCelebrationMessage(milestone),
      animationType: _getAnimationType(milestone.streakLength),
      durationMs: _config['celebration_duration_ms'],
      isShown: false,
    );
  }

  /// Get celebration type for milestone
  CelebrationType _getCelebrationTypeForMilestone(StreakMilestone milestone) {
    switch (milestone.type) {
      case MilestoneType.firstDay:
        return CelebrationType.milestone;
      case MilestoneType.weekly:
        return CelebrationType.weeklyStreak;
      case MilestoneType.monthly:
        return CelebrationType.monthlyStreak;
      default:
        if (milestone.streakLength > 30) {
          return CelebrationType.personalBest;
        }
        return CelebrationType.milestone;
    }
  }

  /// Get celebration message for milestone
  String _getCelebrationMessage(StreakMilestone milestone) {
    final messages = [
      '🎉 ${milestone.title}',
      (milestone.description),
      '🌟 +${milestone.momentumBonusPoints} bonus momentum points!',
    ];
    return messages.join('\n');
  }

  /// Get animation type based on streak length
  String? _getAnimationType(int streakLength) {
    if (streakLength == 1) return 'celebration_start';
    if (streakLength == 7) return 'celebration_weekly';
    if (streakLength == 30) return 'celebration_monthly';
    if (streakLength >= 90) return 'celebration_epic';
    return 'celebration_milestone';
  }

  /// Generate success message
  String _generateSuccessMessage(
    EngagementStreak streak,
    List<StreakMilestone> newMilestones,
  ) {
    if (newMilestones.isNotEmpty) {
      final milestone = newMilestones.last;
      return '🎉 ${milestone.title}! ${streak.currentStreak} day streak!';
    }

    switch (streak.status) {
      case StreakStatus.starting:
        return 'Great start! Keep it going tomorrow!';
      case StreakStatus.building:
        return 'Building momentum! ${streak.currentStreak} days strong!';
      case StreakStatus.strong:
        return 'Incredible streak! ${streak.currentStreak} days and counting!';
      case StreakStatus.champion:
        return 'Champion streak! ${streak.currentStreak} days - unstoppable!';
      default:
        return 'Streak updated to ${streak.currentStreak} days!';
    }
  }

  /// Award milestone bonus points
  Future<void> _awardMilestoneBonus(
    String userId,
    TodayFeedContent content,
    StreakMilestone milestone,
    int? sessionDuration,
  ) async {
    try {
      // Note: This is a bonus award separate from daily momentum
      await _supabase.from('today_feed_momentum_awards').insert({
        'user_id': userId,
        'content_id': content.id,
        'content_date': content.contentDate.toIso8601String().split('T')[0],
        'content_title': content.title,
        'topic_category': content.topicCategory.value,
        'points_awarded': milestone.momentumBonusPoints,
        'session_duration_seconds': sessionDuration,
        'award_timestamp': DateTime.now().toIso8601String(),
        'service_version': 'StreakTrackingService_v1.0',
        'metadata': {
          'award_type': 'streak_milestone_bonus',
          'milestone_type': milestone.type.value,
          'streak_length': milestone.streakLength,
          'milestone_title': milestone.title,
        },
      });

      debugPrint(
        '✅ Milestone bonus awarded: +${milestone.momentumBonusPoints} points',
      );
    } catch (e) {
      debugPrint('❌ Failed to award milestone bonus: $e');
      // Non-blocking - don't fail the whole operation
    }
  }

  /// Calculate streak analytics
  StreakAnalytics _calculateStreakAnalytics(
    String userId,
    List<Map<String, dynamic>> events,
    int periodDays,
  ) {
    if (events.isEmpty) {
      return StreakAnalytics.empty(userId);
    }

    // Group by day and create daily data
    final engagementDays = <String, bool>{};
    final dailyData = <DailyStreakData>[];

    for (final event in events) {
      final eventDate = DateTime.parse(event['created_at']);
      final dayString = eventDate.toIso8601String().split('T')[0];
      engagementDays[dayString] = true;
    }

    // Calculate streak analytics
    final streakMetrics = _calculateStreakMetrics(events);

    // Build daily data for the analysis period
    for (int i = periodDays - 1; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dayString = date.toIso8601String().split('T')[0];
      final hasEngagement = engagementDays[dayString] ?? false;

      dailyData.add(
        DailyStreakData(
          date: date,
          hasEngagement: hasEngagement,
          streakDay: 0, // Would need more complex calculation
          status: hasEngagement ? StreakStatus.building : StreakStatus.inactive,
        ),
      );
    }

    // Calculate streak length distribution
    final streakLengthDistribution = <int, int>{};
    // This would require more sophisticated analysis of historical streaks

    return StreakAnalytics(
      userId: userId,
      analysisPeriodDays: periodDays,
      totalStreaks: 1, // Simplified - would need historical analysis
      averageStreakLength: streakMetrics.currentStreak,
      currentStreak: streakMetrics.currentStreak,
      longestStreak: streakMetrics.longestStreak,
      consistencyRate: streakMetrics.consistencyRate,
      dailyData: dailyData,
      streakLengthDistribution: streakLengthDistribution,
      totalMilestones: 0, // Would get from database
      lastAnalysisDate: DateTime.now(),
    );
  }

  // Database operations

  /// Store streak data
  Future<void> _storeStreakData(String userId, EngagementStreak streak) async {
    try {
      await _supabase.from('today_feed_user_streaks').upsert({
        'user_id': userId,
        'current_streak': streak.currentStreak,
        'longest_streak': streak.longestStreak,
        'streak_start_date': streak.streakStartDate?.toIso8601String(),
        'last_engagement_date': streak.lastEngagementDate?.toIso8601String(),
        'is_active_today': streak.isActiveToday,
        'status': streak.status.value,
        'consistency_rate': streak.consistencyRate,
        'total_engagement_days': streak.totalEngagementDays,
        'updated_at': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Streak data stored successfully');
    } catch (e) {
      debugPrint('❌ Failed to store streak data: $e');
      rethrow;
    }
  }

  /// Get stored streak data
  Future<Map<String, dynamic>?> _getStoredStreakData(String userId) async {
    try {
      final response =
          await _supabase
              .from('today_feed_user_streaks')
              .select('*')
              .eq('user_id', userId)
              .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('❌ Failed to get stored streak data: $e');
      return null;
    }
  }

  /// Get achieved milestones
  Future<List<StreakMilestone>> _getAchievedMilestones(String userId) async {
    try {
      final response = await _supabase
          .from('today_feed_streak_milestones')
          .select('*')
          .eq('user_id', userId)
          .order('achieved_at', ascending: false);

      return response.map<StreakMilestone>((data) {
        return StreakMilestone(
          streakLength: data['streak_length'],
          title: data['title'],
          description: data['description'],
          achievedAt: DateTime.parse(data['achieved_at']),
          isCelebrated: data['is_celebrated'] ?? false,
          type: MilestoneType.fromValue(data['type']),
          momentumBonusPoints: data['momentum_bonus_points'],
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Failed to get achieved milestones: $e');
      return [];
    }
  }

  /// Get pending celebration
  Future<StreakCelebration?> _getPendingCelebration(String userId) async {
    try {
      final response =
          await _supabase
              .from('today_feed_streak_celebrations')
              .select('*')
              .eq('user_id', userId)
              .eq('is_shown', false)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();

      if (response == null) return null;

      // Get milestone data
      final milestoneData =
          await _supabase
              .from('today_feed_streak_milestones')
              .select('*')
              .eq('user_id', userId)
              .eq('streak_length', response['milestone_streak_length'])
              .maybeSingle();

      if (milestoneData == null) return null;

      final milestone = StreakMilestone.fromJson(milestoneData);

      return StreakCelebration.fromJson({
        ...response,
        'milestone': milestone.toJson(),
      });
    } catch (e) {
      debugPrint('❌ Failed to get pending celebration: $e');
      return null;
    }
  }

  // Cache management

  /// Get cached streak
  EngagementStreak? _getCachedStreak(String cacheKey) {
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return null;

    final expiryMinutes = _config['cache_expiry_minutes'];
    final isExpired =
        DateTime.now().difference(timestamp).inMinutes > expiryMinutes;

    if (isExpired) {
      _streakCache.remove(cacheKey);
      _cacheTimestamps.remove(cacheKey);
      return null;
    }

    return _streakCache[cacheKey];
  }

  /// Cache streak
  void _cacheStreak(String cacheKey, EngagementStreak streak) {
    _streakCache[cacheKey] = streak;
    _cacheTimestamps[cacheKey] = DateTime.now();
  }

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

  /// Queue streak update for offline sync
  void _queueStreakUpdate(
    String userId,
    TodayFeedContent content,
    int? sessionDuration,
    Map<String, dynamic>? additionalMetadata,
  ) {
    _pendingUpdates.add({
      'type': 'streak_update',
      'user_id': userId,
      'content': content.toJson(),
      'session_duration': sessionDuration,
      'additional_metadata': additionalMetadata,
      'timestamp': DateTime.now().toIso8601String(),
    });

    debugPrint('✅ Streak update queued for offline sync');
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
