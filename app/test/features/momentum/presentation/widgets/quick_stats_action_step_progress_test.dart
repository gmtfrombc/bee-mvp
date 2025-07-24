import 'package:app/features/momentum/domain/models/momentum_data.dart';
import 'package:app/features/momentum/presentation/widgets/quick_stats_cards.dart';
import 'package:app/features/action_steps/data/action_step_repository.dart';
import 'package:app/features/action_steps/models/action_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('QuickStatsCards displays Action Step progress', (tester) async {
    // Arrange – set up fake current action step data.
    final fakeCurrent = CurrentActionStep(
      step: ActionStep(
        id: 'step-1',
        category: 'fitness',
        description: 'Walk 10k steps',
        frequency: 7,
        weekStart: DateTime.parse('2025-07-14'),
        createdAt: DateTime.parse('2025-07-14T00:00:00Z'),
        updatedAt: DateTime.parse('2025-07-14T00:00:00Z'),
      ),
      completed: 3,
    );

    // Override provider to return fake data immediately.
    final overrides = <Override>[
      currentActionStepProvider.overrideWith((ref) async => fakeCurrent),
    ];

    // Minimal MomentumStats object
    const stats = MomentumStats(
      lessonsCompleted: 0,
      totalLessons: 0,
      streakDays: 0,
      todayMinutes: 0,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: const MaterialApp(
          home: Scaffold(
            body: QuickStatsCards(stats: stats),
          ),
        ),
      ),
    );
    // Allow any animations/microtasks.
    await tester.pumpAndSettle();

    // Assert – progress text is displayed.
    expect(find.text('3/7'), findsOneWidget);
  });
} 