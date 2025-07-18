import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/health_data/models/energy_level.dart';
import 'package:app/core/health_data/services/health_data_repository.dart';
import 'package:app/core/providers/supabase_provider.dart';

/// Holds the currently selected perceived energy score (1–5).
/// `null` indicates no selection yet.
final energyScoreProvider = StateProvider<int?>((ref) => null);

/// Provides the latest 7 [EnergyLevelEntry] items for the authenticated user
/// ordered from oldest → newest (so charts can connect points chronologically).
/// Returns an empty list when the user is not signed-in or no data exists.
final pesTrendProvider = FutureProvider.autoDispose<List<EnergyLevelEntry>>((
  ref,
) async {
  final client = ref.read(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;

  if (userId == null) return <EnergyLevelEntry>[];

  final repo = ref.read(healthDataRepositoryProvider);

  // Fetch the most-recent entries then reverse so oldest comes first.
  final entries = await repo.fetchEnergyLevels(userId: userId);

  // Keep only the last 7 by date descending then reverse.
  final latest = entries.take(7).toList().reversed.toList();

  return latest;
});
