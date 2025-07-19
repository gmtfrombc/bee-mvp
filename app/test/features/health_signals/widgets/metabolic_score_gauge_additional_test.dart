import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/health_signals/widgets/metabolic_score_gauge.dart';

void main() {
  group('MetabolicScoreGauge additional coverage', () {
    testWidgets('displays correct band label for “On Track” category', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: Center(child: MetabolicScoreGauge(mhs: 45))),
          ),
        ),
      );

      // Band label “On Track” should be present in the widget tree.
      expect(find.text('On Track'), findsOneWidget);
    });

    testWidgets('semantics label contains readable value and category', (
      tester,
    ) async {
      // Enables semantics testing.
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: Center(child: MetabolicScoreGauge(mhs: 8))),
          ),
        ),
      );

      // Retrieve the SemanticsNode for the gauge.
      final finder = find.byType(MetabolicScoreGauge);
      expect(finder, findsOneWidget);
      final node = tester.getSemantics(finder);

      // Semantics label should follow the pattern: "Metabolic health score <10 percent, First Gear".
      expect(node.label, contains('<10'));
      expect(node.label, contains('First Gear'));

      handle.dispose();
    });
  });
}
