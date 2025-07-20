import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/utils/health_permission_utils.dart';
import 'package:app/core/services/wearable_data_models.dart';
import 'package:health/health.dart';

void main() {
  group('health_permission_utils', () {
    test('friendlyWearableName maps common types', () {
      expect(friendlyWearableName(WearableDataType.steps), 'Steps');
      expect(friendlyWearableName(WearableDataType.heartRate), 'Heart Rate');
    });

    test('mapToHealthDataType returns non-null mapping', () {
      expect(mapToHealthDataType(WearableDataType.steps), HealthDataType.STEPS);
    });

    test('buildMissingPermissionMessage contains type names', () {
      final msg = buildMissingPermissionMessage([WearableDataType.steps]);
      expect(msg.contains('Steps'), isTrue);
    });
  });
}
