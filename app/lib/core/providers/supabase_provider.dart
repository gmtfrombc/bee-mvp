import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/environment.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/navigation/routes.dart';
import 'package:flutter/widgets.dart';
import 'package:app/core/services/onboarding_submission_flag_service.dart';

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
    try {
      debugPrint('GUARD_IN: ${state.uri.toString()}');
      debugPrint(
        'GUARD_DETAILS: fullPath=${state.fullPath ?? "null"}, path=${state.path ?? "null"}, name=${state.name ?? "null"}',
      );
    } catch (e) {
      debugPrint('GUARD_IN: Error accessing state: $e');
      return null;
    }

    // Always allow auth & confirmation pages to avoid redirect loops.
    final uriString = state.uri.toString();
    if (uriString == '/auth' ||
        uriString == '/login' ||
        uriString.startsWith('/confirm')) {
      debugPrint(
        'GUARD_OUT: auth/login/confirm route "$uriString" - no redirect',
      );
      return null;
    }

    // Allow any route that is already within the onboarding flow to proceed.
    if (state.fullPath?.startsWith('/onboarding') == true) {
      debugPrint('GUARD_OUT: onboarding route - null');
      return null;
    }

    // If a submission is currently running, bypass remote profile check so we
    // don't redirect the user back into onboarding while the flag hasn't yet
    // been persisted to Supabase.
    try {
      final flagService = OnboardingSubmissionFlagService();
      if (await flagService.isSubmitting()) {
        debugPrint('GUARD_OUT: submission running - null');
        return null;
      }
    } catch (e) {
      debugPrint('GUARD_OUT: submission running - null');
      return null;
    }

    // If Supabase has not been initialised yet we cannot decide – allow
    // navigation for now (LaunchController will handle splash/auth states).
    SupabaseClient client;
    try {
      client = Supabase.instance.client;
    } catch (_) {
      debugPrint('GUARD_OUT: supabase not ready - null');
      return null;
    }

    final user = client.auth.currentUser;
    // If user is not authenticated, redirect to login
    if (user == null) {
      debugPrint('GUARD_OUT: no user - /login');
      return '/login';
    }

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
        debugPrint('GUARD_OUT: onboarding incomplete - $kOnboardingStep1Route');
        return kOnboardingStep1Route;
      }
    } catch (_) {
      // On failure (e.g. network issues) default to safer option – send user to
      // onboarding so that required data is collected.
      debugPrint('GUARD_OUT: profile fetch failed - $kOnboardingStep1Route');
      return kOnboardingStep1Route;
    }

    // All checks passed → no redirect.
    debugPrint('GUARD_OUT: all checks passed - null');
    return null;
  }
}
