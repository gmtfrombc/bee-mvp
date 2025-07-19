import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle, AssetBundle;
import '../models/sex.dart';

/// Repository that lazily loads cohort-segmented Metabolic Health Score
/// coefficient tables from the JSON asset `assets/data/mhs_coefficients.json`.
///
/// The repository is a simple key-value lookup:
/// ```json
/// {
///   "non_hispanic_white_asian": {
///     "male":   [-4.83, 0.03, -0.02, ...],
///     "female": [-6.52, 0.05, -0.01, ...]
///   },
///   ...
/// }
/// ```
///
/// If a (cohort, sex) pair is not present, the repository falls back to the
/// `non_hispanic_white_asian/male` coefficient set and logs a warning so that
/// the app never crashes due to unmapped demographics.
class MhsCoefficientRepository {
  MhsCoefficientRepository._({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  static final MhsCoefficientRepository instance = MhsCoefficientRepository._();

  /// Creates a new repository that loads from the provided [bundle] instead of
  /// the rootBundle. This is useful for unit tests where loading from disk
  /// assets is not feasible.
  factory MhsCoefficientRepository.forBundle(AssetBundle bundle) {
    return MhsCoefficientRepository._(bundle: bundle);
  }

  // ──────────────────────────────────────────────
  // Public API
  // ──────────────────────────────────────────────
  /// Returns the list of six MetS coefficients for the given [cohortKey] and
  /// [sex]. If the key is missing the method returns the default coefficient
  /// set and emits a `debugPrint` warning.
  Future<List<double>> getCoefficients({
    required String cohortKey,
    required Sex sex,
  }) async {
    await _ensureLoaded();

    final sexKey = sex == Sex.female ? 'female' : 'male';
    final cohortMap = _data![cohortKey] as Map<String, dynamic>?;
    final coeffs = (cohortMap?[sexKey] as List?)?.cast<num>();

    if (coeffs == null) {
      debugPrint(
        '⚠️  MhsCoefficientRepository: Coefficients not found for cohort "$cohortKey" & sex "$sexKey". Using default set.',
      );
      return _defaultCoefficients;
    }

    return coeffs.map((e) => e.toDouble()).toList(growable: false);
  }

  // ──────────────────────────────────────────────
  // Internal helpers
  // ──────────────────────────────────────────────
  final AssetBundle _bundle;
  static const _assetPath = 'assets/data/mhs_coefficients.json';
  Map<String, dynamic>? _data;

  Future<void> _ensureLoaded() async {
    if (_data != null) return;
    final jsonStr = await _bundle.loadString(_assetPath);
    _data = jsonDecode(jsonStr) as Map<String, dynamic>;
  }

  static const List<double> _defaultCoefficients = [
    -4.8316,
    0.0315,
    -0.0272,
    0.0044,
    0.8018,
    0.0101,
  ];
}
