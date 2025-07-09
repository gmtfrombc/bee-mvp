// ignore_for_file: depend_on_referenced_packages

import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import 'package:app/core/navigation/routes.dart';

/// Middleware that decides whether to send a signed-in user to the onboarding
/// flow or allow them to proceed to the main app.
///
/// Call [maybeRedirect] immediately after a successful login/signup. If the
/// user's profile shows `onboarding_complete = false` (or the profile row is
/// missing / fetch fails), the user is routed to `/onboarding`.
class OnboardingRedirect {
  const OnboardingRedirect(this._router, this._authService);

  final GoRouter _router;
  final AuthService _authService;

  /// Checks the user's onboarding status and navigates accordingly.
  Future<void> maybeRedirect(User user) async {
    try {
      final profile = await _authService.fetchProfile(user.id);
      final needsOnboarding =
          profile == null || profile.onboardingComplete == false;

      if (needsOnboarding) {
        _router.go(kOnboardingStep1Route);
      }
    } catch (_) {
      // If the query fails, default to showing onboarding (safer assumption).
      _router.go(kOnboardingStep1Route);
    }
  }
}
