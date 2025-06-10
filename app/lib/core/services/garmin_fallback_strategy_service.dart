/// Garmin Fallback Strategy Service for T2.2.2.12
///
/// Focused service for executing fallback strategies when Garmin data unavailable.
/// Single responsibility: strategy execution and fallback data generation.
library;

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'wearable_data_repository.dart';
import 'wearable_data_models.dart';
import 'vitals_notifier_service.dart';
import 'garmin_fallback_models.dart';

/// Service for executing Garmin fallback strategies
class GarminFallbackStrategyService {
  static const String _strategyKey = 'garmin_fallback_strategy';

  final WearableDataRepository _repository;
  final GarminFallbackConfig _config;

  GarminFallbackStrategy _activeStrategy =
      GarminFallbackStrategy.alternativeDevices;
  final List<VitalsData> _historicalPatterns = [];
  final Random _random = Random();

  bool _isInitialized = false;

  GarminFallbackStrategyService(this._repository, this._config);

  /// Current active strategy
  GarminFallbackStrategy get activeStrategy => _activeStrategy;

  /// Whether service is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the strategy service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      await _loadStoredStrategy();
      _isInitialized = true;

      debugPrint(
        '✅ GarminFallbackStrategyService initialized with strategy: ${_activeStrategy.name}',
      );
      return true;
    } catch (e) {
      debugPrint('❌ GarminFallbackStrategyService initialization failed: $e');
      return false;
    }
  }

  /// Set active fallback strategy
  Future<void> setActiveStrategy(GarminFallbackStrategy strategy) async {
    _activeStrategy = strategy;
    await _saveStrategy();
  }

  /// Record vitals data for historical pattern building
  void recordVitalsPattern(VitalsData vitals) {
    _historicalPatterns.add(vitals);

    // Maintain reasonable history size
    if (_historicalPatterns.length > _config.maxSyntheticDataPoints) {
      _historicalPatterns.removeAt(0);
    }
  }

  /// Create fallback result based on availability status
  Future<GarminFallbackResult> createFallbackResult(
    GarminAvailabilityStatus status,
  ) async {
    if (status == GarminAvailabilityStatus.available) {
      return _createSuccessResult();
    }

    switch (_activeStrategy) {
      case GarminFallbackStrategy.alternativeDevices:
        return await _createAlternativeDevicesFallback(status);
      case GarminFallbackStrategy.syntheticData:
        return _createSyntheticDataFallback(status);
      case GarminFallbackStrategy.historicalPatterns:
        return _createHistoricalPatternsFallback(status);
      case GarminFallbackStrategy.disablePhysiological:
        return _createDisabledFallback(status);
    }
  }

  /// Create success result when Garmin is available
  GarminFallbackResult _createSuccessResult() {
    return const GarminFallbackResult(
      status: GarminAvailabilityStatus.available,
      strategy: GarminFallbackStrategy.alternativeDevices,
      dataQuality: FallbackDataQuality.high,
      message: 'Garmin data available',
      metadata: {'source': 'garmin'},
    );
  }

  /// Create fallback using alternative wearable devices
  Future<GarminFallbackResult> _createAlternativeDevicesFallback(
    GarminAvailabilityStatus status,
  ) async {
    try {
      final result = await _repository.getHealthData(
        startTime: DateTime.now().subtract(const Duration(minutes: 10)),
        endTime: DateTime.now(),
      );

      if (result.isSuccess && result.samples.isNotEmpty) {
        final vitals = _convertToVitalsData(result.samples.last);
        return GarminFallbackResult(
          status: status,
          strategy: _activeStrategy,
          dataQuality: FallbackDataQuality.high,
          fallbackData: vitals,
          message: 'Using alternative wearable device data',
          metadata: {
            'source': 'alternative_device',
            'samples': result.samples.length,
          },
        );
      }

      // No alternative data available, cascade to synthetic
      return _createSyntheticDataFallback(status);
    } catch (e) {
      debugPrint('❌ Alternative devices fallback failed: $e');
      return _createSyntheticDataFallback(status);
    }
  }

  /// Create fallback using synthetic data
  GarminFallbackResult _createSyntheticDataFallback(
    GarminAvailabilityStatus status,
  ) {
    if (!_config.enableSyntheticData) {
      return _createHistoricalPatternsFallback(status);
    }

    final syntheticVitals = _generateSyntheticVitals();
    return GarminFallbackResult(
      status: status,
      strategy: GarminFallbackStrategy.syntheticData,
      dataQuality: FallbackDataQuality.moderate,
      fallbackData: syntheticVitals,
      message: 'Using synthetic health data based on typical patterns',
      metadata: {'source': 'synthetic', 'quality': 'estimated'},
    );
  }

  /// Create fallback using historical patterns
  GarminFallbackResult _createHistoricalPatternsFallback(
    GarminAvailabilityStatus status,
  ) {
    if (!_config.enableHistoricalPatterns || _historicalPatterns.isEmpty) {
      return _createDisabledFallback(status);
    }

    final avgVitals = _calculateAverageVitals();
    return GarminFallbackResult(
      status: status,
      strategy: GarminFallbackStrategy.historicalPatterns,
      dataQuality: FallbackDataQuality.moderate,
      fallbackData: avgVitals,
      message: 'Using historical health data patterns',
      metadata: {
        'source': 'historical',
        'pattern_count': _historicalPatterns.length,
      },
    );
  }

  /// Create fallback indicating physiological features disabled
  GarminFallbackResult _createDisabledFallback(
    GarminAvailabilityStatus status,
  ) {
    return GarminFallbackResult(
      status: status,
      strategy: GarminFallbackStrategy.disablePhysiological,
      dataQuality: FallbackDataQuality.none,
      message: 'Physiological coaching features temporarily disabled',
      metadata: {'coaching_mode': 'engagement_only'},
    );
  }

  /// Generate synthetic vitals data
  VitalsData _generateSyntheticVitals() {
    // Generate realistic synthetic data based on typical ranges
    final heartRate = 70.0 + _random.nextDouble() * 20; // 70-90 bpm
    final steps = 100 + _random.nextInt(200); // 100-300 steps per interval
    final hrv = 20.0 + _random.nextDouble() * 30; // 20-50 ms

    return VitalsData(
      heartRate: heartRate,
      steps: steps,
      heartRateVariability: hrv,
      timestamp: DateTime.now(),
      quality: VitalsQuality.fair,
      metadata: {'synthetic': true, 'quality': 'estimated'},
    );
  }

  /// Calculate average vitals from historical patterns
  VitalsData? _calculateAverageVitals() {
    if (_historicalPatterns.isEmpty) return null;

    final heartRates =
        _historicalPatterns
            .where((v) => v.hasHeartRate)
            .map((v) => v.heartRate!)
            .toList();
    final steps =
        _historicalPatterns
            .where((v) => v.hasSteps)
            .map((v) => v.steps!)
            .toList();

    final avgHeartRate =
        heartRates.isNotEmpty
            ? heartRates.reduce((a, b) => a + b) / heartRates.length
            : null;
    final avgSteps =
        steps.isNotEmpty
            ? (steps.reduce((a, b) => a + b) / steps.length).round()
            : null;

    return VitalsData(
      heartRate: avgHeartRate,
      steps: avgSteps,
      timestamp: DateTime.now(),
      quality: VitalsQuality.fair,
      metadata: {
        'historical': true,
        'pattern_count': _historicalPatterns.length,
      },
    );
  }

  /// Convert HealthSample to VitalsData
  VitalsData _convertToVitalsData(HealthSample sample) {
    double? heartRate;
    int? steps;
    double? hrv;

    switch (sample.type) {
      case WearableDataType.heartRate:
        heartRate = (sample.value as num?)?.toDouble();
        break;
      case WearableDataType.steps:
        steps = (sample.value as num?)?.toInt();
        break;
      case WearableDataType.heartRateVariability:
        hrv = (sample.value as num?)?.toDouble();
        break;
      default:
        break;
    }

    return VitalsData(
      heartRate: heartRate,
      steps: steps,
      heartRateVariability: hrv,
      timestamp: sample.timestamp,
      quality: VitalsQuality.good,
      metadata: {'source': sample.source, 'fallback': true},
    );
  }

  /// Load stored strategy preference
  Future<void> _loadStoredStrategy() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final strategyName = prefs.getString(_strategyKey);

      if (strategyName != null) {
        _activeStrategy = GarminFallbackStrategy.values.firstWhere(
          (s) => s.name == strategyName,
          orElse: () => GarminFallbackStrategy.alternativeDevices,
        );
      }
    } catch (e) {
      debugPrint('⚠️ Error loading stored strategy: $e');
    }
  }

  /// Save current strategy preference
  Future<void> _saveStrategy() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_strategyKey, _activeStrategy.name);
    } catch (e) {
      debugPrint('⚠️ Error saving strategy: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _historicalPatterns.clear();
    _isInitialized = false;
    debugPrint('🗑️ GarminFallbackStrategyService disposed');
  }
}
