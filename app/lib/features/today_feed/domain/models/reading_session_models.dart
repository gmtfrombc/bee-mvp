import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../../../../core/services/version_service.dart';
import 'today_feed_content.dart';

/// Session quality metrics for engagement analysis
enum SessionQuality {
  brief('brief'),
  moderate('moderate'),
  engaged('engaged'),
  deep('deep');

  const SessionQuality(this.value);
  final String value;

  static SessionQuality fromDuration(Duration duration) {
    if (duration < const Duration(seconds: 30)) {
      return SessionQuality.brief;
    } else if (duration < const Duration(minutes: 2)) {
      return SessionQuality.moderate;
    } else if (duration < const Duration(minutes: 5)) {
      return SessionQuality.engaged;
    } else {
      return SessionQuality.deep;
    }
  }
}

/// Reading session data model for analytics
class ReadingSession {
  final String sessionId;
  final String userId;
  final int contentId;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final SessionQuality quality;
  final int samplesCount;
  final double engagementScore;
  final Map<String, dynamic> metadata;

  const ReadingSession({
    required this.sessionId,
    required this.userId,
    required this.contentId,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.quality,
    required this.samplesCount,
    required this.engagementScore,
    required this.metadata,
  });

  factory ReadingSession.fromTrackingData({
    required String sessionId,
    required String userId,
    required int contentId,
    required DateTime startTime,
    required DateTime endTime,
    required List<DateTime> activitySamples,
    required TodayFeedContent content,
    Map<String, dynamic>? additionalMetadata,
  }) {
    final duration = endTime.difference(startTime);
    final quality = SessionQuality.fromDuration(duration);
    final engagementScore = _calculateEngagementScore(
      duration,
      content.estimatedReadingMinutes,
      activitySamples.length,
    );

    return ReadingSession(
      sessionId: sessionId,
      userId: userId,
      contentId: contentId,
      startTime: startTime,
      endTime: endTime,
      duration: duration,
      quality: quality,
      samplesCount: activitySamples.length,
      engagementScore: engagementScore,
      metadata: {
        'content_title': content.title,
        'content_category': content.topicCategory.value,
        'estimated_reading_minutes': content.estimatedReadingMinutes,
        'ai_confidence_score': content.aiConfidenceScore,
        'platform': defaultTargetPlatform.name,
        'app_version': VersionService.appVersion,
        ...?additionalMetadata,
      },
    );
  }

  static double _calculateEngagementScore(
    Duration actualDuration,
    int estimatedMinutes,
    int samplesCount,
  ) {
    if (estimatedMinutes <= 0) return 0.0;

    final estimatedDuration = Duration(minutes: estimatedMinutes);
    final baseScore = math.min(
      actualDuration.inMilliseconds / estimatedDuration.inMilliseconds,
      2.0,
    );

    final samplingQuality = math.min(samplesCount / 10.0, 1.0);

    return (baseScore * samplingQuality).clamp(0.0, 2.0);
  }

  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'user_id': userId,
    'content_id': contentId,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime.toIso8601String(),
    'duration_seconds': duration.inSeconds,
    'session_quality': quality.value,
    'samples_count': samplesCount,
    'engagement_score': engagementScore,
    'metadata': metadata,
  };

  factory ReadingSession.fromJson(Map<String, dynamic> json) => ReadingSession(
    sessionId: json['session_id'] as String,
    userId: json['user_id'] as String,
    contentId: json['content_id'] as int,
    startTime: DateTime.parse(json['start_time'] as String),
    endTime: DateTime.parse(json['end_time'] as String),
    duration: Duration(seconds: json['duration_seconds'] as int),
    quality: SessionQuality.values.firstWhere(
      (q) => q.value == json['session_quality'],
      orElse: () => SessionQuality.brief,
    ),
    samplesCount: json['samples_count'] as int,
    engagementScore: (json['engagement_score'] as num).toDouble(),
    metadata: json['metadata'] as Map<String, dynamic>,
  );

  @override
  int get hashCode => Object.hash(sessionId, userId, contentId);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReadingSession &&
        other.sessionId == sessionId &&
        other.userId == userId &&
        other.contentId == contentId;
  }

  @override
  String toString() =>
      'ReadingSession(id: $sessionId, duration: ${duration.inSeconds}s, quality: ${quality.value})';
}

/// Aggregated analytics across sessions
class SessionAnalytics {
  final int totalSessions;
  final Duration totalReadingTime;
  final Duration averageSessionDuration;
  final double averageEngagementScore;
  final Map<SessionQuality, int> qualityDistribution;
  final Map<String, double> topicEngagement;
  final DateTime? lastSessionTime;
  final int consecutiveDaysWithSessions;

  const SessionAnalytics({
    required this.totalSessions,
    required this.totalReadingTime,
    required this.averageSessionDuration,
    required this.averageEngagementScore,
    required this.qualityDistribution,
    required this.topicEngagement,
    this.lastSessionTime,
    required this.consecutiveDaysWithSessions,
  });

  factory SessionAnalytics.empty() {
    return const SessionAnalytics(
      totalSessions: 0,
      totalReadingTime: Duration.zero,
      averageSessionDuration: Duration.zero,
      averageEngagementScore: 0.0,
      qualityDistribution: {},
      topicEngagement: {},
      consecutiveDaysWithSessions: 0,
    );
  }

  double get readingEfficiency =>
      totalSessions == 0 ? 0.0 : averageEngagementScore.clamp(0.0, 1.0);
}
