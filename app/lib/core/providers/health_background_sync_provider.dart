/// Riverpod providers for health background sync functionality
///
/// Provides state management for background health data synchronization
/// using the HealthBackgroundSyncService.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/health_background_sync_service.dart';
import '../services/wearable_data_models.dart';

/// Provider for the singleton HealthBackgroundSyncService
final healthBackgroundSyncServiceProvider =
    Provider<HealthBackgroundSyncService>(
      (ref) => HealthBackgroundSyncService(),
    );

/// Provider for background sync status
final backgroundSyncStatusProvider = StreamProvider<HealthBackgroundSyncEvent>((
  ref,
) {
  final service = ref.watch(healthBackgroundSyncServiceProvider);
  return service.events;
});

/// Provider for checking if background sync is active
final isBackgroundSyncActiveProvider = Provider<bool>((ref) {
  final service = ref.watch(healthBackgroundSyncServiceProvider);
  return service.isActive;
});

/// Provider for background sync configuration
final backgroundSyncConfigProvider = StateProvider<HealthBackgroundSyncConfig>(
  (ref) => HealthBackgroundSyncConfig.defaultConfig,
);

/// Provider for managing background sync operations
final backgroundSyncManagerProvider = Provider<BackgroundSyncManager>(
  (ref) => BackgroundSyncManager(ref),
);

/// Manager for background sync operations
class BackgroundSyncManager {
  final Ref _ref;

  const BackgroundSyncManager(this._ref);

  /// Get the background sync service
  HealthBackgroundSyncService get _service =>
      _ref.read(healthBackgroundSyncServiceProvider);

  /// Get current configuration
  HealthBackgroundSyncConfig get config =>
      _ref.read(backgroundSyncConfigProvider);

  /// Initialize background sync
  Future<HealthBackgroundSyncResult> initialize({
    HealthBackgroundSyncConfig? config,
  }) async {
    if (config != null) {
      _ref.read(backgroundSyncConfigProvider.notifier).state = config;
    }
    return _service.initialize(config: config ?? this.config);
  }

  /// Start background monitoring
  Future<HealthBackgroundSyncResult> startMonitoring({
    List<WearableDataType>? dataTypes,
  }) async {
    return _service.startMonitoring(dataTypes: dataTypes);
  }

  /// Stop background monitoring
  Future<HealthBackgroundSyncResult> stopMonitoring() async {
    return _service.stopMonitoring();
  }

  /// Update configuration
  void updateConfig(HealthBackgroundSyncConfig config) {
    _ref.read(backgroundSyncConfigProvider.notifier).state = config;
    _service.updateConfig(config);
  }

  /// Get status information
  Map<String, dynamic> getStatus() => _service.getStatus();

  /// Check if service is active
  bool get isActive => _service.isActive;
}

/// Provider for filtered background sync events by type
final backgroundSyncEventsByTypeProvider =
    Provider.family<Stream<HealthBackgroundSyncEvent>, Type>((ref, eventType) {
      final service = ref.watch(healthBackgroundSyncServiceProvider);
      return service.events.where((event) => event.runtimeType == eventType);
    });

/// Provider for latest health data from background sync
final latestBackgroundHealthDataProvider = StreamProvider<List<HealthSample>>((
  ref,
) {
  final service = ref.watch(healthBackgroundSyncServiceProvider);
  return service.events
      .where((event) => event is HealthBackgroundSyncDataEvent)
      .cast<HealthBackgroundSyncDataEvent>()
      .map((event) => event.samples);
});

/// Provider for background sync error tracking
final backgroundSyncErrorProvider = StreamProvider<String?>((ref) {
  final service = ref.watch(healthBackgroundSyncServiceProvider);
  return service.events
      .where((event) => event is HealthBackgroundSyncErrorEvent)
      .cast<HealthBackgroundSyncErrorEvent>()
      .map((event) => event.error);
});

/// Provider for background sync statistics
final backgroundSyncStatsProvider = Provider<BackgroundSyncStats>((ref) {
  final service = ref.watch(healthBackgroundSyncServiceProvider);
  final status = service.getStatus();

  return BackgroundSyncStats(
    isActive: status['isActive'] as bool,
    platform: status['platform'] as String,
    monitoredTypes: (status['monitoredTypes'] as List<dynamic>).cast<String>(),
    fetchIntervalSeconds: status['fetchInterval'] as int,
    iosObserversActive: status['iosObserversActive'] as int,
    androidCallbackFlowActive: status['androidCallbackFlowActive'] as bool,
  );
});

/// Background sync statistics data class
class BackgroundSyncStats {
  final bool isActive;
  final String platform;
  final List<String> monitoredTypes;
  final int fetchIntervalSeconds;
  final int iosObserversActive;
  final bool androidCallbackFlowActive;

  const BackgroundSyncStats({
    required this.isActive,
    required this.platform,
    required this.monitoredTypes,
    required this.fetchIntervalSeconds,
    required this.iosObserversActive,
    required this.androidCallbackFlowActive,
  });

  int get totalActiveMonitors =>
      iosObserversActive + (androidCallbackFlowActive ? 1 : 0);

  @override
  String toString() {
    return 'BackgroundSyncStats('
        'isActive: $isActive, '
        'platform: $platform, '
        'monitoredTypes: ${monitoredTypes.length}, '
        'activeMonitors: $totalActiveMonitors'
        ')';
  }
}
