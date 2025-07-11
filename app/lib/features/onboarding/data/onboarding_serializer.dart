import 'package:app/features/onboarding/models/onboarding_draft.dart';

class OnboardingSerializer {
  // Prevent instantiation; this class provides only static helpers.
  const OnboardingSerializer._();

  /// Converts an [OnboardingDraft] to JSON for network transmission.
  ///
  /// Removes entries whose values are `null` or empty lists to keep the
  /// payload compact before sending to Supabase.
  static Map<String, dynamic> toJson(OnboardingDraft draft) {
    final Map<String, dynamic> json = Map<String, dynamic>.from(draft.toJson());

    // Strip null values and empty arrays.
    json.removeWhere((key, value) {
      if (value == null) return true;
      if (value is List && value.isEmpty) return true;
      return false;
    });
    return json;
  }

  /// Restores an [OnboardingDraft] from its JSON representation.
  static OnboardingDraft fromJson(Map<String, dynamic> json) =>
      OnboardingDraft.fromJson(json);
}
