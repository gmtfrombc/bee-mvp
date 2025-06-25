/// DEPRECATION SHIM – the full implementation now lives under
/// `lib/core/services/vitals/`. This file keeps only the public types,
/// constants, and unit-test helpers required for backward compatibility.
/// Size capped < 100 LOC per component governance.
library;

import 'package:flutter/foundation.dart';
import 'package:app/core/services/vitals/processing/step_deduplicator.dart';
import 'package:app/core/services/vitals/processing/sleep_analyzer.dart';
import 'package:app/core/services/wearable_data_models.dart';
import 'package:app/core/services/vitals/stream_manager/connection_status.dart';
export 'package:app/core/services/vitals/stream_manager/connection_status.dart'
    show VitalsConnectionStatus;
import 'package:app/core/services/wearable_live_service.dart';
import 'package:app/core/services/wearable_data_repository.dart';

// ---------------------------------------------------------------------------
// Domain types (public API)
// ---------------------------------------------------------------------------

/// Data quality indicator.
enum VitalsQuality { excellent, good, fair, poor, unknown }

/// Immutable vitals snapshot consumed by widgets & services.
class VitalsData {
  final double? heartRate;
  final int? steps;
  final double? heartRateVariability;
  final double? sleepHours;
  final double? activeEnergy; // kcal
  final double? weight; // lbs
  final DateTime timestamp;
  final VitalsQuality quality;
  final Map<String, dynamic> metadata;

  const VitalsData({
    this.heartRate,
    this.steps,
    this.heartRateVariability,
    this.sleepHours,
    this.activeEnergy,
    this.weight,
    required this.timestamp,
    this.quality = VitalsQuality.unknown,
    this.metadata = const {},
  });

  // Convenience flags.
  bool get hasHeartRate => heartRate != null;
  bool get hasSteps => steps != null;
  bool get hasSleep => sleepHours != null;
  bool get hasEnergy => activeEnergy != null;
  bool get hasWeight => weight != null;
  bool get hasValidData =>
      hasHeartRate || hasSteps || hasSleep || hasEnergy || hasWeight;

  VitalsData copyWith({
    double? heartRate,
    int? steps,
    double? heartRateVariability,
    double? sleepHours,
    double? activeEnergy,
    double? weight,
    DateTime? timestamp,
    VitalsQuality? quality,
    Map<String, dynamic>? metadata,
  }) {
    return VitalsData(
      heartRate: heartRate ?? this.heartRate,
      steps: steps ?? this.steps,
      heartRateVariability: heartRateVariability ?? this.heartRateVariability,
      sleepHours: sleepHours ?? this.sleepHours,
      activeEnergy: activeEnergy ?? this.activeEnergy,
      weight: weight ?? this.weight,
      timestamp: timestamp ?? this.timestamp,
      quality: quality ?? this.quality,
      metadata: metadata ?? this.metadata,
    );
  }
}

// ---------------------------------------------------------------------------
// Legacy helpers retained for tests & constants referenced by UI.
// ---------------------------------------------------------------------------
class VitalsNotifierService {
  VitalsNotifierService(this._live, this._repo);

  final WearableLiveService _live; // ignore: unused_field
  final WearableDataRepository _repo; // ignore: unused_field

  // Flags/state retained for tests.
  bool _active = false;
  VitalsConnectionStatus _status = VitalsConnectionStatus.disconnected;

  static const String adaptivePollingPrefKey = 'adaptivePollingEnabled';

  Future<bool> initialize() async => true;

  Future<bool> startSubscription(String userId) async {
    _active = true;
    _status = VitalsConnectionStatus.connected;
    return true;
  }

  Future<void> stopSubscription() async {
    _active = false;
    _status = VitalsConnectionStatus.disconnected;
  }

  bool get isActive => _active;
  VitalsConnectionStatus get connectionStatus => _status;

  void dispose() {}

  @visibleForTesting
  static int? sumStepsForTest(List<VitalsData> samples) =>
      StepDeduplicator.sumSteps(samples);

  @visibleForTesting
  static double? computeRestfulSleepForTest(List<HealthSample> samples) =>
      SleepAnalyzer.computeRestfulSleepHours(samples);
}
