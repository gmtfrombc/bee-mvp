import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/responsive_service.dart';
import '../../../../../core/services/accessibility_service.dart';
import '../../../domain/models/today_feed_content.dart'
    show RichContentElement, RichContentType, TodayFeedContent, HealthTopic;
import '../interactions/today_feed_interactions.dart';

/// Loaded state widget for Today Feed tile
/// Displays complete content with interactions and momentum indicator
class TodayFeedLoadedStateWidget extends StatelessWidget {
  const TodayFeedLoadedStateWidget({
    super.key,
    required this.content,
    required this.showMomentumIndicator,
    required this.pulseAnimation,
    required this.interactionHandler,
    this.enableAnimations = true,
  });

  final TodayFeedContent content;
  final bool showMomentumIndicator;
  final Animation<double> pulseAnimation;
  final TodayFeedInteractionHandler interactionHandler;
  final bool enableAnimations;

  @override
  Widget build(BuildContext context) {
    final isFresh = content.isFresh && !content.hasUserEngaged;
    final isEngaged = content.hasUserEngaged;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildLoadedHeader(context, isFresh, isEngaged),
        Expanded(child: _buildContentSection(context)),
        _buildLoadedActionSection(context, isEngaged),
      ],
    );
  }

  Widget _buildLoadedHeader(
    BuildContext context,
    bool isFresh,
    bool isEngaged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Today's Health Insight",
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.getTextSecondary(context),
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w600,
                  fontSize: _getResponsiveFontSize(context, baseFontSize: 16),
                ),
                maxLines: 2,
              ),
              SizedBox(height: ResponsiveService.getTinySpacing(context) / 2),
              Text(
                _formatDate(DateTime.now()),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.getTextTertiary(context),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        SizedBox(width: ResponsiveService.getTinySpacing(context)),
        Flexible(
          child: _buildStatusBadge(
            context,
            isEngaged ? "VIEWED" : (isFresh ? "NEW" : "TODAY"),
            isEngaged
                ? AppTheme.getTextTertiary(context)
                : (isFresh ? AppTheme.momentumRising : null),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context, String text, Color? color) {
    final spacing = ResponsiveService.getTinySpacing(context);
    final badgeColor = color ?? AppTheme.momentumRising;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: spacing * 2, vertical: spacing),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(
          ResponsiveService.getBorderRadius(context) / 2,
        ),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildContentSection(BuildContext context) {
    // Build simplified content section: title + single paragraph excerpt (no nested scrolling)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: ResponsiveService.getTinySpacing(context)),
        // Title section
        Text(
          content.title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: _getResponsiveFontSize(context, baseFontSize: 18),
            fontWeight: FontWeight.w600,
            height: 1.2,
            letterSpacing: -0.3,
          ),
          maxLines: _getMaxTitleLines(context),
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: ResponsiveService.getMediumSpacing(context)),
        // Excerpt paragraph fills remaining space
        Expanded(
          child: Text(
            _getExcerptText(),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: _getResponsiveFontSize(context, baseFontSize: 16),
              height: 1.4,
              color: AppTheme.getTextSecondary(context),
            ),
            softWrap: true,
            overflow: TextOverflow.fade,
          ),
        ),
        // Spacer keeps minimum distance to bottom meta row
        SizedBox(height: ResponsiveService.getSmallSpacing(context)),
      ],
    );
  }

  Widget _buildTopicBadge(BuildContext context, HealthTopic topic) {
    final spacing = ResponsiveService.getTinySpacing(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: spacing * 2, vertical: spacing),
      decoration: BoxDecoration(
        color: _getTopicColor(topic).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(
          ResponsiveService.getBorderRadius(context) / 2.5,
        ),
      ),
      child: Text(
        topic.value.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: _getTopicColor(topic),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildLoadedActionSection(BuildContext context, bool isEngaged) {
    final spacing = ResponsiveService.getTinySpacing(context);
    final buttonHeight =
        ResponsiveService.shouldUseCompactLayout(context)
            ? AccessibilityService.minimumTouchTarget - 12
            : AccessibilityService.minimumTouchTarget;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Topic badge
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTopicBadge(context, content.topicCategory),
              SizedBox(width: spacing),
            ],
          ),
        ),

        // Action button (no icon, purple accent when unread)
        Flexible(
          child: OutlinedButton(
            onPressed: interactionHandler.onTap,
            style: OutlinedButton.styleFrom(
              minimumSize: Size(90, buttonHeight - 4),
              padding: ResponsiveService.getHorizontalPadding(
                context,
                multiplier: 0.8,
              ),
              textStyle: _getButtonTextStyle(context),
              foregroundColor:
                  isEngaged
                      ? AppTheme.getTextSecondary(context)
                      : AppTheme.accentPurple,
              side: BorderSide(
                color:
                    isEngaged
                        ? AppTheme.getTextTertiary(context)
                        : AppTheme.accentPurple,
                width: 1.5,
              ),
            ),
            child: Text(isEngaged ? "Read Again" : "Read More"),
          ),
        ),
      ],
    );
  }

  // Helper methods

  double _getResponsiveFontSize(
    BuildContext context, {
    required double baseFontSize,
  }) {
    final accessibleScale = AccessibilityService.getAccessibleTextScale(
      context,
    );
    final responsiveMultiplier = ResponsiveService.getFontSizeMultiplier(
      context,
    );
    return baseFontSize * responsiveMultiplier * accessibleScale;
  }

  int _getMaxTitleLines(BuildContext context) {
    return ResponsiveService.shouldUseCompactLayout(context) ? 2 : 3;
  }

  // Max lines no longer used; keep helper for potential future needs
  TextStyle _getButtonTextStyle(BuildContext context) {
    final baseSize =
        ResponsiveService.shouldUseCompactLayout(context) ? 12.0 : 14.0;
    return TextStyle(
      fontSize: _getResponsiveFontSize(context, baseFontSize: baseSize),
      fontWeight: FontWeight.w600,
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

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  // Extract first paragraph or fallback to summary
  String _getExcerptText() {
    if (content.fullContent != null) {
      try {
        final paragraph = content.fullContent!.elements.firstWhere(
          (e) =>
              e.type == RichContentType.paragraph && e.text.trim().isNotEmpty,
          orElse:
              () => const RichContentElement(
                type: RichContentType.paragraph,
                text: '',
              ),
        );
        if (paragraph.text.trim().isNotEmpty) {
          return paragraph.text.trim();
        }
      } catch (_) {}
    }
    return content.summary;
  }
}
