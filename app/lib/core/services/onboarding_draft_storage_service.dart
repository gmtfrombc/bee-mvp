import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/onboarding/models/onboarding_draft.dart';
import 'package:flutter/services.dart';

/// Handles saving and loading [OnboardingDraft] objects to local storage.
///
/// Storage key is currently static but can be extended to include userId when
/// authentication integration is required.
class OnboardingDraftStorageService {
  static const String _prefsKey = 'onboarding_draft';

  /// Save [draft] JSON into [SharedPreferences].
  Future<void> saveDraft(OnboardingDraft draft) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(draft.toJson()));
    } on MissingPluginException {
      // Ignored in test environment where SharedPreferences is not mocked.
    }
  }

  /// Load the previously saved draft, or `null` if none found / parse error.
  Future<OnboardingDraft?> loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefsKey);
      if (jsonStr == null) return null;
      final Map<String, dynamic> map = jsonDecode(jsonStr);
      return OnboardingDraft.fromJson(map);
    } on MissingPluginException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Clear any stored draft.
  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } on MissingPluginException {
      // ignore in test env
    }
  }
}
