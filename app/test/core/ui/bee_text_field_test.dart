import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/ui/widgets/bee_text_field.dart';

void main() {
  group('BeeTextField', () {
    testWidgets('renders label and hint text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BeeTextField(label: 'Email', hint: 'Enter email'),
          ),
        ),
      );

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Enter email'), findsOneWidget);
    });

    testWidgets('obscureText toggle switches icon visibility', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BeeTextField(label: 'Password', obscureText: true),
          ),
        ),
      );

      // Initially the visibility icon should be shown (text obscured)
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsNothing);

      // Tap the visibility icon to reveal text
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();

      // Icon should switch to visibility_off
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('validator displays error message', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: BeeTextField(
                label: 'Name',
                validator:
                    (value) =>
                        (value == null || value.isEmpty) ? 'Required' : null,
              ),
            ),
          ),
        ),
      );

      // Trigger validation
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();

      // Error message should appear
      expect(find.text('Required'), findsOneWidget);
    });
  });
}
