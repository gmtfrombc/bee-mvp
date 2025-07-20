import 'package:flutter/material.dart';
import 'package:app/features/today_feed/domain/models/today_feed_content.dart';
import '../../../../../../core/services/responsive_service.dart';

/// A coloured chip displaying the article topic.
class TopicBadge extends StatelessWidget {
  const TopicBadge({super.key, required this.topic});

  final HealthTopic topic;

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveService.getTinySpacing(context);
    final color = _getTopicColor(topic);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: spacing * 2, vertical: spacing),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(
          ResponsiveService.getBorderRadius(context) / 2.5,
        ),
      ),
      child: Text(
        topic.value.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _getTopicColor(HealthTopic topic) {
    switch (topic) {
      case HealthTopic.nutrition:
        return const Color(0xFF4CAF50);
      case HealthTopic.exercise:
        return const Color(0xFF2196F3);
      case HealthTopic.sleep:
        return const Color(0xFF9C27B0);
      case HealthTopic.stress:
        return const Color(0xFFFF9800);
      case HealthTopic.prevention:
        return const Color(0xFFF44336);
      case HealthTopic.lifestyle:
        return const Color(0xFF607D8B);
    }
  }
}
