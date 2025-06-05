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

    debugPrint('✅ Supabase initialized successfully');
    return Supabase.instance.client;
  }
});

/// Provider for Supabase client that can be used synchronously
/// Only use this after you're sure Supabase is initialized
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
