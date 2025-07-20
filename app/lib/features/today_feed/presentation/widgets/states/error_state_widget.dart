import 'package:flutter/material.dart';

import 'retry_cta.dart';
import 'today_feed_error_card.dart';

/// Error state for Today Feed now composed from smaller widgets.
/// Keeps file size < hard ceiling and improves readability.
class TodayFeedErrorStateWidget extends StatelessWidget {
  const TodayFeedErrorStateWidget({
    super.key,
    required this.errorMessage,
    this.onRetry,
    this.enableNetworkRetry = true,
  });

  final String errorMessage;
  final VoidCallback? onRetry;
  final bool enableNetworkRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TodayFeedErrorCard(errorMessage: errorMessage),
        const SizedBox(height: 12),
        RetryCta(
          errorMessage: errorMessage,
          onRetry: onRetry,
          enableNetworkRetry: enableNetworkRetry,
        ),
      ],
    );
  }
}
