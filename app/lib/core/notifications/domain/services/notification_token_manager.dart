import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles all FCM token retrieval, refresh and persistence logic.
///
/// Separated from `NotificationCoreService` to keep that façade thin and
/// within the 450 LOC component-size ceiling.
class NotificationTokenManager {
  static const String _tokenKey = 'fcm_token';
  static const String _tokenTimestampKey = 'fcm_token_timestamp';

  final FirebaseMessaging? _messaging;

  NotificationTokenManager([this._messaging]);

  Future<String?> getToken() async {
    // Skip Firebase calls when running tests – they can hang indefinite.
    if (_isTestEnvironment()) {
      if (kDebugMode) debugPrint('🧪 Returning mock FCM token (test env)');
      return 'mock_fcm_token_for_testing';
    }

    // When Firebase isn’t available (e.g. during offline dev) fall back to
    // stored token.
    if (!_isFirebaseAvailable()) {
      return _getStoredToken();
    }

    try {
      // Use cached token if still valid (≤7 days old).
      if (await _isTokenValid()) {
        final stored = await _getStoredToken();
        if (stored != null) {
          if (kDebugMode) debugPrint('✅ Using cached FCM token');
          return stored;
        }
      }

      // Fetch fresh token (with 5 s timeout to avoid hangs).
      final newToken = await _messaging?.getToken().timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );

      if (newToken != null) {
        await _storeToken(newToken);
        if (kDebugMode) {
          debugPrint('🔥 New FCM token: ${newToken.substring(0, 20)}…');
        }
        return newToken;
      }

      // iOS Simulator returns null – that’s expected.
      if (_isIOSSimulator) {
        if (kDebugMode) debugPrint('ℹ️ Null FCM token on iOS simulator');
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ getToken error: $e');
      return null;
    }
  }

  Future<void> deleteToken() async {
    if (_isTestEnvironment()) return;

    if (!_isFirebaseAvailable()) {
      await _removeStoredToken();
      return;
    }

    try {
      await _messaging?.deleteToken();
      await _removeStoredToken();
      await _removeTokenFromSupabase();
      if (kDebugMode) debugPrint('🔥 FCM token deleted');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ deleteToken error: $e');
    }
  }

  /// Persist a token received from the `onTokenRefresh` stream.
  Future<void> persistRefreshedToken(String token) async {
    await _storeToken(token);
  }

  // ───────────────────────── Helpers ─────────────────────────

  Future<void> _storeToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setInt(
        _tokenTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );

      await _storeTokenInSupabase(token);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ storeToken error: $e');
    }
  }

  Future<String?> _getStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<bool> _isTokenValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ts = prefs.getInt(_tokenTimestampKey);
      if (ts == null) return false;
      final tokenDate = DateTime.fromMillisecondsSinceEpoch(ts);
      return tokenDate.isAfter(
        DateTime.now().subtract(const Duration(days: 7)),
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> _removeStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_tokenTimestampKey);
    } catch (_) {}
  }

  Future<void> _storeTokenInSupabase(String token) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase.from('user_profiles').upsert({
          'user_id': user.id,
          'fcm_token': token,
          'token_updated_at': DateTime.now().toIso8601String(),
          'platform': Platform.operatingSystem,
        });
      }
    } catch (_) {
      /* swallow */
    }
  }

  Future<void> _removeTokenFromSupabase() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase
            .from('user_profiles')
            .update({
              'fcm_token': null,
              'token_updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', user.id);
      }
    } catch (_) {}
  }

  // ───────────────────────── Env detection ─────────────────────────

  bool _isTestEnvironment() {
    if (const bool.fromEnvironment('flutter.flutter_test')) return true;
    try {
      throw Exception();
    } catch (_, st) {
      return st.toString().contains('flutter_test');
    }
  }

  bool _isFirebaseAvailable() =>
      true; // Currently always true when this class is used.

  bool get _isIOSSimulator => Platform.isIOS && kDebugMode;
}
