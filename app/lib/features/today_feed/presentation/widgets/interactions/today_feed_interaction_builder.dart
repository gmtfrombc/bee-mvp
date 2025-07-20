import 'package:flutter/material.dart';

import '../../../domain/models/today_feed_content.dart';
import 'today_feed_interaction_handler.dart';

/// Wrapper that provides tap + optional swipe gestures for a child widget.
/// Factored out of the original file to keep that library under size limits.
class TodayFeedInteractionBuilder extends StatelessWidget {
  const TodayFeedInteractionBuilder({
    super.key,
    required this.handler,
    required this.content,
    required this.child,
    required this.onAnimationTrigger,
    this.borderRadius,
    this.enableSwipeGestures = false,
  });

  final TodayFeedInteractionHandler handler;
  final TodayFeedContent? content;
  final Widget child;
  final Future<void> Function() onAnimationTrigger;
  final double? borderRadius;
  final bool enableSwipeGestures;

  @override
  Widget build(BuildContext context) {
    Widget wrappedChild = handler.wrapWithTapGesture(
      child: child,
      context: context,
      onAnimationTrigger: onAnimationTrigger,
      borderRadius: borderRadius,
    );

    if (enableSwipeGestures && content != null) {
      wrappedChild = GestureDetector(
        onHorizontalDragEnd: (details) => _handleSwipeGesture(context, details),
        child: wrappedChild,
      );
    }

    return wrappedChild;
  }

  void _handleSwipeGesture(BuildContext context, DragEndDetails details) {
    const threshold = 100.0;

    if (details.primaryVelocity == null || content == null) return;

    if (details.primaryVelocity! > threshold) {
      handler.handleBookmark(context, content!);
    } else if (details.primaryVelocity! < -threshold) {
      handler.handleShare(context, content!);
    }
  }
}
