import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/health_signals/biometrics/presentation/biometric_manual_input_form.dart';

void main() {
  testWidgets('Save button disabled until all required fields filled', (
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

    final saveButtonFinder = find.widgetWithText(ElevatedButton, 'Save');
    expect(tester.widget<ElevatedButton>(saveButtonFinder).onPressed, isNull);

    // Enter weight.
    await tester.enterText(find.byType(TextFormField).at(0), '70');
    await tester.pump();
    expect(tester.widget<ElevatedButton>(saveButtonFinder).onPressed, isNull);

    // Enter height.
    await tester.enterText(find.byType(TextFormField).at(1), '175');
    await tester.pump();
    // After height, BMI should appear.
    expect(find.textContaining('BMI:'), findsOneWidget);

    // Still disabled because glucose missing.
    expect(tester.widget<ElevatedButton>(saveButtonFinder).onPressed, isNull);

    // Enter fasting glucose.
    // The new FG/A1C field is now at index 2.
    await tester.enterText(find.byType(TextFormField).at(2), '95');
    await tester.pump();
    expect(
      tester.widget<ElevatedButton>(saveButtonFinder).onPressed,
      isNotNull,
    );
  });
}
