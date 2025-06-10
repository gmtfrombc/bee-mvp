/// Optimized Live Vitals Service for T2.2.1.5-4
///
/// Refactored service addressing audit findings:
/// - Eliminated code duplication
/// - Improved modularity and testability
/// - Added proper memory management
/// - Configurable parameters
/// - Better separation of concerns
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'wearable_data_repository.dart';
import 'wearable_data_models.dart';
import 'live_vitals_models.dart';
import 'live_vitals_data_fetcher.dart';

/// Optimized service for streaming live vitals data to developer screen
class LiveVitalsService {
  final WearableDataRepository _repository;
  final LiveVitalsDataFetcher _dataFetcher;
  final LiveVitalsConfig _config;

  bool _isInitialized = false;
  bool _isStreaming = false;

  // Test environment detection
  bool get _isTestEnvironment =>
      kDebugMode &&
      (Platform.environment['FLUTTER_TEST'] == 'true' ||
          kIsWeb ||
          !kReleaseMode);

  // Live data tracking with size limits
  final Map<WearableDataType, List<LiveVitalsDataPoint>> _dataHistory = {};

  Timer? _updateTimer;
  StreamController<LiveVitalsUpdate>? _updateController;

  /// Constructor with dependency injection for better testability
  LiveVitalsService({
    WearableDataRepository? repository,
    LiveVitalsConfig? config,
  }) : _repository = repository ?? WearableDataRepository(),
       _config = config ?? LiveVitalsConfig.defaultConfig,
       _dataFetcher = LiveVitalsDataFetcher(
         repository ?? WearableDataRepository(),
       );

  /// Singleton factory for backward compatibility
  static LiveVitalsService? _instance;
  factory LiveVitalsService.instance({
    WearableDataRepository? repository,
    LiveVitalsConfig? config,
  }) {
    _instance ??= LiveVitalsService(repository: repository, config: config);
    return _instance!;
  }

  /// Stream of live vitals updates
  Stream<LiveVitalsUpdate> get vitalsStream {
    if (_updateController == null) {
      throw StateError('LiveVitalsService not initialized');
    }
    return _updateController!.stream;
  }

  /// Whether the service is currently streaming
  bool get isStreaming => _isStreaming;

  /// Current configuration
  LiveVitalsConfig get config => _config;

  /// Initialize the live vitals service (Debug builds only)
  Future<bool> initialize() async {
    // Only allow in debug builds
    if (kReleaseMode) {
      debugPrint('⚠️ LiveVitalsService: Not available in release builds');
      return false;
    }

    if (_isInitialized) return true;

    try {
      if (!_isTestEnvironment) {
        debugPrint('🔴 Initializing LiveVitalsService (Debug Mode)');
      }

      // Initialize repository
      if (!_repository.isInitialized) {
        final repoInit = await _repository.initialize();
        if (!repoInit) {
          if (!_isTestEnvironment) {
            debugPrint('❌ Failed to initialize WearableDataRepository');
          }
          return false;
        }
      }

      // Initialize data history for monitored types
      for (final type in _config.monitoredTypes) {
        _dataHistory[type] = [];
      }

      // Initialize stream controller
      _updateController = StreamController<LiveVitalsUpdate>.broadcast();

      _isInitialized = true;
      if (!_isTestEnvironment) {
        debugPrint('✅ LiveVitalsService initialized');
      }
      return true;
    } catch (e) {
      if (!_isTestEnvironment) {
        debugPrint('❌ LiveVitalsService initialization error: $e');
      }
      return false;
    }
  }

  /// Start streaming live vitals data
  Future<bool> startStreaming() async {
    if (!_isInitialized) {
      throw StateError('LiveVitalsService not initialized');
    }

    if (_isStreaming) {
      if (!_isTestEnvironment) {
        debugPrint('ℹ️ LiveVitalsService already streaming');
      }
      return true;
    }

    try {
      // Check permissions
      final permissionStatus = await _repository.checkPermissions();
      if (permissionStatus != HealthPermissionStatus.authorized) {
        if (!_isTestEnvironment) {
          debugPrint('❌ Health permissions not granted: $permissionStatus');
        }
        return false;
      }

      if (!_isTestEnvironment) {
        debugPrint('🚀 Starting live vitals streaming');
      }

      // Start periodic updates
      _updateTimer = Timer.periodic(
        _config.updateInterval,
        (_) => _updateVitals(),
      );

      _isStreaming = true;
      return true;
    } catch (e) {
      if (!_isTestEnvironment) {
        debugPrint('❌ Failed to start live vitals streaming: $e');
      }
      return false;
    }
  }

  /// Stop streaming live vitals data
  void stopStreaming() {
    if (!_isStreaming) return;

    _updateTimer?.cancel();
    _updateTimer = null;
    _isStreaming = false;

    if (!_isTestEnvironment) {
      debugPrint('⏹️ Live vitals streaming stopped');
    }
  }

  /// Update vitals data from repository
  Future<void> _updateVitals() async {
    try {
      final now = DateTime.now();
      final lookbackTime = now.subtract(_config.dataWindow);

      // Fetch recent data for all monitored types
      final newPoints = await _dataFetcher.fetchRecentData(
        dataTypes: _config.monitoredTypes,
        startTime: lookbackTime,
        endTime: now,
      );

      // Add new points to history and manage size
      for (final point in newPoints) {
        final history = _dataHistory[point.type];
        if (history != null) {
          // Add if not already present (avoid duplicates)
          if (!history.any((p) => p.timestamp == point.timestamp)) {
            history.add(point);

            // Limit history size to prevent memory issues
            if (history.length > _config.maxHistorySize) {
              history.removeRange(0, history.length - _config.maxHistorySize);
            }
          }
        }
      }

      // Clean old data outside the window
      _cleanOldData(lookbackTime);

      // Create update with separated data types
      final update = _createUpdate(now);

      _updateController?.add(update);
    } catch (e) {
      if (!_isTestEnvironment) {
        debugPrint('❌ Error updating live vitals: $e');
      }
    }
  }

  /// Create vitals update from current data
  LiveVitalsUpdate _createUpdate(DateTime updateTime) {
    final heartRatePoints = _dataHistory[WearableDataType.heartRate] ?? [];
    final stepPoints = _dataHistory[WearableDataType.steps] ?? [];

    return LiveVitalsUpdate(
      heartRatePoints: List.from(heartRatePoints),
      stepPoints: List.from(stepPoints),
      updateTime: updateTime,
      dataWindow: _config.dataWindow,
    );
  }

  /// Remove data points older than the data window
  void _cleanOldData(DateTime cutoffTime) {
    for (final history in _dataHistory.values) {
      history.removeWhere((point) => point.timestamp.isBefore(cutoffTime));
    }
  }

  /// Get current statistics for debugging
  Map<String, dynamic> getDebugStats() {
    return {
      'isInitialized': _isInitialized,
      'isStreaming': _isStreaming,
      'totalDataPoints': _dataHistory.values.fold<int>(
        0,
        (sum, list) => sum + list.length,
      ),
      'dataByType': _dataHistory.map(
        (type, points) => MapEntry(type.name, points.length),
      ),
      'dataWindowSeconds': _config.dataWindow.inSeconds,
      'updateIntervalSeconds': _config.updateInterval.inSeconds,
      'maxHistorySize': _config.maxHistorySize,
      'platform': Platform.operatingSystem,
      'fetcherLastValues': _dataFetcher.lastValues,
    };
  }

  /// Reset all data for testing
  void resetData() {
    for (final history in _dataHistory.values) {
      history.clear();
    }
    _dataFetcher.resetDeltas();
    if (!_isTestEnvironment) {
      debugPrint('🔄 Live vitals data reset');
    }
  }

  /// Dispose of resources
  void dispose() {
    stopStreaming();
    _updateController?.close();
    _updateController = null;
    _dataHistory.clear();
    _isInitialized = false;

    // Clear singleton instance
    _instance = null;

    if (!_isTestEnvironment) {
      debugPrint('🗑️ LiveVitalsService disposed');
    }
  }
}
