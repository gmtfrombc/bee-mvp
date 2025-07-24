import 'action_step.dart';

/// Convenience model combining an Action Step with its completion count for a
/// given week.
class ActionStepHistoryEntry {
  const ActionStepHistoryEntry({required this.step, required this.completed});

  /// The Action Step row as stored in Supabase.
  final ActionStep step;

  /// Number of days the user logged this Action Step as completed.
  final int completed;

  /// Helper indicating whether the user met or exceeded their weekly target.
  bool get reachedGoal => completed >= step.frequency;
} 