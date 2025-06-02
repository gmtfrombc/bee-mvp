import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/responsive_service.dart';
import '../../../../../core/services/accessibility_service.dart';
import '../../../domain/models/today_feed_content.dart';
import '../rich_content_renderer.dart';
import '../components/today_feed_interactions.dart';

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
                ),
                overflow: TextOverflow.ellipsis,
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
    // Use rich content if available, otherwise fall back to basic content
    if (content.fullContent != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: ResponsiveService.getMediumSpacing(context)),
          // Title
          Flexible(
            child: Text(
              content.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: _getResponsiveFontSize(context, baseFontSize: 20),
                fontWeight: FontWeight.w600,
                height: 1.2,
                letterSpacing: -0.3,
              ),
              maxLines: _getMaxTitleLines(context),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: ResponsiveService.getSmallSpacing(context)),
          // Rich content in a scrollable container for tile view
          Flexible(
            flex: 3,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: RichContentRenderer(
                content: content.fullContent!,
                onLinkTap: (url, linkText) {
                  HapticFeedback.lightImpact();
                  interactionHandler.onInteraction?.call(
                    TodayFeedInteractionType.externalLinkClick,
                  );
                  interactionHandler.handleExternalLinkTap(
                    context,
                    url,
                    linkText,
                  );
                },
                isCompact: true,
                enableInteractions: true,
              ),
            ),
          ),
          SizedBox(height: ResponsiveService.getSmallSpacing(context)),
          _buildTopicBadge(context, content.topicCategory),
        ],
      );
    }

    // Fallback to original basic content display
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: ResponsiveService.getMediumSpacing(context)),
        Flexible(
          child: Text(
            content.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: _getResponsiveFontSize(context, baseFontSize: 20),
              fontWeight: FontWeight.w600,
              height: 1.2,
              letterSpacing: -0.3,
            ),
            maxLines: _getMaxTitleLines(context),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(height: ResponsiveService.getSmallSpacing(context)),
        Flexible(
          flex: 2,
          child: Text(
            content.summary,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: _getResponsiveFontSize(context, baseFontSize: 16),
              height: 1.4,
              letterSpacing: 0.1,
              color: AppTheme.getTextSecondary(context),
            ),
            maxLines: _getMaxSummaryLines(context),
            overflow: TextOverflow.fade,
          ),
        ),
        SizedBox(height: ResponsiveService.getSmallSpacing(context)),
        _buildTopicBadge(context, content.topicCategory),
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
    final iconSize = ResponsiveService.getIconSize(context, baseSize: 16);
    final spacing = ResponsiveService.getTinySpacing(context);
    final buttonHeight =
        ResponsiveService.shouldUseCompactLayout(context)
            ? AccessibilityService.minimumTouchTarget - 12
            : AccessibilityService.minimumTouchTarget;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Reading time
        Flexible(
          child:
              content.readingTimeText.isNotEmpty
                  ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule,
                        size: iconSize,
                        color: AppTheme.getTextTertiary(context),
                      ),
                      SizedBox(width: spacing),
                      Flexible(
                        child: Text(
                          content.readingTimeText,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: AppTheme.getTextTertiary(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                  : const SizedBox.shrink(),
        ),

        // Action button
        Flexible(
          child: ElevatedButton.icon(
            onPressed:
                isEngaged ? interactionHandler.onTap : interactionHandler.onTap,
            icon:
                showMomentumIndicator
                    ? _buildMomentumIcon(context, isEngaged)
                    : Icon(Icons.arrow_forward, size: iconSize),
            label: Text(isEngaged ? "Read Again" : "Read More"),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(100, buttonHeight),
              padding: ResponsiveService.getHorizontalPadding(
                context,
                multiplier: 0.75,
              ),
              textStyle: _getButtonTextStyle(context),
              backgroundColor: isEngaged ? null : AppTheme.momentumRising,
              foregroundColor: isEngaged ? null : Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMomentumIcon(BuildContext context, bool isEngaged) {
    final iconSize = ResponsiveService.getIconSize(context, baseSize: 16);

    if (isEngaged) {
      return Icon(
        Icons.check_circle,
        size: iconSize,
        color: AppTheme.momentumRising,
      );
    }

    final momentumSize = iconSize;
    final fontSize = ResponsiveService.getFontSizeMultiplier(context) * 10;
    final isFresh = content.isFresh && !content.hasUserEngaged;

    final momentumIndicator = Container(
      width: momentumSize,
      height: momentumSize,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.momentumRising,
      ),
      child: Center(
        child: Text(
          '+1',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );

    // Performance optimization: Use RepaintBoundary and direct animation
    if (enableAnimations && isFresh) {
      return RepaintBoundary(
        child: AnimatedBuilder(
          animation: pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: pulseAnimation.value,
              child: momentumIndicator,
            );
          },
        ),
      );
    }

    return RepaintBoundary(child: momentumIndicator);
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

  int _getMaxSummaryLines(BuildContext context) {
    return ResponsiveService.shouldUseCompactLayout(context) ? 3 : 4;
  }

  TextStyle _getButtonTextStyle(BuildContext context) {
    final baseSize =
        ResponsiveService.shouldUseCompactLayout(context) ? 14.0 : 16.0;
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
}
