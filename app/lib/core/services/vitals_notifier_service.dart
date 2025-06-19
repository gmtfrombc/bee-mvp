/// VitalsNotifier Service for T2.2.2.6
///
/// Client-side subscriber that processes wearable live data for UI widgets
/// and JITAI engine consumption. Bridges streaming infrastructure with consumers.
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/core/utils/logger.dart';

import 'wearable_live_service.dart';
import 'wearable_live_models.dart';
import 'wearable_data_models.dart';
import 'wearable_data_repository.dart';
import 'health_permission_manager.dart';

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
  // Retry/back-off state
  int _retryAttempts = 0;
  static const int _maxRetryAttempts = 5; // cap 32 s back-off

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
  // Throttle "no steps" debug logs to avoid console spam
  DateTime? _lastNoStepLogTime;
  DateTime? _lastPermissionLogTime;
  DateTime? _lastZeroPollLogTime;
  int _consecutiveEmptyPolls = 0;
  bool _midnightBootstrapDone = false;
  bool _hrBootstrapDone = false;
  bool _sleepBootstrapDone = false;

  // NEW: running step total for current day so we don't rely on _dataHistory
  final int _stepsToday = 0;
  final DateTime _stepsDayAnchor = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  // SharedPreferences keys for caching the last good vitals reading
  static const String _cacheKey = 'lastVitalsCache_v1';

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

      // Immediately restore last cached vitals (if any) so subscribers have
      // something to display before fresh data is fetched.
      final cached = await _loadCachedVitals();
      if (cached != null) {
        _currentVitals = cached;
        // Emit to stream so widgets get the value.
        _vitalsController.add(cached);
      }

      _isInitialized = true;
      _updateConnectionStatus(VitalsConnectionStatus.disconnected);

      logI('✅ VitalsNotifierService initialized');
      return true;
    } catch (e) {
      logE('❌ VitalsNotifierService initialization failed', e);
      return false;
    }
  }

  /// Start subscribing to vitals data for a user
  Future<bool> startSubscription(String userId) async {
    if (!_isInitialized) {
      throw StateError('VitalsNotifierService not initialized');
    }

    if (_isActive && _currentUserId == userId) {
      logI('ℹ️ Already subscribed to vitals for user: $userId');
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
      logE('❌ Failed to start vitals subscription', e);
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

    logI('🚀 VitalsNotifier REALTIME subscription started for user: $userId');
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
    logI('🚀 VitalsNotifier POLLING subscription started for user: $userId');
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
      logI('⏹️ VitalsNotifier subscription stopped (Mode: ${_mode.name})');
    } catch (e) {
      logE('❌ Error stopping vitals subscription', e);
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
      logE('❌ Error processing live data', e);
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
        logD('🔢 extracted steps=$steps from ${message.value}');
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
    logD(
      'emit → steps=${merged.steps} hr=${merged.heartRate} sleep=${merged.sleepHours} meta=${merged.metadata}',
    );

    // Notify UI subscribers
    _vitalsController.add(merged);

    // Persist for next cold-launch
    // Fire-and-forget; no need to await.
    // ignore: unawaited_futures
    _saveCachedVitals(merged);
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
    logE('❌ VitalsNotifier stream error', error);
    _updateConnectionStatus(VitalsConnectionStatus.error);
  }

  /// Handle stream completion
  void _handleStreamDone() {
    logI('ℹ️ VitalsNotifier stream completed');
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
    // Dynamically widen the look-back window if we have seen many empty polls.
    Duration adaptiveLookback() {
      if (_currentVitals == null) return const Duration(hours: 12);

      if (_consecutiveEmptyPolls >= 8) return const Duration(hours: 1);
      if (_consecutiveEmptyPolls >= 5) return const Duration(minutes: 30);
      if (_consecutiveEmptyPolls >= 3) return const Duration(minutes: 5);
      return _config.pollingInterval;
    }

    final lookback = adaptiveLookback();

    final startTime = now.subtract(lookback);

    try {
      final result = await _repository.getHealthData(
        startTime: startTime,
        endTime: now,
      );

      if (result.isSuccess) {
        // Reset retry counter after a successful fetch
        _retryAttempts = 0;

        // Update consecutive empty counter
        if (result.samples.isEmpty) {
          _consecutiveEmptyPolls++;
        } else {
          _consecutiveEmptyPolls = 0;
        }

        _processHealthSamples(result.samples);

        // Throttled logging: show counts when we actually have data, or once per minute when empty.
        bool shouldLog = result.samples.isNotEmpty;
        if (!shouldLog) {
          final nowLog = DateTime.now();
          if (_lastZeroPollLogTime == null ||
              nowLog.difference(_lastZeroPollLogTime!) >
                  const Duration(minutes: 1)) {
            shouldLog = true;
            _lastZeroPollLogTime = nowLog;
          }
        }
        if (shouldLog) {
          logD('🔄 Polled ${result.samples.length} vitals samples.');
        }

        // --- iOS cumulative-type quirk workaround ----------------------
        final bool hasStepsRaw = result.samples.any(
          (s) => s.type == WearableDataType.steps,
        );

        if (!hasStepsRaw &&
            !_stepRetryScheduled &&
            _consecutiveEmptyPolls < 3) {
          _stepRetryScheduled = true;

          // Only emit the debug log if it has been >60 s since last one
          final nowTs = DateTime.now();
          if (_lastNoStepLogTime == null ||
              nowTs.difference(_lastNoStepLogTime!) >
                  const Duration(seconds: 60)) {
            _lastNoStepLogTime = nowTs;
            logD('⏳ No step samples – scheduling quick retry');
          }

          Future.delayed(const Duration(seconds: 3), () {
            _stepRetryScheduled = false;
            if (_isActive) _pollForVitals();
          });

          // Also surface permission status (once per 2 min) to help diagnose
          final permNow = DateTime.now();
          if (_lastPermissionLogTime == null ||
              permNow.difference(_lastPermissionLogTime!) >
                  const Duration(minutes: 2)) {
            _lastPermissionLogTime = permNow;
            final pm = HealthPermissionManager();
            if (pm.isInitialized) {
              final summary = pm.permissionCache.entries
                  .map((e) => '${e.key.name}:${e.value.isGranted ? '✔' : '✖'}')
                  .join(', ');
              logD('🔑 Health permission summary → [$summary]');
            }
          }
        }
        // ----------------------------------------------------------------

        // Extra diagnostic & bootstrap: in release we run after 6 empties; in DEBUG run after 1
        const int bootstrapThreshold = kDebugMode ? 1 : 6;

        if (_consecutiveEmptyPolls >= bootstrapThreshold &&
            !_midnightBootstrapDone) {
          _midnightBootstrapDone = true;
          final midnight = DateTime(now.year, now.month, now.day);
          final diagResult = await _repository.getHealthData(
            dataTypes: [WearableDataType.steps],
            startTime: midnight,
            endTime: now,
          );

          logD(
            '🧮 Steps-today diagnostic → ${diagResult.samples.length} points (bootstrap)',
          );

          // Feed the samples through normal processing so history & aggregates update
          if (diagResult.samples.isNotEmpty) {
            _processHealthSamples(diagResult.samples);
          }
        }

        // Heart rate bootstrap (last 2 hours)
        if (_consecutiveEmptyPolls >= bootstrapThreshold && !_hrBootstrapDone) {
          _hrBootstrapDone = true;

          List<HealthSample> hrSamples = [];

          // First try last 2 h
          final hr2h = await _repository.getHealthData(
            dataTypes: [WearableDataType.heartRate],
            startTime: now.subtract(const Duration(hours: 2)),
            endTime: now,
          );
          hrSamples = hr2h.samples;

          // Fallback: last 24 h
          if (hrSamples.isEmpty) {
            final hr24h = await _repository.getHealthData(
              dataTypes: [WearableDataType.heartRate],
              startTime: now.subtract(const Duration(hours: 24)),
              endTime: now,
            );
            hrSamples = hr24h.samples;
          }

          // Last-resort: single most recent sample
          if (hrSamples.isEmpty) {
            final latest = await _repository.getLatestSample(
              WearableDataType.heartRate,
            );
            if (latest != null) hrSamples = [latest];
          }

          logD('💓 HR bootstrap → ${hrSamples.length} points');
          if (hrSamples.isNotEmpty) {
            _processHealthSamples(hrSamples);
          }
        }

        // Sleep bootstrap (previous night 6 PM to now)
        if (_consecutiveEmptyPolls >= bootstrapThreshold &&
            !_sleepBootstrapDone) {
          _sleepBootstrapDone = true;
          final yesterday18 = DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(const Duration(hours: 6));
          final sleepResult = await _repository.getHealthData(
            dataTypes: [WearableDataType.sleepDuration],
            startTime: yesterday18,
            endTime: now,
          );
          logD('😴 Sleep bootstrap → ${sleepResult.samples.length} points');
          if (sleepResult.samples.isNotEmpty) {
            _processHealthSamples(sleepResult.samples);
          }
        }
      } else {
        logE('❌ Polling for vitals failed', result.error);
        _handleStreamError('Polling failed: ${result.error}');
        _scheduleRetry();
      }
    } catch (e) {
      logE('❌ Polling for vitals threw an exception', e);
      _handleStreamError(e);
      _scheduleRetry();
    }
  }

  // T2.2.2.9: New method to process polled health samples
  void _processHealthSamples(List<HealthSample> samples) {
    // Only log when there are samples to avoid spamming console
    if (kDebugMode && samples.isNotEmpty) {
      logD('🩺 Processing ${samples.length} polled samples');
      for (final s in samples.take(10)) {
        logD(
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

    // Calculate total steps since midnight using dedup logic and emit as aggregated VitalsData.
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
        // Deduplicate phone + watch double-count (VR-03)
        final source = sample.source.toLowerCase();
        final isWatch = source.contains('watch');
        final isPhone = source.contains('phone') || source.contains('iphone');

        // If this is a phone sample and we already processed a Watch sample
        // within ±30 s of this timestamp, skip to avoid double count.
        if (isPhone && _recentWatchStepSampleExists(sample.timestamp)) {
          logD('🚫 Skipping phone steps sample at ${sample.timestamp}');
          break;
        }

        steps = _extractInt(sample.value);
        logD('🔢 extracted steps=$steps from ${sample.value}');
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

    logI('🗑️ VitalsNotifierService disposed');
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

  // Calculate total steps since midnight using dedup logic and emit as aggregated VitalsData.
  void _emitAggregatedSteps() {
    final totalSteps = _calculateStepsToday();
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

    final rawToday =
        _dataHistory.where((d) {
          return d.hasSteps &&
              !d.timestamp.isBefore(midnight) &&
              d.metadata['aggregated'] != true;
        }).toList();

    return _sumStepsDedupByMinute(rawToday);
  }

  /// Exposes the step deduplication algorithm for unit testing. This keeps
  /// the production helper private while still allowing tests to verify edge
  /// cases. Implementation delegates to the same private method.
  @visibleForTesting
  static int? sumStepsForTest(List<VitalsData> samples) {
    return _sumStepsDedupByMinute(samples);
  }

  // Static helper with the actual dedup implementation.
  static int? _sumStepsDedupByMinute(List<VitalsData> samples) {
    if (samples.isEmpty) return null;

    // Prefer Watch samples when available to avoid double-counting with Phone.
    final Map<String, List<VitalsData>> bySource = {};
    for (final s in samples) {
      final src = (s.metadata['source']?.toString() ?? 'unknown').toLowerCase();
      bySource.putIfAbsent(src, () => <VitalsData>[]).add(s);
    }

    // Heuristic: choose watch if any source string contains 'watch'.
    List<VitalsData> chosen;
    final watchEntry = bySource.entries.firstWhere(
      (e) => e.key.contains('watch'),
      orElse: () => const MapEntry<String, List<VitalsData>>('', []),
    );
    if (watchEntry.value.isNotEmpty) {
      chosen = watchEntry.value;
    } else {
      // Otherwise pick the source with the largest *step sum* for the day.
      chosen = bySource.values.reduce((a, b) {
        final sumA = a.fold<int>(0, (p, v) => p + (v.steps ?? 0));
        final sumB = b.fold<int>(0, (p, v) => p + (v.steps ?? 0));
        return sumA >= sumB ? a : b;
      });
    }

    // Continue with minute-level dedup on the chosen source list.

    // key: epoch millis at minute precision
    final Map<int, int> minuteMax = {};

    for (final d in chosen) {
      final minuteEpoch =
          DateTime(
            d.timestamp.year,
            d.timestamp.month,
            d.timestamp.day,
            d.timestamp.hour,
            d.timestamp.minute,
          ).millisecondsSinceEpoch;
      final currentMax = minuteMax[minuteEpoch] ?? 0;
      final stepsVal = d.steps ?? 0;
      if (stepsVal > currentMax) minuteMax[minuteEpoch] = stepsVal;
    }

    if (minuteMax.isEmpty) return null;
    return minuteMax.values.fold<int>(0, (a, b) => a + b);
  }

  /// Load cached VitalsData from local storage so the UI can render an
  /// immediate value even before the first fetch completes. Returns null if
  /// no cache exists or parsing fails.
  Future<VitalsData?> _loadCachedVitals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);
      if (jsonString == null) return null;

      final Map<String, dynamic> json = Map<String, dynamic>.from(
        jsonDecode(jsonString) as Map,
      );

      return VitalsData(
        heartRate: json['heartRate'] as double?,
        steps: json['steps'] as int?,
        heartRateVariability: json['hrv'] as double?,
        sleepHours: json['sleepHours'] as double?,
        timestamp:
            DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
        quality: VitalsQuality.values[json['quality'] as int? ?? 4],
        metadata: {},
      );
    } catch (e) {
      logE('⚠️ Failed to load cached vitals', e);
      return null;
    }
  }

  /// Persist the latest VitalsData to disk so it can be restored on next
  /// cold-launch. Only lightweight primitives are stored.
  Future<void> _saveCachedVitals(VitalsData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(<String, dynamic>{
        'heartRate': data.heartRate,
        'steps': data.steps,
        'hrv': data.heartRateVariability,
        'sleepHours': data.sleepHours,
        'timestamp': data.timestamp.toIso8601String(),
        'quality': data.quality.index,
      });
      await prefs.setString(_cacheKey, jsonString);
    } catch (e) {
      logE('⚠️ Failed to save cached vitals', e);
    }
  }

  Duration _currentBackoffDuration() {
    // 2^attempt seconds capped to 32 s
    final seconds = 1 << _retryAttempts; // 1,2,4,8,16,32
    return Duration(seconds: seconds.clamp(1, 32));
  }

  void _scheduleRetry() {
    if (_retryAttempts >= _maxRetryAttempts) {
      logE('🚨 Max retry attempts reached; giving up until next cycle');
      _retryAttempts = 0; // reset for next scheduled poll interval
      return;
    }

    final backoff = _currentBackoffDuration();
    logD('🔁 Scheduling retry in ${backoff.inSeconds}s');
    _retryAttempts++;
    Future.delayed(backoff, () {
      if (_isActive) _pollForVitals();
    });
  }

  // Check if a Watch-origin step sample was processed in the last 30 s
  bool _recentWatchStepSampleExists(DateTime ts) {
    const window = Duration(seconds: 30);
    for (final d in _dataHistory.reversed) {
      if (!d.hasSteps) continue;
      if ((ts.difference(d.timestamp)).abs() > window) break;
      final src = d.metadata['source']?.toString().toLowerCase() ?? '';
      if (src.contains('watch')) return true;
    }
    return false;
  }
}
