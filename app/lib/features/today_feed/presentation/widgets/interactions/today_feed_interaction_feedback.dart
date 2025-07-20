import 'package:flutter/material.dart';
import '../../../domain/models/today_feed_content.dart';
import '../../../data/models/today_feed_sharing_models.dart';
import '../../../data/services/today_feed_momentum_award_service.dart';
import '../momentum_point_feedback_widget.dart';

/// Utility widget helpers that show SnackBars and momentum overlay for
/// Today Feed share / bookmark interactions. Factored out of the original
/// `today_feed_interactions.dart` to reduce file size and simplify testing.
class TodayFeedInteractionFeedback {
  // Private constructor – static only
  TodayFeedInteractionFeedback._();

  // ───────────────── Share Feedback ─────────────────
  static Future<void> showSharingResult(
    BuildContext context,
    TodayFeedContent content,
    SharingResult sharingResult,
  ) async {
    if (sharingResult.success) {
      // Momentum overlay
      if (sharingResult.momentumBonus != null &&
          sharingResult.momentumBonus!.success) {
        await _showMomentumFeedback(context, sharingResult.momentumBonus!);
        if (!context.mounted) return;
      }

      // Success vs queued snackbar
      if (sharingResult.isQueued) {
        _showQueuedShareFeedback(context, content);
      } else {
        _showSuccessShareFeedback(context, content);
      }
      return;
    }

    if (sharingResult.dailyCount != null &&
        sharingResult.maxDailyCount != null) {
      _showDailyLimitMessage(
        context,
        'share',
        sharingResult.dailyCount!,
        sharingResult.maxDailyCount!,
      );
    } else {
      _showShareError(context, sharingResult.message);
    }
  }

  // ───────────────── Bookmark Feedback ─────────────────
  static Future<void> showBookmarkResult(
    BuildContext context,
    TodayFeedContent content,
    BookmarkResult bookmarkResult, {
    required bool wasRemoved,
  }) async {
    if (bookmarkResult.success) {
      // Momentum overlay
      if (bookmarkResult.momentumBonus != null &&
          bookmarkResult.momentumBonus!.success) {
        await _showMomentumFeedback(context, bookmarkResult.momentumBonus!);
        if (!context.mounted) return;
      }

      if (bookmarkResult.isQueued) {
        _showQueuedBookmarkFeedback(context, content, wasRemoved);
      } else if (wasRemoved) {
        _showBookmarkRemovedFeedback(context, content);
      } else {
        _showBookmarkAddedFeedback(context, content);
      }
      return;
    }

    if (bookmarkResult.dailyCount != null &&
        bookmarkResult.maxDailyCount != null) {
      _showDailyLimitMessage(
        context,
        'bookmark',
        bookmarkResult.dailyCount!,
        bookmarkResult.maxDailyCount!,
      );
    } else {
      _showBookmarkError(context, bookmarkResult.message);
    }
  }

  static void showShareError(BuildContext context, [String? message]) =>
      _showShareError(context, message);
  static void showBookmarkError(BuildContext context, [String? message]) =>
      _showBookmarkError(context, message);

  // ───────────────── Private UI helpers ─────────────────

  static Future<void> _showMomentumFeedback(
    BuildContext context,
    MomentumBonusResult momentumBonus,
  ) async {
    final overlay = Overlay.of(context);

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: MediaQuery.of(context).size.height * 0.3,
            left: 20,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: MomentumPointFeedbackWidget(
                awardResult: MomentumAwardResult(
                  success: momentumBonus.success,
                  pointsAwarded: momentumBonus.bonusPoints,
                  message: momentumBonus.message,
                  awardTime: momentumBonus.awardTime,
                  isQueued: false,
                  error: momentumBonus.error,
                ),
                onAnimationComplete: () => overlayEntry.remove(),
                autoHide: true,
                autoHideDuration: const Duration(seconds: 3),
              ),
            ),
          ),
    );

    overlay.insert(overlayEntry);

    // Fallback removal in case onAnimationComplete not triggered
    Future.delayed(const Duration(seconds: 4), () {
      if (overlayEntry.mounted) overlayEntry.remove();
    });
  }

  // ───────────────── Share SnackBars ─────────────────

  static void _showSuccessShareFeedback(
    BuildContext context,
    TodayFeedContent content,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.share, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('Shared: ${content.title}')),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void _showQueuedShareFeedback(
    BuildContext context,
    TodayFeedContent content,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.schedule, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text('Share queued for when back online')),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ───────────────── Bookmark SnackBars ─────────────────

  static void _showBookmarkAddedFeedback(
    BuildContext context,
    TodayFeedContent content,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.bookmark_added, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('Bookmarked: ${content.title}')),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            // TODO: Navigate to bookmarks view
          },
        ),
      ),
    );
  }

  static void _showBookmarkRemovedFeedback(
    BuildContext context,
    TodayFeedContent content,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.bookmark_remove, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text('Bookmark removed')),
          ],
        ),
        backgroundColor: Colors.grey,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void _showQueuedBookmarkFeedback(
    BuildContext context,
    TodayFeedContent content,
    bool wasRemoved,
  ) {
    final action = wasRemoved ? 'Bookmark removal' : 'Bookmark';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.schedule, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('$action queued for when back online')),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ───────────────── Common Helpers ─────────────────

  static void _showDailyLimitMessage(
    BuildContext context,
    String actionType,
    int currentCount,
    int maxCount,
  ) {
    final remaining = maxCount - currentCount;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                remaining > 0
                    ? 'Daily $actionType limit: $remaining bonus points remaining today'
                    : 'Daily $actionType bonus limit reached. Try again tomorrow!',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.amber,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void _showShareError(BuildContext context, [String? message]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message ?? 'Unable to share content. Please try again.',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void _showBookmarkError(BuildContext context, [String? message]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message ?? 'Unable to bookmark content. Please try again.',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
