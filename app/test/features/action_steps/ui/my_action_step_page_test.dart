import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/action_steps/ui/my_action_step_page.dart';
import 'package:app/features/action_steps/data/action_step_repository.dart';
import 'package:app/features/action_steps/models/action_step.dart';

void main() {
  group('MyActionStepPage', () {
    testWidgets('shows NoStepView when no Action Step', (tester) async {
      final noStepOverride = currentActionStepProvider.overrideWith(
        (ref) async => null,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [noStepOverride],
          child: const MaterialApp(home: MyActionStepPage()),
        ),
      );

      // Allow FutureProvider to complete.
      await tester.pumpAndSettle();

      expect(find.text("You haven't set an Action Step yet."), findsOneWidget);
      expect(find.text('Set Up Now'), findsOneWidget);
    });

    testWidgets('shows Action Step details when data available', (
      tester,
    ) async {
      final now = DateTime.now().toUtc();
      const completed = 3;
      const target = 5;

      final step = ActionStep(
        id: 'abc',
        category: 'movement',
        description: 'Walk 5k steps',
        frequency: target,
        weekStart: now,
        createdAt: now,
        updatedAt: now,
      );
      final current = CurrentActionStep(step: step, completed: completed);

      final dataOverride = currentActionStepProvider.overrideWith(
        (ref) async => current,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [dataOverride],
          child: const MaterialApp(home: MyActionStepPage()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Walk 5k steps'), findsOneWidget);
      expect(find.text('$completed / $target this week'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });
  });
}
