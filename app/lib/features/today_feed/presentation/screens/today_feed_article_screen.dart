import 'package:flutter/material.dart';
import '../../domain/models/today_feed_content.dart';
import '../widgets/rich_content_renderer.dart';
import '../../../../core/services/responsive_service.dart';

/// Screen that shows the full daily-feed article
class TodayFeedArticleScreen extends StatelessWidget {
  const TodayFeedArticleScreen({super.key, required this.content});

  final TodayFeedContent content;

  @override
  Widget build(BuildContext context) {
    final hasArticle = content.fullContent != null;
    return Scaffold(
      appBar: AppBar(title: const Text("Daily Insight")),
      body: Padding(
        padding: ResponsiveService.getResponsivePadding(context),
        child:
            hasArticle
                ? RichContentRenderer(
                  content: content.fullContent!,
                  enableInteractions: true,
                  isCompact: false,
                )
                : Center(
                  child: Text(
                    "We're just writing something up — check back soon!",
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
      ),
    );
  }
}
