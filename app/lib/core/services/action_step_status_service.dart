import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Lightweight service that tracks whether the user has already set their first
/// Action Step. Consumes a simple boolean flag stored in `SharedPreferences`.
///
/// This flag is optional — missing key is treated as `false`.
class ActionStepStatusService {
  // Device-persistent flag recording if *this user* has set an Action Step.
  // We suffix the key with the Supabase UID so multiple accounts on one
  // device do not interfere with each other.
  static const String _kPrefsKeyPrefix = 'has_set_action_step_';

  String? _currentUserId() {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  /// Persist the flag locally. If [value] is `false`, the key is removed so the
  /// default remains `false` for fresh installs.
  Future<void> setHasSetActionStep(bool value) async {
    final uid = _currentUserId();
    if (uid == null) return; // not signed-in → ignore

    final key = '$_kPrefsKeyPrefix$uid';
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value) {
        await prefs.setBool(key, true);
      } else {
        await prefs.remove(key);
      }
    } on Exception {
      // Ignore storage failures – app falls back to default behaviour.
    }
  }

  /// Returns `true` if *this user* has previously created an Action Step.
  Future<bool> hasSetActionStep() async {
    final uid = _currentUserId();
    if (uid == null) return false;

    final key = '$_kPrefsKeyPrefix$uid';
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key) ?? false;
    } on Exception {
      return false;
    }
  }
}
