import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/today_feed_streak_models.dart';
import '../../../domain/models/today_feed_content.dart';
import '../today_feed_momentum_award_service.dart';
import 'streak_persistence_service.dart';

/// Service for detecting streak milestones and managing celebrations
///
/// Implements milestone detection, celebration creation, and momentum bonus awards
/// as part of the streak tracking system refactoring.
///
/// Features:
/// - Milestone detection for consecutive engagement streaks
/// - Celebration creation and management
/// - Momentum bonus point integration
/// - Database operations for milestone storage
/// - Analytics support for milestone achievements
class StreakMilestoneService {
  static final StreakMilestoneService _instance =
      StreakMilestoneService._internal();
  factory StreakMilestoneService() => _instance;
  StreakMilestoneService._internal();

  // Dependencies
  late final SupabaseClient _supabase;
  late final TodayFeedMomentumAwardService _momentumService;
  late final StreakPersistenceService _persistenceService;
  bool _isInitialized = false;

  // Configuration for milestones and celebrations
  static const Map<String, dynamic> _config = {
    'milestone_thresholds': [1, 3, 7, 14, 21, 30, 60, 90, 180, 365],
    'milestone_bonus_points': [1, 2, 5, 10, 15, 25, 50, 75, 100, 200],
    'celebration_duration_ms': 3000,
  };

  /// Initialize the milestone service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _supabase = Supabase.instance.client;
      _momentumService = TodayFeedMomentumAwardService();
      _persistenceService = StreakPersistenceService();

      await _momentumService.initialize();
      await _persistenceService.initialize();

      _isInitialized = true;
      debugPrint('✅ StreakMilestoneService initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize StreakMilestoneService: $e');
      rethrow;
    }
  }

  /// Detect new milestones achieved between current and updated streak
  List<StreakMilestone> detectNewMilestones(
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
        final milestone = createMilestone(threshold, bonus);
        newMilestones.add(milestone);
      }
    }

    return newMilestones;
  }

  /// Create milestone for specified threshold
  StreakMilestone createMilestone(int threshold, int bonusPoints) {
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

  /// Create celebration for achieved milestone
  StreakCelebration createCelebration(StreakMilestone milestone) {
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

  /// Award milestone bonus points through momentum system
  Future<void> awardMilestoneBonus(
    String userId,
    TodayFeedContent content,
    StreakMilestone milestone,
    int? sessionDuration,
  ) async {
    await initialize();

    try {
      // Award bonus points through momentum system
      await _supabase.from('today_feed_momentum_awards').insert({
        'user_id': userId,
        'content_id': content.id,
        'content_date': content.contentDate.toIso8601String().split('T')[0],
        'content_title': content.title,
        'topic_category': content.topicCategory.value,
        'points_awarded': milestone.momentumBonusPoints,
        'session_duration_seconds': sessionDuration,
        'award_timestamp': DateTime.now().toIso8601String(),
        'service_version': 'StreakMilestoneService_v1.0',
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
      rethrow;
    }
  }

  /// Store milestone achievement in database
  Future<void> storeMilestoneAchievement(
    String userId,
    StreakMilestone milestone,
  ) async {
    await initialize();

    try {
      await _supabase.from('today_feed_streak_milestones').insert({
        'user_id': userId,
        'streak_length': milestone.streakLength,
        'milestone_type': milestone.type.value,
        'title': milestone.title,
        'description': milestone.description,
        'achieved_at': milestone.achievedAt.toIso8601String(),
        'is_celebrated': milestone.isCelebrated,
        'momentum_bonus_points': milestone.momentumBonusPoints,
        'created_at': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Milestone achievement stored: ${milestone.title}');
    } catch (e) {
      debugPrint('❌ Failed to store milestone achievement: $e');
      rethrow;
    }
  }

  /// Store celebration in database
  Future<void> storeCelebration(
    String userId,
    StreakCelebration celebration,
  ) async {
    await initialize();

    try {
      await _supabase.from('today_feed_streak_celebrations').insert({
        'user_id': userId,
        'celebration_id': celebration.celebrationId,
        'milestone_streak_length': celebration.milestone.streakLength,
        'celebration_type': celebration.type.value,
        'message': celebration.message,
        'animation_type': celebration.animationType,
        'duration_ms': celebration.durationMs,
        'is_shown': celebration.isShown,
        'created_at': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Celebration stored: ${celebration.celebrationId}');
    } catch (e) {
      debugPrint('❌ Failed to store celebration: $e');
      rethrow;
    }
  }

  /// Generate success message based on streak and milestones
  String generateSuccessMessage(
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

  /// Get achieved milestones for user
  Future<List<StreakMilestone>> getAchievedMilestones(String userId) async {
    return _persistenceService.getAchievedMilestones(userId);
  }

  /// Get pending celebration for user
  Future<StreakCelebration?> getPendingCelebration(String userId) async {
    return _persistenceService.getPendingCelebration(userId);
  }

  // Private helper methods

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
}
