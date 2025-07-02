

import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/services/wearable_live_models.dart';
import 'package:app/core/services/wearable_data_models.dart';

void main() {
  group('WearableLiveMessage', () {
    test('creates from JSON payload correctly', () {
      final json = {
        'timestamp': '2025-01-14T15:30:45.123Z',
        'type': 'heartRate',
        'value': 72,
        'source': 'Garmin Connect',
      };

      final message = WearableLiveMessage.fromJson(json);

      expect(
        message.timestamp,
        equals(DateTime.parse('2025-01-14T15:30:45.123Z')),
      );
      expect(message.type, equals(WearableDataType.heartRate));
      expect(message.value, equals(72));
      expect(message.source, equals('Garmin Connect'));
    });

    test('converts to JSON payload correctly', () {
      final message = WearableLiveMessage(
        timestamp: DateTime.parse('2025-01-14T15:30:45.123Z'),
        type: WearableDataType.steps,
        value: 1250,
        source: 'Apple Health',
      );

      final json = message.toJson();

      expect(json['timestamp'], equals('2025-01-14T15:30:45.123Z'));
      expect(json['type'], equals('steps'));
      expect(json['value'], equals(1250));
      expect(json['source'], equals('Apple Health'));
    });

    test('creates from HealthSample correctly', () {
      final healthSample = HealthSample(
        id: 'test_123',
        type: WearableDataType.heartRate,
        value: 75,
        unit: 'bpm',
        timestamp: DateTime.parse('2025-01-14T15:30:45.123Z'),
        source: 'Test Device',
      );

      final message = WearableLiveMessage.fromHealthSample(healthSample);

      expect(message.timestamp, equals(healthSample.timestamp));
      expect(message.type, equals(healthSample.type));
      expect(message.value, equals(healthSample.value));
      expect(message.source, equals(healthSample.source));
    });
  });

  group('WearableLiveMessageBatch', () {
    test('converts to JSON correctly', () {
      final messages = [
        WearableLiveMessage(
          timestamp: DateTime.parse('2025-01-14T15:30:45.123Z'),
          type: WearableDataType.heartRate,
          value: 72,
          source: 'Test Device',
        ),
      ];

      final batch = WearableLiveMessageBatch(
        batchId: 'batch_123',
        messages: messages,
        createdAt: DateTime.parse('2025-01-14T15:30:45.123Z'),
      );

      final json = batch.toJson();

      expect(json['batch_id'], equals('batch_123'));
      expect(json['count'], equals(1));
      expect(json['messages'], isA<List>());
      expect(json['created_at'], equals('2025-01-14T15:30:45.123Z'));
    });

    test('creates from JSON correctly', () {
      final json = {
        'batch_id': 'batch_456',
        'created_at': '2025-01-14T15:30:45.123Z',
        'messages': [
          {
            'timestamp': '2025-01-14T15:30:45.123Z',
            'type': 'steps',
            'value': 100,
            'source': 'Test Device',
          },
        ],
      };

      final batch = WearableLiveMessageBatch.fromJson(json);

      expect(batch.batchId, equals('batch_456'));
      expect(batch.messages.length, equals(1));
      expect(batch.messages.first.type, equals(WearableDataType.steps));
    });
  });
}
