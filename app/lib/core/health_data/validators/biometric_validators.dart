/// Biometric field validators that support both metric and imperial units.
///
/// All functions follow Flutter [`FormFieldValidator`] convention: return
/// `null` when the input is valid, otherwise return a human-readable error
/// string that can be displayed directly beneath the input field.
///
/// Usage:
/// ```dart
/// HealthInputField(
///   label: 'Weight',
///   validator: (v) => BiometricValidators.weight(v, unit: selectedUnit),
/// )
/// ```
library biometric_validators;

import 'package:app/core/health_data/validators/numeric_validators.dart';

/// Collection of biometric validators.
class BiometricValidators {
  BiometricValidators._(); // no instantiation

  // ---------------------------------------------------------------------------
  // Weight
  // ---------------------------------------------------------------------------

  /// Validates weight entered in either kg or lbs.
  ///
  /// [value] – raw text the user typed.
  /// [unit]  – 'kg' or 'lbs'. Case-insensitive.
  static String? weight(String? value, {required String unit}) {
    if (value == null || value.trim().isEmpty) return 'Required';

    final double? parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Enter a valid number';

    final unitLower = unit.toLowerCase();
    late double kgValue;
    if (unitLower == 'kg') {
      kgValue = parsed;
    } else if (unitLower == 'lbs' || unitLower == 'lb') {
      kgValue = NumericValidators.lbToKg(parsed);
    } else {
      return 'Unsupported unit';
    }

    if (!NumericValidators.isWeightKgValid(kgValue)) {
      // Provide range hint in both units for clarity.
      return 'Enter 20‒300 kg (44‒660 lbs)';
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Height
  // ---------------------------------------------------------------------------

  /// Validates height entered in cm or feet.
  ///
  /// When [unit] == 'cm' we apply the 120‒250 cm rule directly.
  /// When [unit] == 'ft', we convert to cm (ft × 30.48) and validate.
  static String? height(String? value, {required String unit}) {
    if (value == null || value.trim().isEmpty) return 'Required';

    final double? parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Enter a valid number';

    final unitLower = unit.toLowerCase();
    late double cmValue;
    if (unitLower == 'cm') {
      cmValue = parsed;
    } else if (unitLower == 'ft') {
      cmValue = NumericValidators.ftToCm(parsed);
    } else {
      return 'Unsupported unit';
    }

    if (!NumericValidators.isHeightCmValid(cmValue)) {
      return 'Enter 120‒250 cm (approx. 4‒8 ft)';
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Fasting Glucose
  // ---------------------------------------------------------------------------

  /// Validates fasting glucose in mg/dL (50–300 mg/dL).
  static String? fastingGlucose(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';

    final double? parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Enter a valid number';

    if (!NumericValidators.isFastingGlucoseValid(parsed)) {
      return 'Enter 50‒300 mg/dL';
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // A1C (Haemoglobin)
  // ---------------------------------------------------------------------------

  /// Validates A1C percentage (3.0–15.0 %).
  static String? a1c(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';

    final double? parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Enter a valid number';

    if (!NumericValidators.isA1cPercentValid(parsed)) {
      return 'Enter 3‒15 %';
    }

    return null;
  }
}
