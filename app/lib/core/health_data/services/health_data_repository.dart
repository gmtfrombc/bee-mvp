import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/energy_level.dart';
import '../models/biometric_manual_input.dart';
import '../../providers/supabase_provider.dart';

/// Repository offering CRUD access to health-data tables with simple in-memory cache.
class HealthDataRepository {
  HealthDataRepository({
    SupabaseClient? supabaseClient,
    this.cacheTTL = const Duration(minutes: 5),
  }) : _supabase = supabaseClient ?? Supabase.instance.client;

  final SupabaseClient _supabase;
  final Duration cacheTTL;

  // ──────────────────────────────────────────────────────────────────────────
  // Caching helpers
  // --------------------------------------------------------------------------
  final Map<String, List<EnergyLevelEntry>> _energyCache = {};
  final Map<String, List<BiometricManualInput>> _biometricCache = {};
  DateTime _energyCacheTimestamp = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _biometricCacheTimestamp = DateTime.fromMillisecondsSinceEpoch(0);

  bool _isCacheValid(DateTime ts) => DateTime.now().difference(ts) < cacheTTL;

  // ──────────────────────────────────────────────────────────────────────────
  // ENERGY LEVEL CRUD
  // --------------------------------------------------------------------------
  Future<EnergyLevelEntry> createEnergyLevel(EnergyLevelEntry entry) async {
    final inserted =
        await _supabase
            .from('energy_levels')
            .insert(entry.toJson())
            .select()
            .single();
    debugPrint(
      '📈 Energy level inserted: ${entry.level.name} for user ${entry.userId}',
    );
    final newEntry = EnergyLevelEntry.fromJson(inserted);
    _energyCache.putIfAbsent(entry.userId, () => []).add(newEntry);
    _energyCacheTimestamp = DateTime.now();
    return newEntry;
  }

  Future<List<EnergyLevelEntry>> fetchEnergyLevels({
    required String userId,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _energyCache.containsKey(userId) &&
        _isCacheValid(_energyCacheTimestamp)) {
      return _energyCache[userId]!;
    }

    final data = await _supabase
        .from('energy_levels')
        .select()
        .eq('user_id', userId)
        .order('recorded_at', ascending: false);

    final entries =
        (data as List)
            .map((e) => EnergyLevelEntry.fromJson(e as Map<String, dynamic>))
            .toList();

    _energyCache[userId] = entries;
    _energyCacheTimestamp = DateTime.now();
    return entries;
  }

  Future<void> updateEnergyLevel(EnergyLevelEntry entry) async {
    await _supabase
        .from('energy_levels')
        .update(entry.toJson())
        .eq('id', entry.id);

    final cacheList = _energyCache[entry.userId];
    if (cacheList != null) {
      final idx = cacheList.indexWhere((e) => e.id == entry.id);
      if (idx != -1) cacheList[idx] = entry;
    }
  }

  Future<void> deleteEnergyLevel({
    required String id,
    required String userId,
  }) async {
    await _supabase.from('energy_levels').delete().eq('id', id);
    _energyCache[userId]?.removeWhere((e) => e.id == id);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BIOMETRIC MANUAL INPUT CRUD
  // --------------------------------------------------------------------------
  Future<BiometricManualInput> createBiometricInput(
    BiometricManualInput input,
  ) async {
    final inserted =
        await _supabase
            .from('biometric_manual_inputs')
            .insert(input.toJson())
            .select()
            .single();
    debugPrint('💡 Biometric input inserted for user ${input.userId}');
    final newInput = BiometricManualInput.fromJson(inserted);
    _biometricCache.putIfAbsent(input.userId, () => []).add(newInput);
    _biometricCacheTimestamp = DateTime.now();
    return newInput;
  }

  Future<List<BiometricManualInput>> fetchBiometricInputs({
    required String userId,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _biometricCache.containsKey(userId) &&
        _isCacheValid(_biometricCacheTimestamp)) {
      return _biometricCache[userId]!;
    }

    final data = await _supabase
        .from('biometric_manual_inputs')
        .select()
        .eq('user_id', userId)
        .order('recorded_at', ascending: false);

    final inputs =
        (data as List)
            .map(
              (e) => BiometricManualInput.fromJson(e as Map<String, dynamic>),
            )
            .toList();

    _biometricCache[userId] = inputs;
    _biometricCacheTimestamp = DateTime.now();
    return inputs;
  }

  Future<void> updateBiometricInput(BiometricManualInput input) async {
    await _supabase
        .from('biometric_manual_inputs')
        .update(input.toJson())
        .eq('id', input.id);

    final cacheList = _biometricCache[input.userId];
    if (cacheList != null) {
      final idx = cacheList.indexWhere((e) => e.id == input.id);
      if (idx != -1) cacheList[idx] = input;
    }
  }

  Future<void> deleteBiometricInput({
    required String id,
    required String userId,
  }) async {
    await _supabase.from('biometric_manual_inputs').delete().eq('id', id);
    _biometricCache[userId]?.removeWhere((e) => e.id == id);
  }
}

/// Riverpod provider exposing a singleton [HealthDataRepository].
final healthDataRepositoryProvider = Provider<HealthDataRepository>((ref) {
  final client = ref.read(supabaseClientProvider);
  return HealthDataRepository(supabaseClient: client);
});
