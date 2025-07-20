import 'package:flutter/material.dart';

import '../../../../../core/services/responsive_service.dart';
import '../../../../../core/theme/app_theme.dart';
import 'error_utils.dart';

/// Compact display-only card showing an error header, message and suggestions.
class TodayFeedErrorCard extends StatelessWidget {
  const TodayFeedErrorCard({super.key, required this.errorMessage});

  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    final (errorTitle, errorIcon, suggestions) = getErrorDetails(errorMessage);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Header(errorMessage: errorMessage),
        const SizedBox(height: 8),
        Icon(
          errorIcon,
          size: ResponsiveService.getIconSize(context, baseSize: 40),
          color: getErrorColor(errorMessage, context),
        ),
        const SizedBox(height: 4),
        Text(
          errorTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.getTextPrimary(context),
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          errorMessage,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.getTextSecondary(context),
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          _InlineSuggestions(suggestions: suggestions),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.errorMessage});
  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveService.getTinySpacing(context);
    final (statusText, statusIcon, statusColor) = getErrorStatus(errorMessage);
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
              SizedBox(height: spacing / 2),
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
        SizedBox(width: spacing),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: spacing * 2,
            vertical: spacing,
          ),
          decoration: BoxDecoration(
            color: statusColor.withAlpha(25),
            borderRadius: BorderRadius.circular(
              ResponsiveService.getBorderRadius(context) / 2,
            ),
            border: Border.all(
              color: AppTheme.getTextTertiary(context).withAlpha(77),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                statusIcon,
                size: ResponsiveService.getIconSize(context, baseSize: 12),
                color: statusColor,
              ),
              SizedBox(width: spacing),
              Text(
                statusText,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
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
}

class _InlineSuggestions extends StatelessWidget {
  const _InlineSuggestions({required this.suggestions});
  final List<String> suggestions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveService.getSmallPadding(context),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceSecondary(context),
        borderRadius: BorderRadius.circular(
          ResponsiveService.getBorderRadius(context),
        ),
        border: Border.all(
          color: AppTheme.getTextTertiary(context).withAlpha(77),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: ResponsiveService.getIconSize(context, baseSize: 14),
                color: AppTheme.momentumSteady,
              ),
              SizedBox(width: ResponsiveService.getTinySpacing(context)),
              Text(
                'Tips:',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.momentumSteady,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveService.getTinySpacing(context)),
          ...suggestions
              .take(2)
              .map(
                (s) => Padding(
                  padding: EdgeInsets.only(
                    bottom: ResponsiveService.getTinySpacing(context) / 2,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.getTextSecondary(context),
                          fontSize: 10,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          s,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: AppTheme.getTextSecondary(context),
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
