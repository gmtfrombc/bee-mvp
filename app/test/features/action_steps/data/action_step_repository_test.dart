import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/action_steps/models/action_step.dart';

void main() {
  group('ActionStep model', () {
    test('fromJson maps correctly', () {
      final now = DateTime.now().toUtc();
      final json = {
        'id': '123',
        'category': 'movement',
        'description': 'Walk 5k steps',
        'frequency': 5,
        'week_start': now.toIso8601String(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final model = ActionStep.fromJson(json);
      expect(model.id, '123');
      expect(model.category, 'movement');
      expect(model.frequency, 5);
      expect(model.weekStart, now);
    });
  });
}
