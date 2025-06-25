import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/core/services/vitals_notifier_service.dart';

/// Persists the latest VitalsData snapshot between app launches.
class VitalsCache {
  static const String _cacheKey = 'lastVitalsCache_v1';

  /// Loads the cached snapshot or returns `null` if nothing stored / parse error.
  Future<VitalsData?> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);
      if (jsonString == null) return null;

      final Map<String, dynamic> json = Map<String, dynamic>.from(
        jsonDecode(jsonString) as Map,
      );

      return VitalsData(
        heartRate: json['heartRate'] as double?,
        steps: json['steps'] as int?,
        heartRateVariability: json['hrv'] as double?,
        sleepHours: json['sleepHours'] as double?,
        activeEnergy: json['activeEnergy'] as double?,
        weight: json['weight'] as double?,
        timestamp:
            DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
        quality: VitalsQuality.values[json['quality'] as int? ?? 4],
        metadata: const {},
      );
    } catch (e) {
      // When in doubt, treat as empty.
      return null;
    }
  }

  /// Persists [data] for future cold-launch restore.
  Future<void> write(VitalsData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(<String, dynamic>{
        'heartRate': data.heartRate,
        'steps': data.steps,
        'hrv': data.heartRateVariability,
        'sleepHours': data.sleepHours,
        'activeEnergy': data.activeEnergy,
        'weight': data.weight,
        'timestamp': data.timestamp.toIso8601String(),
        'quality': data.quality.index,
      });
      await prefs.setString(_cacheKey, jsonString);
    } catch (_) {
      // swallow – caching best-effort only
    }
  }
}
