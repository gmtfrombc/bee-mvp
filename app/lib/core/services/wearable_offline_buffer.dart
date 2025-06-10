/// Wearable Offline Buffer Service for Task T2.2.2.7
///
/// Stores max 2 hours of wearable data deltas using Hive
/// Flushes automatically on connectivity restoration
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import 'wearable_live_models.dart';

/// Configuration for offline buffer behavior
class WearableOfflineBufferConfig {
  final Duration maxBufferDuration;
  final int maxBufferSize;
  final Duration cleanupInterval;
  final bool enableAutoFlush;

  const WearableOfflineBufferConfig({
    this.maxBufferDuration = const Duration(hours: 2),
    this.maxBufferSize = 1000,
    this.cleanupInterval = const Duration(minutes: 15),
    this.enableAutoFlush = true,
  });

  static const WearableOfflineBufferConfig defaultConfig =
      WearableOfflineBufferConfig();
}

/// Status of buffer operations
enum BufferStatus { ready, storing, flushing, cleaning, error }

/// Result of buffer operations
class BufferOperationResult {
  final bool success;
  final String? error;
  final int itemsProcessed;
  final Duration operationTime;

  const BufferOperationResult({
    required this.success,
    this.error,
    this.itemsProcessed = 0,
    required this.operationTime,
  });

  factory BufferOperationResult.success({
    int itemsProcessed = 0,
    required Duration operationTime,
  }) {
    return BufferOperationResult(
      success: true,
      itemsProcessed: itemsProcessed,
      operationTime: operationTime,
    );
  }

  factory BufferOperationResult.failure({
    required String error,
    required Duration operationTime,
  }) {
    return BufferOperationResult(
      success: false,
      error: error,
      operationTime: operationTime,
    );
  }
}

/// Offline buffer service for wearable data deltas
class WearableOfflineBuffer {
  static const String _boxName = 'wearable_deltas';
  static WearableOfflineBuffer? _instance;

  Box<Map<dynamic, dynamic>>? _deltaBox;
  Timer? _cleanupTimer;

  final WearableOfflineBufferConfig _config;
  final Uuid _uuid = const Uuid();
  BufferStatus _status = BufferStatus.ready;
  bool _isInitialized = false;

  WearableOfflineBuffer._({
    WearableOfflineBufferConfig config =
        WearableOfflineBufferConfig.defaultConfig,
  }) : _config = config;

  /// Get singleton instance
  static WearableOfflineBuffer getInstance({
    WearableOfflineBufferConfig? config,
  }) {
    _instance ??= WearableOfflineBuffer._(
      config: config ?? WearableOfflineBufferConfig.defaultConfig,
    );
    return _instance!;
  }

  /// Initialize buffer service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Hive.initFlutter();
      _deltaBox = await Hive.openBox<Map<dynamic, dynamic>>(_boxName);

      _startPeriodicCleanup();

      _status = BufferStatus.ready;
      _isInitialized = true;

      debugPrint('✅ WearableOfflineBuffer initialized');
    } catch (e) {
      _status = BufferStatus.error;
      debugPrint('❌ Failed to initialize WearableOfflineBuffer: $e');
      rethrow;
    }
  }

  /// Store wearable delta in buffer
  Future<BufferOperationResult> storeDelta(WearableLiveMessage delta) async {
    if (!_isInitialized || _deltaBox == null) {
      return BufferOperationResult.failure(
        error: 'Buffer not initialized',
        operationTime: Duration.zero,
      );
    }

    final stopwatch = Stopwatch()..start();

    try {
      _status = BufferStatus.storing;

      // Check buffer capacity
      if (_deltaBox!.length >= _config.maxBufferSize) {
        await _removeOldestDeltas(1);
      }

      // Create buffer entry
      final entryId = _uuid.v4();
      final bufferEntry = {
        'id': entryId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'delta': delta.toJson(),
        'retryCount': 0,
      };

      await _deltaBox!.put(entryId, bufferEntry);

      stopwatch.stop();
      _status = BufferStatus.ready;

      debugPrint('📦 Stored delta in buffer: ${delta.type.name}');

      return BufferOperationResult.success(
        itemsProcessed: 1,
        operationTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      _status = BufferStatus.error;

      debugPrint('❌ Failed to store delta: $e');

      return BufferOperationResult.failure(
        error: e.toString(),
        operationTime: stopwatch.elapsed,
      );
    }
  }

  /// Flush all buffered deltas
  Future<BufferOperationResult> flushBuffer({
    required Future<bool> Function(List<WearableLiveMessage>) flushCallback,
  }) async {
    if (!_isInitialized || _deltaBox == null || _deltaBox!.isEmpty) {
      return BufferOperationResult.success(operationTime: Duration.zero);
    }

    final stopwatch = Stopwatch()..start();

    try {
      _status = BufferStatus.flushing;

      final deltas = _getValidDeltas();
      if (deltas.isEmpty) {
        stopwatch.stop();
        _status = BufferStatus.ready;
        return BufferOperationResult.success(operationTime: stopwatch.elapsed);
      }

      final success = await flushCallback(deltas);

      if (success) {
        await _deltaBox!.clear();
        debugPrint('✅ Flushed ${deltas.length} deltas successfully');
      } else {
        debugPrint('⚠️ Flush callback failed, keeping deltas in buffer');
      }

      stopwatch.stop();
      _status = BufferStatus.ready;

      return BufferOperationResult.success(
        itemsProcessed: success ? deltas.length : 0,
        operationTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      _status = BufferStatus.error;

      debugPrint('❌ Failed to flush buffer: $e');

      return BufferOperationResult.failure(
        error: e.toString(),
        operationTime: stopwatch.elapsed,
      );
    }
  }

  /// Get current buffer statistics
  Map<String, dynamic> getBufferStats() {
    if (!_isInitialized || _deltaBox == null) {
      return {
        'isInitialized': false,
        'status': _status.name,
        'error': 'Buffer not initialized',
      };
    }

    final validDeltas = _getValidDeltas();
    final oldestTimestamp = _getOldestTimestamp();
    final newestTimestamp = _getNewestTimestamp();

    return {
      'isInitialized': _isInitialized,
      'status': _status.name,
      'totalEntries': _deltaBox!.length,
      'validEntries': validDeltas.length,
      'oldestEntry': oldestTimestamp?.toIso8601String(),
      'newestEntry': newestTimestamp?.toIso8601String(),
      'bufferDurationHours':
          oldestTimestamp != null && newestTimestamp != null
              ? newestTimestamp.difference(oldestTimestamp).inHours
              : 0,
      'maxBufferHours': _config.maxBufferDuration.inHours,
      'capacityUsed': (_deltaBox!.length / _config.maxBufferSize * 100).round(),
    };
  }

  /// Start periodic cleanup of expired deltas
  void _startPeriodicCleanup() {
    _cleanupTimer = Timer.periodic(_config.cleanupInterval, (_) async {
      await _cleanupExpiredDeltas();
    });
  }

  /// Clean up expired deltas (older than 2 hours)
  Future<void> _cleanupExpiredDeltas() async {
    if (!_isInitialized || _deltaBox == null) return;

    try {
      _status = BufferStatus.cleaning;

      final cutoffTime =
          DateTime.now()
              .subtract(_config.maxBufferDuration)
              .millisecondsSinceEpoch;

      final keysToRemove = <dynamic>[];

      for (final entry in _deltaBox!.toMap().entries) {
        final data = entry.value;
        final timestamp = data['timestamp'] as int?;

        if (timestamp != null && timestamp < cutoffTime) {
          keysToRemove.add(entry.key);
        }
      }

      if (keysToRemove.isNotEmpty) {
        await _deltaBox!.deleteAll(keysToRemove);
        debugPrint('🧹 Cleaned up ${keysToRemove.length} expired deltas');
      }

      _status = BufferStatus.ready;
    } catch (e) {
      _status = BufferStatus.error;
      debugPrint('❌ Failed to cleanup expired deltas: $e');
    }
  }

  /// Remove oldest deltas to make space
  Future<void> _removeOldestDeltas(int count) async {
    if (!_isInitialized || _deltaBox == null) return;

    final entries = _deltaBox!.toMap().entries.toList();
    entries.sort((a, b) {
      final aTime = a.value['timestamp'] as int? ?? 0;
      final bTime = b.value['timestamp'] as int? ?? 0;
      return aTime.compareTo(bTime);
    });

    final keysToRemove = entries.take(count).map((e) => e.key).toList();

    if (keysToRemove.isNotEmpty) {
      await _deltaBox!.deleteAll(keysToRemove);
    }
  }

  /// Get valid deltas that are not expired
  List<WearableLiveMessage> _getValidDeltas() {
    if (!_isInitialized || _deltaBox == null) return [];

    final cutoffTime =
        DateTime.now()
            .subtract(_config.maxBufferDuration)
            .millisecondsSinceEpoch;

    final validDeltas = <WearableLiveMessage>[];

    for (final entry in _deltaBox!.values) {
      final data = entry;
      final timestamp = data['timestamp'] as int?;
      final deltaJson = data['delta'] as Map<String, dynamic>?;

      if (timestamp != null && timestamp >= cutoffTime && deltaJson != null) {
        try {
          final delta = WearableLiveMessage.fromJson(deltaJson);
          validDeltas.add(delta);
        } catch (e) {
          debugPrint('⚠️ Failed to parse buffered delta: $e');
        }
      }
    }

    return validDeltas;
  }

  /// Get timestamp of oldest entry
  DateTime? _getOldestTimestamp() {
    if (!_isInitialized || _deltaBox == null || _deltaBox!.isEmpty) return null;

    int? oldestTime;
    for (final entry in _deltaBox!.values) {
      final data = entry;
      final timestamp = data['timestamp'] as int?;
      if (timestamp != null && (oldestTime == null || timestamp < oldestTime)) {
        oldestTime = timestamp;
      }
    }

    return oldestTime != null
        ? DateTime.fromMillisecondsSinceEpoch(oldestTime)
        : null;
  }

  /// Get timestamp of newest entry
  DateTime? _getNewestTimestamp() {
    if (!_isInitialized || _deltaBox == null || _deltaBox!.isEmpty) return null;

    int? newestTime;
    for (final entry in _deltaBox!.values) {
      final data = entry;
      final timestamp = data['timestamp'] as int?;
      if (timestamp != null && (newestTime == null || timestamp > newestTime)) {
        newestTime = timestamp;
      }
    }

    return newestTime != null
        ? DateTime.fromMillisecondsSinceEpoch(newestTime)
        : null;
  }

  /// Dispose resources
  Future<void> dispose() async {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;

    _status = BufferStatus.ready;
    debugPrint('🧹 WearableOfflineBuffer disposed');
  }

  /// For testing: Clear instance
  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  /// Current buffer status
  BufferStatus get status => _status;

  /// Whether buffer is initialized
  bool get isInitialized => _isInitialized;

  /// Current configuration
  WearableOfflineBufferConfig get config => _config;
}
