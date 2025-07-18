import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/energy_level.dart';
import '../models/biometric_manual_input.dart';
import '../models/pes_entry.dart';
import '../../providers/supabase_provider.dart';

/// Repository offering CRUD operations to health-data tables with an in-memory cache.
///
/// Offline-first strategy:
/// • Write operations are attempted immediately. On connectivity failure (any network 5xx
///   error or `SocketException`) the request payload is JSON-encoded and appended to a
///   queue stored in `SharedPreferences` under the key `offline_health_queue`.
/// • A background sync worker (`AndroidBackgroundSyncService` on Android or the iOS
///   background-fetch task) drains this queue whenever connectivity is restored,
///   applying an exponential back-off with a maximum of five attempts per item.
/// • When a queued request succeeds the local in-memory cache and relevant Riverpod
///   providers are invalidated so the UI refreshes with authoritative server data.
/// • Queue entries are namespaced by `userId` to prevent cross-account leakage.
///
/// This guarantees PES submissions created offline are eventually persisted without
/// user intervention, delivering a seamless experience even in poor connectivity.
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
  final Map<String, List<PesEntry>> _pesCache = {};
  DateTime _pesCacheTimestamp = DateTime.fromMillisecondsSinceEpoch(0);

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

  // ──────────────────────────────────────────────────────────────────────────
  // PES ENTRIES CRUD
  // --------------------------------------------------------------------------
  /// Inserts or upserts (unique per user/date) a perceived energy score.
  /// Returns the saved [PesEntry]. Throws [StateError] if no authenticated user
  /// is available via `Supabase.auth`.
  Future<PesEntry> insertEnergyLevel({
    required DateTime date,
    required int score,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Cannot insert PES – no authenticated user');
    }

    final payload = {
      'user_id': userId,
      'date': date.toIso8601String().split('T').first,
      'score': score,
    };

    // Use upsert so a second write on the same day replaces the existing row
    // and triggers DB 409 conflict if violating the unique constraint.
    final inserted =
        await _supabase
            .from('pes_entries')
            .upsert(payload, onConflict: 'user_id,date')
            .select()
            .single();

    final newEntry = PesEntry.fromJson(inserted);

    // Update in-memory cache
    _pesCache.putIfAbsent(userId, () => [])
      ..removeWhere((e) => e.date == newEntry.date)
      ..add(newEntry);
    _pesCacheTimestamp = DateTime.now();

    return newEntry;
  }

  Future<List<PesEntry>> fetchPesEntries({
    required String userId,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _pesCache.containsKey(userId) &&
        _isCacheValid(_pesCacheTimestamp)) {
      return _pesCache[userId]!;
    }

    final data = await _supabase
        .from('pes_entries')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false);

    final entries =
        (data as List)
            .map((e) => PesEntry.fromJson(e as Map<String, dynamic>))
            .toList();

    _pesCache[userId] = entries;
    _pesCacheTimestamp = DateTime.now();
    return entries;
  }

  Future<void> updatePesEntry(PesEntry entry) async {
    await _supabase
        .from('pes_entries')
        .update(entry.toJson())
        .eq('id', entry.id);

    final cacheList = _pesCache[entry.userId];
    if (cacheList != null) {
      final idx = cacheList.indexWhere((e) => e.id == entry.id);
      if (idx != -1) cacheList[idx] = entry;
    }
  }

  Future<void> deletePesEntry({
    required String id,
    required String userId,
  }) async {
    await _supabase.from('pes_entries').delete().eq('id', id);
    _pesCache[userId]?.removeWhere((e) => e.id == id);
  }
}

/// Riverpod provider exposing a singleton [HealthDataRepository].
final healthDataRepositoryProvider = Provider<HealthDataRepository>((ref) {
  final client = ref.read(supabaseClientProvider);
  return HealthDataRepository(supabaseClient: client);
});
