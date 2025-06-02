import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/responsive_service.dart';

/// Loading state widget for Today Feed tile
/// Displays animated shimmer placeholders while content loads
/// **OPTIMIZED**: Enhanced with RepaintBoundary for 60fps performance
class TodayFeedLoadingStateWidget extends StatelessWidget {
  const TodayFeedLoadingStateWidget({
    super.key,
    required this.shimmerAnimation,
  });

  final Animation<double> shimmerAnimation;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildLoadingHeader(context),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildShimmerBox(
                  context,
                  height: _getTitleHeight(context),
                  width: double.infinity,
                ),
                SizedBox(height: ResponsiveService.getSmallSpacing(context)),
                _buildShimmerBox(
                  context,
                  height: _getBodyHeight(context),
                  width: double.infinity,
                ),
                SizedBox(height: ResponsiveService.getTinySpacing(context)),
                _buildShimmerBox(
                  context,
                  height: _getBodyHeight(context),
                  width: _getPartialWidth(context),
                ),
                SizedBox(height: ResponsiveService.getMediumSpacing(context)),
                _buildShimmerBox(
                  context,
                  height: _getBadgeHeight(context),
                  width: _getBadgeWidth(context),
                ),
              ],
            ),
          ),
          _buildLoadingActionSection(context),
        ],
      ),
    );
  }

  Widget _buildLoadingHeader(BuildContext context) {
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
        Flexible(child: _buildStatusBadge(context, "Loading...")),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context, String text) {
    final spacing = ResponsiveService.getTinySpacing(context);
    final badgeColor = AppTheme.getTextTertiary(context);

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

  Widget _buildLoadingActionSection(BuildContext context) {
    final iconSize = ResponsiveService.getIconSize(context, baseSize: 16);
    final buttonHeight =
        ResponsiveService.shouldUseCompactLayout(context) ? 36.0 : 44.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Reading time placeholder
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule,
                size: iconSize,
                color: AppTheme.getTextTertiary(context),
              ),
              SizedBox(width: ResponsiveService.getTinySpacing(context)),
              Flexible(
                child: Text(
                  "-- min read",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.getTextTertiary(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // Loading button placeholder
        Flexible(
          child: SizedBox(
            width: 100,
            height: buttonHeight,
            child: _buildShimmerBox(context, height: buttonHeight, width: 100),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerBox(
    BuildContext context, {
    required double height,
    required double width,
  }) {
    // Performance optimization: Use RepaintBoundary and efficient gradient calculation
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: shimmerAnimation,
        builder: (context, child) {
          final shimmerValue = shimmerAnimation.value;
          return Container(
            height: height,
            width: width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                ResponsiveService.getBorderRadius(context) / 4,
              ),
              gradient: LinearGradient(
                colors: [
                  AppTheme.getTextTertiary(context).withValues(alpha: 0.3),
                  AppTheme.getTextTertiary(context).withValues(alpha: 0.1),
                  AppTheme.getTextTertiary(context).withValues(alpha: 0.3),
                ],
                stops: [
                  (shimmerValue - 0.3).clamp(0.0, 1.0),
                  shimmerValue.clamp(0.0, 1.0),
                  (shimmerValue + 0.3).clamp(0.0, 1.0),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper methods for responsive measurements

  double _getTitleHeight(BuildContext context) {
    final baseSize = 20.0;
    final responsiveMultiplier = ResponsiveService.getFontSizeMultiplier(
      context,
    );
    return baseSize * responsiveMultiplier * 1.2;
  }

  double _getBodyHeight(BuildContext context) {
    final baseSize = 16.0;
    final responsiveMultiplier = ResponsiveService.getFontSizeMultiplier(
      context,
    );
    return baseSize * responsiveMultiplier * 1.4;
  }

  double _getBadgeHeight(BuildContext context) {
    final baseSize = 12.0;
    final responsiveMultiplier = ResponsiveService.getFontSizeMultiplier(
      context,
    );
    return baseSize * responsiveMultiplier * 1.3 +
        (ResponsiveService.getTinySpacing(context) * 2);
  }

  double _getBadgeWidth(BuildContext context) =>
      ResponsiveService.getResponsiveSpacing(context) * 4;

  double _getPartialWidth(BuildContext context) =>
      MediaQuery.of(context).size.width * 0.6;

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
