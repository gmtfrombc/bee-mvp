/// Provides reusable validation helpers for onboarding forms.
///
/// This avoids duplicating validation logic across multiple widgets and keeps
/// the rules in a single place that can easily migrate to a dedicated
/// validation package later.
///
/// Usage:
///   mixin MyWidget on ConsumerStatefulWidget implements InputValidator { ... }
///
/// The static helpers can also be referenced directly without applying the
/// mixin via `InputValidator.validateDateOfBirth(dob)`.
///
/// Rules are described in docs/MVP_ROADMAP/1-11 Onboarding/... specs.
///
/// - Date of Birth: Age must be between 13 and 120 (inclusive).
/// - Preferences: List must contain 1–5 items.
library input_validator;

/// Stand-alone static helpers so widgets/tests can reference them directly.
class InputValidatorUtils {
  /// Validate date of birth according to age rules.
  static String? dateOfBirth(DateTime? dob) {
    if (dob == null) return 'Required';
    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age -= 1;
    }
    if (age < 13 || age > 120) {
      return 'Please enter a valid age between 13 – 120.';
    }
    return null;
  }

  /// Validate preferences selection – must contain 1–5 items.
  static String? preferences(List<String> prefs) {
    if (prefs.isEmpty || prefs.length > 5) {
      return 'Pick at least 1 and at most 5 preferences.';
    }
    return null;
  }
}

/// Mixin providing shorthand instance methods for validation.
mixin InputValidator {
  String? validateDateOfBirth(DateTime? dob) =>
      InputValidatorUtils.dateOfBirth(dob);

  String? validatePreferences(List<String> prefs) =>
      InputValidatorUtils.preferences(prefs);
}
