import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Lightweight analytics service that writes events to Supabase `analytics_events`
/// table (or can be mapped to an Edge Function trigger).
/// Designed for small volume UX tracking – not suitable for high-frequency data.
class AnalyticsService {
  final SupabaseClient _client;

  /// Tracks the last time an analytics failure was surfaced so we can
  /// throttle error logs and avoid spamming the console. Static so it is
  /// shared across all `AnalyticsService` instances and across multiple
  /// invocations of [logEvent].
  static DateTime? _lastError;
  AnalyticsService(this._client);

  /// Record an analytics event with optional parameters.
  Future<void> logEvent(String name, {Map<String, dynamic>? params}) async {
    try {
      await _client.from('analytics_events').insert(<String, dynamic>{
        'event_name': name,
        'params': params ?? {},
        'created_at': DateTime.now().toIso8601String(),
        'user_id': _client.auth.currentUser?.id,
      });
    } catch (e) {
      // Fail silently in production – analytics errors must never crash UX.
      // Throttle to avoid console spam and leave TODO for backend fix.
      // TODO(T2-telemetry): Update Supabase RPC/table to accept analytics events.
      final now = DateTime.now();
      // Throttle identical errors so we only emit once every ~2 minutes.
      if (_lastError == null ||
          now.difference(_lastError!) > const Duration(minutes: 2)) {
        _lastError = now;
        debugPrint('❌ Analytics logEvent failed (suppressed repeats): $e');
      }
    }
  }
}
