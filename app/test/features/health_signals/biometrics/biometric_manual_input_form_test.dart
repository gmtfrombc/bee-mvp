import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/health_signals/biometrics/presentation/biometric_manual_input_form.dart';

void main() {
  testWidgets('Save button disabled until both fields filled', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: BiometricManualInputForm())),
      ),
    );

    // Initially disabled.
    final saveButtonFinder = find.text('Save');
    ElevatedButton btn = tester.widget<ElevatedButton>(saveButtonFinder);
    expect(btn.onPressed, isNull);

    // Enter weight.
    await tester.enterText(find.byType(TextFormField).at(0), '70');
    await tester.pump();
    btn = tester.widget<ElevatedButton>(saveButtonFinder);
    expect(btn.onPressed, isNull);

    // Enter height.
    await tester.enterText(find.byType(TextFormField).at(1), '175');
    await tester.pump();
    btn = tester.widget<ElevatedButton>(saveButtonFinder);
    expect(btn.onPressed, isNotNull);
  });
}
