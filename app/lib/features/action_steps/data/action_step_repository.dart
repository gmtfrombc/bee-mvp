import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/core/providers/supabase_provider.dart';

/// Immutable model representing a saved Action Step row.
class ActionStep {
  const ActionStep({
    required this.id,
    required this.category,
    required this.description,
    required this.frequency,
    required this.weekStart,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String category;
  final String description;
  final int frequency;
  final DateTime weekStart;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ActionStep.fromJson(Map<String, dynamic> json) {
    return ActionStep(
      id: json['id'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      frequency: json['frequency'] as int,
      weekStart: DateTime.parse(json['week_start'] as String).toUtc(),
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
    );
  }
}

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
