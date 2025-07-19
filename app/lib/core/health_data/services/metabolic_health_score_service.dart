import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../../models/sex.dart';

/// Service that converts raw height & weight measurements into a
/// Metabolic Health Score (MHS) percentile (0–100).
///
/// The score is derived by computing z-scores for height and weight versus
/// CDC reference means/SDs, mapping each to a percentile using the standard
/// normal CDF, averaging the two percentiles, and clamping the result within
/// 0–100.
///
/// Reference dataset lives at `assets/data/cdc_reference.json` with schema:
/// ```json
/// {
///   "male": {
///     "18-29": { "height_cm_mean": 175.7, "height_cm_sd": 7.4,
///                 "weight_kg_mean": 83.1,  "weight_kg_sd": 12.9 },
///     "30-39": { ... }
///   },
///   "female": { ... }
/// }
/// ```
class MetabolicHealthScoreService {
  MetabolicHealthScoreService({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  // ────────────────────────────────────────────────────────────────────────────
  // Public API
  // --------------------------------------------------------------------------
  /// Calculates the percentile metabolic health score.
  ///
  /// [weightKg] and [heightCm] must already be in metric units. Throws
  /// [ArgumentError] if reference data is missing for the provided demographic.
  Future<double> calculateScore({
    required double weightKg,
    required double heightCm,
    required int ageYears,
    required Sex sex,
  }) async {
    if (weightKg <= 0 || heightCm <= 0) {
      throw ArgumentError('Weight and height must be positive');
    }

    await _ensureLoaded();

    final sexKey = _sexToKey(sex);
    final sexMap = _referenceData[sexKey] as Map<String, dynamic>?;
    if (sexMap == null) {
      throw ArgumentError('Reference data not available for sex $sex');
    }

    final ageBandKey = _resolveAgeBand(sexMap.keys, ageYears);
    if (ageBandKey == null) {
      throw ArgumentError('No CDC reference entry found for age $ageYears');
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

  // ────────────────────────────────────────────────────────────────────────────
  // Internal helpers
  // --------------------------------------------------------------------------

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

  String _sexToKey(Sex sex) => sex == Sex.female ? 'female' : 'male';

  /// Returns the matching age-band key (e.g. "18-29") or null if none match.
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

  /// Standard-normal cumulative distribution function (Abramowitz–Stegun).
  double _cdf(double z) {
    const p = 0.2316419;
    const b1 = 0.319381530;
    const b2 = -0.356563782;
    const b3 = 1.781477937;
    const b4 = -1.821255978;
    const b5 = 1.330274429;

    final absZ = z.abs();
    if (absZ > 37.0) return z > 0 ? 1.0 : 0.0;

    final t = 1.0 / (1.0 + p * absZ);
    final expPart = exp(-pow(absZ, 2) / 2.0) / sqrt(2 * pi);
    final poly = (((((b5 * t + b4) * t + b3) * t + b2) * t + b1) * t);

    final cdf = 1.0 - expPart * poly;
    return z >= 0 ? cdf : 1.0 - cdf;
  }
}
