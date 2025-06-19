/// Wearable Live Data Service for Real-time Streaming
///
/// Manages WebSocket connections for real-time wearable data streaming
/// using Supabase Realtime. Follows the wearable_live:{user_id} channel pattern.
/// Enhanced with HTTPS batch fallback for Epic 2.2 Task T2.2.2.4
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'wearable_live_models.dart';
import 'wearable_data_models.dart';
import 'health_data_http_client.dart';
import 'health_data_batching_service.dart';
import 'wearable_offline_buffer.dart';
import 'connectivity_service.dart';

/// Service for managing real-time wearable data streaming with HTTPS fallback
class WearableLiveService {
  final SupabaseClient _supabase;
  final WearableLiveConfig _config;
  final HealthDataHttpClient _httpClient;
  final HealthDataBatchingService _batchingService;
  late final WearableOfflineBuffer _offlineBuffer;
  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;

  RealtimeChannel? _channel;
  StreamController<List<WearableLiveMessage>>? _messageController;
  Timer? _publishTimer;
  Timer? _reconnectTimer;
  final List<WearableLiveMessage> _messageBuffer = [];
  final List<WearableLiveMessage> _failureQueue = [];

  bool _isActive = false;
  bool _isWebSocketAvailable = true;
  String? _currentUserId;
  int _consecutiveFailures = 0;
  static const int _maxFailuresBeforeFallback = 3;
  static const Duration _reconnectInterval = Duration(seconds: 10);

  WearableLiveService(
    this._supabase, {
    WearableLiveConfig config = WearableLiveConfig.defaultConfig,
    HealthDataHttpClient? httpClient,
    HealthDataBatchingService? batchingService,
  }) : _config = config,
       _httpClient = httpClient ?? HealthDataHttpClient(),
       _batchingService = batchingService ?? HealthDataBatchingService() {
    _offlineBuffer = WearableOfflineBuffer.getInstance();
  }

  /// Stream of incoming live messages
  Stream<List<WearableLiveMessage>> get messageStream =>
      _messageController?.stream ?? const Stream.empty();

  /// Whether the service is actively streaming
  bool get isActive => _isActive;

  /// Current user being monitored
  String? get currentUserId => _currentUserId;

  /// Whether WebSocket is currently available
  bool get isWebSocketAvailable => _isWebSocketAvailable;

  /// Start live data streaming for a user
  Future<bool> startStreaming(String userId) async {
    if (_isActive && _currentUserId == userId) {
      return true; // Already streaming for this user
    }

    try {
      await stopStreaming(); // Stop any existing stream

      _currentUserId = userId;
      _messageController =
          StreamController<List<WearableLiveMessage>>.broadcast();

      // Initialize offline buffer
      await _offlineBuffer.initialize();

      _listenToConnectivity();

      // Attempt WebSocket connection
      final webSocketSuccess = await _initializeWebSocket(userId);
      if (!webSocketSuccess) {
        _isWebSocketAvailable = false;
        debugPrint('⚠️ WebSocket unavailable, using HTTPS fallback only');
      }

      // Flush buffer on initial start if online
      if (ConnectivityService.isOnline) {
        await _flushOfflineBuffer();
      }

      // Start periodic publishing if batching is enabled
      if (_config.enableBatching) {
        _publishTimer = Timer.periodic(
          _config.publishInterval,
          (_) => _publishBufferedMessages(),
        );
      }

      _isActive = true;
      _debugPrint('✅ Started wearable live streaming for user: $userId');
      return true;
    } catch (e) {
      _debugPrint('❌ Failed to start wearable live streaming: $e');
      await stopStreaming();
      return false;
    }
  }

  /// Initialize WebSocket connection
  Future<bool> _initializeWebSocket(String userId) async {
    try {
      // Create channel following the wearable_live:{user_id} pattern
      _channel = _supabase.channel('wearable_live_$userId');

      // Set up message listeners
      _channel!
          .onBroadcast(event: 'live_data', callback: _handleIncomingMessage)
          .subscribe();

      _consecutiveFailures = 0;
      _isWebSocketAvailable = true;
      return true;
    } catch (e) {
      debugPrint('❌ WebSocket initialization failed: $e');
      return false;
    }
  }

  /// Stop live data streaming
  Future<void> stopStreaming() async {
    _isActive = false;

    // Cancel timers
    _publishTimer?.cancel();
    _publishTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    // Unsubscribe from channel
    if (_channel != null) {
      await _channel!.unsubscribe();
      _channel = null;
    }

    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;

    // Close stream controller
    await _messageController?.close();
    _messageController = null;

    // Clear buffers
    _messageBuffer.clear();
    _failureQueue.clear();
    _currentUserId = null;
    _consecutiveFailures = 0;

    _debugPrint('🛑 Stopped wearable live streaming');
  }

  /// Publish a single live message with fallback
  Future<void> publishMessage(WearableLiveMessage message) async {
    if (!_isActive) {
      debugPrint('⚠️ Cannot publish: streaming not active');
      return;
    }

    // Filter by enabled types
    if (!_config.enabledTypes.contains(message.type)) {
      return;
    }

    // Store in offline buffer if offline
    if (!ConnectivityService.isOnline) {
      await _offlineBuffer.storeDelta(message);
      return;
    }

    if (_config.enableBatching) {
      // Add to buffer for batch publishing
      _messageBuffer.add(message);

      // Publish immediately if buffer is full
      if (_messageBuffer.length >= _config.maxBatchSize) {
        await _publishBufferedMessages();
      }
    } else {
      // Publish immediately
      await _publishSingleMessage(message);
    }
  }

  /// Publish multiple messages as a batch with fallback
  Future<void> publishMessageBatch(List<WearableLiveMessage> messages) async {
    if (!_isActive) return;

    // Filter by enabled types
    final filteredMessages =
        messages.where((m) => _config.enabledTypes.contains(m.type)).toList();

    if (filteredMessages.isEmpty) return;

    if (_isWebSocketAvailable && _channel != null) {
      // Try WebSocket first
      final success = await _publishViaWebSocket(filteredMessages);
      if (!success) {
        // WebSocket failed, fall back to HTTPS
        await _publishViaHttps(filteredMessages);
      }
    } else {
      // WebSocket unavailable, use HTTPS directly
      await _publishViaHttps(filteredMessages);
    }
  }

  /// Publish via WebSocket
  Future<bool> _publishViaWebSocket(List<WearableLiveMessage> messages) async {
    try {
      final batch = WearableLiveMessageBatch(
        batchId: 'batch_${DateTime.now().millisecondsSinceEpoch}',
        messages: messages,
        createdAt: DateTime.now(),
      );

      await _channel!.sendBroadcastMessage(
        event: 'live_data_batch',
        payload: batch.toJson(),
      );

      _consecutiveFailures = 0;
      debugPrint('📤 Published via WebSocket: ${messages.length} messages');
      return true;
    } catch (e) {
      _consecutiveFailures++;
      debugPrint(
        '❌ WebSocket publish failed: $e (failures: $_consecutiveFailures)',
      );

      if (_consecutiveFailures >= _maxFailuresBeforeFallback) {
        _handleWebSocketFailure();
      }

      return false;
    }
  }

  /// Publish via HTTPS batch fallback
  Future<void> _publishViaHttps(List<WearableLiveMessage> messages) async {
    if (_currentUserId == null) return;

    try {
      // Convert to HealthSample format for existing HTTP client
      final healthSamples =
          messages
              .map(
                (msg) => HealthSample(
                  id: '${msg.type.name}_${msg.timestamp.millisecondsSinceEpoch}',
                  timestamp: msg.timestamp,
                  type: msg.type,
                  value: msg.value,
                  unit: _getUnitForDataType(msg.type),
                  source: msg.source,
                ),
              )
              .toList();

      // Create batch using existing batching service
      final batches = _batchingService.createBatches(
        userId: _currentUserId!,
        samples: healthSamples,
      );

      if (batches.isEmpty) return;
      final batch = batches.first;

      // Upload via HTTP
      final result = await _httpClient.uploadBatch(batch);

      if (result.isSuccess) {
        debugPrint(
          '📤 Published via HTTPS fallback: ${messages.length} messages',
        );
      } else {
        debugPrint('❌ HTTPS fallback failed: ${result.message}');
        // Queue for retry
        _failureQueue.addAll(messages);
      }
    } catch (e) {
      debugPrint('❌ HTTPS fallback error: $e');
      _failureQueue.addAll(messages);
    }
  }

  /// Handle WebSocket failure and start reconnection
  void _handleWebSocketFailure() {
    _isWebSocketAvailable = false;
    debugPrint('🔄 WebSocket failed, switching to HTTPS fallback');

    // Start reconnection attempts
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(
      _reconnectInterval,
      (_) => _attemptReconnection(),
    );
  }

  /// Attempt to reconnect WebSocket
  Future<void> _attemptReconnection() async {
    if (_currentUserId == null) return;

    debugPrint('🔄 Attempting WebSocket reconnection...');
    final success = await _initializeWebSocket(_currentUserId!);

    if (success) {
      debugPrint('✅ WebSocket reconnected');
      _reconnectTimer?.cancel();
      _reconnectTimer = null;

      // Process any queued failures
      await _processFailureQueue();

      // Flush offline buffer on reconnect
      await _flushOfflineBuffer();
    }
  }

  /// Process queued failed messages
  Future<void> _processFailureQueue() async {
    if (_failureQueue.isEmpty) return;

    final messagesToRetry = List<WearableLiveMessage>.from(_failureQueue);
    _failureQueue.clear();

    debugPrint('🔄 Retrying ${messagesToRetry.length} queued messages');
    await publishMessageBatch(messagesToRetry);
  }

  /// Handle incoming message from WebSocket
  void _handleIncomingMessage(Map<String, dynamic> payload) {
    try {
      if (payload.containsKey('messages')) {
        // Handle batch message
        final batch = WearableLiveMessageBatch.fromJson(payload);
        _messageController?.add(batch.messages);
      } else {
        // Handle single message
        final message = WearableLiveMessage.fromJson(payload);
        _messageController?.add([message]);
      }
    } catch (e) {
      debugPrint('❌ Failed to handle incoming message: $e');
    }
  }

  /// Publish a single message immediately with fallback
  Future<void> _publishSingleMessage(WearableLiveMessage message) async {
    await publishMessageBatch([message]);
  }

  /// Publish all buffered messages as a batch
  Future<void> _publishBufferedMessages() async {
    if (_messageBuffer.isEmpty) return;

    final messagesToPublish = List<WearableLiveMessage>.from(_messageBuffer);
    _messageBuffer.clear();

    await publishMessageBatch(messagesToPublish);
  }

  /// Flush offline buffer when connectivity restored
  Future<void> _flushOfflineBuffer() async {
    try {
      await _offlineBuffer.flushBuffer(
        flushCallback: (deltas) async {
          if (deltas.isEmpty) return true;

          debugPrint('🔄 Flushing ${deltas.length} offline deltas');
          await publishMessageBatch(deltas);
          return true;
        },
      );
    } catch (e) {
      debugPrint('❌ Failed to flush offline buffer: $e');
    }
  }

  /// Get unit for data type (helper for HTTPS conversion)
  String _getUnitForDataType(WearableDataType dataType) {
    switch (dataType) {
      case WearableDataType.heartRate:
      case WearableDataType.restingHeartRate:
        return 'bpm';
      case WearableDataType.steps:
        return 'count';
      case WearableDataType.activeEnergyBurned:
        return 'kcal';
      case WearableDataType.sleepDuration:
        return 'min';
      case WearableDataType.vo2Max:
        return 'ml/kg/min';
      case WearableDataType.heartRateVariability:
        return 'ms';
      case WearableDataType.weight:
        return 'lbs';
      default:
        return 'count';
    }
  }

  /// Get channel connection status
  String get connectionStatus {
    if (!_isActive) return 'inactive';
    if (_channel == null) return 'disconnected';
    if (!_isWebSocketAvailable) return 'https_fallback';
    return 'connected';
  }

  /// Get failure queue size for monitoring
  int get failureQueueSize => _failureQueue.length;

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

  /// Dispose of resources
  Future<void> dispose() async {
    await stopStreaming();
  }

  void _listenToConnectivity() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = ConnectivityService.statusStream.listen((
      status,
    ) {
      if (status == ConnectivityStatus.online) {
        debugPrint('📡 Connection restored, flushing offline buffer.');
        _flushOfflineBuffer();
      }
    });
  }
}

/// Extension for converting HealthSample to live messages
extension HealthSampleToLive on HealthSample {
  WearableLiveMessage toLiveMessage() {
    return WearableLiveMessage.fromHealthSample(this);
  }
}

/// Extension for batch conversion
extension HealthSampleBatchToLive on List<HealthSample> {
  List<WearableLiveMessage> toLiveMessages() {
    return map((sample) => sample.toLiveMessage()).toList();
  }
}
