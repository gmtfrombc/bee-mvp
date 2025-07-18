import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'action_step_draft.dart';
import '../validators/action_step_validators.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/core/providers/supabase_provider.dart';
import 'package:app/core/services/action_step_status_service.dart';
import 'package:app/features/action_steps/services/action_step_analytics.dart';

/// Manages the Action Step draft during creation / editing.
class ActionStepController extends StateNotifier<ActionStepDraft> {
  ActionStepController(this._client, this._analytics)
    : super(const ActionStepDraft());

  /// Supabase client injected via provider for insertion.
  final SupabaseClient _client;
  final ActionStepAnalytics _analytics;

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

  /// Persists the current draft to Supabase `action_steps` table.
  /// Throws if the user is unauthenticated or insert fails.
  Future<void> submit() async {
    final draft = state;

    // Guard clauses – these should already be enforced by UI.
    if (!draft.isComplete) {
      throw StateError('Draft is incomplete');
    }

    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('User not authenticated');
    }

    // Compute start of current ISO week (Monday) as required by schema.
    final nowUtc = DateTime.now().toUtc();
    final mondayUtc = nowUtc.subtract(Duration(days: nowUtc.weekday - 1));

    final payload = <String, dynamic>{
      'user_id': userId,
      'category': draft.category,
      'description': draft.description.trim(),
      'frequency': draft.frequency,
      'week_start': mondayUtc.toIso8601String().substring(0, 10), // YYYY-MM-DD
    };

    // Perform insert – rely on Supabase exceptions for error handling.
    final inserted =
        await _client
            .from('action_steps')
            .insert(payload)
            .select('*')
            .maybeSingle();

    final actionStepId = inserted?['id']?.toString() ?? 'unknown';

    // Fire analytics event.
    await _analytics.logSet(
      actionStepId: actionStepId,
      category: draft.category ?? 'unknown',
      description: draft.description.trim(),
      frequency: draft.frequency,
      weekStart: mondayUtc.toIso8601String().substring(0, 10),
    );

    await ActionStepStatusService().setHasSetActionStep(true);
  }
}

/// Global provider for widgets to watch and mutate the draft.
final actionStepControllerProvider =
    StateNotifierProvider<ActionStepController, ActionStepDraft>((ref) {
      final client = ref.watch(supabaseClientProvider);
      final analytics = ref.watch(actionStepAnalyticsProvider);
      return ActionStepController(client, analytics);
    });
