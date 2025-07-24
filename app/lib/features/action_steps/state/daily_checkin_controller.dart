import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/action_step_day_status.dart';
import 'package:app/features/action_steps/services/action_step_analytics.dart';
import 'package:app/features/action_steps/data/action_step_repository.dart';

/// Controls the check-in state for the current day.
///
/// For now, this controller keeps state only in memory. In Milestone
/// M1.5.4 T2 & T3 we will add persistence to Supabase and edge-function
/// triggers. Methods already return `Future<void>` so the public API will
/// remain stable when asynchronous I/O is introduced.
class DailyCheckinController extends AsyncNotifier<ActionStepDayStatus> {
  @override
  Future<ActionStepDayStatus> build() async {
    final current = await ref.watch(currentActionStepProvider.future);
    if (current == null) return ActionStepDayStatus.queued;

    final repo = ref.read(actionStepRepositoryProvider);
    return repo.fetchDayStatus(
      actionStepId: current.step.id,
      date: DateTime.now(),
    );
  }

  /// User indicates the Action Step was completed today.
  Future<void> markCompleted() async {
    await _updateStatus(ActionStepDayStatus.completed);
    // Analytics
    await ref.read(actionStepAnalyticsProvider).logCompleted(success: true);
  }

  /// User indicates they choose to skip today.
  Future<void> markSkipped() async {
    await _updateStatus(ActionStepDayStatus.skipped);
    await ref.read(actionStepAnalyticsProvider).logCompleted(success: false);
  }

  Future<void> _updateStatus(ActionStepDayStatus newStatus) async {
    // Optimistic UI
    state = const AsyncValue.loading();
    state = AsyncValue.data(newStatus);

    final current = await ref.watch(currentActionStepProvider.future);
    if (current == null) return; // Should not happen, but guard anyway.

    final repo = ref.read(actionStepRepositoryProvider);
    await repo.createLog(
      actionStepId: current.step.id,
      day: DateTime.now(),
      status: newStatus,
    );
  }
}

/// Global provider so UI can watch & mutate daily check-in status.
final dailyCheckinControllerProvider =
    AsyncNotifierProvider<DailyCheckinController, ActionStepDayStatus>(
      DailyCheckinController.new,
    );
