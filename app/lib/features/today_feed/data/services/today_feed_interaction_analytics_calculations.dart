part of 'today_feed_interaction_analytics_service.dart';

// ---------------------------------------------------------------------------
// KEEP ONLY TWO FUNCTIONS BELOW
// ---------------------------------------------------------------------------
// rest of helper functions removed to avoid duplicate definitions

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

// Helper to count weekend vs weekday interactions
double _calculateWeekendRatio(List<Map<String, dynamic>> interactions) {
  int weekend = 0;
  int weekday = 0;
  for (final interaction in interactions) {
    final ts = DateTime.parse(interaction['interaction_timestamp']);
    if (ts.weekday >= 6) {
      weekend++;
    } else {
      weekday++;
    }
  }
  return weekday == 0 ? 0.0 : weekend / weekday;
}
