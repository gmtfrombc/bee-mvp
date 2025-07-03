import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service responsible for persisting and restoring Supabase auth sessions
/// using encrypted secure storage.
///
/// Usage:
///   final service = AuthSessionService();
///   await service.restore(); // cold-start restoration
///   service.listen();        // keep storage in sync
class AuthSessionService {
  // Keys
  static const String _sessionKey = 'supabase_session';

  // Dependencies
  final SupabaseClient _client;
  final FlutterSecureStorage _storage;

  /// Create the service. Optionally inject [client] and [storage] for easier
  /// unit testing.
  AuthSessionService({SupabaseClient? client, FlutterSecureStorage? storage})
    : _client = client ?? Supabase.instance.client,
      _storage = storage ?? const FlutterSecureStorage();

  /// Restores an existing session (if any) from secure storage and sets it
  /// on the underlying Supabase client.
  Future<void> restore() async {
    try {
      final raw = await _storage.read(key: _sessionKey);
      if (raw == null) return;

      await _client.auth.setSession(raw);

      _debug('Session restored');
    } catch (e, st) {
      _debug('Failed to restore session: $e\n$st');
    }
  }

  /// Starts listening to auth state changes to persist refreshed tokens and
  /// remove stored sessions on sign-out.
  void listen() {
    _client.auth.onAuthStateChange.listen((event) {
      final authEvent = event.event;
      final session = event.session;

      switch (authEvent) {
        case AuthChangeEvent.tokenRefreshed:
          if (session != null) {
            _persist(session);
          }
          break;
        case AuthChangeEvent.signedOut:
          _clear();
          break;
        default:
          break;
      }
    });
  }

  // ---- Helpers ----------------------------------------------------------- //

  Future<void> _persist(Session session) async {
    try {
      final json = jsonEncode(session.toJson());
      await _storage.write(key: _sessionKey, value: json);
      _debug('Session persisted');
    } catch (e) {
      _debug('Failed to persist session: $e');
    }
  }

  Future<void> _clear() async {
    try {
      await _storage.delete(key: _sessionKey);
      _debug('Session cleared');
    } catch (e) {
      _debug('Failed to clear session: $e');
    }
  }

  void _debug(String message) {
    if (kDebugMode) {
      // Tokens are not printed; message is already redacted.
      debugPrint('[AuthSessionService] $message');
    }
  }
}
