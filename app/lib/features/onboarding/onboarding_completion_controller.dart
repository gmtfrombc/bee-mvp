import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controller that manages the final submission step of the onboarding flow.
///
/// Exposes an [AsyncValue] so the UI can reactively show a loading spinner,
/// error snackbar, or success navigation while the submission RPC executes.
///
/// The actual network interaction (calling `OnboardingRepository.submit()` and
/// `AuthService.completeOnboarding()`) will be wired up in follow-up tasks
/// (T1.2 – T1.4). For now we provide a stubbed implementation so the UI layer
/// and tests can be built incrementally.
class OnboardingCompletionController extends StateNotifier<AsyncValue<void>> {
  OnboardingCompletionController() : super(const AsyncValue.data(null)); // idle

  /// Kick off the submission pipeline.
  ///
  /// Currently stubbed with a short delay. Will be replaced in T1.2.
  Future<void> submit() async {
    state = const AsyncValue.loading();
    try {
      // TODO(T1.2): integrate with OnboardingRepository & AuthService
      await Future.delayed(const Duration(milliseconds: 300));

      // On success we simply emit `data(null)`.
      state = const AsyncValue.data(null);
    } catch (err, st) {
      state = AsyncValue.error(err, st);
    }
  }
}

/// Riverpod provider exposing the [OnboardingCompletionController].
final onboardingCompletionControllerProvider =
    StateNotifierProvider<OnboardingCompletionController, AsyncValue<void>>(
      (ref) => OnboardingCompletionController(),
    );
