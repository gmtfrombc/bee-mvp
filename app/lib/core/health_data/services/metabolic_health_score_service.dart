import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle, AssetBundle;

import '../../models/sex.dart';

/// Service that converts raw height & weight measurements into a
/// Metabolic Health Score (MHS) percentile (0–100).
///
/// The score is derived by computing z-scores for height and weight versus
/// CDC reference means/SDs, mapping each to a percentile using the standard
/// normal CDF, averaging the two percentiles, and finally clamping the result
/// within 0–100.
///
/// The reference dataset is bundled as a JSON asset at
/// `assets/data/cdc_reference.json` with the following (simplified) schema:
/// ```json
/// {
///   "male": {
///     "18-29": { "height_cm_mean": 175.7, "height_cm_sd": 7.4,
///                 "weight_kg_mean": 83.1,  "weight_kg_sd": 12.9 },
///     "30-39": { ... }
///   },
///   "female": {
///     "18-29": { ... },
///     ...
///   }
/// }
/// ```
/// Age bands must follow the pattern `min-max` (both inclusive).
class MetabolicHealthScoreService {
  MetabolicHealthScoreService({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Calculates the metabolic health score percentile.
  ///
  /// [weightKg] and [heightCm] must already be converted to metric units.
  /// Throws [ArgumentError] if there is no reference data for the provided
  /// [ageYears] or [sex].
  Future<double> calculateScore({
    required double weightKg,
    required double heightCm,
    required int ageYears,
    required Sex sex,
  }) async {
    if (weightKg <= 0 || heightCm <= 0) {
      throw ArgumentError('Weight and height must be positive');
    }
    // Ensure reference data is available.
    await _ensureLoaded();

    final sexKey = _sexToKey(sex);
    final sexMap = _referenceData[sexKey];
    if (sexMap == null) {
      throw ArgumentError('Reference data not available for sex $sex');
    }

    final String? ageBandKey = _resolveAgeBand(sexMap.keys, ageYears);
    if (ageBandKey == null) {
      throw ArgumentError(
        'No CDC reference entry found for age $ageYears ($sexKey)',
      );
    }

    final bandData = sexMap[ageBandKey] as Map<String, dynamic>;

    final heightMean = (bandData['height_cm_mean'] as num).toDouble();
    final heightSd = (bandData['height_cm_sd'] as num).toDouble();
    final weightMean = (bandData['weight_kg_mean'] as num).toDouble();
    final weightSd = (bandData['weight_kg_sd'] as num).toDouble();

    final heightZ = (heightCm - heightMean) / heightSd;
    final weightZ = (weightKg - weightMean) / weightSd;

    final heightPercentile = _cdf(heightZ) * 100.0;
    final weightPercentile = _cdf(weightZ) * 100.0;

    final score = ((heightPercentile + weightPercentile) / 2).clamp(0.0, 100.0);
    return double.parse(score.toStringAsFixed(1));
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  final AssetBundle _bundle;
  static const String _assetPath = 'assets/data/cdc_reference.json';
  late final Map<String, dynamic> _referenceData;
  bool _isLoaded = false;

  Future<void> _ensureLoaded() async {
    if (_isLoaded) return;
    final jsonStr = await _bundle.loadString(_assetPath);
    _referenceData = jsonDecode(jsonStr) as Map<String, dynamic>;
    _isLoaded = true;
  }

  String _sexToKey(Sex sex) => switch (sex) {
    Sex.male => 'male',
    Sex.female => 'female',
  };

  /// Resolves the matching age band key (e.g., "18-29") for the given [age].
  /// Returns `null` if no band matches.
  String? _resolveAgeBand(Iterable<String> bands, int age) {
    for (final band in bands) {
      final parts = band.split('-');
      if (parts.length != 2) continue;
      final min = int.tryParse(parts[0]);
      final max = int.tryParse(parts[1]);
      if (min == null || max == null) continue;
      if (age >= min && age <= max) return band;
    }
    return null;
  }

  /// Cumulative distribution function for the standard normal distribution.
  /// Uses an approximation formula accurate to ~7 decimal places.
  double _cdf(double z) {
    // Abramowitz and Stegun approximation
    const double p = 0.2316419;
    const double b1 = 0.319381530;
    const double b2 = -0.356563782;
    const double b3 = 1.781477937;
    const double b4 = -1.821255978;
    const double b5 = 1.330274429;

    final absZ = z.abs();
    if (absZ > 37.0) {
      // Value is effectively 0 or 1.
      return z > 0 ? 1.0 : 0.0;
    }

    final double t = 1.0 / (1.0 + p * absZ);
    final double expPart = exp(-pow(absZ, 2) / 2.0) / sqrt(2 * pi);

    final double poly = (((((b5 * t + b4) * t + b3) * t + b2) * t + b1) * t);

    final double cdf = 1.0 - expPart * poly;
    return z >= 0 ? cdf : 1.0 - cdf;
  }
}
