/// Numeric validation and unit-conversion utilities used across Health Data.
///
/// These helpers are intentionally lightweight (no external deps) so that they
/// can be reused in plain Dart code, Supabase edge functions, and Flutter UI
/// widgets alike.
class NumericValidators {
  NumericValidators._(); // no instantiation

  /// Generic range check (inclusive).
  static bool isInRange(num value, {required num min, required num max}) =>
      value >= min && value <= max;

  /// Returns `true` if value is positive (> 0).
  static bool isPositive(num value) => value > 0;

  // ──────────────────────────────────────────────────────────────────────────────
  // Domain-specific validators
  // ──────────────────────────────────────────────────────────────────────────────

  /// Weight in kilograms – roughly 20 kg‒300 kg covers 99 % of adults.
  static bool isWeightKgValid(num kg) => isInRange(kg, min: 20, max: 300);

  /// Heart-rate beats per minute – physiologically plausible at rest/activity.
  static bool isHeartRateValid(num bpm) => isInRange(bpm, min: 30, max: 220);

  /// Systolic blood pressure (mmHg)
  static bool isBloodPressureSystolicValid(num mmHg) =>
      isInRange(mmHg, min: 50, max: 250);

  /// Diastolic blood pressure (mmHg)
  static bool isBloodPressureDiastolicValid(num mmHg) =>
      isInRange(mmHg, min: 30, max: 150);

  // ──────────────────────────────────────────────────────────────────────────────
  // Unit converters
  // ──────────────────────────────────────────────────────────────────────────────

  /// Kilograms → pounds.
  static double kgToLb(double kg) => kg * 2.2046226218;

  /// Pounds → kilograms.
  static double lbToKg(double lb) => lb / 2.2046226218;
}
