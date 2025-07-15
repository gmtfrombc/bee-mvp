import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'action_step_draft.dart';
import '../validators/action_step_validators.dart';

/// Manages the Action Step draft during creation / editing.
class ActionStepController extends StateNotifier<ActionStepDraft> {
  ActionStepController() : super(const ActionStepDraft());

  // ---------------------------------------------------------------------------
  // Field updaters
  // ---------------------------------------------------------------------------
  void updateCategory(String? category) {
    state = state.copyWith(category: category);
  }

  void updateDescription(String description) {
    state = state.copyWith(description: description);
  }

  void updateFrequency(int frequency) {
    state = state.copyWith(frequency: frequency);
  }

  /// Convenience getter used by UI to enable/disable primary button.
  bool get isComplete {
    return state.isComplete &&
        isPositivePhrase(state.description) &&
        isFrequencyInRange(state.frequency);
  }

  // Future: submit to Supabase (Task T3).
  Future<void> submit() async {
    // TODO: implement in Task T3 (Supabase integration)
  }
}

/// Global provider for widgets to watch and mutate the draft.
final actionStepControllerProvider =
    StateNotifierProvider<ActionStepController, ActionStepDraft>((ref) {
      return ActionStepController();
    });
