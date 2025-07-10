/// Provides reusable numeric range validation helpers used in onboarding
/// numeric input fields (weight, blood pressure, etc.).
///
/// Each helper returns a validation error [String] when the input is invalid
/// or `null` when the value passes validation. This mirrors Flutter's
/// [`FormFieldValidator`] convention so the validators can be wired directly
/// into `TextFormField.validator`.
///
/// The rules are defined in
/// `docs/MVP_ROADMAP/1-11 Onboarding/Milestones, Tasks, and Epic Docs/`
/// – see M1.11.4 success criteria.
///
/// - Weight: 50 – 600 lb
/// - Blood pressure (sys / dia): 60 – 200 mmHg
library number_range_validator;

class NumberRangeValidator {
  /// Generic range validator used by the specific helpers below.
  ///
  /// [value] – nullable string representing user input.
  /// [min] & [max] – inclusive bounds.
  /// [fieldLabel] – name used in error messages.
  static String? validateRange(
    String? value,
    int min,
    int max,
    String fieldLabel,
  ) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid number.';
    }
    if (parsed < min || parsed > max) {
      return '$fieldLabel must be between $min and $max.';
    }
    return null;
  }

  /// Validate weight in pounds (50 – 600).
  static String? weightLb(String? value) =>
      validateRange(value, 50, 600, 'Weight');

  /// Validate systolic blood pressure (60 – 200 mmHg).
  static String? bpSystolic(String? value) =>
      validateRange(value, 60, 200, 'Systolic BP');

  /// Validate diastolic blood pressure (60 – 200 mmHg).
  static String? bpDiastolic(String? value) =>
      validateRange(value, 60, 200, 'Diastolic BP');
}
