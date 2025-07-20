// @size-exempt Temporary: exceeds hard ceiling – scheduled for refactor
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/today_feed_content.dart';

/// Service for tracking and analyzing user interactions with Today Feed content
///
/// This service handles:
/// - Real-time interaction analytics collection
/// - Engagement pattern analysis and insights
/// - Performance metrics calculation
/// - User behavior tracking and segmentation
/// - Content effectiveness measurement
/// - Integration with Epic 2.1 analytics infrastructure
///
/// Implements T1.3.4.7: Create interaction analytics for engagement tracking
class TodayFeedInteractionAnalyticsService {
  static final TodayFeedInteractionAnalyticsService _instance =
      TodayFeedInteractionAnalyticsService._internal();
  factory TodayFeedInteractionAnalyticsService() => _instance;
  TodayFeedInteractionAnalyticsService._internal();

  // Dependencies
  late final SupabaseClient _supabase;
  bool _isInitialized = false;

  // Configuration constants from PRD specifications
  static const int defaultAnalysisPeriodDays = 30;
  static const int maxAnalyticsHistoryDays = 90;
  static const double highEngagementThreshold = 0.7;
  static const double mediumEngagementThreshold = 0.4;
  static const int minInteractionsForInsights = 5;

  /// Initialize the analytics service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _supabase = Supabase.instance.client;
      _isInitialized = true;
      debugPrint('✅ TodayFeedInteractionAnalyticsService initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize analytics service: $e');
      rethrow;
    }
  }

  /// Get comprehensive interaction analytics for a user
  ///
  /// Returns detailed analytics including engagement patterns,
  /// content preferences, and behavioral insights
  Future<UserInteractionAnalytics> getUserInteractionAnalytics(
    String userId, {
    int analysisPeriodDays = defaultAnalysisPeriodDays,
  }) async {
    await initialize();

    try {
      final startDate = DateTime.now().subtract(
        Duration(days: analysisPeriodDays),
      );

      // Get user interactions
      final interactions = await _getUserInteractions(userId, startDate);

      // Get engagement summary
      final engagementSummary = await _getUserEngagementSummary(
        userId,
        startDate,
      );

      // Calculate analytics
      final analytics = _calculateUserAnalytics(
        interactions,
        engagementSummary,
        analysisPeriodDays,
      );

      debugPrint('✅ User analytics calculated for $userId');
      return analytics;
    } catch (e) {
      debugPrint('❌ Failed to get user analytics: $e');
      return UserInteractionAnalytics.empty(userId);
    }
  }

  /// Get content performance analytics
  ///
  /// Analyzes how specific content performs across all users
  Future<ContentPerformanceAnalytics> getContentPerformanceAnalytics(
    int contentId, {
    int analysisPeriodDays = defaultAnalysisPeriodDays,
  }) async {
    await initialize();

    try {
      final startDate = DateTime.now().subtract(
        Duration(days: analysisPeriodDays),
      );

      // Get content interactions
      final interactions = await _getContentInteractions(contentId, startDate);

      // Get content analytics data
      final contentAnalytics = await _getContentAnalyticsData(contentId);

      // Calculate performance metrics
      final analytics = _calculateContentAnalytics(
        contentId,
        interactions,
        contentAnalytics,
      );

      debugPrint('✅ Content analytics calculated for content $contentId');
      return analytics;
    } catch (e) {
      debugPrint('❌ Failed to get content analytics: $e');
      return ContentPerformanceAnalytics.empty(contentId);
    }
  }

  /// Get engagement trends over time
  ///
  /// Provides time-series data for engagement patterns
  Future<EngagementTrendsAnalytics> getEngagementTrends({
    int analysisPeriodDays = defaultAnalysisPeriodDays,
    String? userId,
    String? topicCategory,
  }) async {
    await initialize();

    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: analysisPeriodDays));

      // Get daily engagement data
      final dailyEngagement = await _getDailyEngagementData(
        startDate,
        endDate,
        userId: userId,
        topicCategory: topicCategory,
      );

      // Calculate trends
      final trends = _calculateEngagementTrends(dailyEngagement);

      debugPrint('✅ Engagement trends calculated');
      return trends;
    } catch (e) {
      debugPrint('❌ Failed to get engagement trends: $e');
      return EngagementTrendsAnalytics.empty();
    }
  }

  /// Get topic performance comparison
  ///
  /// Analyzes performance across different health topic categories
  Future<TopicPerformanceAnalytics> getTopicPerformanceAnalytics({
    int analysisPeriodDays = defaultAnalysisPeriodDays,
    String? userId,
  }) async {
    await initialize();

    try {
      final startDate = DateTime.now().subtract(
        Duration(days: analysisPeriodDays),
      );

      // Get topic performance data
      final topicData = await _getTopicPerformanceData(
        startDate,
        userId: userId,
      );

      // Calculate topic analytics
      final analytics = _calculateTopicAnalytics(topicData);

      debugPrint('✅ Topic performance analytics calculated');
      return analytics;
    } catch (e) {
      debugPrint('❌ Failed to get topic analytics: $e');
      return TopicPerformanceAnalytics.empty();
    }
  }

  /// Record real-time interaction event for analytics
  ///
  /// Captures interaction events for immediate analytics processing
  Future<void> recordInteractionEvent({
    required String userId,
    required int contentId,
    required TodayFeedInteractionType interactionType,
    int? sessionDuration,
    Map<String, dynamic>? metadata,
  }) async {
    await initialize();

    try {
      // Record in analytics events table for real-time processing
      await _supabase.from('today_feed_analytics_events').insert({
        'user_id': userId,
        'content_id': contentId,
        'interaction_type': interactionType.value,
        'session_duration': sessionDuration,
        'event_timestamp': DateTime.now().toIso8601String(),
        'metadata': metadata ?? {},
      });

      debugPrint('✅ Analytics event recorded: ${interactionType.value}');
    } catch (e) {
      debugPrint('❌ Failed to record analytics event: $e');
      // Non-blocking error - analytics is supplementary
    }
  }

  /// Get real-time engagement metrics
  ///
  /// Provides current engagement status and live metrics
  Future<RealTimeEngagementMetrics> getRealTimeEngagementMetrics() async {
    await initialize();

    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      // Get today's metrics
      final todayMetrics = await _getTodayMetrics(todayStart);

      // Get current active users (last 15 minutes)
      final activeUsers = await _getActiveUsersCount(
        now.subtract(const Duration(minutes: 15)),
      );

      // Calculate real-time metrics
      final metrics = RealTimeEngagementMetrics(
        currentActiveUsers: activeUsers,
        todayTotalViews: todayMetrics['total_views'] ?? 0,
        todayUniqueUsers: todayMetrics['unique_users'] ?? 0,
        todayEngagementRate: todayMetrics['engagement_rate'] ?? 0.0,
        todayMomentumPointsAwarded: todayMetrics['momentum_points'] ?? 0,
        lastUpdated: now,
      );

      debugPrint('✅ Real-time metrics calculated');
      return metrics;
    } catch (e) {
      debugPrint('❌ Failed to get real-time metrics: $e');
      return RealTimeEngagementMetrics.empty();
    }
  }

  // Private helper methods

  /// Get user interactions from database
  Future<List<Map<String, dynamic>>> _getUserInteractions(
    String userId,
    DateTime startDate,
  ) async {
    final response = await _supabase
        .from('user_content_interactions')
        .select('''
          *,
          daily_feed_content!inner(
            id,
            title,
            topic_category,
            ai_confidence_score,
            content_date
          )
        ''')
        .eq('user_id', userId)
        .gte('interaction_timestamp', startDate.toIso8601String())
        .order('interaction_timestamp', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get user engagement summary
  Future<Map<String, dynamic>?> _getUserEngagementSummary(
    String userId,
    DateTime startDate,
  ) async {
    final response =
        await _supabase
            .from('user_engagement_summary')
            .select('*')
            .eq('user_id', userId)
            .gte('summary_date', startDate.toIso8601String().split('T')[0])
            .order('summary_date', ascending: false)
            .limit(1)
            .maybeSingle();

    return response;
  }

  /// Calculate comprehensive user analytics
  UserInteractionAnalytics _calculateUserAnalytics(
    List<Map<String, dynamic>> interactions,
    Map<String, dynamic>? engagementSummary,
    int analysisPeriodDays,
  ) {
    if (interactions.isEmpty) {
      return UserInteractionAnalytics.empty(
        engagementSummary?['user_id'] ?? '',
      );
    }

    final userId = interactions.first['user_id'] as String;

    // Calculate basic metrics
    final totalInteractions = interactions.length;
    final uniqueContentPieces =
        interactions.map((i) => i['content_id']).toSet().length;

    final viewInteractions =
        interactions.where((i) => i['interaction_type'] == 'view').toList();

    final avgSessionDuration =
        viewInteractions.isNotEmpty
            ? viewInteractions
                    .where((i) => i['session_duration'] != null)
                    .map((i) => i['session_duration'] as int)
                    .fold(0, (sum, duration) => sum + duration) /
                viewInteractions.length
            : 0.0;

    // Calculate engagement level
    final engagementRate = totalInteractions / analysisPeriodDays;
    final engagementLevel = _determineEngagementLevel(engagementRate);

    // Analyze topic preferences
    final topicPreferences = _analyzeTopicPreferences(interactions);

    // Calculate engagement patterns
    final engagementPatterns = _analyzeEngagementPatterns(interactions);

    return UserInteractionAnalytics(
      userId: userId,
      analysisPeriodDays: analysisPeriodDays,
      totalInteractions: totalInteractions,
      uniqueContentPieces: uniqueContentPieces,
      averageSessionDuration: avgSessionDuration,
      engagementLevel: engagementLevel,
      engagementRate: engagementRate,
      topicPreferences: topicPreferences,
      engagementPatterns: engagementPatterns,
      consecutiveDaysEngaged:
          engagementSummary?['consecutive_days_engaged'] ?? 0,
      lastInteractionDate:
          interactions.isNotEmpty
              ? DateTime.parse(interactions.first['interaction_timestamp'])
              : null,
    );
  }

  /// Calculate content performance analytics
  ContentPerformanceAnalytics _calculateContentAnalytics(
    int contentId,
    List<Map<String, dynamic>> interactions,
    Map<String, dynamic>? contentAnalytics,
  ) {
    final totalViews = contentAnalytics?['total_views'] ?? 0;
    final totalClicks = contentAnalytics?['total_clicks'] ?? 0;
    final uniqueViewers = contentAnalytics?['unique_viewers'] ?? 0;
    final avgSessionDuration = contentAnalytics?['avg_session_duration'] ?? 0.0;
    final engagementRate = contentAnalytics?['engagement_rate'] ?? 0.0;

    // Calculate performance score
    final performanceScore = _calculatePerformanceScore(
      engagementRate,
      avgSessionDuration,
      uniqueViewers,
    );

    return ContentPerformanceAnalytics(
      contentId: contentId,
      totalViews: totalViews,
      totalClicks: totalClicks,
      uniqueViewers: uniqueViewers,
      averageSessionDuration: avgSessionDuration,
      engagementRate: engagementRate,
      performanceScore: performanceScore,
      interactionBreakdown: _calculateInteractionBreakdown(interactions),
    );
  }

  /// Get content interactions from database
  Future<List<Map<String, dynamic>>> _getContentInteractions(
    int contentId,
    DateTime startDate,
  ) async {
    final response = await _supabase
        .from('user_content_interactions')
        .select('*')
        .eq('content_id', contentId)
        .gte('interaction_timestamp', startDate.toIso8601String())
        .order('interaction_timestamp', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get content analytics data
  Future<Map<String, dynamic>?> _getContentAnalyticsData(int contentId) async {
    final response =
        await _supabase
            .from('content_analytics')
            .select('*')
            .eq('content_id', contentId)
            .maybeSingle();

    return response;
  }

  /// Calculate engagement trends
  EngagementTrendsAnalytics _calculateEngagementTrends(
    List<Map<String, dynamic>> dailyData,
  ) {
    if (dailyData.isEmpty) {
      return EngagementTrendsAnalytics.empty();
    }

    final trendData =
        dailyData.map((day) {
          return DailyEngagementData(
            date: DateTime.parse(day['date']),
            totalViews: day['total_views'] ?? 0,
            uniqueUsers: day['unique_users'] ?? 0,
            engagementRate: (day['engagement_rate'] ?? 0.0).toDouble(),
            averageSessionDuration:
                (day['avg_session_duration'] ?? 0.0).toDouble(),
          );
        }).toList();

    // Calculate trend direction
    final trendDirection = _calculateTrendDirection(trendData);

    return EngagementTrendsAnalytics(
      dailyData: trendData,
      trendDirection: trendDirection,
      averageEngagementRate:
          trendData
              .map((d) => d.engagementRate)
              .fold(0.0, (sum, rate) => sum + rate) /
          trendData.length,
      peakEngagementDate:
          trendData
              .reduce((a, b) => a.engagementRate > b.engagementRate ? a : b)
              .date,
    );
  }

  /// Determine engagement level based on interaction rate
  String _determineEngagementLevel(double engagementRate) {
    if (engagementRate >= highEngagementThreshold) {
      return 'high';
    } else if (engagementRate >= mediumEngagementThreshold) {
      return 'medium';
    } else {
      return 'low';
    }
  }

  /// Analyze topic preferences from interactions
  Map<String, double> _analyzeTopicPreferences(
    List<Map<String, dynamic>> interactions,
  ) {
    final topicCounts = <String, int>{};

    for (final interaction in interactions) {
      final content = interaction['daily_feed_content'];
      if (content != null) {
        final topic = content['topic_category'] as String;
        topicCounts[topic] = (topicCounts[topic] ?? 0) + 1;
      }
    }

    final total = topicCounts.values.fold(0, (sum, count) => sum + count);
    if (total == 0) return {};

    return topicCounts.map((topic, count) => MapEntry(topic, count / total));
  }

  /// Analyze engagement patterns
  Map<String, dynamic> _analyzeEngagementPatterns(
    List<Map<String, dynamic>> interactions,
  ) {
    // Analyze time-of-day patterns
    final hourCounts = <int, int>{};
    for (final interaction in interactions) {
      final timestamp = DateTime.parse(interaction['interaction_timestamp']);
      final hour = timestamp.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }

    final peakHour =
        hourCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    return {
      'peak_engagement_hour': peakHour,
      'hourly_distribution': hourCounts,
      'weekend_vs_weekday_ratio': _calculateWeekendRatio(interactions),
    };
  }

  /// Calculate weekend vs weekday engagement ratio
  double _calculateWeekendRatio(List<Map<String, dynamic>> interactions) {
    int weekendCount = 0;
    int weekdayCount = 0;

    for (final interaction in interactions) {
      final timestamp = DateTime.parse(interaction['interaction_timestamp']);
      if (timestamp.weekday >= 6) {
        weekendCount++;
      } else {
        weekdayCount++;
      }
    }

    return weekdayCount > 0 ? weekendCount / weekdayCount : 0.0;
  }

  /// Calculate performance score
  double _calculatePerformanceScore(
    double engagementRate,
    double avgSessionDuration,
    int uniqueViewers,
  ) {
    // Weighted scoring: 50% engagement rate, 30% session duration, 20% reach
    final engagementScore = engagementRate.clamp(0.0, 1.0);
    final durationScore = (avgSessionDuration / 120).clamp(
      0.0,
      1.0,
    ); // 2 min max
    final reachScore = (uniqueViewers / 100).clamp(0.0, 1.0); // 100 users max

    return (engagementScore * 0.5) + (durationScore * 0.3) + (reachScore * 0.2);
  }

  /// Calculate interaction breakdown
  Map<String, int> _calculateInteractionBreakdown(
    List<Map<String, dynamic>> interactions,
  ) {
    final breakdown = <String, int>{};

    for (final interaction in interactions) {
      final type = interaction['interaction_type'] as String;
      breakdown[type] = (breakdown[type] ?? 0) + 1;
    }

    return breakdown;
  }

  /// Get daily engagement data
  Future<List<Map<String, dynamic>>> _getDailyEngagementData(
    DateTime startDate,
    DateTime endDate, {
    String? userId,
    String? topicCategory,
  }) async {
    // Implementation would query daily analytics summary
    // For now, return empty list
    return [];
  }

  /// Get topic performance data
  Future<List<Map<String, dynamic>>> _getTopicPerformanceData(
    DateTime startDate, {
    String? userId,
  }) async {
    // Implementation would query topic performance view
    // For now, return empty list
    return [];
  }

  /// Calculate topic analytics
  TopicPerformanceAnalytics _calculateTopicAnalytics(
    List<Map<String, dynamic>> topicData,
  ) {
    return TopicPerformanceAnalytics.empty();
  }

  /// Get today's metrics
  Future<Map<String, dynamic>> _getTodayMetrics(DateTime todayStart) async {
    // Implementation would query today's analytics
    return {};
  }

  /// Get active users count
  Future<int> _getActiveUsersCount(DateTime since) async {
    // Implementation would query recent interactions
    return 0;
  }

  /// Calculate trend direction
  String _calculateTrendDirection(List<DailyEngagementData> data) {
    if (data.length < 2) return 'stable';

    final recent = data.take(7).map((d) => d.engagementRate).toList();
    final older = data.skip(7).take(7).map((d) => d.engagementRate).toList();

    if (recent.isEmpty || older.isEmpty) return 'stable';

    final recentAvg =
        recent.fold(0.0, (sum, rate) => sum + rate) / recent.length;
    final olderAvg = older.fold(0.0, (sum, rate) => sum + rate) / older.length;

    if (recentAvg > olderAvg * 1.1) return 'increasing';
    if (recentAvg < olderAvg * 0.9) return 'decreasing';
    return 'stable';
  }

  /// Dispose resources
  void dispose() {
    // Clean up any resources if needed
    debugPrint('🧹 TodayFeedInteractionAnalyticsService disposed');
  }
}

// Analytics data models

/// User interaction analytics data model
class UserInteractionAnalytics {
  final String userId;
  final int analysisPeriodDays;
  final int totalInteractions;
  final int uniqueContentPieces;
  final double averageSessionDuration;
  final String engagementLevel;
  final double engagementRate;
  final Map<String, double> topicPreferences;
  final Map<String, dynamic> engagementPatterns;
  final int consecutiveDaysEngaged;
  final DateTime? lastInteractionDate;

  const UserInteractionAnalytics({
    required this.userId,
    required this.analysisPeriodDays,
    required this.totalInteractions,
    required this.uniqueContentPieces,
    required this.averageSessionDuration,
    required this.engagementLevel,
    required this.engagementRate,
    required this.topicPreferences,
    required this.engagementPatterns,
    required this.consecutiveDaysEngaged,
    this.lastInteractionDate,
  });

  factory UserInteractionAnalytics.empty(String userId) {
    return UserInteractionAnalytics(
      userId: userId,
      analysisPeriodDays: 0,
      totalInteractions: 0,
      uniqueContentPieces: 0,
      averageSessionDuration: 0.0,
      engagementLevel: 'low',
      engagementRate: 0.0,
      topicPreferences: {},
      engagementPatterns: {},
      consecutiveDaysEngaged: 0,
    );
  }
}

/// Content performance analytics data model
class ContentPerformanceAnalytics {
  final int contentId;
  final int totalViews;
  final int totalClicks;
  final int uniqueViewers;
  final double averageSessionDuration;
  final double engagementRate;
  final double performanceScore;
  final Map<String, int> interactionBreakdown;

  const ContentPerformanceAnalytics({
    required this.contentId,
    required this.totalViews,
    required this.totalClicks,
    required this.uniqueViewers,
    required this.averageSessionDuration,
    required this.engagementRate,
    required this.performanceScore,
    required this.interactionBreakdown,
  });

  factory ContentPerformanceAnalytics.empty(int contentId) {
    return ContentPerformanceAnalytics(
      contentId: contentId,
      totalViews: 0,
      totalClicks: 0,
      uniqueViewers: 0,
      averageSessionDuration: 0.0,
      engagementRate: 0.0,
      performanceScore: 0.0,
      interactionBreakdown: {},
    );
  }
}

/// Engagement trends analytics data model
class EngagementTrendsAnalytics {
  final List<DailyEngagementData> dailyData;
  final String trendDirection;
  final double averageEngagementRate;
  final DateTime? peakEngagementDate;

  const EngagementTrendsAnalytics({
    required this.dailyData,
    required this.trendDirection,
    required this.averageEngagementRate,
    this.peakEngagementDate,
  });

  factory EngagementTrendsAnalytics.empty() {
    return const EngagementTrendsAnalytics(
      dailyData: [],
      trendDirection: 'stable',
      averageEngagementRate: 0.0,
    );
  }
}

/// Daily engagement data model
class DailyEngagementData {
  final DateTime date;
  final int totalViews;
  final int uniqueUsers;
  final double engagementRate;
  final double averageSessionDuration;

  const DailyEngagementData({
    required this.date,
    required this.totalViews,
    required this.uniqueUsers,
    required this.engagementRate,
    required this.averageSessionDuration,
  });
}

/// Topic performance analytics data model
class TopicPerformanceAnalytics {
  final Map<String, double> topicEngagementRates;
  final Map<String, int> topicViewCounts;
  final String mostEngagingTopic;
  final String leastEngagingTopic;

  const TopicPerformanceAnalytics({
    required this.topicEngagementRates,
    required this.topicViewCounts,
    required this.mostEngagingTopic,
    required this.leastEngagingTopic,
  });

  factory TopicPerformanceAnalytics.empty() {
    return const TopicPerformanceAnalytics(
      topicEngagementRates: {},
      topicViewCounts: {},
      mostEngagingTopic: '',
      leastEngagingTopic: '',
    );
  }
}

/// Real-time engagement metrics data model
class RealTimeEngagementMetrics {
  final int currentActiveUsers;
  final int todayTotalViews;
  final int todayUniqueUsers;
  final double todayEngagementRate;
  final int todayMomentumPointsAwarded;
  final DateTime lastUpdated;

  const RealTimeEngagementMetrics({
    required this.currentActiveUsers,
    required this.todayTotalViews,
    required this.todayUniqueUsers,
    required this.todayEngagementRate,
    required this.todayMomentumPointsAwarded,
    required this.lastUpdated,
  });

  factory RealTimeEngagementMetrics.empty() {
    return RealTimeEngagementMetrics(
      currentActiveUsers: 0,
      todayTotalViews: 0,
      todayUniqueUsers: 0,
      todayEngagementRate: 0.0,
      todayMomentumPointsAwarded: 0,
      lastUpdated: DateTime.now(),
    );
  }
}
