import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/health_signals/biometrics/presentation/biometric_manual_input_form.dart';

void main() {
  testWidgets('BMI auto-calc persists across FG→A1C toggle edge case', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: BiometricManualInputForm()),
          ),
        ),
      ),
    );

    // Enter weight (kg)
    await tester.enterText(find.byType(TextFormField).at(0), '70');
    await tester.pump();

    // Enter height (cm)
    await tester.enterText(find.byType(TextFormField).at(1), '175');
    await tester.pump();

    // BMI text should appear.
    expect(find.textContaining('BMI:'), findsOneWidget);

    // Enter fasting glucose (mg/dL).
    await tester.enterText(find.byType(TextFormField).at(2), '95');
    await tester.pump();

    // Toggle A1C switch ON.
    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);
    await tester.tap(switchFinder, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Enter A1C value.
    await tester.enterText(find.byType(TextFormField).last, '5.4');
    await tester.pump();

    // BMI text should still be visible.
    expect(find.textContaining('BMI:'), findsOneWidget);

    // Save button should be present (enabled state tested in separate widget tests).
    expect(find.widgetWithText(ElevatedButton, 'Save'), findsOneWidget);
  });
}
