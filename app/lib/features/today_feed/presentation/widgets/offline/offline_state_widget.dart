import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/responsive_service.dart';
import '../../../../../core/services/accessibility_service.dart';
import '../../../domain/models/today_feed_content.dart';
import '../rich_content_renderer.dart';
import '../interactions/today_feed_interactions.dart';

import 'components/status_badge.dart';
import 'components/topic_badge.dart';

/// Offline state widget for Today Feed tile (refactored).
/// Shows cached content with an OFFLINE indicator.
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
          _OfflineHeader(onlineDate: DateTime.now()),
          Expanded(
            child: _OfflineContentSection(
              content: cachedContent,
              handler: interactionHandler,
            ),
          ),
          _OfflineActionSection(
            content: cachedContent,
            handler: interactionHandler,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── ≫ HEADER ≪ ───────────────────────────
class _OfflineHeader extends StatelessWidget {
  const _OfflineHeader({required this.onlineDate});

  final DateTime onlineDate;

  @override
  Widget build(BuildContext context) {
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
                _formatDate(onlineDate),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.getTextTertiary(context),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        SizedBox(width: ResponsiveService.getTinySpacing(context)),
        const StatusBadge(
          text: 'OFFLINE',
          icon: Icons.cloud_off,
          color: Colors.grey,
        ),
      ],
    );
  }
}

// ──────────────────────── ≫ CONTENT SECTION ≪ ────────────────────────
class _OfflineContentSection extends StatelessWidget {
  const _OfflineContentSection({required this.content, required this.handler});

  final TodayFeedContent content;
  final TodayFeedInteractionHandler handler;

  @override
  Widget build(BuildContext context) {
    final hasRich = content.fullContent != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: ResponsiveService.getMediumSpacing(context)),
        Flexible(
          child: Text(
            content.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: _getResponsiveFontSize(context, 20),
              fontWeight: FontWeight.w600,
              height: 1.2,
              letterSpacing: -0.3,
            ),
            maxLines: _getMaxTitleLines(context),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(height: ResponsiveService.getSmallSpacing(context)),
        if (hasRich)
          Flexible(
            flex: 3,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: RichContentRenderer(
                content: content.fullContent!,
                isCompact: true,
                enableInteractions: true,
                onLinkTap:
                    (url, linkText) =>
                        handler.handleExternalLinkTap(context, url, linkText),
              ),
            ),
          )
        else
          Flexible(
            flex: 2,
            child: Text(
              content.summary,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: _getResponsiveFontSize(context, 16),
                height: 1.4,
                letterSpacing: 0.1,
                color: AppTheme.getTextSecondary(context),
              ),
              maxLines: _getMaxSummaryLines(context),
              overflow: TextOverflow.fade,
            ),
          ),
        SizedBox(height: ResponsiveService.getSmallSpacing(context)),
        TopicBadge(topic: content.topicCategory),
      ],
    );
  }
}

// ──────────────────────── ≫ ACTION SECTION ≪ ────────────────────────
class _OfflineActionSection extends StatelessWidget {
  const _OfflineActionSection({required this.content, required this.handler});

  final TodayFeedContent content;
  final TodayFeedInteractionHandler handler;

  @override
  Widget build(BuildContext context) {
    final iconSize = ResponsiveService.getIconSize(context, baseSize: 16);
    final spacing = ResponsiveService.getTinySpacing(context);
    final buttonHeight =
        ResponsiveService.shouldUseCompactLayout(context)
            ? AccessibilityService.minimumTouchTarget - 12
            : AccessibilityService.minimumTouchTarget;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
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
        Flexible(
          child: ElevatedButton.icon(
            onPressed: handler.onTap,
            icon: Icon(Icons.arrow_forward, size: iconSize),
            label: const Text('Read More'),
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
}

// ─────────────────────────── ≫ HELPERS ≪ ───────────────────────────

double _getResponsiveFontSize(BuildContext context, double base) {
  final accessibleScale = AccessibilityService.getAccessibleTextScale(context);
  final responsiveMultiplier = ResponsiveService.getFontSizeMultiplier(context);
  return base * responsiveMultiplier * accessibleScale;
}

int _getMaxTitleLines(BuildContext context) =>
    ResponsiveService.shouldUseCompactLayout(context) ? 2 : 3;

int _getMaxSummaryLines(BuildContext context) =>
    ResponsiveService.shouldUseCompactLayout(context) ? 3 : 4;

TextStyle _getButtonTextStyle(BuildContext context) {
  final base = ResponsiveService.shouldUseCompactLayout(context) ? 14.0 : 16.0;
  return TextStyle(
    fontSize: _getResponsiveFontSize(context, base),
    fontWeight: FontWeight.w600,
  );
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
