import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/responsive_service.dart';
import '../../../../../core/services/accessibility_service.dart';
import '../../../domain/models/today_feed_content.dart';

/// Handles rendering of special content elements
/// Supports highlights, tips, and warnings with visual styling
class SpecialContentHandler extends StatelessWidget {
  final RichContentElement element;
  final bool isCompact;

  const SpecialContentHandler({
    super.key,
    required this.element,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    switch (element.type) {
      case RichContentType.highlight:
        return _buildHighlight(context);
      case RichContentType.tip:
        return _buildTip(context);
      case RichContentType.warning:
        return _buildWarning(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHighlight(BuildContext context) {
    return Semantics(
      label: 'Highlighted information: ${element.text}',
      child: Container(
        padding: ResponsiveService.getResponsivePadding(context) * 0.75,
        decoration: BoxDecoration(
          color: AppTheme.momentumRising.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(
            ResponsiveService.getBorderRadius(context),
          ),
          border: Border.all(
            color: AppTheme.momentumRising.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: ResponsiveService.getIconSize(context, baseSize: 20),
              color: AppTheme.momentumRising,
            ),
            SizedBox(width: ResponsiveService.getTinySpacing(context)),
            Expanded(
              child: Text(
                element.text,
                style: _getTextStyle(context).copyWith(
                  fontSize: _getResponsiveFontSize(context, baseFontSize: 15),
                  height: 1.4,
                  color: AppTheme.getTextPrimary(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(BuildContext context) {
    return Semantics(
      label: 'Health tip: ${element.text}',
      child: Container(
        padding: ResponsiveService.getResponsivePadding(context) * 0.75,
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(
            ResponsiveService.getBorderRadius(context),
          ),
          border: Border.all(
            color: Colors.green.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.tips_and_updates_outlined,
              size: ResponsiveService.getIconSize(context, baseSize: 20),
              color: Colors.green.shade600,
            ),
            SizedBox(width: ResponsiveService.getTinySpacing(context)),
            Expanded(
              child: Text(
                element.text,
                style: _getTextStyle(context).copyWith(
                  fontSize: _getResponsiveFontSize(context, baseFontSize: 15),
                  height: 1.4,
                  color: AppTheme.getTextPrimary(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarning(BuildContext context) {
    return Semantics(
      label: 'Important health information: ${element.text}',
      child: Container(
        padding: ResponsiveService.getResponsivePadding(context) * 0.75,
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(
            ResponsiveService.getBorderRadius(context),
          ),
          border: Border.all(
            color: Colors.orange.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_outlined,
              size: ResponsiveService.getIconSize(context, baseSize: 20),
              color: Colors.orange.shade600,
            ),
            SizedBox(width: ResponsiveService.getTinySpacing(context)),
            Expanded(
              child: Text(
                element.text,
                style: _getTextStyle(context).copyWith(
                  fontSize: _getResponsiveFontSize(context, baseFontSize: 15),
                  height: 1.4,
                  color: AppTheme.getTextPrimary(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  TextStyle _getTextStyle(BuildContext context) {
    TextStyle baseStyle = Theme.of(context).textTheme.bodyMedium!;

    if (element.isBold) {
      baseStyle = baseStyle.copyWith(fontWeight: FontWeight.w600);
    }

    if (element.isItalic) {
      baseStyle = baseStyle.copyWith(fontStyle: FontStyle.italic);
    }

    return baseStyle;
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
