import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/services/url_launcher_service.dart';
import '../../../domain/models/today_feed_content.dart';
import '../../../data/services/today_feed_sharing_service.dart';
import '../../../data/models/today_feed_sharing_models.dart';

import 'today_feed_interaction_feedback.dart';

/// Callback types for Today Feed tile interactions
typedef TodayFeedCallback = void Function();
typedef TodayFeedInteractionCallback =
    void Function(TodayFeedInteractionType type);

/// Handles tap, external link, share and bookmark interactions for Today Feed
/// tiles. All UI feedback has been moved to `TodayFeedInteractionFeedback`
/// to keep this class lean and test-friendly.
class TodayFeedInteractionHandler {
  const TodayFeedInteractionHandler({
    this.onTap,
    this.onExternalLinkTap,
    this.onShare,
    this.onBookmark,
    this.onInteraction,
  });

  final TodayFeedCallback? onTap;
  final TodayFeedCallback? onExternalLinkTap;
  final TodayFeedCallback? onShare;
  final TodayFeedCallback? onBookmark;
  final TodayFeedInteractionCallback? onInteraction;

  static final TodayFeedSharingService _sharingService =
      TodayFeedSharingService();

  // ────────────────────── TAP ──────────────────────
  Future<void> handleTap({
    required BuildContext context,
    required Future<void> Function() onAnimationTrigger,
  }) async {
    if (onTap == null) return;

    HapticFeedback.lightImpact();
    await onAnimationTrigger();
    onInteraction?.call(TodayFeedInteractionType.tap);
    onTap!();
  }

  // ──────────────── EXTERNAL LINK ────────────────
  Future<void> handleExternalLinkTap(
    BuildContext context,
    String url,
    String? linkText,
  ) async {
    try {
      final shouldLaunch = await UrlLauncherService().showUrlPreviewDialog(
        context,
        url,
        linkText: linkText,
        description:
            'This will open external health content in a secure browser view.',
      );

      if (!shouldLaunch) return;

      final launched = await UrlLauncherService().launchHealthContentUrl(
        url,
        linkText: linkText,
        sourceContext: 'Today Feed',
      );

      if (!launched) {
        await UrlLauncherService().launchInExternalBrowser(
          url,
          linkText: linkText,
          sourceContext: 'Today Feed',
        );
      }

      onInteraction?.call(TodayFeedInteractionType.externalLinkClick);
      onExternalLinkTap?.call();
    } catch (e) {
      debugPrint('TodayFeedInteractionHandler: external link error: $e');
      onExternalLinkTap?.call();
    }
  }

  // ─────────────────── SHARE ───────────────────
  Future<void> handleShare(
    BuildContext context,
    TodayFeedContent content,
  ) async {
    try {
      onInteraction?.call(TodayFeedInteractionType.share);
      HapticFeedback.selectionClick();

      await _sharingService.initialize();

      final sharingResult = await _sharingService.shareContent(
        content: content,
        additionalMetadata: {
          'source_widget': 'today_feed_tile',
          'interaction_timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (context.mounted) {
        await TodayFeedInteractionFeedback.showSharingResult(
          context,
          content,
          sharingResult,
        );
      }

      onShare?.call();
    } catch (e) {
      debugPrint('TodayFeedInteractionHandler: share error: $e');
      if (context.mounted) {
        TodayFeedInteractionFeedback.showShareError(context);
      }
    }
  }

  // ───────────────── BOOKMARK ─────────────────
  Future<void> handleBookmark(
    BuildContext context,
    TodayFeedContent content,
  ) async {
    try {
      onInteraction?.call(TodayFeedInteractionType.bookmark);
      HapticFeedback.selectionClick();

      await _sharingService.initialize();

      final isAlreadyBookmarked = await _sharingService.isContentBookmarked(
        content,
      );

      final BookmarkResult bookmarkResult;
      final bool wasRemoved;

      if (isAlreadyBookmarked) {
        bookmarkResult = await _sharingService.removeBookmark(
          content: content,
          additionalMetadata: {
            'source_widget': 'today_feed_tile',
            'interaction_timestamp': DateTime.now().toIso8601String(),
          },
        );
        wasRemoved = true;
      } else {
        bookmarkResult = await _sharingService.bookmarkContent(
          content: content,
          additionalMetadata: {
            'source_widget': 'today_feed_tile',
            'interaction_timestamp': DateTime.now().toIso8601String(),
          },
        );
        wasRemoved = false;
      }

      if (context.mounted) {
        await TodayFeedInteractionFeedback.showBookmarkResult(
          context,
          content,
          bookmarkResult,
          wasRemoved: wasRemoved,
        );
      }

      onBookmark?.call();
    } catch (e) {
      debugPrint('TodayFeedInteractionHandler: bookmark error: $e');
      if (context.mounted) {
        TodayFeedInteractionFeedback.showBookmarkError(context);
      }
    }
  }

  // ──────────────── TAP GESTURE WRAP ────────────────
  Widget wrapWithTapGesture({
    required Widget child,
    required BuildContext context,
    required Future<void> Function() onAnimationTrigger,
    double? borderRadius,
  }) {
    if (onTap == null) return child;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:
            () => handleTap(
              context: context,
              onAnimationTrigger: onAnimationTrigger,
            ),
        borderRadius:
            borderRadius != null ? BorderRadius.circular(borderRadius) : null,
        child: child,
      ),
    );
  }
}
