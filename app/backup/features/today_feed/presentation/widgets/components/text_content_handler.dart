import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/responsive_service.dart';
import '../../../../../core/services/accessibility_service.dart';
import '../../../domain/models/today_feed_content.dart';

/// Handles rendering of text-based content elements
/// Supports paragraphs, headings, bullet lists, and numbered lists
class TextContentHandler extends StatelessWidget {
  final RichContentElement element;
  final bool isCompact;

  const TextContentHandler({
    super.key,
    required this.element,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    switch (element.type) {
      case RichContentType.paragraph:
        return _buildParagraph(context);
      case RichContentType.heading:
        return _buildHeading(context);
      case RichContentType.bulletList:
        return _buildBulletList(context);
      case RichContentType.numberedList:
        return _buildNumberedList(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildParagraph(BuildContext context) {
    return Semantics(
      label: 'Health information paragraph',
      child: Text(
        element.text,
        style: _getTextStyle(context).copyWith(
          fontSize: _getResponsiveFontSize(context, baseFontSize: 16),
          height: 1.5,
          color: AppTheme.getTextPrimary(context),
        ),
      ),
    );
  }

  Widget _buildHeading(BuildContext context) {
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

  Widget _buildBulletList(BuildContext context) {
    if (element.listItems == null || element.listItems!.isEmpty) {
      return _buildParagraph(context);
    }

    return Semantics(
      label: 'Bullet list: ${element.text}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (element.text.isNotEmpty) ...[
            Text(
              element.text,
              style: _getTextStyle(context).copyWith(
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

  Widget _buildNumberedList(BuildContext context) {
    if (element.listItems == null || element.listItems!.isEmpty) {
      return _buildParagraph(context);
    }

    return Semantics(
      label: 'Numbered list: ${element.text}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (element.text.isNotEmpty) ...[
            Text(
              element.text,
              style: _getTextStyle(context).copyWith(
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
