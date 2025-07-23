import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import 'onboarding_controller.dart';
import 'data/onboarding_repository.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/scoring_service.dart';
import '../../core/services/onboarding_submission_flag_service.dart';

/// Controller that manages the final submission step of the onboarding flow.
///
/// Exposes an [AsyncValue] so the UI can reactively show a loading spinner,
/// error snackbar, or success navigation while the submission RPC executes.
class OnboardingCompletionController extends StateNotifier<AsyncValue<void>> {
  OnboardingCompletionController(this._ref)
    : super(const AsyncValue.data(null)); // idle

  final Ref _ref;

  /// Kick off the submission pipeline.
  ///
  /// Invokes [OnboardingRepository.submit] with the current [OnboardingDraft]
  /// retrieved from [onboardingControllerProvider]. Computes AI tags before
  /// submission (Milestone M2).
  Future<void> submit() async {
    state = const AsyncValue.loading();

    // Toggle local "in-flight" flag so OnboardingGuard allows navigation
    // while the RPC is executing.
    final flagService = OnboardingSubmissionFlagService();
    await flagService.setSubmitting(true);

    try {
      final draft = _ref.read(onboardingControllerProvider);

      // -------------------------------------------------------------------
      // Compute personalisation tags (Motivation, Readiness, Coach Style)
      // before sending the RPC as per Milestone M2.
      // -------------------------------------------------------------------
      final tags = ScoringService.computeTags(draft);
      final tagsJson = tags.toJson();

      final repo = _ref.read(onboardingRepositoryProvider);

      await repo.submit(
        draft: draft,
        motivationType: tagsJson['motivationType'] as String,
        readinessLevel: tagsJson['readinessLevel'] as String,
        coachStyle: tagsJson['coachStyle'] as String,
      );

      // Mark onboarding complete in Supabase profile.
      final authService = await _ref.read(authServiceProvider.future);
      try {
        await authService.completeOnboarding();
        if (kDebugMode) {
          // ignore: avoid_print
          debugPrint('✅ completeOnboarding upsert succeeded');
        }
      } catch (e) {
        debugPrint('❌ completeOnboarding failed: $e');
        rethrow;
      }

      // Stop autosave timer now that draft is cleared.
      _ref.read(onboardingControllerProvider.notifier).cancelAutosave();
      // On success we simply emit `data(null)`.
      state = const AsyncValue.data(null);
    } catch (err, st) {
      debugPrint('❌ OnboardingCompletionController.submit error: $err');
      state = AsyncValue.error(err, st);
    } finally {
      // Always clear the flag regardless of success or failure.
      await flagService.setSubmitting(false);
    }
  }
}

/// Riverpod provider exposing the [OnboardingCompletionController].
final onboardingCompletionControllerProvider =
    StateNotifierProvider<OnboardingCompletionController, AsyncValue<void>>(
      (ref) => OnboardingCompletionController(ref),
    );
