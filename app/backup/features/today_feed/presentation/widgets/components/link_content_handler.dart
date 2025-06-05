import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/responsive_service.dart';
import '../../../../../core/services/accessibility_service.dart';
import '../../../domain/models/today_feed_content.dart';

/// Callback for external link taps
typedef OnLinkTapCallback = void Function(String url, String? linkText);

/// Handles rendering of external link content elements
/// Supports interactive links with visual styling and haptic feedback
class LinkContentHandler extends StatelessWidget {
  final RichContentElement element;
  final OnLinkTapCallback? onLinkTap;
  final bool enableInteractions;
  final bool isCompact;

  const LinkContentHandler({
    super.key,
    required this.element,
    this.onLinkTap,
    this.enableInteractions = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (element.type != RichContentType.externalLink) {
      return const SizedBox.shrink();
    }

    return _buildExternalLink(context);
  }

  Widget _buildExternalLink(BuildContext context) {
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
