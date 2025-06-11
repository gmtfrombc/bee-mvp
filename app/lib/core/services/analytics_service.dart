import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Lightweight analytics service that writes events to Supabase `analytics_events`
/// table (or can be mapped to an Edge Function trigger).
/// Designed for small volume UX tracking – not suitable for high-frequency data.
class AnalyticsService {
  final SupabaseClient _client;
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
      debugPrint('❌ Analytics logEvent failed: $e');
    }
  }
}
