/// Garmin Fallback Service for T2.2.2.12
///
/// Orchestrates graceful degradation when Garmin data is unavailable for AI coaching.
/// Delegates to focused helper services for different fallback strategies.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';

import 'android_garmin_feature_flag_service.dart';
import 'wearable_data_repository.dart';
import 'vitals_notifier_service.dart';
import 'garmin_fallback_models.dart';
import 'garmin_availability_monitor.dart';
import 'garmin_fallback_strategy_service.dart';

/// Main orchestrator service for Garmin fallback handling
class GarminFallbackService {
  final AndroidGarminFeatureFlagService _garminService;
  final WearableDataRepository _repository;
  final GarminFallbackConfig _config;

  late final GarminAvailabilityMonitor _availabilityMonitor;
  late final GarminFallbackStrategyService _strategyService;

  StreamController<GarminFallbackResult>? _fallbackController;
  bool _isInitialized = false;

  GarminFallbackService(
    this._garminService,
    this._repository, {
    GarminFallbackConfig config = GarminFallbackConfig.defaultConfig,
  }) : _config = config;

  /// Stream of fallback status updates
  Stream<GarminFallbackResult> get fallbackStream =>
      _fallbackController?.stream ?? const Stream.empty();

  /// Current Garmin availability status
  GarminAvailabilityStatus get currentStatus =>
      _availabilityMonitor.currentStatus;

  /// Active fallback strategy
  GarminFallbackStrategy get activeStrategy => _strategyService.activeStrategy;

  /// Whether service is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the fallback service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _fallbackController = StreamController<GarminFallbackResult>.broadcast();

      // Initialize components
      _availabilityMonitor = GarminAvailabilityMonitor(_garminService, _config);
      _strategyService = GarminFallbackStrategyService(_repository, _config);

      await _garminService.initialize();
      await _availabilityMonitor.initialize();
      await _strategyService.initialize();

      // Listen to availability changes
      _availabilityMonitor.statusStream.listen(_handleAvailabilityChange);

      _isInitialized = true;

      // Perform initial check after marking as initialized
      await checkFallbackStatus();

      debugPrint('✅ GarminFallbackService initialized');
      return true;
    } catch (e) {
      debugPrint('❌ GarminFallbackService initialization failed: $e');
      return false;
    }
  }

  /// Check current Garmin availability and determine fallback
  Future<GarminFallbackResult> checkFallbackStatus() async {
    if (!_isInitialized) {
      throw StateError('GarminFallbackService not initialized');
    }

    final status = await _availabilityMonitor.checkAvailability();
    final result = await _strategyService.createFallbackResult(status);

    _fallbackController?.add(result);
    return result;
  }

  /// Get fallback vitals data when Garmin unavailable
  Future<VitalsData?> getFallbackVitalsData() async {
    final result = await checkFallbackStatus();
    return result.fallbackData;
  }

  /// Update fallback strategy preference
  Future<void> setFallbackStrategy(GarminFallbackStrategy strategy) async {
    await _strategyService.setActiveStrategy(strategy);
    debugPrint('🔄 Updated fallback strategy: ${strategy.name}');
  }

  /// Store vitals data for historical pattern building
  void recordVitalsPattern(VitalsData vitals) {
    _strategyService.recordVitalsPattern(vitals);
  }

  /// Handle availability status changes
  void _handleAvailabilityChange(GarminAvailabilityStatus status) {
    debugPrint('🔄 Garmin status changed: ${status.name}');
    // Trigger fallback check on status change
    checkFallbackStatus();
  }

  /// Dispose resources
  void dispose() {
    if (_isInitialized) {
      _availabilityMonitor.dispose();
      _strategyService.dispose();
    }
    _fallbackController?.close();
    _isInitialized = false;
    debugPrint('🗑️ GarminFallbackService disposed');
  }
}
