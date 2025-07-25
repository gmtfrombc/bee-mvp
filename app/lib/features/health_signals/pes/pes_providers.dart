import 'package:flutter_riverpod/flutter_riverpod.dart';
// Removed deprecated EnergyLevelEntry model import – trend now uses PesEntry
import 'package:app/core/health_data/services/health_data_repository.dart';
import 'package:app/core/providers/supabase_provider.dart';
import 'package:flutter/material.dart';
import 'services/notification_scheduler_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/core/health_data/models/pes_entry.dart';

/// Holds the currently selected perceived energy score (1–5).
/// `null` indicates no selection yet.
final energyScoreProvider = StateProvider<int?>((ref) => null);

/// Provides the latest 7 [PesEntry] items for the authenticated user
/// ordered from oldest → newest (so charts can connect points chronologically).
/// Returns an empty list when the user is not signed-in or no data exists.
final pesTrendProvider = FutureProvider.autoDispose<List<PesEntry>>((
  ref,
) async {
  final client = ref.read(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;

  if (userId == null) return <PesEntry>[];

  final repo = ref.read(healthDataRepositoryProvider);

  // Fetch the most-recent PES entries then reverse so oldest comes first.
  final entries = await repo.fetchPesEntries(userId: userId);

  // Keep only the last 7 by date descending then reverse.
  final latest = entries.take(7).toList().reversed.toList();

  return latest;
});

// ---------------------------------------------------------------------------
// Today’s PES entry (single-day) – null when none recorded today
// ---------------------------------------------------------------------------
final todayPesEntryProvider = FutureProvider<PesEntry?>((ref) async {
  final client = ref.read(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;

  if (userId == null) return null;

  final repo = ref.read(healthDataRepositoryProvider);

  // Fetch recent entries – cached in repository
  final entries = await repo.fetchPesEntries(userId: userId);

  final now = DateTime.now();
  for (final e in entries) {
    if (e.date.year == now.year &&
        e.date.month == now.month &&
        e.date.day == now.day) {
      return e;
    }
  }

  return null;
});
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Daily Prompt Scheduling
// ---------------------------------------------------------------------------

/// Provides a fully-initialised [NotificationSchedulerService].
final notificationSchedulerProvider =
    FutureProvider<NotificationSchedulerService>((ref) async {
      return NotificationSchedulerService.create();
    });

/// Async notifier that manages the daily prompt time (defaults to 09:00 local),
/// persists changes via `shared_preferences`, and reschedules notifications.
class DailyPromptController extends AsyncNotifier<TimeOfDay> {
  static const _hourKey = 'dailyPromptHour';
  static const _minuteKey = 'dailyPromptMinute';

  @override
  Future<TimeOfDay> build() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_hourKey) ?? 9;
    final minute = prefs.getInt(_minuteKey) ?? 0;

    // Ensure a prompt is always scheduled on first build.
    final scheduler = await ref.watch(notificationSchedulerProvider.future);
    await scheduler.scheduleDailyPrompt(TimeOfDay(hour: hour, minute: minute));

    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Updates the preferred prompt [time] and reschedules notification.
  Future<void> updateTime(TimeOfDay time) async {
    state = const AsyncValue.loading();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hourKey, time.hour);
    await prefs.setInt(_minuteKey, time.minute);

    final scheduler = await ref.watch(notificationSchedulerProvider.future);
    await scheduler.scheduleDailyPrompt(time);
    state = AsyncValue.data(time);
  }

  /// Disables the PES daily prompt entirely.
  Future<void> disablePrompt() async {
    final scheduler = await ref.watch(notificationSchedulerProvider.future);
    await scheduler.cancelPrompt();
  }
}

/// Global provider for widgets to watch & mutate prompt time.
final dailyPromptControllerProvider =
    AsyncNotifierProvider<DailyPromptController, TimeOfDay>(
      DailyPromptController.new,
    );
