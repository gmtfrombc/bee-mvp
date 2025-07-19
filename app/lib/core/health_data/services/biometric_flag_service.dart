import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/biometric_flag.dart';
import '../../providers/supabase_provider.dart';

/// Service responsible for retrieving **unresolved** biometric flags for the
/// authenticated user and listening for real-time updates.
///
/// The API mirrors other health-data services to keep a consistent developer
/// experience.
class BiometricFlagService {
  BiometricFlagService({
    SupabaseClient? supabaseClient,
    Future<List<dynamic>> Function(String userId)? fetchOverride,
  }) : _supabase = supabaseClient ?? Supabase.instance.client,
       _fetchOverride = fetchOverride;

  final SupabaseClient _supabase;
  final Future<List<dynamic>> Function(String userId)? _fetchOverride;

  /// Returns the currently authenticated user id or `null` if the user is not
  /// signed in.
  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Fetches all **unresolved** biometric flags for [userId], ordered by the
  /// most recent detection time.
  Future<List<BiometricFlag>> fetchUnresolvedFlags(String userId) async {
    final data =
        _fetchOverride != null
            ? await _fetchOverride(userId)
            : await _supabase
                .from('biometric_flags')
                .select()
                .eq('user_id', userId)
                .eq('resolved', false)
                .order('detected_on', ascending: false);

    return (data)
        .map((e) => BiometricFlag.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Stream of **unresolved** biometric flags for [userId]. Consumers can use
  /// this to drive in-app notifications or badge counts.
  Stream<List<BiometricFlag>> listenUnresolvedFlags(String userId) {
    return _supabase
        .from('biometric_flags')
        .stream(primaryKey: ['id'])
        .map(
          (rows) =>
              rows
                  .map((e) => BiometricFlag.fromJson(e))
                  .where((flag) => flag.userId == userId && !flag.resolved)
                  .toList()
                ..sort(
                  // Most recent first
                  (a, b) => b.detectedOn.compareTo(a.detectedOn),
                ),
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Riverpod Providers
// -----------------------------------------------------------------------------

/// Provides a singleton [BiometricFlagService] backed by the global Supabase
/// client.
final biometricFlagServiceProvider = Provider<BiometricFlagService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return BiometricFlagService(supabaseClient: client);
});

/// Convenience provider exposing a stream of unresolved flags for the current
/// user. Automatically disposes when no longer listened-to.
final unresolvedBiometricFlagsProvider =
    StreamProvider.autoDispose<List<BiometricFlag>>((ref) {
      final service = ref.watch(biometricFlagServiceProvider);
      final userId = service.currentUserId;
      if (userId == null) {
        // If the user is not authenticated, emit an empty list.
        return const Stream.empty();
      }
      return service.listenUnresolvedFlags(userId);
    });
