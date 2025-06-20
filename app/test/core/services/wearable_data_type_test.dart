import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/services/wearable_data_models.dart';
import 'package:health/health.dart';

void main() {
  group('WearableDataType mapping', () {
    test('fromHealthDataType maps correctly', () {
      expect(
        WearableDataType.fromHealthDataType(HealthDataType.STEPS),
        WearableDataType.steps,
      );
      expect(
        WearableDataType.fromHealthDataType(HealthDataType.HEART_RATE),
        WearableDataType.heartRate,
      );
    });

    test('toHealthDataType reverse maps correctly', () {
      expect(WearableDataType.steps.toHealthDataType(), HealthDataType.STEPS);
      expect(
        WearableDataType.heartRate.toHealthDataType(),
        HealthDataType.HEART_RATE,
      );
    });
  });
}
