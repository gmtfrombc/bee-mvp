/// Simplified unit tests for VitalsNotifierService.
/// Focuses on happy-path verification and state changes as per testing policy.
library;

import 'dart:async';

import 'package:app/core/services/vitals_notifier_service.dart';
import 'package:app/core/services/wearable_data_models.dart';
import 'package:app/core/services/wearable_data_repository.dart';
import 'package:app/core/services/wearable_live_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mocks
class MockWearableLiveService extends Mock implements WearableLiveService {}

class MockWearableDataRepository extends Mock
    implements WearableDataRepository {}

void main() {
  late VitalsNotifierService service;
  late MockWearableLiveService mockLiveService;
  late MockWearableDataRepository mockRepository;

  setUp(() {
    mockLiveService = MockWearableLiveService();
    mockRepository = MockWearableDataRepository();

    // Mock WearableLiveService
    when(
      () => mockLiveService.messageStream,
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => mockLiveService.startStreaming(any()),
    ).thenAnswer((_) async => true);
    when(() => mockLiveService.stopStreaming()).thenAnswer((_) async {});

    // Mock WearableDataRepository
    when(() => mockRepository.initialize()).thenAnswer((_) async => true);
    when(
      () => mockRepository.getHealthData(
        startTime: any(named: 'startTime'),
        endTime: any(named: 'endTime'),
      ),
    ).thenAnswer((_) async => const HealthDataQueryResult(samples: []));

    service = VitalsNotifierService(mockLiveService, mockRepository);

    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    service.dispose();
  });

  test('initializes correctly', () async {
    final result = await service.initialize();
    expect(result, isTrue);
    expect(service.isActive, isFalse);
    verify(() => mockRepository.initialize()).called(1);
  });

  test(
    'startSubscription uses real-time mode by default (happy path)',
    () async {
      await service.initialize();
      await service.startSubscription('test_user');

      verify(() => mockLiveService.startStreaming('test_user')).called(1);
      expect(service.connectionStatus, VitalsConnectionStatus.connected);
    },
  );

  test(
    'startSubscription uses polling mode when enabled (happy path)',
    () async {
      SharedPreferences.setMockInitialValues({
        VitalsNotifierService.adaptivePollingPrefKey: true,
      });
      await service.initialize();
      await service.startSubscription('test_user');

      verifyNever(() => mockLiveService.startStreaming(any()));
      verify(
        () => mockRepository.getHealthData(
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
        ),
      ).called(1);
      expect(service.connectionStatus, VitalsConnectionStatus.polling);
    },
  );

  test('stopSubscription cleans up real-time subscription', () async {
    await service.initialize();
    await service.startSubscription('test_user');
    await service.stopSubscription();

    verify(() => mockLiveService.stopStreaming()).called(1);
    expect(service.isActive, isFalse);
  });

  test('stopSubscription cleans up polling subscription', () async {
    SharedPreferences.setMockInitialValues({
      VitalsNotifierService.adaptivePollingPrefKey: true,
    });
    await service.initialize();
    await service.startSubscription('test_user');
    await service.stopSubscription();

    // In polling mode, stopStreaming should not be called.
    verifyNever(() => mockLiveService.stopStreaming());
    expect(service.isActive, isFalse);
  });
}
