import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/today_feed_streak_models.dart';
import 'streak_persistence_service.dart';
import 'streak_calculation_service.dart';

/// Service for calculating streak analytics and performance insights
///
/// Implements analytics calculation, trend analysis, and performance reporting
/// as part of the streak tracking system refactoring.
///
/// Features:
/// - Comprehensive streak analytics calculation
/// - Daily engagement pattern analysis
/// - Consistency rate and trend calculations
/// - Performance insights and recommendations
/// - Historical streak data analysis
/// - Integration with calculation and persistence services
class StreakAnalyticsService {
  static final StreakAnalyticsService _instance =
      StreakAnalyticsService._internal();
  factory StreakAnalyticsService() => _instance;
  StreakAnalyticsService._internal();

  // Dependencies
  late final SupabaseClient _supabase;
  late final StreakPersistenceService _persistenceService;
  late final StreakCalculationService _calculationService;
  bool _isInitialized = false;

  // Configuration for analytics
  static const Map<String, dynamic> _config = {
    'analytics_period_days': 90,
    'default_analysis_period': 30,
    'min_data_points_for_insights': 7,
    'trend_analysis_minimum_days': 14,
  };

  /// Initialize the analytics service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _supabase = Supabase.instance.client;
      _persistenceService = StreakPersistenceService();
      _calculationService = StreakCalculationService();

      await _persistenceService.initialize();
      await _calculationService.initialize();

      _isInitialized = true;
      debugPrint('✅ StreakAnalyticsService initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize StreakAnalyticsService: $e');
      rethrow;
    }
  }

  /// Calculate comprehensive streak analytics for user
  Future<StreakAnalytics> calculateStreakAnalytics(
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

      // Calculate analytics from events
      final analytics = await _calculateAnalyticsFromEvents(
        userId,
        engagementEvents,
        periodDays,
      );

      debugPrint('✅ Streak analytics calculated for $periodDays days');
      return analytics;
    } catch (e) {
      debugPrint('❌ Failed to calculate streak analytics: $e');
      return StreakAnalytics.empty(userId);
    }
  }

  /// Get streak insights and recommendations
  Future<StreakInsights> getStreakInsights(
    String userId, {
    int? analysisPeriodDays,
  }) async {
    await initialize();

    try {
      final analytics = await calculateStreakAnalytics(
        userId,
        analysisPeriodDays: analysisPeriodDays,
      );

      final insights = _generateInsights(analytics);
      debugPrint('✅ Streak insights generated');
      return insights;
    } catch (e) {
      debugPrint('❌ Failed to get streak insights: $e');
      return StreakInsights.empty(userId);
    }
  }

  /// Calculate consistency trends over time
  Future<ConsistencyTrend> calculateConsistencyTrend(
    String userId, {
    int? analysisPeriodDays,
  }) async {
    await initialize();

    final periodDays =
        analysisPeriodDays ?? _config['trend_analysis_minimum_days'];

    try {
      final analytics = await calculateStreakAnalytics(
        userId,
        analysisPeriodDays: periodDays,
      );

      final trend = _calculateTrendFromAnalytics(analytics);
      debugPrint('✅ Consistency trend calculated');
      return trend;
    } catch (e) {
      debugPrint('❌ Failed to calculate consistency trend: $e');
      return ConsistencyTrend.empty();
    }
  }

  /// Get performance recommendations based on streak data
  Future<List<StreakRecommendation>> getPerformanceRecommendations(
    String userId,
  ) async {
    await initialize();

    try {
      final analytics = await calculateStreakAnalytics(userId);
      final insights = await getStreakInsights(userId);

      final recommendations = _generateRecommendations(analytics, insights);
      debugPrint('✅ Performance recommendations generated');
      return recommendations;
    } catch (e) {
      debugPrint('❌ Failed to get performance recommendations: $e');
      return [];
    }
  }

  // Private calculation methods

  /// Calculate analytics from engagement events
  Future<StreakAnalytics> _calculateAnalyticsFromEvents(
    String userId,
    List<Map<String, dynamic>> events,
    int periodDays,
  ) async {
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

    // Get current streak using calculation service
    final currentStreak = await _calculationService.calculateCurrentStreak(
      userId,
    );

    // Build daily data for the analysis period
    for (int i = periodDays - 1; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dayString = date.toIso8601String().split('T')[0];
      final hasEngagement = engagementDays[dayString] ?? false;

      dailyData.add(
        DailyStreakData(
          date: date,
          hasEngagement: hasEngagement,
          streakDay: _calculateStreakDayForDate(date, dailyData),
          status: hasEngagement ? StreakStatus.building : StreakStatus.inactive,
        ),
      );
    }

    // Calculate streak length distribution
    final streakLengthDistribution = _calculateStreakDistribution(dailyData);

    // Calculate metrics
    final consistencyRate = engagementDays.length / periodDays;
    final totalStreaks = _countStreaks(dailyData);
    final averageStreakLength = _calculateAverageStreakLength(dailyData);
    final longestStreak = _findLongestStreak(dailyData);

    // Get total milestones from database
    final totalMilestones = await _getTotalMilestones(userId);

    return StreakAnalytics(
      userId: userId,
      analysisPeriodDays: periodDays,
      totalStreaks: totalStreaks,
      averageStreakLength: averageStreakLength.round(),
      currentStreak: currentStreak.currentStreak,
      longestStreak: longestStreak,
      consistencyRate: consistencyRate,
      dailyData: dailyData,
      streakLengthDistribution: streakLengthDistribution,
      totalMilestones: totalMilestones,
      lastAnalysisDate: DateTime.now(),
    );
  }

  /// Calculate streak day number for specific date
  int _calculateStreakDayForDate(
    DateTime date,
    List<DailyStreakData> dailyData,
  ) {
    // Simple implementation - would need more sophisticated logic
    int streakDay = 0;
    for (final data in dailyData.reversed) {
      if (data.date.isBefore(date) && data.hasEngagement) {
        streakDay++;
      } else if (data.date.isBefore(date) && !data.hasEngagement) {
        streakDay = 0;
      }
    }
    return streakDay;
  }

  /// Calculate streak length distribution
  Map<int, int> _calculateStreakDistribution(List<DailyStreakData> dailyData) {
    final distribution = <int, int>{};
    int currentStreakLength = 0;

    for (final data in dailyData) {
      if (data.hasEngagement) {
        currentStreakLength++;
      } else {
        if (currentStreakLength > 0) {
          distribution[currentStreakLength] =
              (distribution[currentStreakLength] ?? 0) + 1;
          currentStreakLength = 0;
        }
      }
    }

    // Add final streak if it exists
    if (currentStreakLength > 0) {
      distribution[currentStreakLength] =
          (distribution[currentStreakLength] ?? 0) + 1;
    }

    return distribution;
  }

  /// Count total number of streaks in period
  int _countStreaks(List<DailyStreakData> dailyData) {
    int streakCount = 0;
    bool inStreak = false;

    for (final data in dailyData) {
      if (data.hasEngagement && !inStreak) {
        streakCount++;
        inStreak = true;
      } else if (!data.hasEngagement) {
        inStreak = false;
      }
    }

    return streakCount;
  }

  /// Calculate average streak length
  double _calculateAverageStreakLength(List<DailyStreakData> dailyData) {
    final distribution = _calculateStreakDistribution(dailyData);
    if (distribution.isEmpty) return 0.0;

    int totalLength = 0;
    int totalStreaks = 0;

    distribution.forEach((length, count) {
      totalLength += length * count;
      totalStreaks += count;
    });

    return totalStreaks > 0 ? totalLength / totalStreaks : 0.0;
  }

  /// Find longest streak in period
  int _findLongestStreak(List<DailyStreakData> dailyData) {
    int maxStreak = 0;
    int currentStreak = 0;

    for (final data in dailyData) {
      if (data.hasEngagement) {
        currentStreak++;
        maxStreak = maxStreak > currentStreak ? maxStreak : currentStreak;
      } else {
        currentStreak = 0;
      }
    }

    return maxStreak;
  }

  /// Get total milestones achieved by user
  Future<int> _getTotalMilestones(String userId) async {
    try {
      final result = await _supabase
          .from('today_feed_streak_milestones')
          .select('id')
          .eq('user_id', userId);

      return result.length;
    } catch (e) {
      debugPrint('❌ Failed to get total milestones: $e');
      return 0;
    }
  }

  /// Generate insights from analytics
  StreakInsights _generateInsights(StreakAnalytics analytics) {
    final insights = <String>[];
    final recommendations = <String>[];

    // Consistency insights
    if (analytics.consistencyRate >= 0.8) {
      insights.add(
        '🔥 Outstanding consistency! You\'re engaging ${(analytics.consistencyRate * 100).toInt()}% of the time.',
      );
    } else if (analytics.consistencyRate >= 0.6) {
      insights.add(
        '👍 Good consistency rate of ${(analytics.consistencyRate * 100).toInt()}%.',
      );
      recommendations.add('Try to engage daily to build stronger habits.');
    } else {
      insights.add(
        '📈 Room for improvement with ${(analytics.consistencyRate * 100).toInt()}% consistency.',
      );
      recommendations.add('Set daily reminders to maintain engagement.');
    }

    // Streak performance insights
    if (analytics.currentStreak >= 7) {
      insights.add(
        '🏆 Amazing current streak of ${analytics.currentStreak} days!',
      );
    } else if (analytics.currentStreak >= 3) {
      insights.add(
        '💪 Building momentum with ${analytics.currentStreak} day streak!',
      );
    }

    // Milestone insights
    if (analytics.totalMilestones > 0) {
      insights.add(
        '🎯 You\'ve achieved ${analytics.totalMilestones} milestones!',
      );
    }

    return StreakInsights(
      userId: analytics.userId,
      insights: insights,
      recommendations: recommendations,
      consistencyGrade: _calculateConsistencyGrade(analytics.consistencyRate),
      motivationalMessage: _generateMotivationalMessage(analytics),
      generatedAt: DateTime.now(),
    );
  }

  /// Calculate consistency grade
  String _calculateConsistencyGrade(double consistencyRate) {
    if (consistencyRate >= 0.9) return 'A+';
    if (consistencyRate >= 0.8) return 'A';
    if (consistencyRate >= 0.7) return 'B+';
    if (consistencyRate >= 0.6) return 'B';
    if (consistencyRate >= 0.5) return 'C+';
    if (consistencyRate >= 0.4) return 'C';
    return 'D';
  }

  /// Generate motivational message
  String _generateMotivationalMessage(StreakAnalytics analytics) {
    if (analytics.currentStreak >= 30) {
      return 'You\'re a consistency champion! Keep this amazing streak going!';
    } else if (analytics.currentStreak >= 7) {
      return 'One week strong! You\'re building excellent habits!';
    } else if (analytics.currentStreak >= 3) {
      return 'Great momentum! Keep it up to reach your weekly goal!';
    } else if (analytics.currentStreak >= 1) {
      return 'Every journey starts with a single step. You\'ve got this!';
    } else {
      return 'Today is a perfect day to start building your streak!';
    }
  }

  /// Calculate trend from analytics
  ConsistencyTrend _calculateTrendFromAnalytics(StreakAnalytics analytics) {
    if (analytics.dailyData.length < _config['trend_analysis_minimum_days']) {
      return ConsistencyTrend.empty();
    }

    // Split data into two halves for comparison
    final midPoint = analytics.dailyData.length ~/ 2;
    final firstHalf = analytics.dailyData.take(midPoint).toList();
    final secondHalf = analytics.dailyData.skip(midPoint).toList();

    final firstHalfRate =
        firstHalf.where((d) => d.hasEngagement).length / firstHalf.length;
    final secondHalfRate =
        secondHalf.where((d) => d.hasEngagement).length / secondHalf.length;

    final trendDirection =
        secondHalfRate > firstHalfRate
            ? 'improving'
            : secondHalfRate < firstHalfRate
            ? 'declining'
            : 'stable';

    final trendStrength = (secondHalfRate - firstHalfRate).abs();

    return ConsistencyTrend(
      direction: trendDirection,
      strength: trendStrength,
      firstPeriodRate: firstHalfRate,
      secondPeriodRate: secondHalfRate,
      calculatedAt: DateTime.now(),
    );
  }

  /// Generate performance recommendations
  List<StreakRecommendation> _generateRecommendations(
    StreakAnalytics analytics,
    StreakInsights insights,
  ) {
    final recommendations = <StreakRecommendation>[];

    // Consistency recommendations
    if (analytics.consistencyRate < 0.6) {
      recommendations.add(
        StreakRecommendation(
          type: 'consistency',
          priority: 'high',
          title: 'Improve Daily Consistency',
          description:
              'Set a specific time each day for engagement to build a stronger habit.',
          actionableSteps: [
            'Choose a consistent time (e.g., morning coffee)',
            'Set daily reminders on your phone',
            'Start with just 5 minutes per day',
          ],
        ),
      );
    }

    // Streak building recommendations
    if (analytics.currentStreak < 7) {
      recommendations.add(
        StreakRecommendation(
          type: 'streak_building',
          priority: 'medium',
          title: 'Build Your First Week',
          description:
              'Focus on reaching a 7-day streak to establish momentum.',
          actionableSteps: [
            'Engage every day this week',
            'Track your progress visually',
            'Celebrate small wins',
          ],
        ),
      );
    }

    // Milestone recommendations
    if (analytics.totalMilestones == 0) {
      recommendations.add(
        StreakRecommendation(
          type: 'milestone',
          priority: 'low',
          title: 'Earn Your First Milestone',
          description:
              'Complete your first day to earn the "First Step" milestone.',
          actionableSteps: [
            'Complete today\'s engagement',
            'Check out your progress in the streak section',
            'Share your achievement with friends',
          ],
        ),
      );
    }

    return recommendations;
  }

  /// Dispose resources
  void dispose() {
    debugPrint('✅ StreakAnalyticsService disposed');
  }
}
