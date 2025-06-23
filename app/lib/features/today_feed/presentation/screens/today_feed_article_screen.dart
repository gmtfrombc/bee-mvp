import 'package:flutter/material.dart';
import 'package:app/features/today_feed/domain/models/today_feed_content.dart';
import 'package:app/features/today_feed/presentation/widgets/rich_content_renderer.dart';
import 'package:app/features/today_feed/presentation/widgets/article_header.dart';
import 'package:app/core/services/responsive_service.dart';

/// Screen that shows the full daily-feed article
class TodayFeedArticleScreen extends StatelessWidget {
  const TodayFeedArticleScreen({super.key, required this.content});

  final TodayFeedContent content;

  @override
  Widget build(BuildContext context) {
    final hasArticle = content.fullContent != null;
    final EdgeInsets padding = ResponsiveService.getResponsivePadding(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Insight')),
      body: SingleChildScrollView(
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ArticleHeader(content: content),
              hasArticle
                  ? RichContentRenderer(
                    content: content.fullContent!,
                    enableInteractions: true,
                    isCompact: false,
                    includeBulletList: false,
                  )
                  : Text(
                    content.summary,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
