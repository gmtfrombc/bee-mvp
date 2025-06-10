/// Android Garmin Feature Flag Riverpod Providers
///
/// This file provides Riverpod providers for the Android Garmin beta feature flag
/// functionality, including reactive state management for all modular components.
///
/// **Architecture**:
/// - Main service provider with auto-initialization
/// - Individual component providers for focused access
/// - Stream providers for reactive UI updates
/// - Future providers for data analysis operations
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/android_garmin_feature_flag_service.dart';

// =============================================================================
// MAIN SERVICE PROVIDER
// =============================================================================

/// Main Android Garmin Feature Flag Service provider
/// Auto-initializes the service when first accessed
final androidGarminFeatureFlagServiceProvider =
    FutureProvider<AndroidGarminFeatureFlagService>((ref) async {
      final service = AndroidGarminFeatureFlagService();
      final initialized = await service.initialize();

      if (!initialized) {
        throw Exception('Failed to initialize AndroidGarminFeatureFlagService');
      }

      // Dispose service when provider is disposed
      ref.onDispose(() {
        service.dispose();
      });

      return service;
    });

/// Synchronous access to service (throws if not initialized)
final androidGarminServiceProvider = Provider<AndroidGarminFeatureFlagService>((
  ref,
) {
  return ref
      .watch(androidGarminFeatureFlagServiceProvider)
      .when(
        data: (service) => service,
        loading:
            () =>
                throw StateError(
                  'AndroidGarminFeatureFlagService not initialized',
                ),
        error: (error, stack) => throw error,
      );
});

// =============================================================================
// COMPONENT PROVIDERS
// =============================================================================

/// Feature Flag component provider
final androidGarminFeatureFlagProvider = Provider<AndroidGarminFeatureFlag>((
  ref,
) {
  final service = ref.watch(androidGarminServiceProvider);
  return service.featureFlag;
});

/// Data Source Analyzer component provider
final garminDataSourceAnalyzerProvider = Provider<GarminDataSourceAnalyzer>((
  ref,
) {
  final service = ref.watch(androidGarminServiceProvider);
  return service.analyzer;
});

/// Warning Manager component provider
final garminWarningManagerProvider = Provider<GarminWarningManager>((ref) {
  final service = ref.watch(androidGarminServiceProvider);
  return service.warningManager;
});

// =============================================================================
// REACTIVE STATE PROVIDERS
// =============================================================================

/// Feature flag enabled state - reactive stream
final garminBetaEnabledProvider = StreamProvider<bool>((ref) {
  final featureFlag = ref.watch(androidGarminFeatureFlagProvider);
  return featureFlag.stream;
});

/// Current feature flag state - synchronous
final garminBetaIsEnabledProvider = Provider<bool>((ref) {
  final featureFlag = ref.watch(androidGarminFeatureFlagProvider);
  return featureFlag.isEnabled;
});

/// Data source analysis results - reactive stream
final garminDataSourceAnalysisProvider =
    StreamProvider<DataSourceAnalysisResult>((ref) {
      final analyzer = ref.watch(garminDataSourceAnalyzerProvider);
      return analyzer.stream;
    });

/// Latest data source analysis - synchronous
final latestGarminAnalysisProvider = Provider<DataSourceAnalysisResult?>((ref) {
  final analyzer = ref.watch(garminDataSourceAnalyzerProvider);
  return analyzer.lastAnalysis;
});

// =============================================================================
// ACTION PROVIDERS
// =============================================================================

/// Provider for enabling/disabling Garmin beta
final setGarminBetaEnabledProvider = Provider<Future<void> Function(bool)>((
  ref,
) {
  return (bool enabled) async {
    final featureFlag = ref.read(androidGarminFeatureFlagProvider);
    await featureFlag.setEnabled(enabled);
  };
});

/// Provider for triggering data source analysis
final analyzeGarminDataSourceProvider =
    Provider<Future<DataSourceAnalysisResult> Function()>((ref) {
      return () async {
        final analyzer = ref.read(garminDataSourceAnalyzerProvider);
        return await analyzer.analyzeDataSources();
      };
    });

/// Provider for recording warning shown
final recordGarminWarningProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final warningManager = ref.read(garminWarningManagerProvider);
    await warningManager.recordWarningShown();
  };
});

/// Provider for setting user opt-out
final setGarminWarningOptOutProvider = Provider<Future<void> Function(bool)>((
  ref,
) {
  return (bool optOut) async {
    final warningManager = ref.read(garminWarningManagerProvider);
    await warningManager.setUserOptOut(optOut);
  };
});

// =============================================================================
// COMPUTED STATE PROVIDERS
// =============================================================================

/// Whether platform supports Garmin functionality
final garminPlatformSupportedProvider = Provider<bool>((ref) {
  final featureFlag = ref.watch(androidGarminFeatureFlagProvider);
  return featureFlag.isPlatformSupported;
});

/// Whether to show Garmin features in UI
final shouldShowGarminFeaturesProvider = Provider<bool>((ref) {
  final service = ref.watch(androidGarminServiceProvider);
  return service.shouldShowGarminFeatures;
});

/// Whether user should see Garmin warning - async
final shouldShowGarminWarningProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(androidGarminServiceProvider);
  return await service.shouldShowGarminWarning();
});

/// Whether to recommend Garmin setup - async
final shouldRecommendGarminSetupProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(androidGarminServiceProvider);
  return await service.shouldRecommendGarminSetup;
});

/// Whether Garmin data source is available - async
final hasGarminDataSourceProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(androidGarminServiceProvider);
  return await service.hasGarminDataSource();
});

/// User-friendly status message
final garminStatusMessageProvider = Provider<String>((ref) {
  final service = ref.watch(androidGarminServiceProvider);
  return service.getStatusMessage();
});

// =============================================================================
// DEBUG PROVIDERS
// =============================================================================

/// Debug information provider
final garminDebugInfoProvider = Provider<Map<String, dynamic>>((ref) {
  final service = ref.watch(androidGarminServiceProvider);
  return service.getDebugInfo();
});

/// Warning manager debug info
final garminWarningDebugProvider = Provider<Map<String, dynamic>>((ref) {
  final warningManager = ref.watch(garminWarningManagerProvider);
  return warningManager.getDebugInfo();
});

// =============================================================================
// UTILITY PROVIDERS
// =============================================================================

/// Combined Garmin state for UI components
final garminFeatureStateProvider = Provider<GarminFeatureState>((ref) {
  final isSupported = ref.watch(garminPlatformSupportedProvider);
  final isEnabled = ref.watch(garminBetaIsEnabledProvider);
  final analysis = ref.watch(latestGarminAnalysisProvider);
  final statusMessage = ref.watch(garminStatusMessageProvider);

  return GarminFeatureState(
    isPlatformSupported: isSupported,
    isEnabled: isEnabled,
    lastAnalysis: analysis,
    statusMessage: statusMessage,
  );
});

/// Garmin feature state data class
class GarminFeatureState {
  final bool isPlatformSupported;
  final bool isEnabled;
  final DataSourceAnalysisResult? lastAnalysis;
  final String statusMessage;

  const GarminFeatureState({
    required this.isPlatformSupported,
    required this.isEnabled,
    required this.lastAnalysis,
    required this.statusMessage,
  });

  /// Whether features should be shown in UI
  bool get shouldShowFeatures => isPlatformSupported && isEnabled;

  /// Whether Garmin data is available
  bool get hasGarminData => lastAnalysis?.hasGarminSource ?? false;

  /// Current status for display
  GarminDataStatus get status =>
      lastAnalysis?.status ?? GarminDataStatus.unknown;

  /// Detected data sources
  List<String> get detectedSources => lastAnalysis?.detectedSources ?? [];

  GarminFeatureState copyWith({
    bool? isPlatformSupported,
    bool? isEnabled,
    DataSourceAnalysisResult? lastAnalysis,
    String? statusMessage,
  }) {
    return GarminFeatureState(
      isPlatformSupported: isPlatformSupported ?? this.isPlatformSupported,
      isEnabled: isEnabled ?? this.isEnabled,
      lastAnalysis: lastAnalysis ?? this.lastAnalysis,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }

  @override
  String toString() {
    return 'GarminFeatureState(isPlatformSupported: $isPlatformSupported, '
        'isEnabled: $isEnabled, status: $status, hasGarminData: $hasGarminData)';
  }
}

// =============================================================================
// INITIALIZATION HELPER
// =============================================================================

/// Helper provider to ensure service is initialized before use
final garminServiceInitializationProvider = FutureProvider<bool>((ref) async {
  final serviceAsyncValue = ref.watch(androidGarminFeatureFlagServiceProvider);
  return serviceAsyncValue.when(
    data: (_) => true,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Convenience provider to check if service is ready
final isGarminServiceReadyProvider = Provider<bool>((ref) {
  return ref
      .watch(garminServiceInitializationProvider)
      .when(
        data: (isReady) => isReady,
        loading: () => false,
        error: (_, __) => false,
      );
});
