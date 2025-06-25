import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/health_revocation_watcher.dart';

/// Exposes the singleton so other layers can call `evaluateCurrentPermissions()` if needed.
final healthRevocationWatcherProvider = Provider<HealthRevocationWatcher>((
  ref,
) {
  final watcher = HealthRevocationWatcher();
  // Ensure watcher is lazily initialised.
  // ignore: unawaited_futures
  watcher.evaluateCurrentPermissions();
  ref.onDispose(() => watcher.dispose());
  return watcher;
});

/// Async provider that returns `true` when *any* required permission is
/// currently revoked, based on the flag persisted by [HealthRevocationWatcher].
final revocationFlagProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(kRevokedFlagPrefsKey) ?? false;
});

/// Stream provider that rebuilds listeners whenever the revoked flag changes
/// (preferred for UI widgets that need to update instantly).
final revokedStreamProvider = StreamProvider<bool>((ref) {
  final watcher = ref.watch(healthRevocationWatcherProvider);
  return watcher.revokedStream;
});
