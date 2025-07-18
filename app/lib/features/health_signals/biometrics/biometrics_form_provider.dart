import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  bool get isValid => weight.isNotEmpty && height.isNotEmpty;

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
  BiometricsFormNotifier() : super(const BiometricsFormState());

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
    await Future.delayed(const Duration(milliseconds: 300));
    // TODO: hook into HealthDataRepository.insertBiometrics() in Task T5.
    state = state.copyWith(isSubmitting: false);
  }
}

/// Global provider for widgets to watch & mutate biometrics form.
final biometricsFormProvider =
    StateNotifierProvider<BiometricsFormNotifier, BiometricsFormState>(
      (ref) => BiometricsFormNotifier(),
    );
