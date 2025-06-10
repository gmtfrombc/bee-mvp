/// Live Vitals Models for T2.2.1.5-4
///
/// Data models for live vitals streaming functionality.
/// Separated from service logic following component guidelines.
library;

import 'wearable_data_models.dart';

/// Live vitals data point for developer screen
class LiveVitalsDataPoint {
  final WearableDataType type;
  final double value;
  final String unit;
  final DateTime timestamp;
  final String source;
  final double? delta; // Change from previous value

  const LiveVitalsDataPoint({
    required this.type,
    required this.value,
    required this.unit,
    required this.timestamp,
    required this.source,
    this.delta,
  });

  @override
  String toString() {
    final deltaStr = delta != null ? ' (Δ${delta!.toStringAsFixed(1)})' : '';
    return '${type.name}: ${value.toStringAsFixed(1)} $unit$deltaStr';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LiveVitalsDataPoint &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          timestamp == other.timestamp;

  @override
  int get hashCode => type.hashCode ^ timestamp.hashCode;
}

/// Live vitals update containing recent data points
class LiveVitalsUpdate {
  final List<LiveVitalsDataPoint> heartRatePoints;
  final List<LiveVitalsDataPoint> stepPoints;
  final DateTime updateTime;
  final Duration dataWindow;

  const LiveVitalsUpdate({
    required this.heartRatePoints,
    required this.stepPoints,
    required this.updateTime,
    required this.dataWindow,
  });

  bool get hasHeartRateData => heartRatePoints.isNotEmpty;
  bool get hasStepData => stepPoints.isNotEmpty;
  bool get hasAnyData => hasHeartRateData || hasStepData;

  LiveVitalsDataPoint? get latestHeartRate =>
      heartRatePoints.isNotEmpty ? heartRatePoints.last : null;
  LiveVitalsDataPoint? get latestSteps =>
      stepPoints.isNotEmpty ? stepPoints.last : null;

  int get totalDataPoints => heartRatePoints.length + stepPoints.length;
}

/// Configuration for live vitals streaming
class LiveVitalsConfig {
  final Duration dataWindow;
  final Duration updateInterval;
  final List<WearableDataType> monitoredTypes;
  final int maxHistorySize;

  const LiveVitalsConfig({
    this.dataWindow = const Duration(seconds: 5),
    this.updateInterval = const Duration(seconds: 1),
    this.monitoredTypes = const [
      WearableDataType.heartRate,
      WearableDataType.steps,
    ],
    this.maxHistorySize = 50,
  });

  static const LiveVitalsConfig defaultConfig = LiveVitalsConfig();
}
