import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/health_data/validators/biometric_validators.dart';
import 'package:app/core/health_data/validators/numeric_validators.dart';
import 'package:app/core/health_data/services/health_data_repository.dart';

/// Enumeration for weight units.
enum WeightUnit { kg, lbs }

/// Enumeration for height units.
enum HeightUnit { cm, ftIn }

/// Immutable state for the biometrics form.
class BiometricsFormState {
  const BiometricsFormState({
    this.weight = '',
    this.weightUnit = WeightUnit.kg,
    this.height = '',
    this.heightUnit = HeightUnit.cm,
    this.isSubmitting = false,
  });

  final String weight;
  final WeightUnit weightUnit;
  final String height;
  final HeightUnit heightUnit;
  final bool isSubmitting;

  bool get isValid =>
      BiometricValidators.weight(weight, unit: weightUnit.name) == null &&
      BiometricValidators.height(height, unit: heightUnit.name) == null;

  BiometricsFormState copyWith({
    String? weight,
    WeightUnit? weightUnit,
    String? height,
    HeightUnit? heightUnit,
    bool? isSubmitting,
  }) {
    return BiometricsFormState(
      weight: weight ?? this.weight,
      weightUnit: weightUnit ?? this.weightUnit,
      height: height ?? this.height,
      heightUnit: heightUnit ?? this.heightUnit,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

/// StateNotifier handling biometrics form state.
class BiometricsFormNotifier extends StateNotifier<BiometricsFormState> {
  BiometricsFormNotifier(this.ref) : super(const BiometricsFormState());

  final Ref ref;

  // Field updates ----------------------------------------------------------
  void updateWeight(String value) {
    state = state.copyWith(weight: value);
  }

  void updateWeightUnit(WeightUnit? unit) {
    if (unit == null) return;
    state = state.copyWith(weightUnit: unit);
  }

  void updateHeight(String value) {
    state = state.copyWith(height: value);
  }

  void updateHeightUnit(HeightUnit? unit) {
    if (unit == null) return;
    state = state.copyWith(heightUnit: unit);
  }

  /// Placeholder submit method – repository integration comes in later tasks.
  Future<void> submit() async {
    if (!state.isValid) return;
    state = state.copyWith(isSubmitting: true);
    try {
      final repo = ref.read(healthDataRepositoryProvider);

      // Convert units to metric
      final double parsedWeight = double.parse(state.weight.trim());
      final double parsedHeight = double.parse(state.height.trim());

      final double weightKg =
          state.weightUnit == WeightUnit.kg
              ? parsedWeight
              : NumericValidators.lbToKg(parsedWeight);

      final double heightCm =
          state.heightUnit == HeightUnit.cm
              ? parsedHeight
              : NumericValidators.ftToCm(parsedHeight);

      await repo.insertBiometrics(weightKg: weightKg, heightCm: heightCm);
    } catch (e, st) {
      // In production we might surface a snackbar; for now log.
      // ignore: avoid_print
      print('Error submitting biometrics: $e\n$st');
    }
    state = state.copyWith(isSubmitting: false);
  }
}

/// Global provider for widgets to watch & mutate biometrics form.
final biometricsFormProvider =
    StateNotifierProvider<BiometricsFormNotifier, BiometricsFormState>(
      (ref) => BiometricsFormNotifier(ref),
    );
