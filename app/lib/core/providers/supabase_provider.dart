import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/environment.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/navigation/routes.dart';
import 'package:flutter/widgets.dart';

/// Enable anonymous sign-in only when running in demo mode.
/// Activate by passing:
///   flutter run --dart-define=DEMO_MODE=true
const bool kDemoMode = bool.fromEnvironment('DEMO_MODE', defaultValue: false);

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
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );

    // Optionally perform anonymous sign-in for demo environments.
    final client = Supabase.instance.client;
    if (kDemoMode && client.auth.currentSession == null) {
      final anonRes = await client.auth.signInAnonymously();
      if (kDebugMode) {
        debugPrint(
          '🆔 Anonymous session established (demo mode): ${anonRes.user?.id}',
        );
      }
    }

    // Log the user id so testers can easily copy it for seeding synthetic data
    debugPrint('⚡️ Current user id: ${client.auth.currentUser?.id}');
    debugPrint('✅ Supabase initialized successfully');
    return Supabase.instance.client;
  }
});

/// Provider for Supabase client that can be used synchronously
/// Only use this after you're sure Supabase is initialized
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

class OnboardingGuard {
  const OnboardingGuard();

  /// Redirect callback used by GoRouter to ensure that users who have not
  /// completed onboarding are always sent to the onboarding flow before
  /// accessing the main application.
  ///
  /// Returns the path to redirect to (e.g. `/onboarding/step1`) or `null` to
  /// allow navigation to proceed.
  FutureOr<String?> call(BuildContext context, GoRouterState state) async {
    // Allow any route that is already within the onboarding flow to proceed.
    if (state.fullPath?.startsWith('/onboarding') == true) {
      return null;
    }

    // If Supabase has not been initialised yet we cannot decide – allow
    // navigation for now (LaunchController will handle splash/auth states).
    SupabaseClient client;
    try {
      client = Supabase.instance.client;
    } catch (_) {
      return null;
    }

    final user = client.auth.currentUser;
    // Guard only applies to authenticated users.
    if (user == null) return null;

    try {
      final data =
          await client
              .from('profiles')
              .select('onboarding_complete')
              .eq('id', user.id)
              .maybeSingle();

      final completed = (data?['onboarding_complete'] as bool?) ?? false;
      if (!completed) {
        // User still needs onboarding → redirect to first step.
        return kOnboardingStep1Route;
      }
    } catch (_) {
      // On failure (e.g. network issues) default to safer option – send user to
      // onboarding so that required data is collected.
      return kOnboardingStep1Route;
    }

    // All checks passed → no redirect.
    return null;
  }
}
