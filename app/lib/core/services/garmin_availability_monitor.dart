/// Garmin Availability Monitor for T2.2.2.12
///
/// Focused service for monitoring Garmin data availability status.
/// Single responsibility: availability detection and status streaming.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'android_garmin_feature_flag_service.dart';
import 'garmin_fallback_models.dart';

/// Service for monitoring Garmin data availability
class GarminAvailabilityMonitor {
  static const String _lastCheckKey = 'garmin_availability_last_check';

  final AndroidGarminFeatureFlagService _garminService;
  final GarminFallbackConfig _config;

  Timer? _monitoringTimer;
  StreamController<GarminAvailabilityStatus>? _statusController;

  GarminAvailabilityStatus _currentStatus = GarminAvailabilityStatus.unknown;
  bool _isInitialized = false;

  GarminAvailabilityMonitor(this._garminService, this._config);

  /// Stream of availability status updates
  Stream<GarminAvailabilityStatus> get statusStream =>
      _statusController?.stream ?? const Stream.empty();

  /// Current availability status
  GarminAvailabilityStatus get currentStatus => _currentStatus;

  /// Whether monitor is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the availability monitor
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _statusController =
          StreamController<GarminAvailabilityStatus>.broadcast();
      _startPeriodicMonitoring();
      _isInitialized = true;

      debugPrint('✅ GarminAvailabilityMonitor initialized');
      return true;
    } catch (e) {
      debugPrint('❌ GarminAvailabilityMonitor initialization failed: $e');
      return false;
    }
  }

  /// Check current Garmin availability
  Future<GarminAvailabilityStatus> checkAvailability() async {
    if (!_isInitialized) {
      throw StateError('GarminAvailabilityMonitor not initialized');
    }

    try {
      final hasGarminData = await _garminService.hasGarminDataSource();
      final newStatus = _determineStatus(hasGarminData);

      if (newStatus != _currentStatus) {
        _currentStatus = newStatus;
        _statusController?.add(_currentStatus);
        debugPrint('📊 Garmin availability: ${_currentStatus.name}');
      }

      await _saveCheckTimestamp();
      return _currentStatus;
    } catch (e) {
      debugPrint('❌ Error checking Garmin availability: $e');
      _currentStatus = GarminAvailabilityStatus.unknown;
      _statusController?.add(_currentStatus);
      return _currentStatus;
    }
  }

  /// Determine status based on data presence
  GarminAvailabilityStatus _determineStatus(bool hasGarminData) {
    if (hasGarminData) {
      return GarminAvailabilityStatus.available;
    }

    // For now, treat unavailability as temporary
    // Could be enhanced with persistence logic for permanent detection
    return GarminAvailabilityStatus.temporarilyUnavailable;
  }

  /// Start periodic availability monitoring
  void _startPeriodicMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(
      _config.availabilityCheckInterval,
      (_) => checkAvailability(),
    );
  }

  /// Save check timestamp for tracking
  Future<void> _saveCheckTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastCheckKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('⚠️ Error saving availability check timestamp: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _monitoringTimer?.cancel();
    _statusController?.close();
    _isInitialized = false;
    debugPrint('🗑️ GarminAvailabilityMonitor disposed');
  }
}
