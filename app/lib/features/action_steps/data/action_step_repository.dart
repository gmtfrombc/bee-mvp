import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/core/providers/supabase_provider.dart';
import '../models/action_step.dart';

/// Lightweight DTO containing the current Action Step plus week-to-date progress.
class CurrentActionStep {
  const CurrentActionStep({required this.step, required this.completed});

  final ActionStep step;
  final int completed;

  int get target => step.frequency;
}

/// Repository responsible for all DB interactions related to Action Steps.
///
/// Exposes simple high-level methods used by UI or other services.  Keep
/// Supabase SQL in one place so that we can upgrade/optimise later without
/// touching feature code.
class ActionStepRepository {
  ActionStepRepository(this._client);

  final SupabaseClient _client;

  /// Fetches the current (latest) Action Step for the signed-in user.
  /// Returns `null` if the user has none.
  Future<CurrentActionStep?> fetchCurrent() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    // 1. Latest Action Step row for the user (by week_start DESC)
    final stepRow =
        await _client
            .from('action_steps')
            .select('*')
            .eq('user_id', userId)
            .order('week_start', ascending: false)
            .limit(1)
            .maybeSingle();

    if (stepRow == null) return null;

    final step = ActionStep.fromJson(stepRow);

    // 2. Count completion logs within current week (Mon-Sun UTC)
    final monday = _startOfIsoWeek(DateTime.now().toUtc());
    final sunday = monday.add(const Duration(days: 6));

    final logs = await _client
        .from('action_step_logs')
        .select('id')
        .eq('action_step_id', step.id)
        .gte('day', _formatDate(monday))
        .lte('day', _formatDate(sunday));

    return CurrentActionStep(step: step, completed: logs.length);
  }

  /// Updates the given Action Step row.  Only mutable fields are updated.
  Future<void> updateActionStep(ActionStep step) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('User not authenticated');
    }

    await _client
        .from('action_steps')
        .update({
          'category': step.category,
          'description': step.description,
          'frequency': step.frequency,
        })
        .eq('id', step.id)
        .eq('user_id', userId);
  }

  /// Permanently deletes the Action Step row (and cascading logs) for the user.
  Future<void> deleteActionStep(String id) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('User not authenticated');
    }

    await _client
        .from('action_steps')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  static DateTime _startOfIsoWeek(DateTime dateUtc) {
    final diff = dateUtc.weekday - DateTime.monday; // 0-based
    return dateUtc.subtract(Duration(days: diff));
  }

  static String _formatDate(DateTime d) => d.toIso8601String().substring(0, 10);
}

// -----------------------------------------------------------------------------
// Riverpod provider
// -----------------------------------------------------------------------------

final actionStepRepositoryProvider = Provider<ActionStepRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ActionStepRepository(client);
});

final currentActionStepProvider = FutureProvider<CurrentActionStep?>((
  ref,
) async {
  final repo = ref.watch(actionStepRepositoryProvider);
  return repo.fetchCurrent();
});
