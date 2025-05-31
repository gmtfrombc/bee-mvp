import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/today_feed_momentum_award_service.dart';
import '../../domain/models/today_feed_content.dart';

/// State for momentum point feedback
class MomentumFeedbackState {
  const MomentumFeedbackState({
    this.awardResult,
    this.isVisible = false,
    this.content,
  });

  final MomentumAwardResult? awardResult;
  final bool isVisible;
  final TodayFeedContent? content;

  MomentumFeedbackState copyWith({
    MomentumAwardResult? awardResult,
    bool? isVisible,
    TodayFeedContent? content,
  }) {
    return MomentumFeedbackState(
      awardResult: awardResult ?? this.awardResult,
      isVisible: isVisible ?? this.isVisible,
      content: content ?? this.content,
    );
  }
}

/// Notifier for managing momentum point feedback
/// Handles showing and hiding feedback based on momentum award results
/// Implements T1.3.4.6: Visual feedback for momentum point awards
class MomentumFeedbackNotifier extends StateNotifier<MomentumFeedbackState> {
  MomentumFeedbackNotifier(this._momentumAwardService)
    : super(const MomentumFeedbackState());

  final TodayFeedMomentumAwardService _momentumAwardService;

  /// Show momentum point feedback for a successful award
  /// Called after a momentum point is awarded from Today Feed interaction
  void showFeedback({
    required MomentumAwardResult awardResult,
    required TodayFeedContent content,
  }) {
    if (awardResult.success || awardResult.isQueued) {
      state = state.copyWith(
        awardResult: awardResult,
        isVisible: true,
        content: content,
      );
    }
  }

  /// Hide momentum point feedback
  /// Called when feedback animation completes or user dismisses
  void hideFeedback() {
    state = state.copyWith(isVisible: false);
  }

  /// Clear feedback state completely
  /// Called when transitioning to new content or resetting state
  void clearFeedback() {
    state = const MomentumFeedbackState();
  }

  /// Award momentum points and show feedback
  /// Convenience method that combines awarding and showing feedback
  Future<void> awardMomentumAndShowFeedback({
    required String userId,
    required TodayFeedContent content,
    int? sessionDuration,
    Map<String, dynamic>? interactionMetadata,
  }) async {
    try {
      final awardResult = await _momentumAwardService.awardMomentumPoints(
        userId: userId,
        content: content,
        sessionDuration: sessionDuration,
        interactionMetadata: interactionMetadata,
      );

      // Show feedback for successful awards or queued awards
      if (awardResult.success || awardResult.isQueued) {
        showFeedback(awardResult: awardResult, content: content);
      }
    } catch (e) {
      // Show error feedback if needed
      showFeedback(
        awardResult: MomentumAwardResult.failed(
          message: 'Failed to award momentum points',
          error: e.toString(),
        ),
        content: content,
      );
    }
  }
}

/// Provider for momentum feedback state management
final momentumFeedbackProvider =
    StateNotifierProvider<MomentumFeedbackNotifier, MomentumFeedbackState>((
      ref,
    ) {
      final momentumAwardService = TodayFeedMomentumAwardService();
      return MomentumFeedbackNotifier(momentumAwardService);
    });

/// Provider for accessing feedback visibility state
final momentumFeedbackVisibilityProvider = Provider<bool>((ref) {
  return ref.watch(momentumFeedbackProvider).isVisible;
});

/// Provider for accessing current award result
final momentumFeedbackResultProvider = Provider<MomentumAwardResult?>((ref) {
  return ref.watch(momentumFeedbackProvider).awardResult;
});

/// Provider for triggering momentum award with feedback
final momentumAwardWithFeedbackProvider = Provider<
  Future<void> Function({
    required String userId,
    required TodayFeedContent content,
    int? sessionDuration,
    Map<String, dynamic>? interactionMetadata,
  })
>((ref) {
  final notifier = ref.read(momentumFeedbackProvider.notifier);

  return ({
    required String userId,
    required TodayFeedContent content,
    int? sessionDuration,
    Map<String, dynamic>? interactionMetadata,
  }) async {
    return await notifier.awardMomentumAndShowFeedback(
      userId: userId,
      content: content,
      sessionDuration: sessionDuration,
      interactionMetadata: interactionMetadata,
    );
  };
});
