/// VitalsNotifier Service for T2.2.2.6
///
/// Client-side subscriber that processes wearable live data for UI widgets
/// and JITAI engine consumption. Bridges streaming infrastructure with consumers.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'wearable_live_service.dart';
import 'wearable_live_models.dart';
import 'wearable_data_models.dart';
import 'wearable_data_repository.dart';

/// Processed vitals data for UI and JITAI consumption
class VitalsData {
  final double? heartRate;
  final int? steps;
  final double? heartRateVariability;
  final double? sleepHours;
  final DateTime timestamp;
  final VitalsQuality quality;
  final Map<String, dynamic> metadata;

  const VitalsData({
    this.heartRate,
    this.steps,
    this.heartRateVariability,
    this.sleepHours,
    required this.timestamp,
    this.quality = VitalsQuality.unknown,
    this.metadata = const {},
  });

  bool get hasHeartRate => heartRate != null;
  bool get hasSteps => steps != null;
  bool get hasSleep => sleepHours != null;
  bool get hasValidData => hasHeartRate || hasSteps || hasSleep;

  VitalsData copyWith({
    double? heartRate,
    int? steps,
    double? heartRateVariability,
    double? sleepHours,
    DateTime? timestamp,
    VitalsQuality? quality,
    Map<String, dynamic>? metadata,
  }) {
    return VitalsData(
      heartRate: heartRate ?? this.heartRate,
      steps: steps ?? this.steps,
      heartRateVariability: heartRateVariability ?? this.heartRateVariability,
      sleepHours: sleepHours ?? this.sleepHours,
      timestamp: timestamp ?? this.timestamp,
      quality: quality ?? this.quality,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Data quality indicators for JITAI decision making
enum VitalsQuality { excellent, good, fair, poor, unknown }

/// Connection status for UI feedback
enum VitalsConnectionStatus {
  connecting,
  connected,
  disconnected,
  error,
  polling,
}

/// T2.2.2.9: Add subscription mode for adaptive polling
enum SubscriptionMode { realtime, polling }

/// VitalsNotifier service configuration
class VitalsNotifierConfig {
  final Duration dataRetentionWindow;
  final int maxHistorySize;
  final Duration qualityEvaluationWindow;
  // T2.2.2.9: Add polling interval for fallback mode
  final Duration pollingInterval;

  const VitalsNotifierConfig({
    this.dataRetentionWindow = const Duration(hours: 24),
    this.maxHistorySize = 100,
    this.qualityEvaluationWindow = const Duration(seconds: 30),
    this.pollingInterval = const Duration(
      seconds: 30,
    ), // Fallback polling interval
  });

  static const VitalsNotifierConfig defaultConfig = VitalsNotifierConfig();
}

/// Client-side subscriber for wearable vitals data
class VitalsNotifierService {
  // T2.2.2.9: Preference key for adaptive polling
  static const String adaptivePollingPrefKey = 'adaptivePollingEnabled';

  final WearableLiveService _liveService;
  // T2.2.2.9: Add repository for polling fallback
  final WearableDataRepository _repository;
  final VitalsNotifierConfig _config;

  // Controllers are created immediately so Riverpod gets a stable stream
  // reference even before `initialize()` is called. Otherwise widgets that
  // read the stream too early would receive an empty stream and stay in the
  // loading state forever.
  final StreamController<VitalsData> _vitalsController =
      StreamController<VitalsData>.broadcast();

  final StreamController<VitalsConnectionStatus> _statusController =
      StreamController<VitalsConnectionStatus>.broadcast();

  StreamSubscription<List<WearableLiveMessage>>? _liveDataSubscription;
  // T2.2.2.9: Add timer for polling fallback
  Timer? _pollingTimer;

  final List<VitalsData> _dataHistory = [];
  VitalsData? _currentVitals;
  VitalsConnectionStatus _connectionStatus =
      VitalsConnectionStatus.disconnected;
  String? _currentUserId;

  bool _isInitialized = false;
  bool _isActive = false;
  // T2.2.2.9: Track current subscription mode
  SubscriptionMode _mode = SubscriptionMode.realtime;
  // NEW: guard so we only schedule one immediate retry for missing steps
  bool _stepRetryScheduled = false;

  // NEW: running step total for current day so we don't rely on _dataHistory
  int _stepsToday = 0;
  DateTime _stepsDayAnchor = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  VitalsNotifierService(
    this._liveService,
    this._repository, {
    VitalsNotifierConfig config = VitalsNotifierConfig.defaultConfig,
  }) : _config = config;

  /// Stream of processed vitals data
  Stream<VitalsData> get vitalsStream => _vitalsController.stream;

  /// Stream of connection status updates
  Stream<VitalsConnectionStatus> get statusStream => _statusController.stream;

  /// Current vitals data (latest)
  VitalsData? get currentVitals => _currentVitals;

  /// Current connection status
  VitalsConnectionStatus get connectionStatus => _connectionStatus;

  /// Historical vitals data for trend analysis
  List<VitalsData> get dataHistory => List.unmodifiable(_dataHistory);

  /// Whether service is actively processing data
  bool get isActive => _isActive;

  /// Initialize the vitals notifier service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // T2.2.2.9: Initialize repository for polling mode
      await _repository.initialize();

      _isInitialized = true;
      _updateConnectionStatus(VitalsConnectionStatus.disconnected);

      debugPrint('✅ VitalsNotifierService initialized');
      return true;
    } catch (e) {
      debugPrint('❌ VitalsNotifierService initialization failed: $e');
      return false;
    }
  }

  /// Start subscribing to vitals data for a user
  Future<bool> startSubscription(String userId) async {
    if (!_isInitialized) {
      throw StateError('VitalsNotifierService not initialized');
    }

    if (_isActive && _currentUserId == userId) {
      debugPrint('ℹ️ Already subscribed to vitals for user: $userId');
      return true;
    }

    try {
      _updateConnectionStatus(VitalsConnectionStatus.connecting);

      // T2.2.2.9: Determine subscription mode from user preferences
      final prefs = await SharedPreferences.getInstance();
      final usePolling = prefs.getBool(adaptivePollingPrefKey) ?? false;
      _mode = usePolling ? SubscriptionMode.polling : SubscriptionMode.realtime;

      if (_mode == SubscriptionMode.polling) {
        return _startPolling(userId);
      } else {
        return _startRealtimeStreaming(userId);
      }
    } catch (e) {
      _updateConnectionStatus(VitalsConnectionStatus.error);
      debugPrint('❌ Failed to start vitals subscription: $e');
      return false;
    }
  }

  // T2.2.2.9: Extracted original logic for real-time streaming
  Future<bool> _startRealtimeStreaming(String userId) async {
    // Start live service streaming
    final success = await _liveService.startStreaming(userId);
    if (!success) {
      _updateConnectionStatus(VitalsConnectionStatus.error);
      return false;
    }

    // Subscribe to live data stream
    _liveDataSubscription = _liveService.messageStream.listen(
      _handleLiveData,
      onError: _handleStreamError,
      onDone: _handleStreamDone,
    );

    _currentUserId = userId;
    _isActive = true;
    _updateConnectionStatus(VitalsConnectionStatus.connected);

    // Fetch an initial local snapshot so the UI has data even if no live
    // packets arrive yet (e.g., server ingestion delay).
    await _pollForVitals();

    debugPrint(
      '🚀 VitalsNotifier REALTIME subscription started for user: $userId',
    );
    return true;
  }

  // T2.2.2.9: New method for polling fallback
  Future<bool> _startPolling(String userId) async {
    _currentUserId = userId;
    _isActive = true;

    // Fetch initial data immediately
    await _pollForVitals();

    // Start periodic polling
    _pollingTimer = Timer.periodic(
      _config.pollingInterval,
      (_) => _pollForVitals(),
    );

    _updateConnectionStatus(VitalsConnectionStatus.polling);
    debugPrint(
      '🚀 VitalsNotifier POLLING subscription started for user: $userId',
    );
    return true;
  }

  /// Stop vitals subscription
  Future<void> stopSubscription() async {
    if (!_isActive) return;

    try {
      // T2.2.2.9: Stop polling timer if active
      _pollingTimer?.cancel();
      _pollingTimer = null;

      await _liveDataSubscription?.cancel();
      _liveDataSubscription = null;

      // Only stop live service if it was used
      if (_mode == SubscriptionMode.realtime) {
        await _liveService.stopStreaming();
      }

      _currentUserId = null;
      _isActive = false;
      _currentVitals = null;
      _dataHistory.clear();

      _updateConnectionStatus(VitalsConnectionStatus.disconnected);
      debugPrint(
        '⏹️ VitalsNotifier subscription stopped (Mode: ${_mode.name})',
      );
    } catch (e) {
      debugPrint('❌ Error stopping vitals subscription: $e');
    }
  }

  /// Handle incoming live data messages
  void _handleLiveData(List<WearableLiveMessage> messages) {
    if (messages.isEmpty) return;

    try {
      for (final message in messages) {
        final vitalsData = _processMessage(message);
        if (vitalsData != null) {
          _addVitalsData(vitalsData);
        }
      }
    } catch (e) {
      debugPrint('❌ Error processing live data: $e');
    }
  }

  /// Process live message into VitalsData
  VitalsData? _processMessage(WearableLiveMessage message) {
    final timestamp = message.timestamp;
    double? heartRate;
    int? steps;
    double? hrv;
    double? sleepHours;

    // Extract data based on message type
    switch (message.type) {
      case WearableDataType.heartRate:
        heartRate = message.value;
        break;
      case WearableDataType.steps:
        steps = _extractInt(message.value);
        debugPrint('🔢 extracted steps=$steps from ${message.value}');
        break;
      case WearableDataType.heartRateVariability:
        hrv = message.value;
        break;
      case WearableDataType.sleepDuration:
        // Assume incoming value is total sleep duration in minutes
        try {
          final minutes = (message.value as num).toDouble();
          sleepHours = minutes / 60.0;
        } catch (_) {
          // Fallback: if already hours
          sleepHours = (message.value as num?)?.toDouble();
        }
        break;
      default:
        return null; // Skip unsupported data types
    }

    // Calculate data quality
    final quality = _calculateDataQuality(timestamp);

    return VitalsData(
      heartRate: heartRate,
      steps: steps,
      heartRateVariability: hrv,
      sleepHours: sleepHours,
      timestamp: timestamp,
      quality: quality,
      metadata: {'source': message.source},
    );
  }

  /// Calculate data quality for JITAI decision making
  VitalsQuality _calculateDataQuality(DateTime timestamp) {
    // Quality based on data freshness
    final ageSeconds = DateTime.now().difference(timestamp).inSeconds;

    if (_mode == SubscriptionMode.polling) {
      if (ageSeconds > _config.pollingInterval.inSeconds * 2) {
        return VitalsQuality.poor;
      }
      if (ageSeconds > _config.pollingInterval.inSeconds) {
        return VitalsQuality.fair;
      }
      return VitalsQuality.good;
    }

    // Original logic for realtime
    if (ageSeconds > 60) return VitalsQuality.poor;
    if (ageSeconds > 30) return VitalsQuality.fair;
    // Battery status not available in current message format
    if (ageSeconds <= 5) return VitalsQuality.excellent;

    return VitalsQuality.good;
  }

  /// Add vitals data to history and notify consumers
  void _addVitalsData(VitalsData vitalsData) {
    // Always persist to history first
    _dataHistory.add(vitalsData);
    _cleanupHistory();

    // Skip forwarding raw step-only samples – we will emit a daily aggregate separately.
    final isRawStepOnly =
        vitalsData.hasSteps &&
        !vitalsData.hasHeartRate &&
        !vitalsData.hasSleep &&
        (vitalsData.metadata['aggregated'] != true);

    if (isRawStepOnly) return;

    // Merge with previous vitals so metrics missing in latest record are kept.
    VitalsData merged = vitalsData;
    if (_currentVitals != null) {
      merged = _currentVitals!.copyWith(
        heartRate: vitalsData.heartRate ?? _currentVitals!.heartRate,
        steps: vitalsData.steps ?? _currentVitals!.steps,
        heartRateVariability:
            vitalsData.heartRateVariability ??
            _currentVitals!.heartRateVariability,
        sleepHours: vitalsData.sleepHours ?? _currentVitals!.sleepHours,
        timestamp: vitalsData.timestamp,
        quality: vitalsData.quality,
        metadata: vitalsData.metadata,
      );
    }

    // Update current vitals for downstream consumers
    _currentVitals = merged;

    // Emit trace for debugging stream propagation to UI
    debugPrint(
      '🚚 emit → steps=${merged.steps} hr=${merged.heartRate} '
      'sleep=${merged.sleepHours} meta=${merged.metadata}',
    );

    // Notify UI subscribers
    _vitalsController.add(merged);
  }

  /// Clean up old data outside retention window
  void _cleanupHistory() {
    final cutoffTime = DateTime.now().subtract(_config.dataRetentionWindow);

    _dataHistory.removeWhere((data) => data.timestamp.isBefore(cutoffTime));

    // Also enforce max size limit
    if (_dataHistory.length > _config.maxHistorySize) {
      final excess = _dataHistory.length - _config.maxHistorySize;
      _dataHistory.removeRange(0, excess);
    }
  }

  /// Handle stream errors
  void _handleStreamError(dynamic error) {
    debugPrint('❌ VitalsNotifier stream error: $error');
    _updateConnectionStatus(VitalsConnectionStatus.error);
  }

  /// Handle stream completion
  void _handleStreamDone() {
    debugPrint('ℹ️ VitalsNotifier stream completed');
    if (_mode == SubscriptionMode.realtime) {
      _updateConnectionStatus(VitalsConnectionStatus.disconnected);
    }
  }

  /// Update connection status and notify subscribers
  void _updateConnectionStatus(VitalsConnectionStatus status) {
    if (_connectionStatus != status) {
      _connectionStatus = status;
      _statusController.add(status);
    }
  }

  /// Get recent vitals for JITAI analysis
  List<VitalsData> getRecentVitals({Duration? window}) {
    final analysisWindow = window ?? _config.qualityEvaluationWindow;
    final cutoffTime = DateTime.now().subtract(analysisWindow);

    return _dataHistory
        .where((data) => data.timestamp.isAfter(cutoffTime))
        .toList();
  }

  /// Get average heart rate for JITAI context
  double? getAverageHeartRate({Duration? window}) {
    final recentData = getRecentVitals(window: window);
    final heartRates =
        recentData
            .where((data) => data.hasHeartRate)
            .map((data) => data.heartRate!)
            .toList();

    if (heartRates.isEmpty) return null;

    return heartRates.reduce((a, b) => a + b) / heartRates.length;
  }

  /// Check if current vitals indicate stress for JITAI triggers
  bool isStressIndicator() {
    final recent = getRecentVitals();
    if (recent.length < 2) return false;

    final recentHeartRates =
        recent
            .where((data) => data.hasHeartRate)
            .map((data) => data.heartRate!)
            .toList();

    if (recentHeartRates.length < 2) return false;

    // Simple stress detection: elevated and increasing heart rate
    final latest = recentHeartRates.last;
    final average =
        recentHeartRates.reduce((a, b) => a + b) / recentHeartRates.length;

    return latest > average * 1.15; // 15% above recent average
  }

  // T2.2.2.9: New method to poll for vitals data using repository
  Future<void> _pollForVitals() async {
    if (!_isActive || _currentUserId == null) return;

    final now = DateTime.now();
    // For first snapshot (no current vitals) fetch a broader window so we get
    // at least one sample even if data hasn't changed in the last 30 s.
    final lookback =
        _currentVitals == null
            ? const Duration(hours: 12)
            : _config.pollingInterval;
    final startTime = now.subtract(lookback);

    try {
      final result = await _repository.getHealthData(
        startTime: startTime,
        endTime: now,
      );

      if (result.isSuccess) {
        _processHealthSamples(result.samples);
        debugPrint('🔄 Polled ${result.samples.length} vitals samples.');

        // --- iOS cumulative-type quirk workaround ----------------------
        // HealthKit may return an empty array for cumulative metrics
        // (e.g. Steps) on the very first query after authorization. If we
        // received *no* raw step samples, schedule a one-off quick retry so
        // the Steps tile doesn't stay blank for 30 s.
        final bool hasStepsRaw = result.samples.any(
          (s) => s.type == WearableDataType.steps,
        );
        if (!hasStepsRaw && !_stepRetryScheduled) {
          _stepRetryScheduled = true;
          debugPrint('⏳ No step samples – scheduling quick retry');
          Future.delayed(const Duration(seconds: 3), () {
            _stepRetryScheduled = false;
            if (_isActive) _pollForVitals();
          });
        }
        // ----------------------------------------------------------------
      } else {
        debugPrint('❌ Polling for vitals failed: ${result.error}');
        _handleStreamError('Polling failed: ${result.error}');
      }
    } catch (e) {
      debugPrint('❌ Polling for vitals threw an exception: $e');
      _handleStreamError(e);
    }
  }

  // T2.2.2.9: New method to process polled health samples
  void _processHealthSamples(List<HealthSample> samples) {
    // Debug: surface raw samples to console for easier investigation on iOS.
    if (kDebugMode) {
      debugPrint('🩺 Processing ${samples.length} polled samples');
      for (final s in samples.take(10)) {
        debugPrint(
          '   ↳ ${s.type.name} | value=${s.value} | unit=${s.unit} | ts=${s.timestamp}',
        );
      }
    }

    if (samples.isEmpty) return;

    for (final sample in samples) {
      final vitalsData = _processHealthSample(sample);
      if (vitalsData != null) {
        _addVitalsData(vitalsData);
      }
    }

    // After processing raw samples, emit an aggregated daily steps event so
    // the UI shows total steps instead of the last delta.
    _emitAggregatedSteps();
  }

  // T2.2.2.9: New method to process a single HealthSample into VitalsData
  VitalsData? _processHealthSample(HealthSample sample) {
    double? heartRate;
    int? steps;
    double? hrv;
    double? sleepHours;

    switch (sample.type) {
      case WearableDataType.heartRate:
        heartRate = _extractDouble(sample.value);
        break;
      case WearableDataType.steps:
        steps = _extractInt(sample.value);
        debugPrint('🔢 extracted steps=$steps from ${sample.value}');
        // --- update per-day accumulator ---------------------------------
        if (steps != null) {
          final sampleDay = DateTime(
            sample.timestamp.year,
            sample.timestamp.month,
            sample.timestamp.day,
          );
          if (sampleDay.isAfter(_stepsDayAnchor)) {
            // crossed midnight – reset counter
            _stepsDayAnchor = sampleDay;
            _stepsToday = 0;
          }
          if (!sample.timestamp.isBefore(_stepsDayAnchor)) {
            _stepsToday += steps;
          }
        }
        // ----------------------------------------------------------------
        break;
      case WearableDataType.heartRateVariability:
        hrv = _extractDouble(sample.value);
        break;
      case WearableDataType.sleepDuration:
      case WearableDataType.sleepInBed:
      case WearableDataType.sleepAwake:
      case WearableDataType.sleepDeep:
      case WearableDataType.sleepLight:
      case WearableDataType.sleepRem:
        // Assume incoming value is total sleep duration in minutes
        try {
          final minutes = _extractDouble(sample.value);
          if (minutes != null) sleepHours = minutes / 60.0;
        } catch (_) {
          sleepHours = _extractDouble(sample.value);
        }
        break;
      default:
        return null;
    }

    if (heartRate == null &&
        steps == null &&
        hrv == null &&
        sleepHours == null) {
      return null;
    }

    final quality = _calculateDataQuality(sample.timestamp);

    return VitalsData(
      heartRate: heartRate,
      steps: steps,
      heartRateVariability: hrv,
      sleepHours: sleepHours,
      timestamp: sample.timestamp,
      quality: quality,
      metadata: {'source': sample.source, 'polled': true},
    );
  }

  /// Dispose resources
  void dispose() {
    stopSubscription();
    _vitalsController.close();
    _statusController.close();
    _dataHistory.clear();
    _isInitialized = false;

    debugPrint('🗑️ VitalsNotifierService disposed');
  }

  // --- HealthKit numeric wrapper helpers ---------------------------------
  // Some iOS HealthKit values come back as `NumericHealthValue` (or similar)
  // wrapper objects introduced in health >=13.x.  These contain a `numericValue`
  // property that holds the actual double.  These helpers safely extracted that
  // value while still supporting plain `num` values.

  double? _extractDouble(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();

    try {
      final dynamic candidate = (raw as dynamic).numericValue;
      if (candidate is num) return candidate.toDouble();
    } catch (_) {
      // ignore – not a wrapper type
    }

    // Fallback: attempt to extract number from toString, e.g.
    // "NumericHealthValue - numericValue: 215.0"
    final str = raw.toString();
    final match = RegExp(r'([0-9]+(?:\.[0-9]+)?)').firstMatch(str);
    if (match != null) {
      return double.tryParse(match.group(1)!);
    }
    return null;
  }

  int? _extractInt(dynamic raw) {
    final v = _extractDouble(raw);
    return v?.round();
  }

  // Calculate total steps since midnight and emit as a synthetic VitalsData.
  void _emitAggregatedSteps() {
    final totalSteps = _stepsToday > 0 ? _stepsToday : _calculateStepsToday();
    if (totalSteps == null || totalSteps == 0) return; // No steps yet today

    // Find most recent sleep hours within last 36h
    double? latestSleep;
    DateTime latestTs = DateTime.fromMillisecondsSinceEpoch(0);
    for (final d in _dataHistory) {
      if (d.hasSleep && d.timestamp.isAfter(latestTs)) {
        latestSleep = d.sleepHours;
        latestTs = d.timestamp;
      }
    }

    final now = DateTime.now();

    final aggregated = VitalsData(
      steps: totalSteps,
      sleepHours: latestSleep,
      timestamp: now,
      quality: VitalsQuality.good,
      metadata: const {'aggregated': true},
    );

    _addVitalsData(aggregated);
  }

  int? _calculateStepsToday() {
    final midnight = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    int sum = 0;
    bool hasData = false;

    // Use a set to skip duplicate raw samples that may be fetched in multiple
    // polls. Key on timestamp + value. Also ignore previously aggregated
    // records.
    final Set<String> seen = {};

    for (final d in _dataHistory) {
      if (!d.hasSteps) continue;
      if (d.timestamp.isBefore(midnight)) continue;
      if (d.metadata['aggregated'] == true) continue;

      final key = '${d.timestamp.millisecondsSinceEpoch}_${d.steps}';
      if (seen.add(key)) {
        sum += d.steps!;
        hasData = true;
      }
    }

    return hasData ? sum : null;
  }
}
