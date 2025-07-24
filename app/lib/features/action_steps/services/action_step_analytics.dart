import 'dart:async';
import 'package:app/core/services/analytics_service.dart';
import 'package:app/core/services/device_id_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/providers/analytics_provider.dart';
import 'package:app/core/providers/supabase_provider.dart';

/// High-level analytics wrapper dedicated to the Action-Step feature.
///
/// Encapsulates all event-name constants & schema so UI/business logic
/// can simply call strongly-typed methods.
class ActionStepAnalytics {
  ActionStepAnalytics(this._client, this._analytics);

  final SupabaseClient _client;
  final AnalyticsService _analytics;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Logs when a user sets a brand-new Action Step.
  Future<void> logSet({
    required String actionStepId,
    required String category,
    required String description,
    required int frequency,
    required String weekStart,
    String source = 'manual',
  }) async {
    final deviceId = await DeviceIdService.instance.getDeviceId();

    final payload = <String, dynamic>{
      'user_id': _client.auth.currentUser?.id,
      'action_step_id': actionStepId,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'device_id': deviceId,
      // Event-specific fields
      'category': category,
      'description': description,
      'frequency': frequency,
      'week_start': weekStart,
      'source': source,
    };

    await _analytics.logEvent('action_step_set', params: payload);
  }

  /// Logs when the user completes (or skips) today’s Action Step.
  ///
  /// If [actionStepId] is omitted the function fetches the most recent Action
  /// Step for the current user.
  Future<void> logCompleted({
    required bool success,
    String? actionStepId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return; // Unauthenticated – nothing to log.

    final id = actionStepId ?? await _latestActionStepIdForUser(userId);
    if (id == null) return; // No action step yet – skip.

    final deviceId = await DeviceIdService.instance.getDeviceId();

    final payload = <String, dynamic>{
      'user_id': userId,
      'action_step_id': id,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'device_id': deviceId,
      // Event-specific fields
      'status': success ? 'success' : 'skipped',
    };

    await _analytics.logEvent('action_step_completed', params: payload);
  }

  /// Logs when the user views their current Action Step page.
  Future<void> logView({required String actionStepId}) async {
    final userId = _client.auth.currentUser?.id;

    final deviceId = await DeviceIdService.instance.getDeviceId();

    final payload = <String, dynamic>{
      'user_id': userId,
      'action_step_id': actionStepId,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'device_id': deviceId,
    };

    await _analytics.logEvent('action_step_view', params: payload);
  }

  /// Logs when the user edits their Action Step.
  Future<void> logEdit({
    required String actionStepId,
    required String category,
    required String description,
    required int frequency,
  }) async {
    final userId = _client.auth.currentUser?.id;

    final deviceId = await DeviceIdService.instance.getDeviceId();

    final payload = <String, dynamic>{
      'user_id': userId,
      'action_step_id': actionStepId,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'device_id': deviceId,
      'category': category,
      'description': description,
      'frequency': frequency,
    };

    await _analytics.logEvent('action_step_edit', params: payload);
  }

  /// Logs when the user deletes their Action Step.
  Future<void> logDelete({required String actionStepId}) async {
    final userId = _client.auth.currentUser?.id;

    final deviceId = await DeviceIdService.instance.getDeviceId();

    final payload = <String, dynamic>{
      'user_id': userId,
      'action_step_id': actionStepId,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'device_id': deviceId,
    };

    await _analytics.logEvent('action_step_delete', params: payload);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<String?> _latestActionStepIdForUser(String userId) async {
    try {
      final data =
          await _client
              .from('action_steps')
              .select('id')
              .eq('user_id', userId)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();
      return data?['id'] as String?;
    } catch (_) {
      return null;
    }
  }
}

// -----------------------------------------------------------------------------
// Riverpod Provider
// -----------------------------------------------------------------------------

/// Exposes [ActionStepAnalytics] via Riverpod for injection.
final actionStepAnalyticsProvider = Provider<ActionStepAnalytics>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final analyticsService = ref.watch(analyticsServiceProvider);
  return ActionStepAnalytics(client, analyticsService);
});
