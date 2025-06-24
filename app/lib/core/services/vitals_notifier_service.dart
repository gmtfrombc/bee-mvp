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
  final double? activeEnergy; // kcal
  final double? weight; // lbs  – converted from kg for display
  final DateTime timestamp;
  final VitalsQuality quality;
  final Map<String, dynamic> metadata;

  const VitalsData({
    this.heartRate,
    this.steps,
    this.heartRateVariability,
    this.sleepHours,
    this.activeEnergy,
    this.weight,
    required this.timestamp,
    this.quality = VitalsQuality.unknown,
    this.metadata = const {},
  });

  bool get hasHeartRate => heartRate != null;
  bool get hasSteps => steps != null;
  bool get hasSleep => sleepHours != null;
  bool get hasEnergy => activeEnergy != null;
  bool get hasWeight => weight != null;
  bool get hasValidData =>
      hasHeartRate || hasSteps || hasSleep || hasEnergy || hasWeight;

  VitalsData copyWith({
    double? heartRate,
    int? steps,
    double? heartRateVariability,
    double? sleepHours,
    double? activeEnergy,
    double? weight,
    DateTime? timestamp,
    VitalsQuality? quality,
    Map<String, dynamic>? metadata,
  }) {
    return VitalsData(
      heartRate: heartRate ?? this.heartRate,
      steps: steps ?? this.steps,
      heartRateVariability: heartRateVariability ?? this.heartRateVariability,
      sleepHours: sleepHours ?? this.sleepHours,
      activeEnergy: activeEnergy ?? this.activeEnergy,
      weight: weight ?? this.weight,
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

  // Running step total logic was refactored; legacy fields removed.

  // SharedPreferences keys for caching the last good vitals reading
  static const String _cacheKey = 'lastVitalsCache_v1';

  StreamSubscription<List<PermissionDelta>>? _permissionDeltaSubscription;

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

  /// Manually trigger an immediate refresh of health data – can be called from
  /// Settings → Health Permissions UI to ensure latest samples are pulled.
  Future<void> refreshVitals() async {
    await _pollForVitals();
  }

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

      // Listen for permission changes so we can refresh data when user grants
      // previously denied HealthKit/Health Connect types. This avoids stale
      // cache after the user revisits Settings → Health.
      final pm = HealthPermissionManager();
      if (pm.isInitialized) {
        _permissionDeltaSubscription = pm.deltaStream.listen(
          _handlePermissionDelta,
        );
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

      await _permissionDeltaSubscription?.cancel();
      _permissionDeltaSubscription = null;

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
    double? activeEnergy;
    double? weight;

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
      case WearableDataType.activeEnergyBurned:
        activeEnergy = _extractDouble(message.value);
        break;
      case WearableDataType.weight:
        final kg = _extractDouble(message.value);
        if (kg != null) weight = kg * 2.20462; // convert to lbs
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
      activeEnergy: activeEnergy,
      weight: weight,
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
    if (kDebugMode && vitalsData.metadata['aggregated'] == true) {
      debugPrint(
        '📮 aggregated emit → sleep=${vitalsData.sleepHours} steps=${vitalsData.steps}',
      );
    }
    // Always persist to history first
    _dataHistory.add(vitalsData);
    _cleanupHistory();

    // Skip forwarding raw step-only samples – we will emit a daily aggregate separately.
    final isRawStepOnly =
        vitalsData.hasSteps &&
        !vitalsData.hasHeartRate &&
        !vitalsData.hasSleep &&
        (vitalsData.metadata['aggregated'] != true);

    // Skip raw per-segment sleep entries (sleepKind ≠ aggregated) so the UI shows the
    // properly aggregated nightly total rather than the last individual stage sample.
    final isRawSleepSegment =
        vitalsData.hasSleep && (vitalsData.metadata['aggregated'] != true);

    if (isRawStepOnly || isRawSleepSegment) return;

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
        activeEnergy: vitalsData.activeEnergy ?? _currentVitals!.activeEnergy,
        weight: vitalsData.weight ?? _currentVitals!.weight,
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
    _currentVitals = null;
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

  /// Manually trigger an immediate data refresh. This is invoked by the
  /// pull-to-refresh gesture in the WearableDashboardScreen. A broader
  /// look-back window is used to guarantee that new samples are fetched even
  /// if HealthKit has not produced events in the last minute.
  ///
  /// In addition to fetching fresh data we now *purge* any existing sleep-related
  /// samples that fall within the analysis window so that deleted or amended
  /// Sleep records in Apple Health are reflected immediately.  This fixes the
  /// scenario where a user removed an erroneous 0.1-minute record but the app
  /// continued to display the stale value (#H2-A-sleep-stale).
  Future<void> refreshNow() async {
    if (!_isInitialized) {
      // Attempt late initialization so manual refresh still works.
      final ok = await initialize();
      if (!ok) return;
    }

    // ---------------------------------------------------------------------
    // 1️⃣ Purge stale sleep samples so that subsequent aggregation reflects
    // the *current* ground-truth from HealthKit/Health Connect.  We only wipe
    // records from the analysis window (yesterday 18:00 → now) to keep memory
    // usage low while guaranteeing correct aggregation.
    // ---------------------------------------------------------------------
    final now = DateTime.now();
    final sleepWindowStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(hours: 6)); // yesterday 18:00

    _purgeSleepSamples(since: sleepWindowStart);

    // If the current snapshot contains a sleepHours value, clear it out so the
    // UI doesn't continue showing the stale figure in the brief interval
    // before fresh data arrives.
    if (_currentVitals?.hasSleep ?? false) {
      _currentVitals = _currentVitals!.copyWith(sleepHours: null);
    }

    // Notify listeners of the cleared state so the Sleep tile can render a
    // loading/placeholder UI immediately, giving the user feedback that the
    // refresh gesture is in progress.
    if (_currentVitals != null) {
      _vitalsController.add(_currentVitals!);
      // Persist the cleared snapshot so a hot-restart doesn't resurrect the
      // stale 0.1-minute value from SharedPreferences.
      // ignore: unawaited_futures
      _saveCachedVitals(_currentVitals!);
    }

    final List<HealthSample> combined = [];

    // 2️⃣ Steps – fetch since midnight so we always have the full daily total.
    final midnight = DateTime(now.year, now.month, now.day);
    final stepsRes = await _repository.getHealthData(
      dataTypes: [WearableDataType.steps],
      startTime: midnight,
      endTime: now,
    );
    combined.addAll(stepsRes.samples);

    // 3️⃣ Heart-related metrics – fetch both instantaneous and resting HR for context.
    final hrRes = await _repository.getHealthData(
      dataTypes: [
        WearableDataType.heartRate,
        WearableDataType.restingHeartRate,
        WearableDataType.heartRateVariability,
      ],
      startTime: now.subtract(const Duration(hours: 24)),
      endTime: now,
    );
    // Process instantaneous HR first, then resting HR so the latter becomes the final merged value.
    final hrSamplesSorted = [...hrRes.samples]..sort((a, b) {
      final aRest = a.type == WearableDataType.restingHeartRate;
      final bRest = b.type == WearableDataType.restingHeartRate;
      if (aRest == bRest) return 0;
      return aRest ? 1 : -1; // resting → after
    });
    combined.addAll(hrSamplesSorted);

    // 4️⃣ Active energy – since midnight to capture full-day burn.
    final energyRes = await _repository.getHealthData(
      dataTypes: [WearableDataType.activeEnergyBurned],
      startTime: midnight,
      endTime: now,
    );
    combined.addAll(energyRes.samples);

    // 5️⃣ Weight – use most recent sample within last 30 days.
    final weightRes = await _repository.getHealthData(
      dataTypes: [WearableDataType.weight],
      startTime: now.subtract(const Duration(days: 30)),
      endTime: now,
    );
    if (weightRes.samples.isNotEmpty) {
      // Choose the most recent weight entry by timestamp.
      weightRes.samples.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      combined.add(weightRes.samples.first);
    }

    // 6️⃣ Sleep – previous night (18:00) → now covers the common window.
    var sleepRes = await _repository.getHealthData(
      dataTypes: [
        WearableDataType.sleepDuration,
        WearableDataType.sleepAwake,
        WearableDataType.sleepAsleep,
        WearableDataType.sleepDeep,
        WearableDataType.sleepLight,
        WearableDataType.sleepRem,
      ],
      startTime: sleepWindowStart,
      endTime: now,
    );

    // Fallback: widen look-back to past 5 days if no samples found
    if (sleepRes.samples.isEmpty) {
      logD('🛌 No sleep samples in 21-h window – retrying 5-day fetch');
      sleepRes = await _repository.getHealthData(
        dataTypes: [
          WearableDataType.sleepDuration,
          WearableDataType.sleepAwake,
          WearableDataType.sleepAsleep,
          WearableDataType.sleepDeep,
          WearableDataType.sleepLight,
          WearableDataType.sleepRem,
        ],
        startTime: now.subtract(const Duration(days: 5)),
        endTime: now,
      );
    }

    combined.addAll(sleepRes.samples);

    // ---------------------------------------------------------------------
    // 🔢 Compute nightly restful sleep total from the freshly fetched samples
    //     and emit it as an aggregated record so the Sleep tile has the
    //     correct value immediately after a manual refresh.
    // ---------------------------------------------------------------------
    final nightlyHours = _computeRestfulSleepHours(sleepRes.samples);
    if (nightlyHours != null && nightlyHours > 0) {
      _addVitalsData(
        VitalsData(
          sleepHours: nightlyHours,
          timestamp: now,
          quality: VitalsQuality.good,
          metadata: const {'aggregated': true, 'source': 'manualRefresh'},
        ),
      );
    }

    if (combined.isEmpty) {
      logD('🌧️ Manual refresh found no new samples');
      return;
    }

    _processHealthSamples(combined);
  }

  // ---------------------------------------------------------------------------
  // 🧹 Helper: remove existing sleep-related samples from history so that a
  //           subsequent fetch can rebuild the nightly sleep aggregate without
  //           double-counting or retaining deleted entries.
  // ---------------------------------------------------------------------------
  void _purgeSleepSamples({required DateTime since}) {
    _dataHistory.removeWhere((d) => d.hasSleep && d.timestamp.isAfter(since));
  }

  // T2.2.2.9: New method to poll for vitals data using repository
  Future<void> _pollForVitals() async {
    if (!_isActive || _currentUserId == null) return;

    logD('📡 _pollForVitals triggered at ${DateTime.now().toIso8601String()}');

    final now = DateTime.now();
    // Dynamically widen the look-back window if we have seen many empty polls.
    Duration adaptiveLookback() {
      if (_currentVitals == null) return const Duration(hours: 12);

      if (_consecutiveEmptyPolls >= 8) return const Duration(hours: 1);
      if (_consecutiveEmptyPolls >= 5) return const Duration(minutes: 30);
      // Default to 5 minutes instead of the polling interval to ensure we pick
      // up samples that are written less frequently than our timer.
      return const Duration(minutes: 5);
    }

    final lookback = adaptiveLookback();

    final startTime = now.subtract(lookback);

    try {
      // 🆕 Separate cumulative vs point-in-time metrics so we can use the correct
      // look-back window for each category.
      final allTypes = _repository.config.dataTypes;
      final cumulativeTypes = allTypes.where((t) => t.isCumulative).toList();
      final pointTypes = allTypes.where((t) => !t.isCumulative).toList();

      // 1️⃣ Point-in-time metrics with adaptive look-back window (default 5 min).
      final pointRes = await _repository.getHealthData(
        dataTypes: pointTypes,
        startTime: startTime,
        endTime: now,
      );

      // 2️⃣ Cumulative metrics (Steps, ActiveEnergy) with midnight window.
      final midnight = DateTime(now.year, now.month, now.day);
      final cumulativeRes = await _repository.getHealthData(
        dataTypes: cumulativeTypes,
        startTime: midnight,
        endTime: now,
      );

      final List<HealthSample> combinedSamples = [
        ...pointRes.samples,
        ...cumulativeRes.samples,
      ];

      final bool querySuccess = pointRes.isSuccess && cumulativeRes.isSuccess;

      if (querySuccess) {
        // Reset retry counter after a successful fetch
        _retryAttempts = 0;

        // Update consecutive empty counter – only count as empty when *both* queries are empty
        if (combinedSamples.isEmpty) {
          _consecutiveEmptyPolls++;
          // Do NOT clear _currentVitals here – we retain last good data until stale.
        } else {
          _consecutiveEmptyPolls = 0;
        }

        // Merge sample lists before processing
        _processHealthSamples(combinedSamples);

        // Throttled logging: show counts when we actually have data, or once per minute when empty.
        bool shouldLog = combinedSamples.isNotEmpty;
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
          logD('🔄 Polled ${combinedSamples.length} vitals samples.');
        }

        // --- iOS cumulative-type quirk workaround ----------------------
        final bool hasStepsRaw = combinedSamples.any(
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

        if (!_midnightBootstrapDone) {
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
            dataTypes: [
              WearableDataType.heartRate,
              WearableDataType.restingHeartRate,
            ],
            startTime: now.subtract(const Duration(hours: 2)),
            endTime: now,
          );
          hrSamples = hr2h.samples;

          // Fallback: last 24 h
          if (hrSamples.isEmpty) {
            final hr24h = await _repository.getHealthData(
              dataTypes: [
                WearableDataType.heartRate,
                WearableDataType.restingHeartRate,
              ],
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
            dataTypes: [
              WearableDataType.sleepDuration,
              WearableDataType.sleepAwake,
              WearableDataType.sleepAsleep,
            ],
            startTime: yesterday18,
            endTime: now,
          );
          logD('😴 Sleep bootstrap → ${sleepResult.samples.length} points');
          if (sleepResult.samples.isNotEmpty) {
            _processHealthSamples(sleepResult.samples);
          }
        }
      } else {
        final errMsg = pointRes.error ?? cumulativeRes.error ?? 'unknown';
        logE('❌ Polling for vitals failed', errMsg);
        // Do not clear cached vitals here; we rely on retention windows to determine staleness.
        _handleStreamError('Polling failed: $errMsg');
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

    // Aggregations for summary metrics -------------------------------------------------
    _emitAggregatedSteps();
    _emitAggregatedActiveEnergy();
    _emitAggregatedSleep();
  }

  // T2.2.2.9: New method to process a single HealthSample into VitalsData
  VitalsData? _processHealthSample(HealthSample sample) {
    final timestamp = sample.timestamp;

    double? heartRate;
    int? steps;
    double? hrv;
    double? sleepHours;
    double? activeEnergy;
    double? weight;

    // Capture common metadata (will add sleepKind later if needed)
    final Map<String, dynamic> meta = {'source': sample.source, 'polled': true};

    switch (sample.type) {
      case WearableDataType.heartRate:
        heartRate = _extractDouble(sample.value);
        break;

      case WearableDataType.restingHeartRate:
        // Prefer resting HR for daily snapshot
        heartRate = _extractDouble(sample.value);
        break;

      case WearableDataType.steps:
        // Deduplicate phone + watch double-count (VR-03)
        final source = sample.source.toLowerCase();
        final isPhone = source.contains('phone') || source.contains('iphone');

        // If this is a phone sample and we already processed a Watch sample
        // within ±30 s of this timestamp, skip to avoid double count.
        if (isPhone && _recentWatchStepSampleExists(sample.timestamp)) {
          logD('🚫 Skipping phone steps sample at ${sample.timestamp}');
          return null;
        }

        steps = _extractInt(sample.value);
        logD('🔢 extracted steps=$steps from ${sample.value}');
        break;

      case WearableDataType.heartRateVariability:
        hrv = _extractDouble(sample.value);
        break;

      case WearableDataType.sleepDuration:
        meta['sleepKind'] = 'inBed';
        // Assume incoming value is total sleep duration in minutes
        try {
          final minutes = _extractDouble(sample.value);
          if (minutes != null) sleepHours = minutes / 60.0;
        } catch (_) {
          sleepHours = _extractDouble(sample.value);
        }
        break;

      case WearableDataType.sleepAwake:
        // Awake minutes during sleep session – used to subtract from in-bed duration.
        final minutes = _extractDouble(sample.value);
        if (minutes != null) sleepHours = minutes / 60.0;
        meta['sleepKind'] = 'awake';
        break;

      case WearableDataType.sleepDeep:
      case WearableDataType.sleepLight:
      case WearableDataType.sleepRem:
      case WearableDataType.sleepAsleep:
        // Treat sleep stage minutes as sleep contribution.
        final minutes = _extractDouble(sample.value);
        if (minutes != null) sleepHours = minutes / 60.0;
        meta['sleepKind'] = 'stage';
        break;

      case WearableDataType.activeEnergyBurned:
        activeEnergy = _extractDouble(sample.value);
        break;

      case WearableDataType.weight:
        final kg = _extractDouble(sample.value);
        if (kg != null) weight = kg * 2.20462; // convert to lbs
        break;

      default:
        return null; // Unsupported or unknown type
    }

    // If nothing was extracted, skip.
    if (heartRate == null &&
        steps == null &&
        hrv == null &&
        sleepHours == null &&
        activeEnergy == null &&
        weight == null) {
      return null;
    }

    final quality = _calculateDataQuality(timestamp);

    return VitalsData(
      heartRate: heartRate,
      steps: steps,
      heartRateVariability: hrv,
      sleepHours: sleepHours,
      activeEnergy: activeEnergy,
      weight: weight,
      timestamp: timestamp,
      quality: quality,
      metadata: meta,
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

  static double? _extractDouble(dynamic raw) {
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

  static int? _extractInt(dynamic raw) {
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
        activeEnergy: json['activeEnergy'] as double?,
        weight: json['weight'] as double?,
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
        'activeEnergy': data.activeEnergy,
        'weight': data.weight,
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

  // Sum total active energy (kcal) burned since midnight.
  double? _calculateActiveEnergyToday() {
    final midnight = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    final todayEnergySamples =
        _dataHistory.where((d) {
          return d.hasEnergy &&
              !d.timestamp.isBefore(midnight) &&
              d.metadata['aggregated'] != true;
        }).toList();

    if (todayEnergySamples.isEmpty) return null;

    return todayEnergySamples
        .map((d) => d.activeEnergy ?? 0)
        .fold<double>(0, (prev, e) => prev + e);
  }

  void _emitAggregatedActiveEnergy() {
    final totalEnergy = _calculateActiveEnergyToday();
    if (totalEnergy == null || totalEnergy == 0) return;

    final aggregated = VitalsData(
      activeEnergy: totalEnergy,
      timestamp: DateTime.now(),
      quality: VitalsQuality.good,
      metadata: const {'aggregated': true},
    );

    _addVitalsData(aggregated);
  }

  void _emitAggregatedSleep() {
    // Calculate restorative sleep (time actually asleep) for the most recent sleep session.

    // Define analysis window → yesterday 6 PM → now. This safely captures the entire previous
    // night even if the user is a late sleeper.
    final now = DateTime.now();
    final analysisStart = DateTime(now.year, now.month, now.day).subtract(
      const Duration(hours: 6), // 6 PM previous calendar day
    );

    double minutesInBed = 0;
    double minutesAwake = 0;
    double minutesStages = 0;

    for (final d in _dataHistory) {
      if (!d.hasSleep) continue;
      if (d.timestamp.isBefore(analysisStart)) continue;
      if (d.metadata['aggregated'] == true) continue;

      final kind = d.metadata['sleepKind']?.toString() ?? 'unknown';
      final minutes = (d.sleepHours ?? 0) * 60;

      if (kind == 'awake') {
        minutesAwake += minutes;
      } else if (kind == 'inBed') {
        minutesInBed += minutes;
      } else if (kind == 'stage') {
        minutesStages += minutes;
      }
    }

    double restfulMinutes;

    if (minutesStages > 0) {
      // Prefer summed sleep stages when available – more precise.
      restfulMinutes = minutesStages;
    } else {
      // Fallback to in-bed minus awake.
      restfulMinutes = minutesInBed - minutesAwake;
    }

    if (restfulMinutes <= 0) return;

    final restfulHours = restfulMinutes / 60.0;

    final aggregated = VitalsData(
      sleepHours: restfulHours,
      timestamp: now,
      quality: VitalsQuality.good,
      metadata: const {'aggregated': true},
    );

    _addVitalsData(aggregated);
  }

  /// Exposes the restorative-sleep computation for unit tests.
  @visibleForTesting
  static double? computeRestfulSleepForTest(List<HealthSample> samples) {
    return _computeRestfulSleepHoursStatic(samples);
  }

  // Static helper that contains the actual algorithm so both production
  // and tests use the exact same code path.
  static double? _computeRestfulSleepHoursStatic(List<HealthSample> samples) {
    if (samples.isEmpty) return null;

    // Focus on the latest sleep session (18:00 → +18 h window)
    final latestTs = samples
        .map((s) => s.timestamp)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    DateTime sessionStart;
    if (latestTs.hour < 12) {
      final prevDay = latestTs.subtract(const Duration(days: 1));
      sessionStart = DateTime(prevDay.year, prevDay.month, prevDay.day, 18);
    } else {
      sessionStart = DateTime(latestTs.year, latestTs.month, latestTs.day, 18);
    }
    final sessionEnd = sessionStart.add(const Duration(hours: 18));

    double minutesInBed = 0;
    double minutesAwake = 0;
    double minutesStages = 0;

    for (final s in samples) {
      if (s.timestamp.isBefore(sessionStart) ||
          s.timestamp.isAfter(sessionEnd)) {
        continue;
      }

      final v = _extractDouble(s.value);
      if (v == null) continue;

      switch (s.type) {
        case WearableDataType.sleepAwake:
          minutesAwake += v;
          break;
        case WearableDataType.sleepDuration:
        case WearableDataType.sleepInBed:
          minutesInBed += v;
          break;
        case WearableDataType.sleepDeep:
        case WearableDataType.sleepLight:
        case WearableDataType.sleepRem:
        case WearableDataType.sleepAsleep:
          minutesStages += v;
          break;
        default:
          break;
      }
    }

    double? restfulMinutes;
    if (minutesInBed > 0) {
      restfulMinutes = (minutesInBed - minutesAwake).clamp(0, double.infinity);
    } else if (minutesStages > 0) {
      restfulMinutes = minutesStages;
    }

    if (restfulMinutes == null || restfulMinutes <= 0) return null;
    return restfulMinutes / 60.0;
  }

  // Instance proxy that calls the static algorithm so existing code remains
  // unchanged.
  double? _computeRestfulSleepHours(List<HealthSample> samples) {
    return _computeRestfulSleepHoursStatic(samples);
  }

  // Listen for permission changes so we can refresh data when user grants
  // previously denied HealthKit/Health Connect types. This avoids stale
  // cache after the user revisits Settings → Health.
  void _handlePermissionDelta(List<PermissionDelta> deltas) {
    // Trigger refresh only when previously denied → now granted to avoid
    // unnecessary fetches on unrelated permission events.
    final newlyGranted = deltas.where((d) => d.isNewlyGranted);
    if (newlyGranted.isNotEmpty) {
      final names = newlyGranted.map((d) => d.dataType.name).join(', ');
      logI('🔄 Permissions newly granted for $names → refreshing vitals');

      // Clear history so downstream UI widgets don\'t keep stale values.
      _dataHistory.clear();

      // Force an immediate poll. No need to await.
      _pollForVitals();
    }
  }
}
