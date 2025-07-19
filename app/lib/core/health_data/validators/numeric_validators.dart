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

  /// Height in centimetres – typical adult range 120‒250 cm.
  static bool isHeightCmValid(num cm) => isInRange(cm, min: 120, max: 250);

  /// Height in feet – converts to cm and checks range above (approx. 3.9‒8.2 ft).
  static bool isHeightFtValid(num feet) =>
      isHeightCmValid(ftToCm(feet.toDouble()));

  /// Heart-rate beats per minute – physiologically plausible at rest/activity.
  static bool isHeartRateValid(num bpm) => isInRange(bpm, min: 30, max: 220);

  /// Systolic blood pressure (mmHg)
  static bool isBloodPressureSystolicValid(num mmHg) =>
      isInRange(mmHg, min: 50, max: 250);

  /// Diastolic blood pressure (mmHg)
  static bool isBloodPressureDiastolicValid(num mmHg) =>
      isInRange(mmHg, min: 30, max: 150);

  /// Fasting glucose mg/dL valid range 50–300.
  static bool isFastingGlucoseValid(num mgdl) =>
      isInRange(mgdl, min: 50, max: 300);

  /// A1C percentage valid range 3.0–15.0.
  static bool isA1cPercentValid(num percent) =>
      isInRange(percent, min: 3.0, max: 15.0);

  // ──────────────────────────────────────────────────────────────────────────────
  // Unit converters
  // ──────────────────────────────────────────────────────────────────────────────

  /// Centimetres → inches.
  static double cmToIn(double cm) => cm / 2.54;

  /// Inches → centimetres.
  static double inToCm(double inch) => inch * 2.54;

  /// Centimetres → feet (decimal).
  static double cmToFt(double cm) => cm / 30.48;

  /// Feet (decimal) → centimetres.
  static double ftToCm(double ft) => ft * 30.48;

  /// Kilograms → pounds.
  static double kgToLb(double kg) => kg * 2.2046226218;

  /// Pounds → kilograms.
  static double lbToKg(double lb) => lb / 2.2046226218;
}
