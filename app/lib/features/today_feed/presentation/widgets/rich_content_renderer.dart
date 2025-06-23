import 'package:flutter/material.dart';
import '../../../../core/services/responsive_service.dart';
import '../../domain/models/today_feed_content.dart';
import 'components/text_content_handler.dart';
import 'components/special_content_handler.dart';
import 'components/link_content_handler.dart';
import 'components/section_content_handler.dart';

/// Callback for external link taps
typedef OnLinkTapCallback = void Function(String url, String? linkText);

/// Rich content renderer for Today Feed health content
/// Supports structured content with headings, lists, tips, and external links
/// Implements Material Design 3 with full accessibility support
///
/// Refactored to use extracted content handler components for better maintainability
class RichContentRenderer extends StatelessWidget {
  final TodayFeedRichContent content;
  final OnLinkTapCallback? onLinkTap;
  final bool isCompact;
  final bool enableInteractions;
  final bool includeBulletList;

  const RichContentRenderer({
    super.key,
    required this.content,
    this.onLinkTap,
    this.isCompact = false,
    this.enableInteractions = true,
    this.includeBulletList = true,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main content elements using extracted handlers
          ...content.elements.map(
            (element) => _buildContentElement(context, element),
          ),

          // Section content (key takeaways, actionable advice, source reference)
          SectionContentHandler(content: content, isCompact: isCompact),
        ],
      ),
    );
  }

  Widget _buildContentElement(
    BuildContext context,
    RichContentElement element,
  ) {
    if (!includeBulletList && element.type == RichContentType.bulletList) {
      return const SizedBox.shrink();
    }
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
    // Route to appropriate content handler based on element type
    switch (element.type) {
      case RichContentType.paragraph:
      case RichContentType.heading:
      case RichContentType.bulletList:
      case RichContentType.numberedList:
        return TextContentHandler(element: element, isCompact: isCompact);

      case RichContentType.highlight:
      case RichContentType.tip:
      case RichContentType.warning:
        return SpecialContentHandler(element: element, isCompact: isCompact);

      case RichContentType.externalLink:
        return LinkContentHandler(
          element: element,
          onLinkTap: onLinkTap,
          enableInteractions: enableInteractions,
          isCompact: isCompact,
        );
    }
  }
}
