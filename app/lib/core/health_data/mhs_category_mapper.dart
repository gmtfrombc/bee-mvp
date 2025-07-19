/// Maps an Advanced Metabolic Health Score (MHS) percentile (0–100)
/// to a semantic category used for colour-band gauges.
///
/// Thresholds come from product specification (see docs/MVP_ROADMAP
/// M1.7.4_advanced-metabolic-health-score-gauge.md):
///   • < 20   → firstGear (red)
///   • < 40   → stepItUp (orange)
///   • < 55   → onTrack (blue)
///   • < 70   → inTheZone (green)
///   • ≥ 70  → peakMomentum (purple)
///
/// Keeping thresholds as `const` prevents magic-number lints and makes
/// future adjustments straightforward.
// ignore_for_file: public_member_api_docs

// 📌 No imports required – pure logic.

/// Discrete MHS performance bands.
library;

enum MhsCategory {
  /// 0–19
  firstGear,

  /// 20–39
  stepItUp,

  /// 40–54
  onTrack,

  /// 55–69
  inTheZone,

  /// ≥70
  peakMomentum,
}

/// Converts a raw MHS percentile to its [MhsCategory] band.
MhsCategory mapMhsToCategory(double mhs) {
  if (mhs.isNaN) {
    throw ArgumentError('MHS percentile must be a valid number');
  }

  const kFirstGearMax = 20.0;
  const kStepItUpMax = 40.0;
  const kOnTrackMax = 55.0;
  const kInTheZoneMax = 70.0;

  if (mhs < kFirstGearMax) return MhsCategory.firstGear;
  if (mhs < kStepItUpMax) return MhsCategory.stepItUp;
  if (mhs < kOnTrackMax) return MhsCategory.onTrack;
  if (mhs < kInTheZoneMax) return MhsCategory.inTheZone;
  return MhsCategory.peakMomentum;
}
