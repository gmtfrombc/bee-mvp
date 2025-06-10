/// Health Data Quality Harness for T2.2.1.5-3
///
/// Validates data quality by comparing pulled health data values against
/// Apple Health Summary data using runtime asserts with ±3% tolerance.
/// Part of Epic 2.2 wearable integration validation.
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

import 'wearable_data_repository.dart';
import 'wearable_data_models.dart';

/// Data quality validation result
class HealthDataQualityResult {
  final String validationId;
  final DateTime timestamp;
  final bool passed;
  final Map<WearableDataType, DataTypeValidation> validations;
  final List<String> issues;
  final List<String> warnings;
  final Map<String, dynamic> summary;

  const HealthDataQualityResult({
    required this.validationId,
    required this.timestamp,
    required this.passed,
    required this.validations,
    required this.issues,
    required this.warnings,
    required this.summary,
  });

  factory HealthDataQualityResult.error(String error) {
    return HealthDataQualityResult(
      validationId: 'error_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      passed: false,
      validations: {},
      issues: [error],
      warnings: [],
      summary: {'error': error},
    );
  }
}

/// Individual data type validation result
class DataTypeValidation {
  final WearableDataType type;
  final double? appValue;
  final double? healthSummaryValue;
  final double? variancePercent;
  final bool withinTolerance;
  final String status;
  final String? details;

  const DataTypeValidation({
    required this.type,
    this.appValue,
    this.healthSummaryValue,
    this.variancePercent,
    required this.withinTolerance,
    required this.status,
    this.details,
  });
}

/// Health Data Quality Harness Service
class HealthDataQualityHarness {
  static const double _tolerancePercent = 3.0;
  static const Duration _validationWindow = Duration(hours: 24);

  final WearableDataRepository _repository = WearableDataRepository();
  final Health _health = Health();
  bool _isInitialized = false;

  // Test environment detection
  bool get _isTestEnvironment =>
      kDebugMode &&
      (Platform.environment['FLUTTER_TEST'] == 'true' ||
          kIsWeb ||
          !kReleaseMode);

  /// Target data types for validation per T2.2.1.5-2 requirements
  static const List<WearableDataType> _targetTypes = [
    WearableDataType.steps,
    WearableDataType.heartRate,
    WearableDataType.sleepDuration,
  ];

  /// Initialize the quality harness
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      if (_isTestEnvironment) {
        debugPrint('🧪 Initializing HealthDataQualityHarness (Test Mode)');
      } else {
        debugPrint('🔍 Initializing HealthDataQualityHarness');
      }

      final repositoryInitialized = await _repository.initialize();
      if (!repositoryInitialized) {
        if (!_isTestEnvironment) {
          debugPrint('❌ Failed to initialize WearableDataRepository');
        }
        return false;
      }

      _isInitialized = true;
      if (_isTestEnvironment) {
        debugPrint('✅ HealthDataQualityHarness initialized (Test Mode)');
      } else {
        debugPrint('✅ HealthDataQualityHarness initialized');
      }
      return true;
    } catch (e) {
      if (!_isTestEnvironment) {
        debugPrint('❌ HealthDataQualityHarness initialization error: $e');
      }
      return false;
    }
  }

  /// Execute comprehensive quality validation
  Future<HealthDataQualityResult> executeValidation({
    List<WearableDataType>? dataTypes,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    if (!_isInitialized) {
      throw StateError('HealthDataQualityHarness not initialized');
    }

    final validationId = 'validation_${DateTime.now().millisecondsSinceEpoch}';
    final timestamp = DateTime.now();
    final types = dataTypes ?? _targetTypes;
    final end = endTime ?? timestamp;
    final start = startTime ?? end.subtract(_validationWindow);

    debugPrint('🔍 Starting quality validation: $validationId');
    debugPrint('📊 Validating types: ${types.map((t) => t.name).join(', ')}');
    debugPrint('⏰ Time range: $start to $end');

    try {
      final validations = <WearableDataType, DataTypeValidation>{};
      final issues = <String>[];
      final warnings = <String>[];
      bool overallPassed = true;

      // Validate each data type
      for (final type in types) {
        try {
          final validation = await _validateDataType(type, start, end);
          validations[type] = validation;

          if (!validation.withinTolerance) {
            overallPassed = false;
            issues.add(
              '${type.name}: ${validation.variancePercent?.toStringAsFixed(1)}% '
              'variance exceeds ±$_tolerancePercent% tolerance',
            );
          }

          // Runtime assert for critical validation failures
          if (kDebugMode && !validation.withinTolerance) {
            assert(
              validation.variancePercent != null &&
                  validation.variancePercent!.abs() <= _tolerancePercent,
              'QUALITY ASSERT FAILED: ${type.name} variance '
              '${validation.variancePercent?.toStringAsFixed(1)}% > ±$_tolerancePercent%',
            );
          }
        } catch (e) {
          overallPassed = false;
          issues.add('${type.name}: Validation error - $e');

          validations[type] = DataTypeValidation(
            type: type,
            withinTolerance: false,
            status: 'error',
            details: e.toString(),
          );
        }
      }

      final summary = _generateSummary(validations, overallPassed);

      final result = HealthDataQualityResult(
        validationId: validationId,
        timestamp: timestamp,
        passed: overallPassed,
        validations: validations,
        issues: issues,
        warnings: warnings,
        summary: summary,
      );

      debugPrint(
        overallPassed
            ? (_isTestEnvironment
                ? '✅ Quality validation completed (Test Mode): $validationId'
                : '✅ Quality validation PASSED: $validationId')
            : (_isTestEnvironment
                ? '🧪 Quality validation completed with expected test errors: $validationId'
                : '❌ Quality validation FAILED: $validationId'),
      );

      return result;
    } catch (e) {
      debugPrint('❌ Quality validation error: $e');
      return HealthDataQualityResult.error(e.toString());
    }
  }

  /// Validate individual data type against Health Summary
  Future<DataTypeValidation> _validateDataType(
    WearableDataType type,
    DateTime start,
    DateTime end,
  ) async {
    if (_isTestEnvironment) {
      debugPrint('🧪 Testing validation for $type (expecting platform errors)');
    } else {
      debugPrint('🔍 Validating $type');
    }

    try {
      // Get data from our app's repository
      final appResult = await _repository.getHealthData(
        dataTypes: [type],
        startTime: start,
        endTime: end,
      );

      if (!appResult.isSuccess) {
        return DataTypeValidation(
          type: type,
          withinTolerance: false,
          status: _isTestEnvironment ? 'test_expected_error' : 'app_data_error',
          details:
              _isTestEnvironment
                  ? 'Expected test environment error: ${appResult.error}'
                  : appResult.error,
        );
      }

      // Get data directly from Health platform for comparison
      final healthSummaryValue = await _getHealthSummaryValue(type, start, end);

      if (healthSummaryValue == null) {
        return DataTypeValidation(
          type: type,
          withinTolerance: false,
          status:
              _isTestEnvironment ? 'test_no_health_data' : 'no_health_summary',
          details:
              _isTestEnvironment
                  ? 'No health data available in test environment'
                  : 'Could not retrieve Health app summary data',
        );
      }

      final appValue = _aggregateAppData(appResult.samples, type);

      if (appValue == null) {
        return DataTypeValidation(
          type: type,
          appValue: appValue,
          healthSummaryValue: healthSummaryValue,
          withinTolerance: false,
          status: _isTestEnvironment ? 'test_no_app_data' : 'no_app_data',
          details:
              _isTestEnvironment
                  ? 'No app data available in test environment'
                  : 'No app data available for comparison',
        );
      }

      // Calculate variance percentage
      final variance = _calculateVariancePercent(appValue, healthSummaryValue);
      final withinTolerance = variance.abs() <= _tolerancePercent;

      if (!_isTestEnvironment) {
        debugPrint(
          '📊 $type: App=${appValue.toStringAsFixed(1)}, '
          'Health=${healthSummaryValue.toStringAsFixed(1)}, '
          'Variance=${variance.toStringAsFixed(1)}%',
        );
      }

      return DataTypeValidation(
        type: type,
        appValue: appValue,
        healthSummaryValue: healthSummaryValue,
        variancePercent: variance,
        withinTolerance: withinTolerance,
        status: withinTolerance ? 'passed' : 'failed',
        details: 'Variance: ${variance.toStringAsFixed(1)}%',
      );
    } catch (e) {
      if (_isTestEnvironment) {
        // Don't print error messages in test mode - they're expected
      } else {
        debugPrint('❌ Error validating $type: $e');
      }
      return DataTypeValidation(
        type: type,
        withinTolerance: false,
        status:
            _isTestEnvironment ? 'test_environment_error' : 'validation_error',
        details:
            _isTestEnvironment
                ? 'Expected validation error in test environment'
                : e.toString(),
      );
    }
  }

  /// Get health summary value directly from platform
  Future<double?> _getHealthSummaryValue(
    WearableDataType type,
    DateTime start,
    DateTime end,
  ) async {
    final healthType = type.toHealthDataType();
    if (healthType == null) return null;

    try {
      final healthData = await _health.getHealthDataFromTypes(
        types: [healthType],
        startTime: start,
        endTime: end,
      );

      if (healthData.isEmpty) return null;

      // Aggregate based on data type
      switch (type) {
        case WearableDataType.steps:
        case WearableDataType.activeEnergyBurned:
          // Sum for cumulative metrics
          return healthData
              .map((point) => (point.value as num).toDouble())
              .fold<double>(0.0, (sum, value) => sum + value);

        case WearableDataType.heartRate:
          // Average for rate metrics
          if (healthData.isEmpty) return null;
          final values =
              healthData
                  .map((point) => (point.value as num).toDouble())
                  .toList();
          return values.isNotEmpty
              ? values.fold(0.0, (sum, value) => sum + value) / values.length
              : null;

        case WearableDataType.sleepDuration:
          // Total sleep duration in hours
          return healthData
              .map((point) => (point.value as num).toDouble())
              .fold<double>(0.0, (sum, value) => sum + value);

        default:
          // For other types, take most recent value
          return (healthData.first.value as num).toDouble();
      }
    } catch (e) {
      debugPrint('❌ Error getting health summary for $type: $e');
      return null;
    }
  }

  /// Aggregate app data based on data type
  double? _aggregateAppData(List<HealthSample> samples, WearableDataType type) {
    if (samples.isEmpty) return null;

    switch (type) {
      case WearableDataType.steps:
      case WearableDataType.activeEnergyBurned:
        // Sum for cumulative metrics
        return samples
            .map((s) => (s.value as num).toDouble())
            .fold<double>(0.0, (sum, value) => sum + value);

      case WearableDataType.heartRate:
        // Average for rate metrics
        final values = samples.map((s) => (s.value as num).toDouble()).toList();
        return values.isNotEmpty
            ? values.fold(0.0, (sum, value) => sum + value) / values.length
            : null;

      case WearableDataType.sleepDuration:
        // Total sleep duration
        return samples
            .map((s) => (s.value as num).toDouble())
            .fold<double>(0.0, (sum, value) => sum + value);

      default:
        // For other types, take most recent value
        return (samples.first.value as num).toDouble();
    }
  }

  /// Calculate variance percentage between two values
  double _calculateVariancePercent(double appValue, double healthValue) {
    if (healthValue == 0) {
      return appValue == 0 ? 0.0 : 100.0;
    }
    return ((appValue - healthValue) / healthValue) * 100.0;
  }

  /// Generate validation summary
  Map<String, dynamic> _generateSummary(
    Map<WearableDataType, DataTypeValidation> validations,
    bool overallPassed,
  ) {
    final passedCount =
        validations.values.where((v) => v.withinTolerance).length;
    final failedCount = validations.length - passedCount;

    final variances =
        validations.values
            .where((v) => v.variancePercent != null)
            .map((v) => v.variancePercent!.abs())
            .toList();

    final avgVariance =
        variances.isNotEmpty
            ? variances.fold<double>(0.0, (sum, value) => sum + value) /
                variances.length
            : 0.0;

    final maxVariance =
        variances.isNotEmpty
            ? variances.fold<double>(
              0.0,
              (current, value) => value > current ? value : current,
            )
            : 0.0;

    return {
      'overall_passed': overallPassed,
      'passed_count': passedCount,
      'failed_count': failedCount,
      'total_count': validations.length,
      'pass_rate':
          validations.isNotEmpty
              ? (passedCount / validations.length * 100)
              : 0.0,
      'average_variance_percent': avgVariance,
      'max_variance_percent': maxVariance,
      'tolerance_percent': _tolerancePercent,
      'validation_window_hours': _validationWindow.inHours,
    };
  }

  /// Quick validation for specific data types
  Future<bool> quickValidation(List<WearableDataType> types) async {
    final result = await executeValidation(dataTypes: types);
    return result.passed;
  }

  /// Dispose of resources
  void dispose() {
    _repository.dispose();
    _isInitialized = false;
  }
}
