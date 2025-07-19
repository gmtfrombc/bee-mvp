import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/health_data/services/health_data_repository.dart';
import 'package:app/core/health_data/services/metabolic_health_score_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/core/models/sex.dart';

/// Provider that exposes a singleton MetabolicHealthScoreService.
final metabolicHealthScoreServiceProvider =
    Provider<MetabolicHealthScoreService>(
      (ref) => MetabolicHealthScoreService(),
    );

/// Fetches and calculates the latest metabolic health score for the current user.
final latestMhsProvider = FutureProvider<double>((ref) async {
  final repo = ref.read(healthDataRepositoryProvider);
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) {
    throw StateError('User not authenticated');
  }

  // Fetch biometric inputs (for weight) – may be empty if none recorded.
  final inputs = await repo.fetchBiometricInputs(
    userId: user.id,
    forceRefresh: false,
  );

  double? weightKg;
  for (final input in inputs) {
    if (input.type.name == 'weight') {
      weightKg = _toKg(input.value, input.unit);
      break;
    }
  }

  final profile = user.userMetadata ?? {};
  final heightCm = (profile['height_cm'] as num?)?.toDouble();
  if (weightKg == null || heightCm == null) return 0;

  final ageYears = profile['age_years'] as int? ?? 30;
  final sexStr = (profile['sex'] as String?) ?? 'male';
  final sexEnum = sexStr.toLowerCase() == 'female' ? Sex.female : Sex.male;

  final service = ref.read(metabolicHealthScoreServiceProvider);
  final score = await service.calculateScore(
    weightKg: weightKg,
    heightCm: heightCm,
    ageYears: ageYears,
    sex: sexEnum,
  );
  return score;
});

/// Provides a 30-day history of metabolic scores (one per day) for spark-line.
final mhsThirtyDayHistoryProvider = FutureProvider<List<double>>((ref) async {
  final latestScore = await ref.watch(latestMhsProvider.future);
  // Generate a simple decaying list for now until real historical data is wired.
  return List.generate(30, (i) => (latestScore - i).clamp(0, 100));
});

// _───────────────────────────────────────────────────────────────────────────
// Unit helpers – conversion between imperial & metric for MVP only.
// --------------------------------------------------------------------------

double _toKg(double value, String unit) {
  switch (unit) {
    case 'kg':
      return value;
    case 'lbs':
      return value * 0.45359237;
    default:
      return value;
  }
}
