import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/responsive_service.dart';
import '../../../../core/services/accessibility_service.dart';
import '../../domain/models/today_feed_content.dart';

/// Callback for external link taps
typedef OnLinkTapCallback = void Function(String url, String? linkText);

/// Rich content renderer for Today Feed health content
/// Supports structured content with headings, lists, tips, and external links
/// Implements Material Design 3 with full accessibility support
class RichContentRenderer extends StatelessWidget {
  final TodayFeedRichContent content;
  final OnLinkTapCallback? onLinkTap;
  final bool isCompact;
  final bool enableInteractions;

  const RichContentRenderer({
    super.key,
    required this.content,
    this.onLinkTap,
    this.isCompact = false,
    this.enableInteractions = true,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main content elements
          ...content.elements.map(
            (element) => _buildContentElement(context, element),
          ),

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
      ),
    );
  }

  Widget _buildContentElement(
    BuildContext context,
    RichContentElement element,
  ) {
    final spacing = ResponsiveService.getSmallSpacing(context);

    return Padding(
      padding: EdgeInsets.only(bottom: spacing),
      child: _renderElementByType(context, element),
    );
  }

  Widget _renderElementByType(
    BuildContext context,
    RichContentElement element,
  ) {
    switch (element.type) {
      case RichContentType.paragraph:
        return _buildParagraph(context, element);
      case RichContentType.heading:
        return _buildHeading(context, element);
      case RichContentType.bulletList:
        return _buildBulletList(context, element);
      case RichContentType.numberedList:
        return _buildNumberedList(context, element);
      case RichContentType.highlight:
        return _buildHighlight(context, element);
      case RichContentType.tip:
        return _buildTip(context, element);
      case RichContentType.warning:
        return _buildWarning(context, element);
      case RichContentType.externalLink:
        return _buildExternalLink(context, element);
    }
  }

  Widget _buildParagraph(BuildContext context, RichContentElement element) {
    return Semantics(
      label: 'Health information paragraph',
      child: Text(
        element.text,
        style: _getTextStyle(context, element).copyWith(
          fontSize: _getResponsiveFontSize(context, baseFontSize: 16),
          height: 1.5,
          color: AppTheme.getTextPrimary(context),
        ),
      ),
    );
  }

  Widget _buildHeading(BuildContext context, RichContentElement element) {
    return Semantics(
      header: true,
      label: 'Section heading: ${element.text}',
      child: Text(
        element.text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontSize: _getResponsiveFontSize(context, baseFontSize: 18),
          fontWeight: FontWeight.w600,
          color: AppTheme.getTextPrimary(context),
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildBulletList(BuildContext context, RichContentElement element) {
    if (element.listItems == null || element.listItems!.isEmpty) {
      return _buildParagraph(context, element);
    }

    return Semantics(
      label: 'Bullet list: ${element.text}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (element.text.isNotEmpty) ...[
            Text(
              element.text,
              style: _getTextStyle(context, element).copyWith(
                fontSize: _getResponsiveFontSize(context, baseFontSize: 16),
                fontWeight: FontWeight.w500,
                color: AppTheme.getTextPrimary(context),
              ),
            ),
            SizedBox(height: ResponsiveService.getTinySpacing(context)),
          ],
          ...element.listItems!.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Semantics(
              label:
                  'Bullet point ${index + 1} of ${element.listItems!.length}: $item',
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: ResponsiveService.getTinySpacing(context) * 0.5,
                  left: ResponsiveService.getSmallSpacing(context),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(
                        top:
                            _getResponsiveFontSize(context, baseFontSize: 16) *
                            0.4,
                        right: ResponsiveService.getTinySpacing(context),
                      ),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.momentumRising,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
    );
  }

  Widget _buildNumberedList(BuildContext context, RichContentElement element) {
    if (element.listItems == null || element.listItems!.isEmpty) {
      return _buildParagraph(context, element);
    }

    return Semantics(
      label: 'Numbered list: ${element.text}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (element.text.isNotEmpty) ...[
            Text(
              element.text,
              style: _getTextStyle(context, element).copyWith(
                fontSize: _getResponsiveFontSize(context, baseFontSize: 16),
                fontWeight: FontWeight.w500,
                color: AppTheme.getTextPrimary(context),
              ),
            ),
            SizedBox(height: ResponsiveService.getTinySpacing(context)),
          ],
          ...element.listItems!.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Semantics(
              label: 'Step ${index + 1} of ${element.listItems!.length}: $item',
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: ResponsiveService.getTinySpacing(context) * 0.5,
                  left: ResponsiveService.getSmallSpacing(context),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(
                        right: ResponsiveService.getTinySpacing(context),
                      ),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppTheme.momentumRising.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.momentumRising,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: _getResponsiveFontSize(
                              context,
                              baseFontSize: 12,
                            ),
                            fontWeight: FontWeight.w600,
                            color: AppTheme.momentumRising,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
    );
  }

  Widget _buildHighlight(BuildContext context, RichContentElement element) {
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
                style: _getTextStyle(context, element).copyWith(
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

  Widget _buildTip(BuildContext context, RichContentElement element) {
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
                style: _getTextStyle(context, element).copyWith(
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

  Widget _buildWarning(BuildContext context, RichContentElement element) {
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
                style: _getTextStyle(context, element).copyWith(
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

  Widget _buildExternalLink(BuildContext context, RichContentElement element) {
    final linkText = element.linkText ?? 'Learn More →';

    return Semantics(
      label: 'External link: ${element.text}',
      hint: 'Double tap to open link',
      button: true,
      child: InkWell(
        onTap:
            enableInteractions && onLinkTap != null
                ? () {
                  HapticFeedback.lightImpact();
                  onLinkTap!(element.linkUrl ?? '', linkText);
                }
                : null,
        borderRadius: BorderRadius.circular(
          ResponsiveService.getBorderRadius(context),
        ),
        child: Container(
          padding: ResponsiveService.getResponsivePadding(context) * 0.75,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(
              ResponsiveService.getBorderRadius(context),
            ),
            border: Border.all(
              color: Colors.blue.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (element.text.isNotEmpty) ...[
                Text(
                  element.text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: _getResponsiveFontSize(context, baseFontSize: 15),
                    height: 1.4,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
                SizedBox(height: ResponsiveService.getTinySpacing(context)),
              ],
              Row(
                children: [
                  Icon(
                    Icons.open_in_new,
                    size: ResponsiveService.getIconSize(context, baseSize: 16),
                    color: Colors.blue.shade600,
                  ),
                  SizedBox(width: ResponsiveService.getTinySpacing(context)),
                  Expanded(
                    child: Text(
                      linkText,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: _getResponsiveFontSize(
                          context,
                          baseFontSize: 14,
                        ),
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
                        decoration: BoxDecoration(
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

  // Helper methods

  TextStyle _getTextStyle(BuildContext context, RichContentElement element) {
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
