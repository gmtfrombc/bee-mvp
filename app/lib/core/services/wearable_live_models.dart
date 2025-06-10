/// Wearable Live Data Models for Real-time Streaming
///
/// Models for WebSocket real-time data streaming following the specified
/// Part of Epic 2.2 Task T2.2.2.1
library;

import 'wearable_data_models.dart';

/// Core message for real-time wearable data streaming
class WearableLiveMessage {
  final DateTime timestamp;
  final WearableDataType type;
  final dynamic value;
  final String source;

  const WearableLiveMessage({
    required this.timestamp,
    required this.type,
    required this.value,
    required this.source,
  });

  /// Create from JSON payload (WebSocket message)
  factory WearableLiveMessage.fromJson(Map<String, dynamic> json) {
    return WearableLiveMessage(
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: WearableDataType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => WearableDataType.unknown,
      ),
      value: json['value'],
      source: json['source'] as String,
    );
  }

  /// Convert to JSON payload (WebSocket message)
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'value': value,
      'source': source,
    };
  }

  /// Create from HealthSample for real-time streaming
  factory WearableLiveMessage.fromHealthSample(HealthSample sample) {
    return WearableLiveMessage(
      timestamp: sample.timestamp,
      type: sample.type,
      value: sample.value,
      source: sample.source,
    );
  }

  @override
  String toString() {
    return 'WearableLiveMessage(timestamp: $timestamp, type: $type, value: $value, source: $source)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WearableLiveMessage &&
          runtimeType == other.runtimeType &&
          timestamp == other.timestamp &&
          type == other.type &&
          value == other.value &&
          source == other.source;

  @override
  int get hashCode => Object.hash(timestamp, type, value, source);
}

/// Batch of live messages for efficient transmission
class WearableLiveMessageBatch {
  final String batchId;
  final List<WearableLiveMessage> messages;
  final DateTime createdAt;

  const WearableLiveMessageBatch({
    required this.batchId,
    required this.messages,
    required this.createdAt,
  });

  /// Convert to JSON for WebSocket transmission
  Map<String, dynamic> toJson() {
    return {
      'batch_id': batchId,
      'messages': messages.map((m) => m.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'count': messages.length,
    };
  }

  /// Create from JSON payload
  factory WearableLiveMessageBatch.fromJson(Map<String, dynamic> json) {
    final messagesList =
        (json['messages'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(WearableLiveMessage.fromJson)
            .toList();

    return WearableLiveMessageBatch(
      batchId: json['batch_id'] as String,
      messages: messagesList,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Configuration for live data streaming
class WearableLiveConfig {
  final Duration publishInterval;
  final int maxBatchSize;
  final List<WearableDataType> enabledTypes;
  final bool enableBatching;

  const WearableLiveConfig({
    this.publishInterval = const Duration(seconds: 5),
    this.maxBatchSize = 10,
    this.enabledTypes = const [
      WearableDataType.heartRate,
      WearableDataType.steps,
      WearableDataType.sleepDuration,
    ],
    this.enableBatching = true,
  });

  /// Default configuration for BEE MVP
  static const WearableLiveConfig defaultConfig = WearableLiveConfig();
}
