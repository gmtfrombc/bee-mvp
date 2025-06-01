import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/today_feed_streak_models.dart';
import 'streak_persistence_service.dart';

/// Service responsible for all streak calculation operations
///
/// Handles:
/// - Core streak calculation algorithms
/// - Streak metrics computation
/// - Streak update logic
/// - Consistency rate calculations
///
/// Part of the modular streak tracking architecture
class StreakCalculationService {
  static final StreakCalculationService _instance =
      StreakCalculationService._internal();
  factory StreakCalculationService() => _instance;
  StreakCalculationService._internal();

  // Dependencies
  late final SupabaseClient _supabase;
  late final StreakPersistenceService _persistenceService;
  bool _isInitialized = false;

  // Configuration
  static const Map<String, dynamic> _config = {'max_streak_history_days': 365};

  /// Initialize the calculation service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _supabase = Supabase.instance.client;
      _persistenceService = StreakPersistenceService();
      await _persistenceService.initialize();

      _isInitialized = true;
      debugPrint('✅ StreakCalculationService initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize StreakCalculationService: $e');
      rethrow;
    }
  }

  /// Calculate current streak from engagement data
  Future<EngagementStreak> calculateCurrentStreak(String userId) async {
    await initialize();

    try {
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

      // Get stored streak from persistence service
      final storedStreak = await _persistenceService.getStoredStreakData(
        userId,
      );

      // Calculate streak metrics
      final streakMetrics = _calculateStreakMetrics(engagementEvents);

      // Get achieved milestones and pending celebration
      final milestones = await _persistenceService.getAchievedMilestones(
        userId,
      );
      final pendingCelebration = await _persistenceService
          .getPendingCelebration(userId);

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
    } catch (e) {
      debugPrint('❌ Failed to calculate current streak: $e');
      return EngagementStreak.empty();
    }
  }

  /// Calculate updated streak after engagement or break
  Future<EngagementStreak> calculateUpdatedStreak(
    String userId,
    EngagementStreak currentStreak, {
    required bool isNewEngagement,
    bool isBreak = false,
  }) async {
    await initialize();

    try {
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

      final newLongestStreak = max(
        newStreakLength,
        currentStreak.longestStreak,
      );
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
    } catch (e) {
      debugPrint('❌ Failed to calculate updated streak: $e');
      return currentStreak;
    }
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

  /// Dispose resources
  void dispose() {
    debugPrint('✅ StreakCalculationService disposed');
  }
}
