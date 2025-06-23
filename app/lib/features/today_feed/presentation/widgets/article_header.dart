import 'package:flutter/material.dart';
import 'package:app/features/today_feed/domain/models/today_feed_content.dart';
import 'package:app/core/services/responsive_service.dart';
import 'package:app/core/theme/app_theme.dart';
import 'article_actions.dart';

/// Displays the hero/banner image and title for an article.
///
/// Falls back to a solid color container if the image fails to load.
class ArticleHeader extends StatelessWidget {
  const ArticleHeader({super.key, required this.content});

  final TodayFeedContent content;

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveService.getSmallSpacing(context);
    final double imageHeight =
        ResponsiveService.getQuickStatsCardHeight(context) * 2;
    final double halfSpacing = spacing * 0.5;

    // Local topic-based placeholder asset path (PNG files expected at this path)
    final String placeholderAsset =
        'assets/images/placeholders/${content.topicCategory.value}.png';

    // Determine if we have a specific network image for this article
    final String? networkUrl =
        content.contentUrl?.isNotEmpty == true ? content.contentUrl : null;

    Widget heroImage;
    if (networkUrl != null) {
      heroImage = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FadeInImage.assetNetwork(
          placeholder: placeholderAsset,
          image: networkUrl,
          width: double.infinity,
          height: imageHeight,
          fit: BoxFit.cover,
          placeholderErrorBuilder:
              (_, __, ___) => _fallbackContainer(context, imageHeight),
          imageErrorBuilder:
              (_, __, ___) => _fallbackContainer(context, imageHeight),
        ),
      );
    } else {
      heroImage = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          placeholderAsset,
          width: double.infinity,
          height: imageHeight,
          fit: BoxFit.cover,
          errorBuilder:
              (_, __, ___) => _fallbackContainer(context, imageHeight),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heroImage,
        SizedBox(height: spacing),
        SizedBox(height: halfSpacing),
        // Title
        Text(
          content.title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: spacing * 0.5),
        // Icons row left-aligned
        ArticleActions(content: content),
        SizedBox(height: halfSpacing),
      ],
    );
  }

  Widget _fallbackContainer(BuildContext context, double height) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkSurfaceTertiary
                : AppTheme.surfaceTertiary,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
