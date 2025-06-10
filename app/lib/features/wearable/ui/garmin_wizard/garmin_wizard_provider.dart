/// Garmin Wizard State Management
///
/// Providers and state notifiers for managing the Garmin→Apple Health
/// enablement wizard progression and state.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'garmin_wizard_models.dart';

/// Provider for managing wizard state
final garminWizardProvider =
    StateNotifierProvider<GarminWizardNotifier, GarminWizardState>((ref) {
      return GarminWizardNotifier();
    });

/// State notifier for managing wizard progression
class GarminWizardNotifier extends StateNotifier<GarminWizardState> {
  GarminWizardNotifier()
    : super(GarminWizardState(steps: GarminWizardSteps.getInitialSteps()));

  void completeStep(int stepIndex) {
    if (stepIndex >= 0 && stepIndex < state.steps.length) {
      final updatedSteps = List<GarminWizardStep>.from(state.steps);
      updatedSteps[stepIndex] = updatedSteps[stepIndex].copyWith(
        isCompleted: true,
      );

      state = state.copyWith(
        steps: updatedSteps,
        currentStepIndex:
            stepIndex < state.steps.length - 1 ? stepIndex + 1 : stepIndex,
        isCompleted: updatedSteps.every((step) => step.isCompleted),
      );
    }
  }

  void uncompleteStep(int stepIndex) {
    if (stepIndex >= 0 && stepIndex < state.steps.length) {
      final updatedSteps = List<GarminWizardStep>.from(state.steps);
      updatedSteps[stepIndex] = updatedSteps[stepIndex].copyWith(
        isCompleted: false,
      );

      state = state.copyWith(
        steps: updatedSteps,
        currentStepIndex: stepIndex,
        isCompleted: false,
      );
    }
  }

  void dismissWizard() {
    state = state.copyWith(isDismissed: true);
  }

  void resetWizard() {
    state = GarminWizardState(steps: GarminWizardSteps.getInitialSteps());
  }
}
