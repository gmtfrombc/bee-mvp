import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/action_step_day_status.dart';

/// Controls the check-in state for the current day.
///
/// For now, this controller keeps state only in memory. In Milestone
/// M1.5.4 T2 & T3 we will add persistence to Supabase and edge-function
/// triggers. Methods already return `Future<void>` so the public API will
/// remain stable when asynchronous I/O is introduced.
class DailyCheckinController extends AsyncNotifier<ActionStepDayStatus> {
  @override
  Future<ActionStepDayStatus> build() async {
    // TODO(M1.5.4-T2): Replace with repository lookup / local cache.
    return ActionStepDayStatus.queued;
  }

  /// User indicates the Action Step was completed today.
  Future<void> markCompleted() async {
    // Optimistic update: immediately show new state.
    state = const AsyncValue.loading();
    state = const AsyncValue.data(ActionStepDayStatus.completed);

    // TODO(M1.5.4-T2): Persist completion log to Supabase.
  }

  /// User indicates they choose to skip today.
  Future<void> markSkipped() async {
    state = const AsyncValue.loading();
    state = const AsyncValue.data(ActionStepDayStatus.skipped);

    // TODO(M1.5.4-T2): Persist skip log to Supabase.
  }
}

/// Global provider so UI can watch & mutate daily check-in status.
final dailyCheckinControllerProvider =
    AsyncNotifierProvider<DailyCheckinController, ActionStepDayStatus>(
      DailyCheckinController.new,
    );
