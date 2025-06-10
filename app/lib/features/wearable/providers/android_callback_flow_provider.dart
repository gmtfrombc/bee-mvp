/// Android Callback Flow Providers
///
/// Riverpod providers for Android Health Connect callback flow.
/// Mirrors the existing iOS provider patterns for consistency.
/// Part of Epic 2.2 Task T2.2.2.3
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';
import '../../../core/services/android_callback_flow_service.dart';
import '../../../core/services/wearable_live_models.dart';
import '../../../core/services/wearable_data_models.dart';

/// Provider for Health instance (reuse existing)
final healthProvider = Provider<Health>((ref) => Health());

/// Provider for AndroidCallbackFlowService instance
final androidCallbackFlowServiceProvider = Provider<AndroidCallbackFlowService>(
  (ref) {
    final health = ref.watch(healthProvider);
    final messageController = StreamController<WearableLiveMessage>();

    return AndroidCallbackFlowService(health, messageController);
  },
);

/// Provider for Android callback flow setup status
final androidCallbackFlowSetupProvider =
    FutureProvider<CallbackFlowSetupResult>((ref) async {
      final service = ref.watch(androidCallbackFlowServiceProvider);
      return service.setupCallbackFlow();
    });

/// Provider for Android callback flow active status
final androidCallbackFlowActiveProvider = Provider<bool>((ref) {
  final service = ref.watch(androidCallbackFlowServiceProvider);
  return service.isActive;
});

/// Provider for Android callback flow statistics
final androidCallbackFlowStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final service = ref.watch(androidCallbackFlowServiceProvider);
  return service.getCallbackFlowStats();
});

/// Provider for managing Android callback flow operations
final androidCallbackFlowManagerProvider = Provider<AndroidCallbackFlowManager>(
  (ref) => AndroidCallbackFlowManager(ref),
);

/// Manager for Android callback flow operations
class AndroidCallbackFlowManager {
  final Ref _ref;

  const AndroidCallbackFlowManager(this._ref);

  /// Get the callback flow service
  AndroidCallbackFlowService get _service =>
      _ref.read(androidCallbackFlowServiceProvider);

  /// Setup callback flow
  Future<CallbackFlowSetupResult> setupCallbackFlow() async {
    return _service.setupCallbackFlow();
  }

  /// Stop callback flow
  Future<void> stopCallbackFlow() async {
    return _service.stopCallbackFlow();
  }

  /// Pause callback flow
  void pauseCallbackFlow() {
    _service.pauseCallbackFlow();
  }

  /// Resume callback flow
  void resumeCallbackFlow() {
    _service.resumeCallbackFlow();
  }

  /// Get callback flow statistics
  Map<String, dynamic> getCallbackFlowStats() =>
      _service.getCallbackFlowStats();

  /// Check if service is active
  bool get isActive => _service.isActive;

  /// Check if service is supported
  bool get isSupported => _service.isSupported;

  /// Get enabled data types
  Set<WearableDataType> get enabledTypes => _service.enabledTypes;
}
