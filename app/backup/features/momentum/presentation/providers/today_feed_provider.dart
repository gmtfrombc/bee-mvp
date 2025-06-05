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
}
