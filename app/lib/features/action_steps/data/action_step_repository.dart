import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/core/providers/supabase_provider.dart';
import '../models/action_step.dart';
import '../models/action_step_day_status.dart';
import '../models/action_step_history_entry.dart';

/// Convenience wrapper combining the current Action Step row with week progress.
class CurrentActionStep {
  const CurrentActionStep({required this.step, required this.completed});
  final ActionStep step;
  final int completed;
  int get target => step.frequency;
}

/// Repository handling Supabase queries for Action Steps.
class ActionStepRepository {
  ActionStepRepository(this._client);

  final SupabaseClient _client;

  /// Fetch the latest Action Step for the signed-in user.
  Future<CurrentActionStep?> fetchCurrent() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final row =
        await _client
            .from('action_steps')
            .select('*')
            .eq('user_id', userId)
            .order('week_start', ascending: false)
            .limit(1)
            .maybeSingle();

    if (row == null) return null;

    final step = ActionStep.fromJson(row);

    // Count completions for current ISO week.
    final monday = DateTime.now().toUtc().subtract(
      Duration(days: DateTime.now().toUtc().weekday - DateTime.monday),
    );
    final sunday = monday.add(const Duration(days: 6));

    final logs = await _client
        .from('action_step_logs')
        .select('id')
        .eq('action_step_id', step.id)
        .gte('day', _format(monday))
        .lte('day', _format(sunday));

    return CurrentActionStep(step: step, completed: logs.length);
  }

  /// Update mutable fields of an existing Action Step.
  Future<void> updateActionStep(ActionStep step) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

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

  /// Delete an Action Step row (cascades logs via DB).
  Future<void> deleteActionStep(String id) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('action_steps')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }

  String _format(DateTime d) => d.toIso8601String().substring(0, 10);

  // ---------------------------------------------------------------------------
  // Daily log helpers (T12)
  // ---------------------------------------------------------------------------

  /// Returns the [ActionStepDayStatus] for the given [date]. If no log exists
  /// yet, returns [ActionStepDayStatus.queued]. If the user is unauthenticated
  /// or has no current Action Step, also returns `queued`.
  Future<ActionStepDayStatus> fetchDayStatus({required String actionStepId, required DateTime date}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return ActionStepDayStatus.queued;

    final dateStr = _format(date);

    final row = await _client
        .from('action_step_logs')
        .select('status')
        .eq('user_id', userId)
        .eq('action_step_id', actionStepId)
        .eq('day', dateStr)
        .maybeSingle();

    if (row == null) return ActionStepDayStatus.queued;

    return ActionStepDayStatus.values.firstWhere(
      (e) => e.name == row['status'],
      orElse: () => ActionStepDayStatus.queued,
    );
  }

  /// Inserts or updates a log for the given day. Uses an `upsert` so the same
  /// row is updated if the user toggles between completed/skipped.
  Future<void> createLog({
    required String actionStepId,
    required DateTime day,
    required ActionStepDayStatus status,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('action_step_logs').upsert({
      'user_id': userId,
      'action_step_id': actionStepId,
      'day': _format(day),
      'status': status.name,
    });
  }

  // ---------------------------------------------------------------------------
  // History helpers (T13)
  // ---------------------------------------------------------------------------

  /// Returns a paginated list of the user’s past [ActionStep]s along with
  /// how many days were completed for each week. Results are ordered by
  /// `week_start` descending so the most recent week comes first.
  ///
  /// [offset] – starting index (0-based) for pagination.
  /// [limit]  – number of rows to return. Defaults to 10.
  Future<List<ActionStepHistoryEntry>> fetchHistory({
    int offset = 0,
    int limit = 10,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    // Fetch the requested slice of Action Steps.
    final rows = await _client
        .from('action_steps')
        .select('*')
        .eq('user_id', userId)
        .order('week_start', ascending: false)
        .range(offset, offset + limit - 1);

    // For each step gather its completion count.
    final List<ActionStepHistoryEntry> history = [];
    for (final row in rows) {
      final step = ActionStep.fromJson(row);
      final logs = await _client
          .from('action_step_logs')
          .select('id')
          .eq('action_step_id', step.id);
      history.add(
        ActionStepHistoryEntry(step: step, completed: logs.length),
      );
    }
    return history;
  }
}

// ---------------------------------------------------------------------------
// Riverpod providers
// ---------------------------------------------------------------------------
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
