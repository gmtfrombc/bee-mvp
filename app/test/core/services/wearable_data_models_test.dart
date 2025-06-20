import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/services/wearable_data_models.dart';

void main() {
  group('HealthSample serialization', () {
    test('toMap and fromMap should be inverses', () {
      final sample = HealthSample(
        id: 'sample_1',
        type: WearableDataType.steps,
        value: 1234,
        unit: 'count',
        timestamp: DateTime.utc(2024, 1, 1, 12, 0, 0),
        endTime: DateTime.utc(2024, 1, 1, 12, 5, 0),
        source: 'Garmin Connect',
        metadata: {'unitTest': true},
      );

      final map = sample.toMap();
      final fromMap = HealthSample.fromMap(map);

      expect(fromMap.id, sample.id);
      expect(fromMap.type, sample.type);
      expect(fromMap.value, sample.value);
      expect(fromMap.unit, sample.unit);
      expect(fromMap.timestamp, sample.timestamp);
      expect(fromMap.endTime, sample.endTime);
      expect(fromMap.source, sample.source);
      expect(fromMap.metadata, sample.metadata);
    });
  });
}
