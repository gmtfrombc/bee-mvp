/// Action step draft model used by [ActionStepController].
///
/// Follows architecture rule – models live in their own file under `state/models`.
/// No Freezed yet (code-gen infra to be enabled later).
class ActionStepDraft {
  const ActionStepDraft({
    this.category,
    this.description = '',
    this.frequency = 3,
  });

  /// Category key selected by the user (e.g. "exercise", "nutrition").
  final String? category;

  /// Positive-phrased description provided by the user.
  final String description;

  /// Target completions per week, must be between 3–7.
  final int frequency;

  ActionStepDraft copyWith({
    String? category,
    String? description,
    int? frequency,
  }) {
    return ActionStepDraft(
      category: category ?? this.category,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
    );
  }

  /// Whether all required fields have been filled.
  bool get isComplete =>
      (category?.isNotEmpty ?? false) && description.trim().isNotEmpty;
}
