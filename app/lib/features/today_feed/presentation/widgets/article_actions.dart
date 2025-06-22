import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:app/features/today_feed/domain/models/today_feed_content.dart';
import 'package:app/core/services/responsive_service.dart';
import 'package:app/core/theme/app_theme.dart';

/// Floating action buttons for sharing and bookmarking an article.
class ArticleActions extends StatelessWidget {
  const ArticleActions({super.key, required this.content});

  final TodayFeedContent content;

  void _onShare(BuildContext context) {
    final String body =
        content.externalLink?.isNotEmpty == true
            ? '${content.title}\n\nRead more: ${content.externalLink}'
            : '${content.title}\n\n${content.summary}';
    Share.share(body, subject: content.title);
  }

  void _onBookmark(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bookmark feature coming soon ✨')),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color shareColor = AppTheme.momentumRising;
    final Color bookmarkColor = Theme.of(context).colorScheme.secondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _actionIcon(
          context,
          icon: Icons.share,
          color: shareColor,
          onTap: () => _onShare(context),
          tooltip: 'Share',
        ),
        SizedBox(width: ResponsiveService.getTinySpacing(context)),
        _actionIcon(
          context,
          icon: Icons.bookmark_add_outlined,
          color: bookmarkColor,
          onTap: () => _onBookmark(context),
          tooltip: 'Bookmark',
        ),
      ],
    );
  }

  Widget _actionIcon(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Semantics(
      label: tooltip,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.all(ResponsiveService.getTinySpacing(context)),
          child: Icon(icon, color: color),
        ),
      ),
    );
  }
}
