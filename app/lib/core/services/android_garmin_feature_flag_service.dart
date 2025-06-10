/// Android Garmin Feature Flag Service
///
/// This service manages the feature flag for Android Garmin beta functionality,
/// including detecting Health Connect data origin and warning users when Garmin
/// support is not yet enabled on their device.
///
/// **Task**: T2.2.1.8 - Feature‑flag Android Garmin beta
/// **Functionality**:
/// - Detect Health Connect data origin (Garmin vs other sources)
/// - Warn if Garmin support not yet enabled on tester's device
/// - Manage beta feature rollout with configurable flags
/// - Provide graceful fallback when Garmin data unavailable
///
/// **Separation of Concerns**:
/// - `AndroidGarminFeatureFlag`: Core feature flag management
/// - `GarminDataSourceAnalyzer`: Data source detection and analysis
/// - `GarminWarningManager`: User warning management and cooldowns
/// - `AndroidGarminFeatureFlagService`: Orchestrator service
///
/// **Usage**:
/// ```dart
/// final service = AndroidGarminFeatureFlagService();
/// await service.initialize();
///
/// // Check if Garmin beta is enabled
/// final isEnabled = service.featureFlag.isEnabled;
///
/// // Check data source
/// final hasGarminData = await service.hasGarminDataSource();
/// ```
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'wearable_data_repository.dart';
import 'wearable_data_models.dart';

/// Configuration for Android Garmin beta feature
class AndroidGarminBetaConfig {
  // Feature flag settings
  static const bool enableGarminBetaDefault = false;
  static const bool enableDataSourceDetection = true;
  static const bool enableUserWarnings = true;

  // Data source detection settings
  static const Duration dataSourceCheckTimeout = Duration(seconds: 10);
  static const int minSamplesForDetection = 5;
  static const List<String> garminSourceIdentifiers = [
    'Garmin Connect',
    'com.garmin.android.apps.connectmobile',
    'Garmin',
  ];

  // Warning display settings
  static const Duration warningCooldown = Duration(hours: 24);
  static const int maxWarningsPerDay = 3;

  // Monitoring settings
  static const Duration periodicCheckInterval = Duration(hours: 1);
}

/// Status of Garmin data detection
enum GarminDataStatus {
  /// Garmin data is available and detected
  available,

  /// No Garmin data detected, but other health data is available
  notDetected,

  /// No health data available at all
  noData,

  /// Unable to determine due to permissions or other issues
  unknown,
}

/// Result of data source analysis
class DataSourceAnalysisResult {
  final GarminDataStatus status;
  final List<String> detectedSources;
  final bool hasGarminSource;
  final int totalSamples;
  final DateTime analysisTimestamp;
  final String? errorMessage;

  const DataSourceAnalysisResult({
    required this.status,
    required this.detectedSources,
    required this.hasGarminSource,
    required this.totalSamples,
    required this.analysisTimestamp,
    this.errorMessage,
  });

  bool get isSuccessful => errorMessage == null;

  Map<String, dynamic> toMap() {
    return {
      'status': status.name,
      'detectedSources': detectedSources,
      'hasGarminSource': hasGarminSource,
      'totalSamples': totalSamples,
      'analysisTimestamp': analysisTimestamp.toIso8601String(),
      'errorMessage': errorMessage,
    };
  }
}

/// Core feature flag management - Single Responsibility
class AndroidGarminFeatureFlag {
  static const String _featureFlagKey = 'android_garmin_beta_enabled';

  final SharedPreferences _prefs;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  AndroidGarminFeatureFlag(this._prefs);

  /// Stream of feature flag changes
  Stream<bool> get stream => _controller.stream;

  /// Whether Android Garmin beta is enabled
  bool get isEnabled {
    if (!Platform.isAndroid) return false;
    return _prefs.getBool(_featureFlagKey) ??
        AndroidGarminBetaConfig.enableGarminBetaDefault;
  }

  /// Whether this platform supports Garmin beta functionality
  bool get isPlatformSupported => Platform.isAndroid;

  /// Enable or disable Garmin beta feature
  Future<void> setEnabled(bool enabled) async {
    if (!Platform.isAndroid) return;

    await _prefs.setBool(_featureFlagKey, enabled);
    _controller.add(enabled);

    debugPrint('🔧 Android Garmin beta ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Dispose resources
  void dispose() {
    _controller.close();
  }
}

/// Data source analysis - Single Responsibility
class GarminDataSourceAnalyzer {
  static const String _lastAnalysisKey = 'android_garmin_last_analysis';

  final WearableDataRepository _repository;
  final SharedPreferences _prefs;
  final StreamController<DataSourceAnalysisResult> _controller =
      StreamController<DataSourceAnalysisResult>.broadcast();

  DataSourceAnalysisResult? _lastAnalysis;

  GarminDataSourceAnalyzer(this._repository, this._prefs);

  /// Stream of analysis updates
  Stream<DataSourceAnalysisResult> get stream => _controller.stream;

  /// Last analysis result
  DataSourceAnalysisResult? get lastAnalysis => _lastAnalysis;

  /// Initialize and load previous analysis
  Future<void> initialize() async {
    await _loadLastAnalysis();
  }

  /// Analyze data sources to detect Garmin presence
  Future<DataSourceAnalysisResult> analyzeDataSources() async {
    if (!Platform.isAndroid) {
      return _createErrorResult('Unsupported platform');
    }

    try {
      // Check repository availability
      if (!_repository.isHealthConnectAvailable) {
        return _createErrorResult('Health Connect not available');
      }

      // Check permissions
      final permissionStatus = await _repository.checkPermissions();
      if (permissionStatus != HealthPermissionStatus.authorized) {
        return _createErrorResult('Health permissions not granted');
      }

      // Fetch recent health data to analyze sources
      final healthResult = await _repository.getHealthData(
        dataTypes: [
          WearableDataType.steps,
          WearableDataType.heartRate,
          WearableDataType.sleepDuration,
        ],
        startTime: DateTime.now().subtract(const Duration(days: 7)),
        endTime: DateTime.now(),
      );

      if (!healthResult.isSuccess || healthResult.samples.isEmpty) {
        final result = DataSourceAnalysisResult(
          status: GarminDataStatus.noData,
          detectedSources: [],
          hasGarminSource: false,
          totalSamples: 0,
          analysisTimestamp: DateTime.now(),
          errorMessage: healthResult.error,
        );
        await _saveAnalysis(result);
        return result;
      }

      // Analyze data sources
      final allSources = <String>{};
      bool hasGarmin = false;

      for (final sample in healthResult.samples) {
        allSources.add(sample.source);

        // Check if this source matches Garmin identifiers
        if (_isGarminSource(sample.source)) {
          hasGarmin = true;
        }
      }

      final status =
          hasGarmin
              ? GarminDataStatus.available
              : (allSources.isNotEmpty
                  ? GarminDataStatus.notDetected
                  : GarminDataStatus.noData);

      final result = DataSourceAnalysisResult(
        status: status,
        detectedSources: allSources.toList(),
        hasGarminSource: hasGarmin,
        totalSamples: healthResult.samples.length,
        analysisTimestamp: DateTime.now(),
      );

      await _saveAnalysis(result);

      debugPrint(
        '📊 Data source analysis: ${allSources.length} sources, '
        'Garmin: $hasGarmin, ${healthResult.samples.length} samples',
      );

      return result;
    } catch (e) {
      debugPrint('❌ Error analyzing data sources: $e');
      final result = _createErrorResult(e.toString());
      await _saveAnalysis(result);
      return result;
    }
  }

  /// Check if a source name indicates Garmin origin
  bool _isGarminSource(String sourceName) {
    final lowerSource = sourceName.toLowerCase();
    return AndroidGarminBetaConfig.garminSourceIdentifiers.any(
      (identifier) => lowerSource.contains(identifier.toLowerCase()),
    );
  }

  /// Create error result
  DataSourceAnalysisResult _createErrorResult(String error) {
    final result = DataSourceAnalysisResult(
      status: GarminDataStatus.unknown,
      detectedSources: [],
      hasGarminSource: false,
      totalSamples: 0,
      analysisTimestamp: DateTime.now(),
      errorMessage: error,
    );
    _lastAnalysis = result;
    _controller.add(result);
    return result;
  }

  /// Save analysis result
  Future<void> _saveAnalysis(DataSourceAnalysisResult result) async {
    _lastAnalysis = result;
    _controller.add(result);

    try {
      // Store timestamp for cache invalidation
      await _prefs.setInt(
        _lastAnalysisKey,
        result.analysisTimestamp.millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('Error saving analysis: $e');
    }
  }

  /// Load last analysis from storage
  Future<void> _loadLastAnalysis() async {
    try {
      final lastAnalysisTime = _prefs.getInt(_lastAnalysisKey);
      if (lastAnalysisTime != null) {
        debugPrint('Previous analysis found, will refresh on next check');
      }
    } catch (e) {
      debugPrint('Error loading last analysis: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _controller.close();
  }
}

/// Warning management - Single Responsibility
class GarminWarningManager {
  static const String _lastWarningKey = 'android_garmin_last_warning';
  static const String _warningCountKey = 'android_garmin_warning_count';
  static const String _userOptOutKey = 'android_garmin_user_opt_out';

  final SharedPreferences _prefs;

  GarminWarningManager(this._prefs);

  /// Check if user should see Garmin setup warning
  Future<bool> shouldShowWarning(DataSourceAnalysisResult? analysis) async {
    // Check if user has opted out of warnings
    if (_prefs.getBool(_userOptOutKey) == true) {
      return false;
    }

    // Check warning cooldown
    if (!_isWarningCooldownExpired()) {
      return false;
    }

    // Check daily warning limit
    if (_getDailyWarningCount() >= AndroidGarminBetaConfig.maxWarningsPerDay) {
      return false;
    }

    // Check if Garmin data is missing but other data exists
    return analysis?.status == GarminDataStatus.notDetected &&
        (analysis?.detectedSources.isNotEmpty ?? false);
  }

  /// Record that warning was shown
  Future<void> recordWarningShown() async {
    final now = DateTime.now();
    await _prefs.setInt(_lastWarningKey, now.millisecondsSinceEpoch);

    final newCount = _getDailyWarningCount() + 1;
    await _prefs.setInt(_warningCountKey, newCount);

    debugPrint('⚠️ Garmin warning shown (count: $newCount)');
  }

  /// Allow user to opt out of warnings
  Future<void> setUserOptOut(bool optOut) async {
    await _prefs.setBool(_userOptOutKey, optOut);
    debugPrint('🔕 User Garmin warnings opt-out: $optOut');
  }

  /// Get debug info for warnings
  Map<String, dynamic> getDebugInfo() {
    return {
      'dailyWarningCount': _getDailyWarningCount(),
      'userOptOut': _prefs.getBool(_userOptOutKey) ?? false,
      'cooldownExpired': _isWarningCooldownExpired(),
      'lastWarningTime': _getLastWarningTime()?.toIso8601String(),
    };
  }

  /// Check if warning cooldown has expired
  bool _isWarningCooldownExpired() {
    final lastWarning = _prefs.getInt(_lastWarningKey);
    if (lastWarning == null) return true;

    final lastWarningTime = DateTime.fromMillisecondsSinceEpoch(lastWarning);
    return DateTime.now().difference(lastWarningTime) >=
        AndroidGarminBetaConfig.warningCooldown;
  }

  /// Get current daily warning count
  int _getDailyWarningCount() {
    final count = _prefs.getInt(_warningCountKey) ?? 0;

    // Reset count if it's a new day
    final lastWarning = _prefs.getInt(_lastWarningKey);
    if (lastWarning != null) {
      final lastWarningTime = DateTime.fromMillisecondsSinceEpoch(lastWarning);
      final now = DateTime.now();

      if (now.day != lastWarningTime.day ||
          now.month != lastWarningTime.month ||
          now.year != lastWarningTime.year) {
        // New day, reset count
        _prefs.setInt(_warningCountKey, 0);
        return 0;
      }
    }

    return count;
  }

  /// Get last warning time
  DateTime? _getLastWarningTime() {
    final lastWarning = _prefs.getInt(_lastWarningKey);
    return lastWarning != null
        ? DateTime.fromMillisecondsSinceEpoch(lastWarning)
        : null;
  }
}

/// Main orchestrator service - Coordinates the modular components
class AndroidGarminFeatureFlagService {
  static final AndroidGarminFeatureFlagService _instance =
      AndroidGarminFeatureFlagService._internal();
  factory AndroidGarminFeatureFlagService() => _instance;
  AndroidGarminFeatureFlagService._internal();

  // Modular components
  AndroidGarminFeatureFlag? _featureFlag;
  GarminDataSourceAnalyzer? _analyzer;
  GarminWarningManager? _warningManager;

  // Dependencies
  final WearableDataRepository _repository = WearableDataRepository();
  Timer? _periodicCheckTimer;
  bool _isInitialized = false;

  /// Whether the service is initialized
  bool get isInitialized => _isInitialized;

  /// Feature flag component
  AndroidGarminFeatureFlag get featureFlag {
    if (_featureFlag == null) throw StateError('Service not initialized');
    return _featureFlag!;
  }

  /// Data source analyzer component
  GarminDataSourceAnalyzer get analyzer {
    if (_analyzer == null) throw StateError('Service not initialized');
    return _analyzer!;
  }

  /// Warning manager component
  GarminWarningManager get warningManager {
    if (_warningManager == null) throw StateError('Service not initialized');
    return _warningManager!;
  }

  /// Initialize the service and all components
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Initialize dependencies
      if (!_repository.isInitialized) {
        await _repository.initialize();
      }

      final prefs = await SharedPreferences.getInstance();

      // Initialize modular components
      _featureFlag = AndroidGarminFeatureFlag(prefs);
      _analyzer = GarminDataSourceAnalyzer(_repository, prefs);
      _warningManager = GarminWarningManager(prefs);

      // Initialize analyzer
      await _analyzer!.initialize();

      // Start periodic monitoring if enabled
      if (!kIsWeb && AndroidGarminBetaConfig.enableDataSourceDetection) {
        _startPeriodicMonitoring();
      }

      _isInitialized = true;
      debugPrint('✅ AndroidGarminFeatureFlagService initialized');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to initialize AndroidGarminFeatureFlagService: $e');
      return false;
    }
  }

  /// Convenience method: Check if Garmin data source is available
  Future<bool> hasGarminDataSource() async {
    final analysis = await analyzer.analyzeDataSources();
    return analysis.hasGarminSource;
  }

  /// Convenience method: Check if user should see warning
  Future<bool> shouldShowGarminWarning() async {
    if (!featureFlag.isEnabled) return false;

    final analysis =
        analyzer.lastAnalysis ?? await analyzer.analyzeDataSources();
    return await warningManager.shouldShowWarning(analysis);
  }

  /// Get user-friendly status message
  String getStatusMessage() {
    if (!featureFlag.isPlatformSupported) {
      return 'Garmin integration only available on Android';
    }

    if (!featureFlag.isEnabled) {
      return 'Garmin beta feature not enabled';
    }

    if (!_repository.isHealthConnectAvailable) {
      return 'Health Connect not available on this device';
    }

    final analysis = analyzer.lastAnalysis;
    if (analysis == null) {
      return 'Data source analysis pending';
    }

    switch (analysis.status) {
      case GarminDataStatus.available:
        return 'Garmin data detected and available';
      case GarminDataStatus.notDetected:
        return 'No Garmin data detected. Connect Garmin in Health Connect.';
      case GarminDataStatus.noData:
        return 'No health data available. Check permissions and connected apps.';
      case GarminDataStatus.unknown:
        return analysis.errorMessage ?? 'Unable to determine Garmin status';
    }
  }

  /// Get comprehensive debug information
  Map<String, dynamic> getDebugInfo() {
    return {
      'isInitialized': _isInitialized,
      'featureFlag':
          _featureFlag != null
              ? {
                'isPlatformSupported': _featureFlag!.isPlatformSupported,
                'isEnabled': _featureFlag!.isEnabled,
              }
              : null,
      'analyzer':
          _analyzer != null
              ? {'lastAnalysis': _analyzer!.lastAnalysis?.toMap()}
              : null,
      'warningManager': _warningManager?.getDebugInfo(),
      'repository': {
        'isInitialized': _repository.isInitialized,
        'healthConnectAvailable': _repository.isHealthConnectAvailable,
      },
    };
  }

  /// Start periodic data source monitoring
  void _startPeriodicMonitoring() {
    _periodicCheckTimer?.cancel();

    _periodicCheckTimer = Timer.periodic(
      AndroidGarminBetaConfig.periodicCheckInterval,
      (_) async {
        try {
          if (_analyzer != null) {
            await _analyzer!.analyzeDataSources();
          }
        } catch (e) {
          debugPrint('Error in periodic data source check: $e');
        }
      },
    );
  }

  /// Dispose all resources
  void dispose() {
    _periodicCheckTimer?.cancel();
    _featureFlag?.dispose();
    _analyzer?.dispose();

    _featureFlag = null;
    _analyzer = null;
    _warningManager = null;
    _isInitialized = false;
  }
}

/// Extension for convenient access to common operations
extension AndroidGarminFeatureFlagExtension on AndroidGarminFeatureFlagService {
  /// Quick check if Garmin functionality should be shown to user
  bool get shouldShowGarminFeatures =>
      featureFlag.isPlatformSupported && featureFlag.isEnabled;

  /// Quick check if we should recommend Garmin setup
  Future<bool> get shouldRecommendGarminSetup async {
    if (!shouldShowGarminFeatures) return false;

    final analysis = await analyzer.analyzeDataSources();
    return analysis.status == GarminDataStatus.notDetected &&
        analysis.detectedSources.isNotEmpty;
  }
}
