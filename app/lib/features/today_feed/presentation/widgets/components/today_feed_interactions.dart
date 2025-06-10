import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/services/url_launcher_service.dart';
import '../../../domain/models/today_feed_content.dart';
import '../../../data/services/today_feed_sharing_service.dart';
import '../../../data/models/today_feed_sharing_models.dart';
import '../../../data/services/today_feed_momentum_award_service.dart';
import '../momentum_point_feedback_widget.dart';

/// Callback types for Today Feed tile interactions
typedef TodayFeedCallback = void Function();
typedef TodayFeedInteractionCallback =
    void Function(TodayFeedInteractionType type);

/// Handles all user interactions for Today Feed tiles
/// Including tap, share, bookmark, and external link functionality
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

  // Lazy initialization of sharing service
  static final TodayFeedSharingService _sharingService =
      TodayFeedSharingService();

  /// Handle main tile tap with animation feedback
  Future<void> handleTap({
    required BuildContext context,
    required Function() onAnimationTrigger,
  }) async {
    if (onTap == null) return;

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Trigger animation
    await onAnimationTrigger();

    // Track interaction
    onInteraction?.call(TodayFeedInteractionType.tap);

    // Execute callback
    onTap!();
  }

  /// Handle external link tap with preview and security
  Future<void> handleExternalLinkTap(
    BuildContext context,
    String url,
    String? linkText,
  ) async {
    try {
      // Show preview dialog first for user confirmation
      final shouldLaunch = await UrlLauncherService().showUrlPreviewDialog(
        context,
        url,
        linkText: linkText,
        description:
            "This will open external health content in a secure browser view.",
      );

      if (shouldLaunch) {
        // Try launching with in-app browser first
        final launched = await UrlLauncherService().launchHealthContentUrl(
          url,
          linkText: linkText,
          sourceContext: "Today Feed",
        );

        if (!launched) {
          // Fallback to external browser if in-app browser fails
          await UrlLauncherService().launchInExternalBrowser(
            url,
            linkText: linkText,
            sourceContext: "Today Feed",
          );
        }

        // Track interaction
        onInteraction?.call(TodayFeedInteractionType.externalLinkClick);

        // Call the original callback if provided
        onExternalLinkTap?.call();
      }
    } catch (e) {
      debugPrint(
        'TodayFeedInteractionHandler: Error handling external link: $e',
      );
      // Still call the callback on error for backward compatibility
      onExternalLinkTap?.call();
    }
  }

  /// Handle share action with platform-specific sharing and momentum bonus
  Future<void> handleShare(
    BuildContext context,
    TodayFeedContent content,
  ) async {
    try {
      // Track interaction first
      onInteraction?.call(TodayFeedInteractionType.share);

      // Haptic feedback
      HapticFeedback.selectionClick();

      // Initialize sharing service
      await _sharingService.initialize();

      // Attempt to share content with momentum bonus
      final sharingResult = await _sharingService.shareContent(
        content: content,
        additionalMetadata: {
          'source_widget': 'today_feed_tile',
          'interaction_timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (context.mounted) {
        await _showSharingResult(context, content, sharingResult);
      }

      // Call callback if provided
      onShare?.call();
    } catch (e) {
      debugPrint('TodayFeedInteractionHandler: Error sharing content: $e');
      if (context.mounted) {
        _showShareError(context);
      }
    }
  }

  /// Handle bookmark action with local storage and momentum bonus
  Future<void> handleBookmark(
    BuildContext context,
    TodayFeedContent content,
  ) async {
    try {
      // Track interaction first
      onInteraction?.call(TodayFeedInteractionType.bookmark);

      // Haptic feedback
      HapticFeedback.selectionClick();

      // Initialize sharing service
      await _sharingService.initialize();

      // Check if already bookmarked first
      final isAlreadyBookmarked = await _sharingService.isContentBookmarked(
        content,
      );

      if (isAlreadyBookmarked) {
        // Remove bookmark if already bookmarked
        final bookmarkResult = await _sharingService.removeBookmark(
          content: content,
          additionalMetadata: {
            'source_widget': 'today_feed_tile',
            'interaction_timestamp': DateTime.now().toIso8601String(),
          },
        );

        if (context.mounted) {
          await _showBookmarkResult(
            context,
            content,
            bookmarkResult,
            wasRemoved: true,
          );
        }
      } else {
        // Add bookmark if not already bookmarked
        final bookmarkResult = await _sharingService.bookmarkContent(
          content: content,
          additionalMetadata: {
            'source_widget': 'today_feed_tile',
            'interaction_timestamp': DateTime.now().toIso8601String(),
          },
        );

        if (context.mounted) {
          await _showBookmarkResult(
            context,
            content,
            bookmarkResult,
            wasRemoved: false,
          );
        }
      }

      // Call callback if provided
      onBookmark?.call();
    } catch (e) {
      debugPrint('TodayFeedInteractionHandler: Error bookmarking content: $e');
      if (context.mounted) {
        _showBookmarkError(context);
      }
    }
  }

  /// Create a tap gesture wrapper with proper accessibility
  Widget wrapWithTapGesture({
    required Widget child,
    required BuildContext context,
    required Function() onAnimationTrigger,
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

  // Enhanced result display methods

  Future<void> _showSharingResult(
    BuildContext context,
    TodayFeedContent content,
    SharingResult sharingResult,
  ) async {
    if (sharingResult.success) {
      // Show momentum feedback if bonus was awarded
      if (sharingResult.momentumBonus != null &&
          sharingResult.momentumBonus!.success) {
        await _showMomentumFeedback(context, sharingResult.momentumBonus!);
      }

      // Show success message
      if (sharingResult.isQueued) {
        if (context.mounted) {
          _showQueuedShareFeedback(context, content);
        }
      } else {
        if (context.mounted) {
          _showSuccessShareFeedback(context, content);
        }
      }
    } else if (sharingResult.dailyCount != null &&
        sharingResult.maxDailyCount != null) {
      // Show daily limit message
      if (context.mounted) {
        _showDailyLimitMessage(
          context,
          'share',
          sharingResult.dailyCount!,
          sharingResult.maxDailyCount!,
        );
      }
    } else {
      // Show error
      if (context.mounted) {
        _showShareError(context, sharingResult.message);
      }
    }
  }

  Future<void> _showBookmarkResult(
    BuildContext context,
    TodayFeedContent content,
    BookmarkResult bookmarkResult, {
    required bool wasRemoved,
  }) async {
    if (bookmarkResult.success) {
      // Show momentum feedback if bonus was awarded
      if (bookmarkResult.momentumBonus != null &&
          bookmarkResult.momentumBonus!.success) {
        await _showMomentumFeedback(context, bookmarkResult.momentumBonus!);
      }

      // Show appropriate feedback message
      if (bookmarkResult.isQueued) {
        if (context.mounted) {
          _showQueuedBookmarkFeedback(context, content, wasRemoved);
        }
      } else if (wasRemoved) {
        if (context.mounted) {
          _showBookmarkRemovedFeedback(context, content);
        }
      } else {
        if (context.mounted) {
          _showBookmarkAddedFeedback(context, content);
        }
      }
    } else if (bookmarkResult.dailyCount != null &&
        bookmarkResult.maxDailyCount != null) {
      // Show daily limit message
      if (context.mounted) {
        _showDailyLimitMessage(
          context,
          'bookmark',
          bookmarkResult.dailyCount!,
          bookmarkResult.maxDailyCount!,
        );
      }
    } else {
      // Show error
      if (context.mounted) {
        _showBookmarkError(context, bookmarkResult.message);
      }
    }
  }

  Future<void> _showMomentumFeedback(
    BuildContext context,
    MomentumBonusResult momentumBonus,
  ) async {
    // Create an overlay entry to show momentum feedback
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
                onAnimationComplete: () {
                  overlayEntry.remove();
                },
                autoHide: true,
                autoHideDuration: const Duration(seconds: 3),
              ),
            ),
          ),
    );

    overlay.insert(overlayEntry);

    // Auto-remove after 4 seconds as fallback
    Future.delayed(const Duration(seconds: 4), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  void _showSuccessShareFeedback(
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

  void _showQueuedShareFeedback(
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

  void _showBookmarkAddedFeedback(
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

  void _showBookmarkRemovedFeedback(
    BuildContext context,
    TodayFeedContent content,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.bookmark_remove, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text('Bookmark removed')),
          ],
        ),
        backgroundColor: Colors.grey,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () => handleBookmark(context, content),
        ),
      ),
    );
  }

  void _showQueuedBookmarkFeedback(
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

  void _showDailyLimitMessage(
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

  void _showShareError(BuildContext context, [String? message]) {
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

  void _showBookmarkError(BuildContext context, [String? message]) {
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

/// Interaction builder widget that provides common interaction patterns
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
  final Function() onAnimationTrigger;
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

    // Add swipe gestures if enabled and content is available
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

    // Right swipe - bookmark
    if (details.primaryVelocity! > threshold) {
      handler.handleBookmark(context, content!);
    }
    // Left swipe - share
    else if (details.primaryVelocity! < -threshold) {
      handler.handleShare(context, content!);
    }
  }
}
