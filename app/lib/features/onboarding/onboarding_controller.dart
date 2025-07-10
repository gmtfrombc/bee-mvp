import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/onboarding_draft.dart';
import '../../core/models/medical_history.dart';

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

  void updateReadinessLevel(int? level) {
    state = state.copyWith(readinessLevel: level);
  }

  void updateConfidenceLevel(int? level) {
    state = state.copyWith(confidenceLevel: level);
  }

  void updateMindsetType(String? type) {
    state = state.copyWith(mindsetType: type);
  }

  // ---------------------------------------------------------------------
  // Mindset & Motivation updates (Section 4)
  // ---------------------------------------------------------------------

  void updateMotivationReason(String? reason) {
    state = state.copyWith(motivationReason: reason);
  }

  void updateSatisfactionOutcome(String? outcome) {
    state = state.copyWith(satisfactionOutcome: outcome);
  }

  void updateChallengeResponse(String? response) {
    state = state.copyWith(challengeResponse: response);
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
  // Priorities handling (Q10)
  // -------------------------------------------------------------------------

  /// Toggle a priority key (e.g. "nutrition") in the list, respecting max 2.
  void togglePriority(String key) {
    final priorities = List<String>.from(state.priorities);
    if (priorities.contains(key)) {
      priorities.remove(key);
    } else {
      if (priorities.length >= 2) return; // Q10 allows max 2 selections
      priorities.add(key);
    }
    state = state.copyWith(priorities: priorities);
  }

  /// Replace priorities list entirely – caller ensures constraints.
  void setPriorities(List<String> keys) {
    state = state.copyWith(priorities: List<String>.from(keys));
  }

  void updateGoalTarget(String? target) {
    state = state.copyWith(goalTarget: target);
  }

  // ---------------------------------------------------------------------
  // Medical History (Section 6)
  // ---------------------------------------------------------------------

  /// Toggle a [MedicalCondition] in the list of selected conditions.
  void toggleMedicalCondition(MedicalCondition condition) {
    final conditions = List<MedicalCondition>.from(state.medicalConditions);
    if (conditions.contains(condition)) {
      conditions.remove(condition);
    } else {
      conditions.add(condition);
    }
    state = state.copyWith(medicalConditions: conditions);
  }

  bool get isMedicalHistoryComplete => state.medicalConditions.isNotEmpty;

  // ---------------------------------------------------------------------
  // Goal Setup completion (Section 5)
  // ---------------------------------------------------------------------
  bool get isGoalSetupComplete => (state.goalTarget ?? '').isNotEmpty;

  // -------------------------------------------------------------------------
  // Validation helpers
  // -------------------------------------------------------------------------

  bool get isValid => state.isValid;

  bool get isStep1Complete =>
      state.dateOfBirth != null && (state.gender ?? '').isNotEmpty;

  bool get isStep2Complete => state.preferences.isNotEmpty;

  bool get isReadinessComplete =>
      state.priorities.isNotEmpty &&
      state.readinessLevel != null &&
      state.confidenceLevel != null;

  bool get isMindsetComplete =>
      state.motivationReason != null &&
      state.satisfactionOutcome != null &&
      state.challengeResponse != null &&
      state.mindsetType != null;
}

/// Global provider for widgets to watch and mutate onboarding draft.
final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingDraft>(
      (ref) => OnboardingController(),
    );
