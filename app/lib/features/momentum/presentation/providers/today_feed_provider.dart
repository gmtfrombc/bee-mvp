import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../../today_feed/domain/models/today_feed_content.dart';
import '../../../today_feed/data/services/today_feed_data_service.dart';

/// Provider for managing Today Feed state in the momentum screen
final todayFeedProvider =
    StateNotifierProvider<TodayFeedNotifier, TodayFeedState>((ref) {
      return TodayFeedNotifier();
    });

/// State notifier for managing Today Feed content and interactions
class TodayFeedNotifier extends StateNotifier<TodayFeedState> {
  TodayFeedNotifier() : super(const TodayFeedState.loading()) {
    _loadTodayContent();
  }

  /// Load today's content
  Future<void> _loadTodayContent() async {
    try {
      state = const TodayFeedState.loading();

      final content = await TodayFeedDataService.getTodayContent();

      if (content != null) {
        state = TodayFeedState.loaded(content);
      } else {
        state = const TodayFeedState.error('No content available');
      }
    } catch (e) {
      debugPrint('❌ Failed to load today content: $e');
      state = TodayFeedState.error('Failed to load content: $e');
    }
  }

  /// Refresh content
  Future<void> refresh() async {
    try {
      final content = await TodayFeedDataService.refreshContent();

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

      final content = await TodayFeedDataService.forceRefreshAndClearCache();

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
      await TodayFeedDataService.recordInteraction(type, currentContent);
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
