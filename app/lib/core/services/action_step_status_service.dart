import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight service that tracks whether the user has already set their first
/// Action Step. Consumes a simple boolean flag stored in `SharedPreferences`.
///
/// This flag is optional — missing key is treated as `false`.
class ActionStepStatusService {
  static const String _kPrefsKey = 'has_set_action_step';

  /// Persist the flag locally. If [value] is `false`, the key is removed so the
  /// default remains `false` for fresh installs.
  Future<void> setHasSetActionStep(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value) {
        await prefs.setBool(_kPrefsKey, true);
      } else {
        await prefs.remove(_kPrefsKey);
      }
    } on Exception {
      // Ignore storage failures – app falls back to default behaviour.
    }
  }

  /// Returns `true` if the user has previously created an Action Step.
  Future<bool> hasSetActionStep() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kPrefsKey) ?? false;
    } on Exception {
      return false;
    }
  }
}
