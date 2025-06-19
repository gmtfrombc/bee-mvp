/// Simplified unit tests for VitalsNotifierService.
/// Focuses on happy-path verification and state changes as per testing policy.
library;

import 'dart:async';

import 'package:app/core/services/vitals_notifier_service.dart';
import 'package:app/core/services/wearable_data_models.dart';
import 'package:app/core/services/wearable_data_repository.dart';
import 'package:app/core/services/wearable_live_service.dart';
import 'package:app/core/services/wearable_live_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mocks
class MockWearableLiveService extends Mock implements WearableLiveService {}

class MockWearableDataRepository extends Mock
    implements WearableDataRepository {}

void main() {
  // Register fallback for mocktail so `any<WearableDataType>()` works.
  setUpAll(() {
    registerFallbackValue(WearableDataType.steps);
  });

  late VitalsNotifierService service;
  late MockWearableLiveService mockLiveService;
  late MockWearableDataRepository mockRepository;

  setUp(() {
    mockLiveService = MockWearableLiveService();
    mockRepository = MockWearableDataRepository();

    // Mock WearableLiveService – use an open StreamController so the
    // stream does not complete immediately (which would trigger an
    // unexpected disconnection status inside the service).
    final controller = StreamController<List<WearableLiveMessage>>.broadcast();
    addTearDown(controller.close);

    when(
      () => mockLiveService.messageStream,
    ).thenAnswer((_) => controller.stream);
    when(
      () => mockLiveService.startStreaming(any()),
    ).thenAnswer((_) async => true);
    when(() => mockLiveService.stopStreaming()).thenAnswer((_) async {});

    // Mock WearableDataRepository
    when(() => mockRepository.initialize()).thenAnswer((_) async => true);
    when(
      () => mockRepository.getHealthData(
        dataTypes: any(named: 'dataTypes'),
        startTime: any(named: 'startTime'),
        endTime: any(named: 'endTime'),
      ),
    ).thenAnswer((_) async => const HealthDataQueryResult(samples: []));

    // Provide fallback for getLatestSample used in bootstrap paths.
    when(() => mockRepository.getLatestSample(any())).thenAnswer(
      (_) async => HealthSample(
        id: 'dummy_hr',
        type: WearableDataType.heartRate,
        value: 70,
        unit: 'bpm',
        timestamp: DateTime(2020, 1, 1),
        source: 'Mock',
      ),
    );

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
          dataTypes: any(named: 'dataTypes'),
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
        ),
      );
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
