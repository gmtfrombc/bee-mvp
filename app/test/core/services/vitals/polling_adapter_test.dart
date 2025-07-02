import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app/core/services/vitals/adapters/polling_adapter.dart';
import 'package:app/core/services/vitals/processing/vitals_aggregator.dart';
import 'package:app/core/services/wearable_data_repository.dart';
import 'package:app/core/services/wearable_data_models.dart';
// already imported this earlier, HealthSyncConfig included.

class _MockRepo extends Mock implements WearableDataRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PollingAdapter', () {
    late _MockRepo repo;
    late VitalsAggregator agg;
    late PollingAdapter adapter;

    setUp(() {
      repo = _MockRepo();
      agg = VitalsAggregator();

      when(() => repo.isInitialized).thenReturn(true);
      when(() => repo.config).thenReturn(HealthSyncConfig.defaultConfig);
    });

    test('polls repository and forwards samples to aggregator', () async {
      final sample = HealthSample(
        id: 's1',
        type: WearableDataType.steps,
        value: 123,
        unit: 'count',
        timestamp: DateTime.now(),
        endTime: null,
        source: 'watch',
      );

      when(
        () => repo.getHealthData(
          dataTypes: any(named: 'dataTypes'),
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
        ),
      ).thenAnswer((_) async => HealthDataQueryResult(samples: [sample]));

      adapter = PollingAdapter(
        repository: repo,
        aggregator: agg,
        interval: const Duration(milliseconds: 50),
      );

      await adapter.start();
      await Future.delayed(const Duration(milliseconds: 60));

      expect(agg.current?.steps, 123);

      await adapter.stop();
    });
  });
}
