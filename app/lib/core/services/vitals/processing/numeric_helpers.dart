/// Numeric extraction helpers for HealthKit wrapper objects.
class NumericHelpers {
  /// Attempts to coerce [raw] into a `double`.
  static double? toDouble(dynamic raw) {
    // TODO: Port extraction logic.
    return null;
  }

  /// Attempts to coerce [raw] into an `int`.
  static int? toInt(dynamic raw) {
    final d = toDouble(raw);
    return d?.round();
  }
}
