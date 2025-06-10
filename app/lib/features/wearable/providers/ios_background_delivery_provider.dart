/// iOS Background Delivery Providers
///
/// Riverpod providers for iOS background health data delivery.
/// Follows existing provider patterns and integrates with live data streaming.
/// Part of Epic 2.2 Task T2.2.2.2
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';
import '../../../core/services/ios_background_delivery_service.dart';
import '../../../core/services/wearable_live_models.dart';
import '../../../core/services/wearable_data_models.dart';

/// Provider for Health instance
final healthProvider = Provider<Health>((ref) => Health());

/// Provider for IOSBackgroundDeliveryService instance
final iosBackgroundDeliveryServiceProvider =
    Provider<IOSBackgroundDeliveryService>((ref) {
      final health = ref.watch(healthProvider);
      // Create our own stream controller for the background delivery service
      final messageController = StreamController<WearableLiveMessage>();

      return IOSBackgroundDeliveryService(health, messageController);
    });

/// Provider for iOS background delivery setup status
final iosBackgroundDeliverySetupProvider =
    FutureProvider<BackgroundDeliverySetupResult>((ref) async {
      final service = ref.watch(iosBackgroundDeliveryServiceProvider);
      return service.setupBackgroundDelivery();
    });

/// Provider for iOS background delivery active status
final iosBackgroundDeliveryActiveProvider = Provider<bool>((ref) {
  final service = ref.watch(iosBackgroundDeliveryServiceProvider);
  return service.isActive;
});

/// Provider for iOS background delivery statistics
final iosBackgroundDeliveryStatsProvider = Provider<Map<String, dynamic>>((
  ref,
) {
  final service = ref.watch(iosBackgroundDeliveryServiceProvider);
  return service.getDeliveryStats();
});

/// Provider for managing iOS background delivery operations
final iosBackgroundDeliveryManagerProvider =
    Provider<IOSBackgroundDeliveryManager>(
      (ref) => IOSBackgroundDeliveryManager(ref),
    );

/// Manager for iOS background delivery operations
class IOSBackgroundDeliveryManager {
  final Ref _ref;

  const IOSBackgroundDeliveryManager(this._ref);

  /// Get the background delivery service
  IOSBackgroundDeliveryService get _service =>
      _ref.read(iosBackgroundDeliveryServiceProvider);

  /// Setup background delivery
  Future<BackgroundDeliverySetupResult> setupBackgroundDelivery() async {
    return _service.setupBackgroundDelivery();
  }

  /// Stop background delivery
  Future<void> stopBackgroundDelivery() async {
    return _service.stopBackgroundDelivery();
  }

  /// Pause background delivery
  void pauseBackgroundDelivery() {
    _service.pauseBackgroundDelivery();
  }

  /// Resume background delivery
  void resumeBackgroundDelivery() {
    _service.resumeBackgroundDelivery();
  }

  /// Get delivery statistics
  Map<String, dynamic> getDeliveryStats() => _service.getDeliveryStats();

  /// Check if service is active
  bool get isActive => _service.isActive;

  /// Check if service is supported
  bool get isSupported => _service.isSupported;

  /// Get enabled data types
  Set<WearableDataType> get enabledTypes => _service.enabledTypes;
}
