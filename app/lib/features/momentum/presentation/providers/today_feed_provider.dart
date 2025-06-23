import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../../today_feed/domain/models/today_feed_content.dart';
import '../../../today_feed/data/services/today_feed_simple_service.dart';
import '../../../../core/services/today_feed_local_store.dart';
import '../../../../core/services/connectivity_service.dart';

/// Helper method to build a simple fallback result when no content is available.
TodayFeedFallbackResult _buildOfflineFallback(String message) {
  return TodayFeedFallbackResult(
    content: null,
    fallbackType: TodayFeedFallbackType.none,
    contentAge: Duration.zero,
    isStale: true,
    userMessage: message,
    shouldShowAgeWarning: false,
    lastAttemptToRefresh: DateTime.now(),
  );
}

/// Provider for managing Today Feed state in the momentum screen
final todayFeedProvider =
    StateNotifierProvider<TodayFeedNotifier, TodayFeedState>((ref) {
      return TodayFeedNotifier(ref);
    });

/// State notifier for managing Today Feed content and interactions
class TodayFeedNotifier extends StateNotifier<TodayFeedState> {
  TodayFeedNotifier(this._ref) : super(const TodayFeedState.loading()) {
    _initialize();

    // Listen to connectivity changes so we can auto-refresh when back online.
    _ref.listen<ConnectivityStatus>(currentConnectivityProvider, (
      previous,
      next,
    ) {
      if (next == ConnectivityStatus.online) {
        _silentRefresh();
      }
    });
  }

  final Ref _ref;

  /// Initialize by showing cached content instantly, then refresh silently
  Future<void> _initialize() async {
    try {
      // Step 1: try to get any cached/stale content synchronously for instant UI
      final cached = await TodayFeedLocalStore.getCachedContent();

      if (cached != null) {
        state = TodayFeedState.loaded(cached);
      } else {
        state = const TodayFeedState.loading();
      }

      // Step 2: silently attempt to refresh in background (no spinner)
      await _silentRefresh();
    } catch (e) {
      debugPrint('❌ Failed to initialize Today Feed: $e');
      // Fallback instead of error – keep UI friendly.
      state = TodayFeedState.fallback(
        _buildOfflineFallback('Momentum Health will update your feed soon.'),
      );
    }
  }

  /// Internal helper to perform a silent refresh without disturbing UI.
  Future<void> _silentRefresh() async {
    debugPrint('🔄 [TodayFeed] Silent refresh started');

    final cached = state.content;

    // If we are offline and already showing content or fallback, bail out.
    if (ConnectivityService.isOffline) {
      if (cached != null) return; // keep cached

      // No cached content – ensure we show offline fallback.
      state = TodayFeedState.fallback(
        _buildOfflineFallback(
          "Offline – we'll update your feed once you're online again!",
        ),
      );
      return;
    }

    final fresh = await TodayFeedSimpleService.getTodayContent(
      forceRefresh: true,
    );

    if (fresh != null) {
      state = TodayFeedState.loaded(fresh);
    } else if (cached == null) {
      // Online but still nothing (edge function not ready) – show friendly msg.
      state = TodayFeedState.fallback(
        _buildOfflineFallback(
          "We're generating today's article. Check back in a bit!",
        ),
      );
    }

    debugPrint('ℹ️  [TodayFeed] Silent refresh complete');
  }

  /// Refresh content
  Future<void> refresh() async {
    try {
      final content = await TodayFeedSimpleService.refreshContent();

      if (content != null) {
        state = TodayFeedState.loaded(content);
      }
    } catch (e) {
      debugPrint('❌ Failed to refresh today content: $e');
      // Keep existing state – no need to show error.
    }
  }

  /// Force refresh with cache clear (for debugging/testing)
  Future<void> forceRefresh() async {
    try {
      state = const TodayFeedState.loading();

      final content = await TodayFeedSimpleService.refreshContent();

      if (content != null) {
        state = TodayFeedState.loaded(content);
        debugPrint('✅ Today Feed force refreshed successfully');
      }
    } catch (e) {
      debugPrint('❌ Failed to force refresh today content: $e');
      // Keep existing state.
    }
  }

  /// Record user interaction
  Future<void> recordInteraction(TodayFeedInteractionType type) async {
    final currentContent = state.content;
    if (currentContent == null) return;

    try {
      await TodayFeedSimpleService.recordInteraction(type, currentContent);
      debugPrint('✅ Interaction recorded: ${type.value}');
    } catch (e) {
      debugPrint('❌ Failed to record interaction: $e');
    }
  }

  /// Handle tap interaction (awards momentum on first daily interaction)
  Future<void> handleTap() async {
    final currentContent = state.content;

    if (currentContent == null) return;

    // Record interaction only once per day (per article)
    if (!currentContent.hasUserEngaged) {
      await recordInteraction(TodayFeedInteractionType.tap);

      // Update local state & cache so subsequent taps are ignored today
      final updatedContent = currentContent.copyWith(hasUserEngaged: true);
      state = TodayFeedState.loaded(updatedContent);

      // Persist to local store so the flag survives app restarts
      try {
        await TodayFeedLocalStore.saveContent(updatedContent);
      } catch (e) {
        debugPrint('⚠️ Failed to update local Today Feed cache: $e');
      }
    }
  }

  /// Handle share interaction
  Future<void> handleShare() async {
    await recordInteraction(TodayFeedInteractionType.share);
  }

  /// Handle bookmark interaction
  Future<void> handleBookmark() async {
    await recordInteraction(TodayFeedInteractionType.bookmark);
  }

  /// Add a coaching card to the top of the Today Feed
  /// Used for momentum-triggered proactive coaching interventions
  void addCoachingCard({
    required String title,
    required String message,
    required String momentumState,
    String? previousState,
  }) {
    final currentContent = state.content;
    if (currentContent == null) return;

    // Create a coaching-specific content item
    final coachingContent = currentContent.copyWith(
      title: title,
      summary: message,
      topicCategory: HealthTopic.lifestyle, // Default to lifestyle for coaching
      contentUrl: null, // No external URL for coaching cards
      externalLink: null,
      imageUrl: null,
      estimatedReadingMinutes: 1, // Quick read for coaching messages
      hasUserEngaged: false,
      isCached: true,
    );

    // Update state with the coaching content
    state = TodayFeedState.loaded(coachingContent);

    debugPrint('🎯 Coaching card added to Today Feed: $title');
  }
}
