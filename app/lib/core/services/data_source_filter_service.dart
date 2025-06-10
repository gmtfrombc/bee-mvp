/// Data Source Filter Service for T2.2.2.11
///
/// Focused service for filtering health data by source to distinguish
/// Garmin-sourced data from other devices using source metadata.
/// Supports real-time streaming and batch filtering operations.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';

import 'wearable_data_models.dart';

/// Source categories for health data
enum DataSourceCategory { garmin, apple, fitbit, samsung, googleFit, unknown }

/// Filter criteria for data source filtering
class DataSourceFilterCriteria {
  final Set<DataSourceCategory> includedSources;
  final Set<DataSourceCategory> excludedSources;
  final bool includeUnknownSources;

  const DataSourceFilterCriteria({
    this.includedSources = const {},
    this.excludedSources = const {},
    this.includeUnknownSources = true,
  });

  /// Create filter for Garmin-only data
  static const DataSourceFilterCriteria garminOnly = DataSourceFilterCriteria(
    includedSources: {DataSourceCategory.garmin},
    includeUnknownSources: false,
  );

  /// Create filter excluding Garmin data
  static const DataSourceFilterCriteria excludeGarmin =
      DataSourceFilterCriteria(excludedSources: {DataSourceCategory.garmin});

  /// Create filter for all sources
  static const DataSourceFilterCriteria all = DataSourceFilterCriteria();
}

/// Result of data source filtering operation
class DataSourceFilterResult {
  final List<HealthSample> samples;
  final Map<DataSourceCategory, int> sourceCounts;
  final int totalSamples;
  final int filteredSamples;

  const DataSourceFilterResult({
    required this.samples,
    required this.sourceCounts,
    required this.totalSamples,
    required this.filteredSamples,
  });

  bool get hasGarminData =>
      sourceCounts[DataSourceCategory.garmin] != null &&
      sourceCounts[DataSourceCategory.garmin]! > 0;

  double get garminDataPercentage =>
      totalSamples > 0
          ? (sourceCounts[DataSourceCategory.garmin] ?? 0) / totalSamples
          : 0.0;
}

/// Data Source Filter Service
class DataSourceFilterService {
  // Source identification patterns
  static const Map<DataSourceCategory, List<String>> _sourcePatterns = {
    DataSourceCategory.garmin: [
      'Garmin Connect',
      'com.garmin.android.apps.connectmobile',
      'Garmin',
    ],
    DataSourceCategory.apple: [
      'Health',
      'HealthKit',
      'Apple Watch',
      'iPhone',
      'com.apple.health',
    ],
    DataSourceCategory.fitbit: [
      'Fitbit',
      'com.fitbit.FitbitMobile',
      'Fitbit App',
    ],
    DataSourceCategory.samsung: [
      'Samsung Health',
      'com.sec.android.app.shealth',
      'Galaxy Watch',
    ],
    DataSourceCategory.googleFit: [
      'Google Fit',
      'com.google.android.apps.fitness',
      'Fit',
    ],
  };

  /// Identify the source category of a health sample
  DataSourceCategory identifySourceCategory(String sourceName) {
    final lowerSource = sourceName.toLowerCase();

    for (final entry in _sourcePatterns.entries) {
      final category = entry.key;
      final patterns = entry.value;

      if (patterns.any(
        (pattern) => lowerSource.contains(pattern.toLowerCase()),
      )) {
        return category;
      }
    }

    return DataSourceCategory.unknown;
  }

  /// Filter health samples based on source criteria
  DataSourceFilterResult filterSamples(
    List<HealthSample> samples,
    DataSourceFilterCriteria criteria,
  ) {
    final Map<DataSourceCategory, int> sourceCounts = {};
    final List<HealthSample> filteredSamples = [];

    // Count all sources first
    for (final sample in samples) {
      final category = identifySourceCategory(sample.source);
      sourceCounts[category] = (sourceCounts[category] ?? 0) + 1;
    }

    // Apply filtering
    for (final sample in samples) {
      final category = identifySourceCategory(sample.source);

      bool shouldInclude = true;

      // Check inclusion criteria
      if (criteria.includedSources.isNotEmpty) {
        shouldInclude = criteria.includedSources.contains(category);
      }

      // Check exclusion criteria
      if (criteria.excludedSources.contains(category)) {
        shouldInclude = false;
      }

      // Handle unknown sources
      if (category == DataSourceCategory.unknown &&
          !criteria.includeUnknownSources) {
        shouldInclude = false;
      }

      if (shouldInclude) {
        filteredSamples.add(sample);
      }
    }

    return DataSourceFilterResult(
      samples: filteredSamples,
      sourceCounts: sourceCounts,
      totalSamples: samples.length,
      filteredSamples: filteredSamples.length,
    );
  }

  /// Filter samples to include only Garmin data
  List<HealthSample> filterGarminOnly(List<HealthSample> samples) {
    return filterSamples(samples, DataSourceFilterCriteria.garminOnly).samples;
  }

  /// Filter samples to exclude Garmin data
  List<HealthSample> filterExcludeGarmin(List<HealthSample> samples) {
    return filterSamples(
      samples,
      DataSourceFilterCriteria.excludeGarmin,
    ).samples;
  }

  /// Check if a sample is from Garmin source
  bool isGarminSource(HealthSample sample) {
    return identifySourceCategory(sample.source) == DataSourceCategory.garmin;
  }

  /// Get source distribution analysis
  Map<String, dynamic> analyzeSourceDistribution(List<HealthSample> samples) {
    final result = filterSamples(samples, DataSourceFilterCriteria.all);

    return {
      'totalSamples': result.totalSamples,
      'sourceBreakdown': result.sourceCounts.map(
        (category, count) => MapEntry(category.name, count),
      ),
      'garminPercentage': result.garminDataPercentage,
      'hasMultipleSources': result.sourceCounts.length > 1,
      'uniqueSources': samples.map((s) => s.source).toSet().toList(),
    };
  }

  /// Create stream transformer for real-time filtering
  StreamTransformer<List<HealthSample>, List<HealthSample>>
  createFilterTransformer(DataSourceFilterCriteria criteria) {
    return StreamTransformer<
      List<HealthSample>,
      List<HealthSample>
    >.fromHandlers(
      handleData: (samples, sink) {
        final result = filterSamples(samples, criteria);
        sink.add(result.samples);
      },
      handleError: (error, stackTrace, sink) {
        debugPrint('DataSourceFilter: Stream error - $error');
        sink.addError(error, stackTrace);
      },
    );
  }

  /// Get available source categories from samples
  Set<DataSourceCategory> getAvailableSourceCategories(
    List<HealthSample> samples,
  ) {
    return samples
        .map((sample) => identifySourceCategory(sample.source))
        .toSet();
  }
}
