import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/responsive_service.dart';
import '../../../../../core/services/accessibility_service.dart';
import '../../../domain/models/today_feed_content.dart';

/// Handles rendering of section content elements
/// Supports key takeaways, actionable advice, and source references
class SectionContentHandler extends StatelessWidget {
  final TodayFeedRichContent content;
  final bool isCompact;

  const SectionContentHandler({
    super.key,
    required this.content,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Key takeaways section
        if (content.keyTakeaways.isNotEmpty) ...[
          SizedBox(height: ResponsiveService.getLargeSpacing(context)),
          _buildKeyTakeaways(context),
        ],

        // Actionable advice section
        if (content.actionableAdvice != null) ...[
          SizedBox(height: ResponsiveService.getMediumSpacing(context)),
          _buildActionableAdvice(context),
        ],

        // Source reference
        if (content.sourceReference != null) ...[
          SizedBox(height: ResponsiveService.getSmallSpacing(context)),
          _buildSourceReference(context),
        ],
      ],
    );
  }

  Widget _buildKeyTakeaways(BuildContext context) {
    return Semantics(
      label: 'Key takeaways from this health insight',
      child: Container(
        padding: ResponsiveService.getResponsivePadding(context),
        decoration: BoxDecoration(
          color: AppTheme.getSurfacePrimary(context),
          borderRadius: BorderRadius.circular(
            ResponsiveService.getBorderRadius(context),
          ),
          border: Border.all(
            color: AppTheme.getTextTertiary(context).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.key,
                  size: ResponsiveService.getIconSize(context, baseSize: 18),
                  color: AppTheme.momentumRising,
                ),
                SizedBox(width: ResponsiveService.getTinySpacing(context)),
                Expanded(
                  child: Text(
                    'Key Takeaways',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: _getResponsiveFontSize(
                        context,
                        baseFontSize: 16,
                      ),
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getTextPrimary(context),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveService.getSmallSpacing(context)),
            ...content.keyTakeaways.asMap().entries.map((entry) {
              final index = entry.key;
              final takeaway = entry.value;
              return Semantics(
                label:
                    'Key takeaway ${index + 1} of ${content.keyTakeaways.length}: $takeaway',
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: ResponsiveService.getTinySpacing(context),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.only(
                          top:
                              _getResponsiveFontSize(
                                context,
                                baseFontSize: 15,
                              ) *
                              0.3,
                          right: ResponsiveService.getTinySpacing(context),
                        ),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppTheme.momentumRising,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          takeaway,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            fontSize: _getResponsiveFontSize(
                              context,
                              baseFontSize: 15,
                            ),
                            height: 1.4,
                            color: AppTheme.getTextSecondary(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionableAdvice(BuildContext context) {
    return Semantics(
      label: 'Actionable advice: ${content.actionableAdvice}',
      child: Container(
        padding: ResponsiveService.getResponsivePadding(context),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.momentumRising.withValues(alpha: 0.1),
              AppTheme.momentumRising.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(
            ResponsiveService.getBorderRadius(context),
          ),
          border: Border.all(
            color: AppTheme.momentumRising.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.rocket_launch,
                  size: ResponsiveService.getIconSize(context, baseSize: 18),
                  color: AppTheme.momentumRising,
                ),
                SizedBox(width: ResponsiveService.getTinySpacing(context)),
                Expanded(
                  child: Text(
                    'Take Action',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: _getResponsiveFontSize(
                        context,
                        baseFontSize: 16,
                      ),
                      fontWeight: FontWeight.w600,
                      color: AppTheme.momentumRising,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveService.getSmallSpacing(context)),
            Text(
              content.actionableAdvice!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: _getResponsiveFontSize(context, baseFontSize: 15),
                height: 1.4,
                color: AppTheme.getTextPrimary(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceReference(BuildContext context) {
    return Semantics(
      label: 'Source reference: ${content.sourceReference}',
      child: Text(
        content.sourceReference!,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: _getResponsiveFontSize(context, baseFontSize: 12),
          color: AppTheme.getTextTertiary(context),
          fontStyle: FontStyle.italic,
          height: 1.3,
        ),
      ),
    );
  }

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
    final compactMultiplier = isCompact ? 0.9 : 1.0;

    return baseFontSize *
        responsiveMultiplier *
        accessibleScale *
        compactMultiplier;
  }
}
