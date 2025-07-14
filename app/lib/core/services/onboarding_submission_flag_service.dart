import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight service that stores a local flag to indicate that the final
/// onboarding submission RPC is currently running.
///
/// When this flag is `true` we treat the user as "in-flight" even though
/// `profiles.onboarding_complete` may not yet be updated on Supabase. This
/// prevents the [OnboardingGuard] from bouncing the user back into the
/// onboarding flow while the app is navigating to `/launch` after tapping
/// "Finish".
class OnboardingSubmissionFlagService {
  static const String _kPrefsKey = 'onboarding_submitting';

  /// Set the flag to [value]. If [value] is `false` the key is removed.
  Future<void> setSubmitting(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value) {
        await prefs.setBool(_kPrefsKey, true);
      } else {
        await prefs.remove(_kPrefsKey);
      }
    } on Exception {
      // Ignore storage failures (e.g., in tests without plugin setup).
    }
  }

  /// Return `true` if a submission is currently in-flight.
  Future<bool> isSubmitting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kPrefsKey) ?? false;
    } on Exception {
      return false;
    }
  }
}
