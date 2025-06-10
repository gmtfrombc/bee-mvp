/// Live Vitals Data Fetcher for T2.2.1.5-4
///
/// Focused service for fetching health data with delta calculation.
/// Eliminates code duplication and follows single responsibility principle.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'wearable_data_repository.dart';
import 'wearable_data_models.dart';
import 'live_vitals_models.dart';

/// Service for fetching live vitals data with delta calculation
class LiveVitalsDataFetcher {
  final WearableDataRepository _repository;
  final Map<WearableDataType, double> _lastValues = {};

  LiveVitalsDataFetcher(this._repository);

  /// Fetch recent data for specified types with delta calculation
  Future<List<LiveVitalsDataPoint>> fetchRecentData({
    required List<WearableDataType> dataTypes,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final result = await _repository.getHealthData(
        dataTypes: dataTypes,
        startTime: startTime,
        endTime: endTime,
      );

      if (!result.isSuccess) {
        _debugPrint('❌ Failed to fetch health data: ${result.error}');
        return [];
      }

      final List<LiveVitalsDataPoint> points = [];

      for (final sample in result.samples) {
        final point = _createDataPoint(sample);
        if (point != null) {
          points.add(point);
        }
      }

      // Sort by timestamp to ensure correct order
      points.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      return points;
    } catch (e) {
      _debugPrint('❌ Error fetching data for types $dataTypes: $e');
      return [];
    }
  }

  /// Create a data point with delta calculation
  LiveVitalsDataPoint? _createDataPoint(HealthSample sample) {
    final value = (sample.value as num).toDouble();
    final lastValue = _lastValues[sample.type];
    final delta = lastValue != null ? value - lastValue : null;

    // Update last known value
    _lastValues[sample.type] = value;

    return LiveVitalsDataPoint(
      type: sample.type,
      value: value,
      unit: sample.unit,
      timestamp: sample.timestamp,
      source: sample.source,
      delta: delta,
    );
  }

  /// Reset delta calculations (useful for testing)
  void resetDeltas() {
    _lastValues.clear();
  }

  /// Get last known values for debugging
  Map<WearableDataType, double> get lastValues => Map.unmodifiable(_lastValues);

  /// Smart debug printing that suppresses messages in test mode
  void _debugPrint(String message) {
    // Suppress debug messages during test execution to avoid confusion
    if (_isTestMode) return;
    debugPrint(message);
  }

  /// Detect if we're running in test mode
  bool get _isTestMode {
    try {
      // Check if we're in a test environment
      return Platform.environment.containsKey('FLUTTER_TEST') ||
          Zone.current[#flutter.test] != null;
    } catch (e) {
      // If Platform is not available, check zone
      return Zone.current[#flutter.test] != null;
    }
  }
}
