import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/action_steps/models/action_step.dart';
import 'package:app/features/action_steps/models/action_step_history_entry.dart';

void main() {
  group('ActionStepHistoryEntry', () {
    test('reachedGoal returns true when completed >= frequency', () {
      final step = ActionStep(
        id: '1',
        category: 'move',
        description: 'Walk',
        frequency: 5,
        weekStart: DateTime(2025, 1, 1),
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );
      final entry = ActionStepHistoryEntry(step: step, completed: 5);
      expect(entry.reachedGoal, isTrue);
    });

    test('reachedGoal returns false when completed < frequency', () {
      final step = ActionStep(
        id: '2',
        category: 'move',
        description: 'Run',
        frequency: 3,
        weekStart: DateTime(2025, 1, 1),
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );
      final entry = ActionStepHistoryEntry(step: step, completed: 2);
      expect(entry.reachedGoal, isFalse);
    });
  });
} 