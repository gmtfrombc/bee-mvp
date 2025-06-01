/// Data models for Today Feed streak tracking functionality
///
/// Implements T1.3.4.10 - Create streak tracking for consecutive daily engagements
/// with celebration, analytics, and visual feedback support.
library;

import 'package:flutter/material.dart';

/// Represents a user's engagement streak with detailed metadata
class EngagementStreak {
  final int currentStreak;
  final int longestStreak;
  final DateTime? streakStartDate;
  final DateTime? lastEngagementDate;
  final bool isActiveToday;
  final StreakStatus status;
  final List<StreakMilestone> achievedMilestones;
  final StreakCelebration? pendingCelebration;
  final double consistencyRate;
  final int totalEngagementDays;

  const EngagementStreak({
    required this.currentStreak,
    required this.longestStreak,
    this.streakStartDate,
    this.lastEngagementDate,
    required this.isActiveToday,
    required this.status,
    required this.achievedMilestones,
    this.pendingCelebration,
    required this.consistencyRate,
    required this.totalEngagementDays,
  });

  /// Factory constructor for empty/new streak
  factory EngagementStreak.empty() {
    return const EngagementStreak(
      currentStreak: 0,
      longestStreak: 0,
      isActiveToday: false,
      status: StreakStatus.inactive,
      achievedMilestones: [],
      consistencyRate: 0.0,
      totalEngagementDays: 0,
    );
  }

  /// Copy with method for immutable updates
  EngagementStreak copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? streakStartDate,
    DateTime? lastEngagementDate,
    bool? isActiveToday,
    StreakStatus? status,
    List<StreakMilestone>? achievedMilestones,
    StreakCelebration? pendingCelebration,
    double? consistencyRate,
    int? totalEngagementDays,
  }) {
    return EngagementStreak(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      streakStartDate: streakStartDate ?? this.streakStartDate,
      lastEngagementDate: lastEngagementDate ?? this.lastEngagementDate,
      isActiveToday: isActiveToday ?? this.isActiveToday,
      status: status ?? this.status,
      achievedMilestones: achievedMilestones ?? this.achievedMilestones,
      pendingCelebration: pendingCelebration,
      consistencyRate: consistencyRate ?? this.consistencyRate,
      totalEngagementDays: totalEngagementDays ?? this.totalEngagementDays,
    );
  }

  /// Convert to JSON for storage/caching
  Map<String, dynamic> toJson() {
    return {
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'streak_start_date': streakStartDate?.toIso8601String(),
      'last_engagement_date': lastEngagementDate?.toIso8601String(),
      'is_active_today': isActiveToday,
      'status': status.value,
      'achieved_milestones': achievedMilestones.map((m) => m.toJson()).toList(),
      'pending_celebration': pendingCelebration?.toJson(),
      'consistency_rate': consistencyRate,
      'total_engagement_days': totalEngagementDays,
    };
  }

  /// Create from JSON for storage/caching
  factory EngagementStreak.fromJson(Map<String, dynamic> json) {
    return EngagementStreak(
      currentStreak: json['current_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
      streakStartDate:
          json['streak_start_date'] != null
              ? DateTime.parse(json['streak_start_date'])
              : null,
      lastEngagementDate:
          json['last_engagement_date'] != null
              ? DateTime.parse(json['last_engagement_date'])
              : null,
      isActiveToday: json['is_active_today'] ?? false,
      status: StreakStatus.fromValue(json['status'] ?? 'inactive'),
      achievedMilestones:
          (json['achieved_milestones'] as List? ?? [])
              .map((m) => StreakMilestone.fromJson(m))
              .toList(),
      pendingCelebration:
          json['pending_celebration'] != null
              ? StreakCelebration.fromJson(json['pending_celebration'])
              : null,
      consistencyRate: (json['consistency_rate'] ?? 0.0).toDouble(),
      totalEngagementDays: json['total_engagement_days'] ?? 0,
    );
  }
}

/// Streak status enumeration
enum StreakStatus {
  inactive('inactive'),
  starting('starting'),
  building('building'),
  strong('strong'),
  champion('champion'),
  broken('broken');

  const StreakStatus(this.value);
  final String value;

  static StreakStatus fromValue(String value) {
    return StreakStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => StreakStatus.inactive,
    );
  }

  /// Get status based on current streak length
  static StreakStatus fromStreakLength(int streak) {
    if (streak == 0) return StreakStatus.inactive;
    if (streak == 1) return StreakStatus.starting;
    if (streak <= 6) return StreakStatus.building;
    if (streak <= 29) return StreakStatus.strong;
    return StreakStatus.champion;
  }

  /// Get display message for streak status
  String getDisplayMessage(int currentStreak) {
    switch (this) {
      case StreakStatus.inactive:
        return "Ready to start your streak?";
      case StreakStatus.starting:
        return "Great start! Keep it going tomorrow!";
      case StreakStatus.building:
        return "Building momentum! $currentStreak days strong!";
      case StreakStatus.strong:
        return "Incredible streak! $currentStreak days and counting!";
      case StreakStatus.champion:
        return "Champion streak! $currentStreak days - you're unstoppable!";
      case StreakStatus.broken:
        return "Don't worry! Start fresh - every day is a new chance!";
    }
  }

  /// Get theme color for status
  Color getThemeColor() {
    switch (this) {
      case StreakStatus.inactive:
        return const Color(0xFF9E9E9E);
      case StreakStatus.starting:
        return const Color(0xFF4CAF50);
      case StreakStatus.building:
        return const Color(0xFF2196F3);
      case StreakStatus.strong:
        return const Color(0xFFFF9800);
      case StreakStatus.champion:
        return const Color(0xFFE91E63);
      case StreakStatus.broken:
        return const Color(0xFFF44336);
    }
  }
}

/// Represents a milestone achievement in streak progression
class StreakMilestone {
  final int streakLength;
  final String title;
  final String description;
  final DateTime achievedAt;
  final bool isCelebrated;
  final MilestoneType type;
  final int momentumBonusPoints;

  const StreakMilestone({
    required this.streakLength,
    required this.title,
    required this.description,
    required this.achievedAt,
    required this.isCelebrated,
    required this.type,
    required this.momentumBonusPoints,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'streak_length': streakLength,
      'title': title,
      'description': description,
      'achieved_at': achievedAt.toIso8601String(),
      'is_celebrated': isCelebrated,
      'type': type.value,
      'momentum_bonus_points': momentumBonusPoints,
    };
  }

  /// Create from JSON
  factory StreakMilestone.fromJson(Map<String, dynamic> json) {
    return StreakMilestone(
      streakLength: json['streak_length'],
      title: json['title'],
      description: json['description'],
      achievedAt: DateTime.parse(json['achieved_at']),
      isCelebrated: json['is_celebrated'],
      type: MilestoneType.fromValue(json['type']),
      momentumBonusPoints: json['momentum_bonus_points'],
    );
  }

  /// Copy with method
  StreakMilestone copyWith({bool? isCelebrated}) {
    return StreakMilestone(
      streakLength: streakLength,
      title: title,
      description: description,
      achievedAt: achievedAt,
      isCelebrated: isCelebrated ?? this.isCelebrated,
      type: type,
      momentumBonusPoints: momentumBonusPoints,
    );
  }
}

/// Milestone type enumeration
enum MilestoneType {
  firstDay('first_day'),
  weekly('weekly'),
  biweekly('biweekly'),
  monthly('monthly'),
  quarterly('quarterly'),
  special('special');

  const MilestoneType(this.value);
  final String value;

  static MilestoneType fromValue(String value) {
    return MilestoneType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => MilestoneType.special,
    );
  }
}

/// Represents a celebration for streak achievements
class StreakCelebration {
  final String celebrationId;
  final StreakMilestone milestone;
  final CelebrationType type;
  final String message;
  final String? animationType;
  final int durationMs;
  final bool isShown;
  final DateTime? shownAt;

  const StreakCelebration({
    required this.celebrationId,
    required this.milestone,
    required this.type,
    required this.message,
    this.animationType,
    required this.durationMs,
    required this.isShown,
    this.shownAt,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'celebration_id': celebrationId,
      'milestone': milestone.toJson(),
      'type': type.value,
      'message': message,
      'animation_type': animationType,
      'duration_ms': durationMs,
      'is_shown': isShown,
      'shown_at': shownAt?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory StreakCelebration.fromJson(Map<String, dynamic> json) {
    return StreakCelebration(
      celebrationId: json['celebration_id'],
      milestone: StreakMilestone.fromJson(json['milestone']),
      type: CelebrationType.fromValue(json['type']),
      message: json['message'],
      animationType: json['animation_type'],
      durationMs: json['duration_ms'],
      isShown: json['is_shown'],
      shownAt:
          json['shown_at'] != null ? DateTime.parse(json['shown_at']) : null,
    );
  }

  /// Copy with method
  StreakCelebration copyWith({bool? isShown, DateTime? shownAt}) {
    return StreakCelebration(
      celebrationId: celebrationId,
      milestone: milestone,
      type: type,
      message: message,
      animationType: animationType,
      durationMs: durationMs,
      isShown: isShown ?? this.isShown,
      shownAt: shownAt ?? this.shownAt,
    );
  }
}

/// Celebration type enumeration
enum CelebrationType {
  milestone('milestone'),
  weeklyStreak('weekly_streak'),
  monthlyStreak('monthly_streak'),
  personalBest('personal_best'),
  comeback('comeback');

  const CelebrationType(this.value);
  final String value;

  static CelebrationType fromValue(String value) {
    return CelebrationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => CelebrationType.milestone,
    );
  }
}

/// Result of streak update operations
class StreakUpdateResult {
  final bool success;
  final EngagementStreak updatedStreak;
  final List<StreakMilestone> newMilestones;
  final StreakCelebration? celebration;
  final int momentumPointsEarned;
  final String message;
  final String? error;

  const StreakUpdateResult({
    required this.success,
    required this.updatedStreak,
    required this.newMilestones,
    this.celebration,
    required this.momentumPointsEarned,
    required this.message,
    this.error,
  });

  /// Factory for successful update
  factory StreakUpdateResult.success({
    required EngagementStreak updatedStreak,
    List<StreakMilestone>? newMilestones,
    StreakCelebration? celebration,
    int momentumPointsEarned = 0,
    required String message,
  }) {
    return StreakUpdateResult(
      success: true,
      updatedStreak: updatedStreak,
      newMilestones: newMilestones ?? [],
      celebration: celebration,
      momentumPointsEarned: momentumPointsEarned,
      message: message,
    );
  }

  /// Factory for failed update
  factory StreakUpdateResult.failed({required String message, String? error}) {
    return StreakUpdateResult(
      success: false,
      updatedStreak: EngagementStreak.empty(),
      newMilestones: [],
      momentumPointsEarned: 0,
      message: message,
      error: error,
    );
  }
}

/// Analytics data for streak performance
class StreakAnalytics {
  final String userId;
  final int analysisPeriodDays;
  final int totalStreaks;
  final int averageStreakLength;
  final int currentStreak;
  final int longestStreak;
  final double consistencyRate;
  final List<DailyStreakData> dailyData;
  final Map<int, int> streakLengthDistribution;
  final int totalMilestones;
  final DateTime? lastAnalysisDate;

  const StreakAnalytics({
    required this.userId,
    required this.analysisPeriodDays,
    required this.totalStreaks,
    required this.averageStreakLength,
    required this.currentStreak,
    required this.longestStreak,
    required this.consistencyRate,
    required this.dailyData,
    required this.streakLengthDistribution,
    required this.totalMilestones,
    this.lastAnalysisDate,
  });

  /// Factory for empty analytics
  factory StreakAnalytics.empty(String userId) {
    return StreakAnalytics(
      userId: userId,
      analysisPeriodDays: 0,
      totalStreaks: 0,
      averageStreakLength: 0,
      currentStreak: 0,
      longestStreak: 0,
      consistencyRate: 0.0,
      dailyData: [],
      streakLengthDistribution: {},
      totalMilestones: 0,
    );
  }
}

/// Daily streak data for analytics
class DailyStreakData {
  final DateTime date;
  final bool hasEngagement;
  final int streakDay;
  final StreakStatus status;

  const DailyStreakData({
    required this.date,
    required this.hasEngagement,
    required this.streakDay,
    required this.status,
  });
}

/// Streak insights and recommendations data
class StreakInsights {
  final String userId;
  final List<String> insights;
  final List<String> recommendations;
  final String consistencyGrade;
  final String motivationalMessage;
  final DateTime generatedAt;

  const StreakInsights({
    required this.userId,
    required this.insights,
    required this.recommendations,
    required this.consistencyGrade,
    required this.motivationalMessage,
    required this.generatedAt,
  });

  /// Factory for empty insights
  factory StreakInsights.empty(String userId) {
    return StreakInsights(
      userId: userId,
      insights: [],
      recommendations: [],
      consistencyGrade: 'N/A',
      motivationalMessage: 'Start your streak today!',
      generatedAt: DateTime.now(),
    );
  }
}

/// Consistency trend analysis data
class ConsistencyTrend {
  final String direction;
  final double strength;
  final double firstPeriodRate;
  final double secondPeriodRate;
  final DateTime calculatedAt;

  const ConsistencyTrend({
    required this.direction,
    required this.strength,
    required this.firstPeriodRate,
    required this.secondPeriodRate,
    required this.calculatedAt,
  });

  /// Factory for empty trend
  factory ConsistencyTrend.empty() {
    return ConsistencyTrend(
      direction: 'stable',
      strength: 0.0,
      firstPeriodRate: 0.0,
      secondPeriodRate: 0.0,
      calculatedAt: DateTime.now(),
    );
  }
}

/// Performance recommendation for streak improvement
class StreakRecommendation {
  final String type;
  final String priority;
  final String title;
  final String description;
  final List<String> actionableSteps;

  const StreakRecommendation({
    required this.type,
    required this.priority,
    required this.title,
    required this.description,
    required this.actionableSteps,
  });
}
