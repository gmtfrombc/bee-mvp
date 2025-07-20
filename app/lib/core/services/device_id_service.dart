import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

/// Provides a persistent, anonymous device identifier for analytics.
///
/// The ID is generated once per installation and cached in
/// `SharedPreferences` so it remains stable across app restarts. If
/// `SharedPreferences` is unavailable (e.g. unit tests), the service falls
/// back to an in-memory UUID for the current session.
class DeviceIdService {
  static const _prefsKey = 'device_id';
  static final DeviceIdService instance = DeviceIdService._internal();

  String? _cached;

  DeviceIdService._internal();

  /// Returns the stable device identifier, generating and persisting a new one
  /// if needed.
  Future<String> getDeviceId() async {
    // Return cached value if we already resolved it.
    if (_cached != null) return _cached!;

    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getString(_prefsKey);
      if (existing != null && existing.isNotEmpty) {
        _cached = existing;
        return existing;
      }

      final newId = const Uuid().v4();
      await prefs.setString(_prefsKey, newId);
      _cached = newId;
      return newId;
    } catch (e) {
      // SharedPreferences isn’t available (e.g. tests). Use volatile UUID.
      _cached = const Uuid().v4();
      debugPrint('⚠️  DeviceIdService: using volatile ID $_cached – $e');
      return _cached!;
    }
  }
}
