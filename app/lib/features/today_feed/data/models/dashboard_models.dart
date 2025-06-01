import 'package:flutter/material.dart';
import '../services/session_duration_tracking_service.dart';

/// Dashboard data models for Today Feed analytics
///
/// Contains all data structures used by the analytics dashboard system
/// following modular design principles with separation of concerns.

/// Main dashboard data container
class DashboardData {
  final int periodDays;
  final DateTime generatedAt;
  final EngagementMetrics engagementMetrics;
  final ContentPerformanceMetrics contentMetrics;
  final UserBehaviorMetrics userBehaviorMetrics;
  final KPIMetrics kpiMetrics;
  final TrendAnalysis trendAnalysis;
  final AlertsAndInsights alertsAndInsights;
  final String? userId;
  final List<String>? appliedFilters;

  const DashboardData({
    required this.periodDays,
    required this.generatedAt,
    required this.engagementMetrics,
    required this.contentMetrics,
    required this.userBehaviorMetrics,
    required this.kpiMetrics,
    required this.trendAnalysis,
    required this.alertsAndInsights,
    this.userId,
    this.appliedFilters,
  });

  /// Create empty dashboard data for fallback scenarios
  factory DashboardData.empty({
    int periodDays = 30,
    String? userId,
    List<String>? appliedFilters,
  }) {
    return DashboardData(
      periodDays: periodDays,
      generatedAt: DateTime.now(),
      engagementMetrics: EngagementMetrics.empty(),
      contentMetrics: ContentPerformanceMetrics.empty(),
      userBehaviorMetrics: UserBehaviorMetrics.empty(),
      kpiMetrics: KPIMetrics.empty(),
      trendAnalysis: TrendAnalysis.empty(),
      alertsAndInsights: AlertsAndInsights.empty(),
      userId: userId,
      appliedFilters: appliedFilters,
    );
  }
}

/// Engagement metrics for dashboard
class EngagementMetrics {
  final int totalViews;
  final int uniqueUsers;
  final double engagementRate;
  final double averageSessionDuration;
  final int momentumPointsAwarded;
  final int activeUsers;
  final String trendDirection;
  final DateTime? peakEngagementDate;

  const EngagementMetrics({
    required this.totalViews,
    required this.uniqueUsers,
    required this.engagementRate,
    required this.averageSessionDuration,
    required this.momentumPointsAwarded,
    required this.activeUsers,
    required this.trendDirection,
    this.peakEngagementDate,
  });

  factory EngagementMetrics.empty() {
    return const EngagementMetrics(
      totalViews: 0,
      uniqueUsers: 0,
      engagementRate: 0.0,
      averageSessionDuration: 0.0,
      momentumPointsAwarded: 0,
      activeUsers: 0,
      trendDirection: 'stable',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_views': totalViews,
      'unique_users': uniqueUsers,
      'engagement_rate': engagementRate,
      'average_session_duration': averageSessionDuration,
      'momentum_points_awarded': momentumPointsAwarded,
      'active_users': activeUsers,
      'trend_direction': trendDirection,
      'peak_engagement_date': peakEngagementDate?.toIso8601String(),
    };
  }
}

/// Content performance metrics for dashboard
class ContentPerformanceMetrics {
  final int totalContentPublished;
  final double averageEngagementRate;
  final String topPerformingTopic;
  final Duration averageLoadTime;
  final double targetComplianceRate;
  final double contentQualityScore;
  final Map<String, int> topicBreakdown;

  const ContentPerformanceMetrics({
    required this.totalContentPublished,
    required this.averageEngagementRate,
    required this.topPerformingTopic,
    required this.averageLoadTime,
    required this.targetComplianceRate,
    required this.contentQualityScore,
    required this.topicBreakdown,
  });

  factory ContentPerformanceMetrics.empty() {
    return const ContentPerformanceMetrics(
      totalContentPublished: 0,
      averageEngagementRate: 0.0,
      topPerformingTopic: '',
      averageLoadTime: Duration.zero,
      targetComplianceRate: 0.0,
      contentQualityScore: 0.0,
      topicBreakdown: {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_content_published': totalContentPublished,
      'average_engagement_rate': averageEngagementRate,
      'top_performing_topic': topPerformingTopic,
      'average_load_time_ms': averageLoadTime.inMilliseconds,
      'target_compliance_rate': targetComplianceRate,
      'content_quality_score': contentQualityScore,
      'topic_breakdown': topicBreakdown,
    };
  }
}

/// User behavior metrics for dashboard
class UserBehaviorMetrics {
  final Duration averageSessionDuration;
  final Map<SessionQuality, int> sessionQualityDistribution;
  final Map<String, double> topicPreferences;
  final int consecutiveDaysEngaged;
  final double readingEfficiency;
  final double averageStreakLength;
  final int totalUsersWithStreaks;

  const UserBehaviorMetrics({
    required this.averageSessionDuration,
    required this.sessionQualityDistribution,
    required this.topicPreferences,
    required this.consecutiveDaysEngaged,
    required this.readingEfficiency,
    required this.averageStreakLength,
    required this.totalUsersWithStreaks,
  });

  factory UserBehaviorMetrics.empty() {
    return const UserBehaviorMetrics(
      averageSessionDuration: Duration.zero,
      sessionQualityDistribution: {},
      topicPreferences: {},
      consecutiveDaysEngaged: 0,
      readingEfficiency: 0.0,
      averageStreakLength: 0.0,
      totalUsersWithStreaks: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'average_session_duration_seconds': averageSessionDuration.inSeconds,
      'session_quality_distribution': sessionQualityDistribution.map(
        (k, v) => MapEntry(k.name, v),
      ),
      'topic_preferences': topicPreferences,
      'consecutive_days_engaged': consecutiveDaysEngaged,
      'reading_efficiency': readingEfficiency,
      'average_streak_length': averageStreakLength,
      'total_users_with_streaks': totalUsersWithStreaks,
    };
  }
}

/// KPI metrics aligned with Epic 1.3 success criteria
class KPIMetrics {
  final double dailyEngagementRate;
  final double engagementRateTarget;
  final Duration averageLoadTime;
  final Duration loadTimeTarget;
  final double contentQualityScore;
  final double qualityTarget;
  final double momentumIntegrationSuccess;
  final double userSatisfactionScore;
  final double kpiComplianceRate;

  const KPIMetrics({
    required this.dailyEngagementRate,
    required this.engagementRateTarget,
    required this.averageLoadTime,
    required this.loadTimeTarget,
    required this.contentQualityScore,
    required this.qualityTarget,
    required this.momentumIntegrationSuccess,
    required this.userSatisfactionScore,
    required this.kpiComplianceRate,
  });

  factory KPIMetrics.empty() {
    return const KPIMetrics(
      dailyEngagementRate: 0.0,
      engagementRateTarget: 0.6,
      averageLoadTime: Duration.zero,
      loadTimeTarget: Duration(seconds: 2),
      contentQualityScore: 0.0,
      qualityTarget: 0.8,
      momentumIntegrationSuccess: 0.0,
      userSatisfactionScore: 0.0,
      kpiComplianceRate: 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'daily_engagement_rate': dailyEngagementRate,
      'engagement_rate_target': engagementRateTarget,
      'average_load_time_ms': averageLoadTime.inMilliseconds,
      'load_time_target_ms': loadTimeTarget.inMilliseconds,
      'content_quality_score': contentQualityScore,
      'quality_target': qualityTarget,
      'momentum_integration_success': momentumIntegrationSuccess,
      'user_satisfaction_score': userSatisfactionScore,
      'kpi_compliance_rate': kpiComplianceRate,
    };
  }
}

/// Trend analysis data
class TrendAnalysis {
  final String engagementTrend;
  final List<TrendDataPoint> engagementTrendData;
  final double growthRate;
  final Map<String, dynamic> seasonalityInsights;
  final Map<String, double> projectedMetrics;

  const TrendAnalysis({
    required this.engagementTrend,
    required this.engagementTrendData,
    required this.growthRate,
    required this.seasonalityInsights,
    required this.projectedMetrics,
  });

  factory TrendAnalysis.empty() {
    return const TrendAnalysis(
      engagementTrend: 'stable',
      engagementTrendData: [],
      growthRate: 0.0,
      seasonalityInsights: {},
      projectedMetrics: {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'engagement_trend': engagementTrend,
      'trend_data': engagementTrendData.map((p) => p.toJson()).toList(),
      'growth_rate': growthRate,
      'seasonality_insights': seasonalityInsights,
      'projected_metrics': projectedMetrics,
    };
  }
}

/// Trend data point
class TrendDataPoint {
  final DateTime date;
  final double value;
  final Map<String, dynamic> metadata;

  const TrendDataPoint({
    required this.date,
    required this.value,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'value': value,
      'metadata': metadata,
    };
  }
}

/// Alerts and insights
class AlertsAndInsights {
  final List<DashboardAlert> activeAlerts;
  final List<String> recommendations;
  final List<String> optimizationOpportunities;
  final double healthScore;

  const AlertsAndInsights({
    required this.activeAlerts,
    required this.recommendations,
    required this.optimizationOpportunities,
    required this.healthScore,
  });

  factory AlertsAndInsights.empty() {
    return const AlertsAndInsights(
      activeAlerts: [],
      recommendations: [],
      optimizationOpportunities: [],
      healthScore: 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'active_alerts': activeAlerts.map((a) => a.toJson()).toList(),
      'recommendations': recommendations,
      'optimization_opportunities': optimizationOpportunities,
      'health_score': healthScore,
    };
  }
}

/// Dashboard alert
class DashboardAlert {
  final String id;
  final DashboardAlertType type;
  final DashboardAlertSeverity severity;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const DashboardAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.message,
    required this.timestamp,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'severity': severity.name,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// Dashboard update notification
class DashboardUpdate {
  final DashboardUpdateType type;
  final DashboardData data;
  final DateTime timestamp;

  const DashboardUpdate({
    required this.type,
    required this.data,
    required this.timestamp,
  });
}

/// Dashboard insight
class DashboardInsight {
  final DashboardInsightType type;
  final String title;
  final String description;
  final bool actionable;
  final List<String>? recommendations;

  const DashboardInsight({
    required this.type,
    required this.title,
    required this.description,
    required this.actionable,
    this.recommendations,
  });
}

/// Dashboard layout configuration for responsive design
class DashboardLayoutConfig {
  final int columnCount;
  final double cardSpacing;
  final EdgeInsets cardPadding;
  final double chartHeight;
  final bool useCompactLayout;
  final double iconSize;
  final double fontSizeMultiplier;

  const DashboardLayoutConfig({
    required this.columnCount,
    required this.cardSpacing,
    required this.cardPadding,
    required this.chartHeight,
    required this.useCompactLayout,
    required this.iconSize,
    required this.fontSizeMultiplier,
  });
}

// Enums for dashboard system

enum DashboardExportFormat { summary, comprehensive, business }

enum DashboardAlertType { performance, quality, engagement, system }

enum DashboardAlertSeverity { info, warning, critical }

enum DashboardUpdateType { dataRefresh, newAlert, systemUpdate }

enum DashboardInsightType { positive, neutral, actionRequired, warning }
