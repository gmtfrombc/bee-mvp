import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/environment.dart';
import 'package:flutter/foundation.dart';

/// Provider for initialized Supabase client
/// This ensures Supabase is properly initialized before providing the client
final supabaseProvider = FutureProvider<SupabaseClient>((ref) async {
  // Check if Supabase is already initialized
  try {
    return Supabase.instance.client;
  } catch (e) {
    // Not initialized yet, so initialize it
    debugPrint('🔄 Initializing Supabase...');

    if (!Environment.hasValidConfiguration) {
      throw Exception('Supabase configuration is incomplete');
    }

    await Supabase.initialize(
      url: Environment.supabaseUrl,
      anonKey: Environment.supabaseAnonKey,
    );

    // Ensure we always have an authenticated session (anonymous if needed)
    final client = Supabase.instance.client;
    if (client.auth.currentSession == null) {
      final anonRes = await client.auth.signInAnonymously();
      if (kDebugMode) {
        debugPrint('🆔 Anonymous session established: ${anonRes.user?.id}');
      }
    }

    // Log the user id so testers can easily copy it for seeding synthetic data
    debugPrint('⚡️ Current user id: \\${client.auth.currentUser?.id}');
    debugPrint('✅ Supabase initialized successfully');
    return Supabase.instance.client;
  }
});

/// Provider for Supabase client that can be used synchronously
/// Only use this after you're sure Supabase is initialized
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
