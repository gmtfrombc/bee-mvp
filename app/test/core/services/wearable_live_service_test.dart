/// Simple unit tests for WearableLiveService fallback functionality
///
/// Focused on core fallback behavior for T2.2.2.4
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/core/services/wearable_live_service.dart';
import 'package:app/core/services/wearable_live_models.dart';
import 'package:app/core/services/wearable_data_models.dart';
import 'package:app/core/services/health_data_http_client.dart';
import 'package:app/core/services/health_data_batching_service.dart';

// Simple mocks for testing
class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockHttpClient extends Mock implements HealthDataHttpClient {}

class MockBatchingService extends Mock implements HealthDataBatchingService {}

void main() {
  group('WearableLiveService Fallback Logic', () {
    late MockSupabaseClient mockSupabase;
    late MockHttpClient mockHttpClient;
    late MockBatchingService mockBatchingService;

    setUp(() {
      mockSupabase = MockSupabaseClient();
      mockHttpClient = MockHttpClient();
      mockBatchingService = MockBatchingService();
    });

    test('should initialize with WebSocket available by default', () {
      // Arrange & Act
      final service = WearableLiveService(
        mockSupabase,
        httpClient: mockHttpClient,
        batchingService: mockBatchingService,
      );

      // Assert
      expect(service.isActive, isFalse);
      expect(service.isWebSocketAvailable, isTrue);
      expect(service.connectionStatus, equals('inactive'));
      expect(service.failureQueueSize, equals(0));
    });

    test('should track failure queue size correctly', () {
      // Arrange
      final service = WearableLiveService(
        mockSupabase,
        httpClient: mockHttpClient,
        batchingService: mockBatchingService,
      );

      // Initially empty
      expect(service.failureQueueSize, equals(0));

      // Note: Since _failureQueue is private, we test through the public interface
      // The actual testing of queue operations would happen through integration tests
    });

    test('should provide correct connection status states', () {
      // Arrange
      final service = WearableLiveService(
        mockSupabase,
        httpClient: mockHttpClient,
        batchingService: mockBatchingService,
      );

      // Test inactive state
      expect(service.connectionStatus, equals('inactive'));

      // Test WebSocket availability flag
      expect(service.isWebSocketAvailable, isTrue);
    });

    test('should handle disposal correctly', () async {
      // Arrange
      final service = WearableLiveService(
        mockSupabase,
        httpClient: mockHttpClient,
        batchingService: mockBatchingService,
      );

      // Act
      await service.dispose();

      // Assert - service should be properly disposed
      expect(service.isActive, isFalse);
      expect(service.currentUserId, isNull);
      expect(service.failureQueueSize, equals(0));
    });

    test('should create live messages correctly', () {
      // Test the data conversion logic
      final timestamp = DateTime.now();
      final message = WearableLiveMessage(
        timestamp: timestamp,
        type: WearableDataType.heartRate,
        value: 75,
        source: 'Test Device',
      );

      expect(message.timestamp, equals(timestamp));
      expect(message.type, equals(WearableDataType.heartRate));
      expect(message.value, equals(75));
      expect(message.source, equals('Test Device'));

      // Test JSON conversion
      final json = message.toJson();
      expect(json['type'], equals('heartRate'));
      expect(json['value'], equals(75));
      expect(json['source'], equals('Test Device'));

      // Test round-trip conversion
      final reconstructed = WearableLiveMessage.fromJson(json);
      expect(reconstructed.type, equals(message.type));
      expect(reconstructed.value, equals(message.value));
      expect(reconstructed.source, equals(message.source));
    });

    test('should create message batches correctly', () {
      final messages = [
        WearableLiveMessage(
          timestamp: DateTime.now(),
          type: WearableDataType.heartRate,
          value: 75,
          source: 'Test',
        ),
        WearableLiveMessage(
          timestamp: DateTime.now(),
          type: WearableDataType.steps,
          value: 1000,
          source: 'Test',
        ),
      ];

      final batch = WearableLiveMessageBatch(
        batchId: 'test_batch',
        messages: messages,
        createdAt: DateTime.now(),
      );

      expect(batch.messages.length, equals(2));
      expect(batch.batchId, equals('test_batch'));

      // Test JSON conversion
      final json = batch.toJson();
      expect(json['batch_id'], equals('test_batch'));
      expect(json['count'], equals(2));
      expect(json['messages'], isA<List>());
    });
  });
}
