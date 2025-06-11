import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../../today_feed/domain/models/today_feed_content.dart';
import '../../../today_feed/data/services/today_feed_simple_service.dart';
import '../../../../core/services/today_feed_local_store.dart';

/// Provider for managing Today Feed state in the momentum screen
final todayFeedProvider =
    StateNotifierProvider<TodayFeedNotifier, TodayFeedState>((ref) {
      return TodayFeedNotifier();
    });

/// State notifier for managing Today Feed content and interactions
class TodayFeedNotifier extends StateNotifier<TodayFeedState> {
  TodayFeedNotifier() : super(const TodayFeedState.loading()) {
    _initialize();
  }

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
      debugPrint('🔄 [TodayFeed] Silent refresh started');
      final fresh = await TodayFeedSimpleService.getTodayContent(
        forceRefresh: true,
      );

      if (fresh != null && fresh != cached) {
        debugPrint(
          '✅ [TodayFeed] Silent refresh complete – new content retrieved',
        );
        state = TodayFeedState.loaded(fresh);
      } else {
        debugPrint('ℹ️  [TodayFeed] Silent refresh complete – no new content');
        if (cached == null && fresh == null) {
          state = const TodayFeedState.error('No content available');
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to initialize Today Feed: $e');
      state = TodayFeedState.error('Failed to load content: $e');
    }
  }

  /// Refresh content
  Future<void> refresh() async {
    try {
      final content = await TodayFeedSimpleService.refreshContent();

      if (content != null) {
        state = TodayFeedState.loaded(content);
      } else {
        state = const TodayFeedState.error('Failed to refresh content');
      }
    } catch (e) {
      debugPrint('❌ Failed to refresh today content: $e');
      state = TodayFeedState.error('Failed to refresh content: $e');
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
      } else {
        state = const TodayFeedState.error('Failed to force refresh content');
      }
    } catch (e) {
      debugPrint('❌ Failed to force refresh today content: $e');
      state = TodayFeedState.error('Failed to force refresh content: $e');
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
    await recordInteraction(TodayFeedInteractionType.tap);
    // TODO: Award momentum points for first daily interaction
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
