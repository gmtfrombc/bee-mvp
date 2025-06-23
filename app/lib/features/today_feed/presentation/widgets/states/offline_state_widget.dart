import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/responsive_service.dart';
import '../../../../../core/services/accessibility_service.dart';
import '../../../domain/models/today_feed_content.dart';
import '../rich_content_renderer.dart';
import '../components/today_feed_interactions.dart';

/// Offline state widget for Today Feed tile
/// Displays cached content with offline indicators
class TodayFeedOfflineStateWidget extends StatelessWidget {
  const TodayFeedOfflineStateWidget({
    super.key,
    required this.cachedContent,
    required this.interactionHandler,
  });

  final TodayFeedContent cachedContent;
  final TodayFeedInteractionHandler interactionHandler;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildOfflineHeader(context),
          Expanded(child: _buildOfflineContentSection(context)),
          _buildOfflineActionSection(context),
        ],
      ),
    );
  }

  Widget _buildOfflineHeader(BuildContext context) {
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
                  fontSize:
                      Theme.of(context).textTheme.labelMedium!.fontSize! *
                      ResponsiveService.getFontSizeMultiplier(context) *
                      1.1,
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
            "OFFLINE",
            Icons.cloud_off,
            AppTheme.getTextTertiary(context),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(
    BuildContext context,
    String text,
    IconData icon,
    Color color,
  ) {
    final spacing = ResponsiveService.getTinySpacing(context);
    final iconSize = ResponsiveService.getIconSize(context, baseSize: 12);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: spacing * 2, vertical: spacing),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(
          ResponsiveService.getBorderRadius(context) / 2,
        ),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: color),
          SizedBox(width: spacing),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineContentSection(BuildContext context) {
    // Use rich content if available, otherwise fall back to basic content
    if (cachedContent.fullContent != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: ResponsiveService.getMediumSpacing(context)),
          // Title
          Flexible(
            child: Text(
              cachedContent.title,
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
                content: cachedContent.fullContent!,
                onLinkTap: (url, linkText) {
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
          _buildTopicBadge(context, cachedContent.topicCategory),
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
            cachedContent.title,
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
            cachedContent.summary,
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
        _buildTopicBadge(context, cachedContent.topicCategory),
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

  Widget _buildOfflineActionSection(BuildContext context) {
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
              cachedContent.readingTimeText.isNotEmpty
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
                          cachedContent.readingTimeText,
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

        // Action button (no momentum for offline content)
        Flexible(
          child: ElevatedButton.icon(
            onPressed: interactionHandler.onTap,
            icon: Icon(Icons.arrow_forward, size: iconSize),
            label: const Text("Read More"),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(100, buttonHeight),
              padding: ResponsiveService.getHorizontalPadding(
                context,
                multiplier: 0.75,
              ),
              textStyle: _getButtonTextStyle(context),
            ),
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

/// Fallback state widget for Today Feed tile
/// Displays fallback content with appropriate warnings and indicators
class TodayFeedFallbackStateWidget extends StatelessWidget {
  const TodayFeedFallbackStateWidget({
    super.key,
    required this.fallbackResult,
    required this.interactionHandler,
  });

  final TodayFeedFallbackResult fallbackResult;
  final TodayFeedInteractionHandler interactionHandler;

  @override
  Widget build(BuildContext context) {
    // Calculate opacity based on content staleness
    final opacity = fallbackResult.isStale ? 0.7 : 0.85;

    return Opacity(
      opacity: opacity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildFallbackHeader(context),
          if (fallbackResult.shouldShowAgeWarning) _buildAgeWarning(context),
          Expanded(child: _buildFallbackContent(context)),
          _buildFallbackActionSection(context),
        ],
      ),
    );
  }

  Widget _buildFallbackHeader(BuildContext context) {
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
                  fontSize:
                      Theme.of(context).textTheme.labelMedium!.fontSize! *
                      ResponsiveService.getFontSizeMultiplier(context) *
                      1.1,
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
            _getFallbackStatusText(fallbackResult.fallbackType),
            _getFallbackStatusIcon(fallbackResult.fallbackType),
            _getFallbackStatusColor(fallbackResult.fallbackType),
          ),
        ),
      ],
    );
  }

  Widget _buildAgeWarning(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: ResponsiveService.getTinySpacing(context),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveService.getSmallSpacing(context),
        vertical: ResponsiveService.getTinySpacing(context),
      ),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(
          ResponsiveService.getBorderRadius(context) / 2,
        ),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            size: ResponsiveService.getIconSize(context, baseSize: 14),
            color: Colors.amber.shade700,
          ),
          SizedBox(width: ResponsiveService.getTinySpacing(context)),
          Expanded(
            child: Text(
              fallbackResult.userMessage,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.amber.shade700,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackContent(BuildContext context) {
    // Display content if available
    if (fallbackResult.content != null) {
      return _buildContentSection(context, fallbackResult.content!);
    }

    // No content available
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.content_paste_off,
          size: ResponsiveService.getIconSize(context, baseSize: 48),
          color: AppTheme.getTextTertiary(context),
        ),
        SizedBox(height: ResponsiveService.getLargeSpacing(context)),
        Text(
          "No cached content available",
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: ResponsiveService.getSmallSpacing(context)),
        Text(
          fallbackResult.userMessage,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.getTextSecondary(context),
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildContentSection(BuildContext context, TodayFeedContent content) {
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

  Widget _buildStatusBadge(
    BuildContext context,
    String text,
    IconData icon,
    Color color,
  ) {
    final spacing = ResponsiveService.getTinySpacing(context);
    final iconSize = ResponsiveService.getIconSize(context, baseSize: 12);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: spacing * 2, vertical: spacing),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(
          ResponsiveService.getBorderRadius(context) / 2,
        ),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: color),
          SizedBox(width: spacing),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
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

  Widget _buildFallbackActionSection(BuildContext context) {
    final iconSize = ResponsiveService.getIconSize(context, baseSize: 16);
    final buttonHeight =
        ResponsiveService.shouldUseCompactLayout(context)
            ? AccessibilityService.minimumTouchTarget - 12
            : AccessibilityService.minimumTouchTarget;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Reading time (if content available)
        Flexible(
          child:
              fallbackResult.content?.readingTimeText.isNotEmpty ?? false
                  ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule,
                        size: iconSize,
                        color: AppTheme.getTextTertiary(context),
                      ),
                      SizedBox(
                        width: ResponsiveService.getTinySpacing(context),
                      ),
                      Flexible(
                        child: Text(
                          fallbackResult.content!.readingTimeText,
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
          child:
              fallbackResult.content == null
                  ? ElevatedButton.icon(
                    onPressed: interactionHandler.onTap,
                    icon: Icon(Icons.refresh, size: iconSize),
                    label: const Text("Retry"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(80, buttonHeight),
                      padding: ResponsiveService.getHorizontalPadding(
                        context,
                        multiplier: 0.75,
                      ),
                      textStyle: _getButtonTextStyle(context),
                    ),
                  )
                  : ElevatedButton.icon(
                    onPressed: interactionHandler.onTap,
                    icon: Icon(Icons.arrow_forward, size: iconSize),
                    label: const Text("Read More"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(100, buttonHeight),
                      padding: ResponsiveService.getHorizontalPadding(
                        context,
                        multiplier: 0.75,
                      ),
                      textStyle: _getButtonTextStyle(context),
                    ),
                  ),
        ),
      ],
    );
  }

  // Helper methods for fallback types

  String _getFallbackStatusText(TodayFeedFallbackType fallbackType) {
    switch (fallbackType) {
      case TodayFeedFallbackType.previousDay:
        return "CACHED";
      case TodayFeedFallbackType.contentHistory:
        return "ARCHIVED";
      case TodayFeedFallbackType.none:
        return "NO CONTENT";
      case TodayFeedFallbackType.error:
        return "ERROR";
    }
  }

  IconData _getFallbackStatusIcon(TodayFeedFallbackType fallbackType) {
    switch (fallbackType) {
      case TodayFeedFallbackType.previousDay:
        return Icons.cached;
      case TodayFeedFallbackType.contentHistory:
        return Icons.archive;
      case TodayFeedFallbackType.none:
        return Icons.content_paste_off;
      case TodayFeedFallbackType.error:
        return Icons.error_outline;
    }
  }

  Color _getFallbackStatusColor(TodayFeedFallbackType fallbackType) {
    switch (fallbackType) {
      case TodayFeedFallbackType.previousDay:
        return Colors.blue;
      case TodayFeedFallbackType.contentHistory:
        return Colors.orange;
      case TodayFeedFallbackType.none:
      case TodayFeedFallbackType.error:
        return Colors.red;
    }
  }

  // Common helper methods

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
