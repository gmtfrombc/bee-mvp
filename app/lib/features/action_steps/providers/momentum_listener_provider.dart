import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_provider.dart';
import '../../momentum/presentation/providers/momentum_api_provider.dart';

/// Listens for broadcast momentum updates from the `update-momentum-from-action-step` edge
/// function and refreshes the global [realtimeMomentumProvider] so UI widgets update
/// within seconds after a user logs their daily Action Step.
///
/// * Subscribes to the `momentum_updates:{user_id}` realtime channel.
/// * On every `momentum_update` broadcast, it invalidates [realtimeMomentumProvider],
///   triggering a refetch with the most recent data.
/// * The provider keeps itself alive for the lifetime of the app and cleans up
///   the channel properly when disposed (e.g., on logout).
final momentumListenerProvider = Provider<void>((ref) {
  // Keep this provider alive for the whole app session.
  final link = ref.keepAlive();

  // Obtain an initialized Supabase client via the global provider.
  final supabase = ref.read(supabaseClientProvider);
  final user = supabase.auth.currentUser;

  // If the user is not yet authenticated, do nothing. The provider will be
  // rebuilt after login and the subscription will be established then.
  if (user == null) {
    // When auth status changes the supabaseClientProvider notifies listeners
    // and this provider will rebuild, so no manual listener is needed.
    return;
  }

  // Build channel name matching the edge-function pattern.
  final channelName = 'momentum_updates_${user.id}';
  final channel = supabase.channel(channelName)
    ..onBroadcast(
      event: 'momentum_update',
      callback: (payload) {
        // Invalidate cached momentum data so consumers refresh quickly.
        ref.invalidate(realtimeMomentumProvider);
      },
    ).subscribe();

  // Clean up when Riverpod disposes of this provider.
  ref.onDispose(() async {
    await channel.unsubscribe();
    link.close();
  });
});
