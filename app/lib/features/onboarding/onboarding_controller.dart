import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/onboarding_draft.dart';

/// Manages the mutable onboarding draft across multi-step onboarding flow.
class OnboardingController extends StateNotifier<OnboardingDraft> {
  OnboardingController() : super(const OnboardingDraft());

  // -------------------------------------------------------------------------
  // Field updates
  // -------------------------------------------------------------------------

  void updateDateOfBirth(DateTime? dob) {
    state = state.copyWith(dateOfBirth: dob);
  }

  void updateGender(String? gender) {
    state = state.copyWith(gender: gender);
  }

  void updateCulture(String? culture) {
    state = state.copyWith(culture: culture);
  }

  // -------------------------------------------------------------------------
  // Preferences handling
  // -------------------------------------------------------------------------

  /// Toggle a preference key (e.g. "activity") in the list, respecting max 5.
  void togglePreference(String key) {
    final prefs = List<String>.from(state.preferences);
    if (prefs.contains(key)) {
      prefs.remove(key);
    } else {
      if (prefs.length >= 5) return; // obey validation spec
      prefs.add(key);
    }
    state = state.copyWith(preferences: prefs);
  }

  /// Replace preferences list entirely – caller ensures constraints.
  void setPreferences(List<String> keys) {
    state = state.copyWith(preferences: List<String>.from(keys));
  }

  // -------------------------------------------------------------------------
  // Validation helpers
  // -------------------------------------------------------------------------

  bool get isValid => state.isValid;

  bool get isStep1Complete =>
      state.dateOfBirth != null && (state.gender ?? '').isNotEmpty;

  bool get isStep2Complete => state.preferences.isNotEmpty;
}

/// Global provider for widgets to watch and mutate onboarding draft.
final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingDraft>(
      (ref) => OnboardingController(),
    );
