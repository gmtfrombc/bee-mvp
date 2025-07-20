// Analytics data models extracted from today_feed_interaction_analytics_service.dart

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
      topicPreferences: const {},
      engagementPatterns: const {},
      consecutiveDaysEngaged: 0,
    );
  }
}

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
      interactionBreakdown: const {},
    );
  }
}

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
