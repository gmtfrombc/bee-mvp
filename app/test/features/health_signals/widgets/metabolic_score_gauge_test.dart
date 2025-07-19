import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/health_signals/widgets/metabolic_score_gauge.dart';

void main() {
  group('MetabolicScoreGauge', () {
    testWidgets('renders "<10" when value is below 10', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: Center(child: MetabolicScoreGauge(mhs: 8.4))),
          ),
        ),
      );

      expect(find.text('<10'), findsOneWidget);
    });

    testWidgets('renders integer-rounded value when ≥ 10', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: Center(child: MetabolicScoreGauge(mhs: 65.2))),
          ),
        ),
      );

      // Rounded to 65 (nearest integer string)
      expect(find.text('65'), findsOneWidget);
    });
  });
}
