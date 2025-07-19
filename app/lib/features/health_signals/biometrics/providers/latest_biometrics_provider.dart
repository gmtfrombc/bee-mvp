import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/core/health_data/services/health_data_repository.dart';
import 'package:app/core/health_data/models/manual_biometrics_entry.dart';

/// Provides a realtime stream of the **latest** [`ManualBiometricsEntry`] for
/// the currently authenticated user. Emits `null` when the user has not yet
/// saved any manual biometrics.
final latestBiometricsStreamProvider = StreamProvider<ManualBiometricsEntry?>((
  ref,
) {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) {
    // Not authenticated – emit an empty stream.
    return const Stream.empty();
  }

  final repo = ref.read(healthDataRepositoryProvider);
  return repo.watchLatestBiometrics(userId);
});
