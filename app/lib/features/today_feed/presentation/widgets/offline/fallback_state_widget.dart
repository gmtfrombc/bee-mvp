import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/responsive_service.dart';
import '../../../../../core/services/accessibility_service.dart';
import '../../../domain/models/today_feed_content.dart';
import '../components/today_feed_interactions.dart';

import 'components/status_badge.dart';
import 'components/topic_badge.dart';

/// Fallback state widget for Today Feed tile (refactored).
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
    final opacity = fallbackResult.isStale ? 0.7 : 0.85;
    return Opacity(
      opacity: opacity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _FallbackHeader(result: fallbackResult),
          if (fallbackResult.shouldShowAgeWarning)
            _AgeWarningBanner(text: fallbackResult.userMessage),
          Expanded(child: _FallbackContent(result: fallbackResult)),
          _FallbackActionSection(
            result: fallbackResult,
            handler: interactionHandler,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── HEADER ───────────────────────────
class _FallbackHeader extends StatelessWidget {
  const _FallbackHeader({required this.result});

  final TodayFeedFallbackResult result;

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
        StatusBadge(
          text: _getStatusText(result.fallbackType),
          icon: _getStatusIcon(result.fallbackType),
          color: _getStatusColor(result.fallbackType),
        ),
      ],
    );
  }
}

// ─────────────────── AGE WARNING ───────────────────
class _AgeWarningBanner extends StatelessWidget {
  const _AgeWarningBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
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
              text,
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
}

// ────────────────── CONTENT ──────────────────
class _FallbackContent extends StatelessWidget {
  const _FallbackContent({required this.result});

  final TodayFeedFallbackResult result;

  @override
  Widget build(BuildContext context) {
    if (result.content != null) {
      return _ContentSection(content: result.content!);
    }
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
          'No cached content available',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: ResponsiveService.getSmallSpacing(context)),
        Text(
          result.userMessage,
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
}

class _ContentSection extends StatelessWidget {
  const _ContentSection({required this.content});

  final TodayFeedContent content;

  @override
  Widget build(BuildContext context) {
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

// ────────────────── ACTIONS ──────────────────
class _FallbackActionSection extends StatelessWidget {
  const _FallbackActionSection({required this.result, required this.handler});

  final TodayFeedFallbackResult result;
  final TodayFeedInteractionHandler handler;

  @override
  Widget build(BuildContext context) {
    final iconSize = ResponsiveService.getIconSize(context, baseSize: 16);
    final buttonHeight =
        ResponsiveService.shouldUseCompactLayout(context)
            ? AccessibilityService.minimumTouchTarget - 12
            : AccessibilityService.minimumTouchTarget;

    final hasContent = result.content != null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child:
              hasContent && result.content!.readingTimeText.isNotEmpty
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
                          result.content!.readingTimeText,
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
            icon: Icon(
              hasContent ? Icons.arrow_forward : Icons.refresh,
              size: iconSize,
            ),
            label: Text(hasContent ? 'Read More' : 'Retry'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(hasContent ? 100 : 80, buttonHeight),
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

// ────────────────── HELPERS ──────────────────
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

String _getStatusText(TodayFeedFallbackType type) {
  switch (type) {
    case TodayFeedFallbackType.previousDay:
      return 'CACHED';
    case TodayFeedFallbackType.contentHistory:
      return 'ARCHIVED';
    case TodayFeedFallbackType.none:
      return 'NO CONTENT';
    case TodayFeedFallbackType.error:
      return 'ERROR';
  }
}

IconData _getStatusIcon(TodayFeedFallbackType type) {
  switch (type) {
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

Color _getStatusColor(TodayFeedFallbackType type) {
  switch (type) {
    case TodayFeedFallbackType.previousDay:
      return Colors.blue;
    case TodayFeedFallbackType.contentHistory:
      return Colors.orange;
    case TodayFeedFallbackType.none:
    case TodayFeedFallbackType.error:
      return Colors.red;
  }
}
