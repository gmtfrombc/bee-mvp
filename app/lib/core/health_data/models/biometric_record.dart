import 'package:meta/meta.dart';
import '../../models/sex.dart';

/// Immutable set of biometric measurements required to compute the **Advanced
/// Metabolic Health Score (MHS)**.
///
/// All numeric values are expected in **metric** units:
/// * weight – kilograms (kg)
/// * height – centimetres (cm)
/// * HDL – milligrams per decilitre (mg/dL)
/// * SBP – systolic blood pressure, millimetres of mercury (mmHg)
/// * TG  – triglycerides, milligrams per decilitre (mg/dL)
/// * FG  – fasting glucose, milligrams per decilitre (mg/dL)
/// * A1C – glycosylated haemoglobin, percentage (%).
///
/// Either [fgMgDl] or [a1cPercent] **must** be provided. If [fgMgDl] is null,
/// the service will derive it from [a1cPercent] using:
///
/// ```text
/// FG = 38.46 × (A1C − 3.146)
/// ```
@immutable
class BiometricRecord {
  const BiometricRecord({
    required this.weightKg,
    required this.heightCm,
    required this.hdlMgDl,
    required this.sbp,
    required this.tgMgDl,
    this.fgMgDl,
    this.a1cPercent,
    required this.cohortKey,
    required this.sex,
  }) : assert(
         fgMgDl != null || a1cPercent != null,
         'Either fasting glucose (FG) or A1C must be provided',
       );

  final double weightKg;
  final double heightCm;
  final double hdlMgDl;
  final double sbp;
  final double tgMgDl;

  /// Fasting glucose (mg/dL). Optional if [a1cPercent] supplied.
  final double? fgMgDl;

  /// Haemoglobin A1C (%). Optional if [fgMgDl] supplied.
  final double? a1cPercent;

  /// Ethnicity cohort key matching `assets/data/mhs_coefficients.json`.
  final String cohortKey;

  final Sex sex;

  /// Body-mass index, kg/m² – computed lazily from [weightKg] & [heightCm].
  double get bmi {
    // Height is in cm, convert to metres squared.
    final hM = heightCm / 100.0;
    return weightKg / (hM * hM);
  }
}
