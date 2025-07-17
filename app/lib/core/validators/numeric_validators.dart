// app/lib/core/validators/numeric_validators.dart
/// Numeric-related validators consolidated for reuse across forms.
///
/// All functions follow Flutter form convention: return `null` when the input
/// is valid, otherwise return an error string suitable for displaying directly
/// in a `TextFormField.validator` callback.
///
/// Example usage:
/// ```dart
/// TextFormField(
///   validator: (v) => numericRangeValidator(v, min: 1, max: 10),
/// )
/// ```
///
/// The helpers below intentionally avoid throwing and instead treat malformed
/// input as invalid, returning a helpful error message.
library;

/// Returns true if [value] is within the inclusive range `[min, max]`.
bool isWithinRange(num value, {required num min, required num max}) =>
    value >= min && value <= max;

/// Validator that ensures the text represents a number within `[min, max]`.
///
/// If the user enters an empty string or non-numeric text, an error message is
/// returned. The optional [unit] param lets you append a unit like `kg` or
/// `°C` in the error text (e.g. "Enter 30–180 kg").
String? numericRangeValidator(
  String? value, {
  required num min,
  required num max,
  String unit = '',
}) {
  if (value == null || value.trim().isEmpty) {
    return 'Required';
  }

  final parsed = num.tryParse(value.trim());
  if (parsed == null) {
    return 'Enter a valid number';
  }

  if (!isWithinRange(parsed, min: min, max: max)) {
    final unitSuffix = unit.isNotEmpty ? ' $unit' : '';
    return 'Enter $min–$max$unitSuffix';
  }

  return null;
}

/// Validator that ensures the input is a positive (> 0) number.
/// An optional [unit] may be supplied for the error message.
String? positiveNumberValidator(String? value, {String unit = ''}) {
  if (value == null || value.trim().isEmpty) {
    return 'Required';
  }

  final parsed = num.tryParse(value.trim());
  if (parsed == null || parsed <= 0) {
    final unitSuffix = unit.isNotEmpty ? ' $unit' : '';
    return 'Enter a positive number$unitSuffix';
  }

  return null;
}
