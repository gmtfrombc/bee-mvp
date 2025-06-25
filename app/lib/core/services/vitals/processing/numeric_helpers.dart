/// Numeric extraction helpers for HealthKit wrapper objects.
class NumericHelpers {
  /// Attempts to coerce [raw] into a `double`.
  static double? toDouble(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();

    // HealthKit ≥ 13 returns wrapper objects that expose `numericValue`.
    try {
      final dynamic candidate = (raw as dynamic).numericValue;
      if (candidate is num) return candidate.toDouble();
    } catch (_) {
      // Not a wrapper type – continue.
    }

    // Fallback: parse first numeric substring from toString().
    final str = raw.toString();
    final match = RegExp(r'([0-9]+(?:\.[0-9]+)?)').firstMatch(str);
    if (match != null) {
      return double.tryParse(match.group(1)!);
    }
    return null;
  }

  /// Attempts to coerce [raw] into an `int`.
  static int? toInt(dynamic raw) {
    final d = toDouble(raw);
    return d?.round();
  }
}
