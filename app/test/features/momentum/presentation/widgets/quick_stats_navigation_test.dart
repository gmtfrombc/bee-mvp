import 'package:app/features/momentum/domain/models/momentum_data.dart';
import 'package:app/features/momentum/presentation/widgets/quick_stats_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Tapping Action Step card navigates to Setup route', (tester) async {
    // Arrange – minimal MomentumStats object for widget.
    const stats = MomentumStats(
      lessonsCompleted: 0,
      totalLessons: 0,
      streakDays: 0,
      todayMinutes: 0,
    );

    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/action-step/setup': (_) => const Scaffold(body: Text('Setup Page')),
        },
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return QuickStatsCards(
                stats: stats,
                onActionStepTap: () {
                  Navigator.of(context).pushNamed('/action-step/setup');
                },
              );
            },
          ),
        ),
      ),
    );

    // Act – tap on the "Action Step" stat card label.
    await tester.tap(find.text('Action Step'));
    await tester.pumpAndSettle();

    // Assert – navigation succeeded.
    expect(find.text('Setup Page'), findsOneWidget);
  });
} 