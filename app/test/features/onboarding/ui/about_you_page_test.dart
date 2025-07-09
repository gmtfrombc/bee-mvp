// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/onboarding/ui/about_you_page.dart';

void main() {
  testWidgets(
    'Continue button should be disabled until form fields are valid',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: AboutYouPage())),
      );

      final ElevatedButton continueBtn = tester.widget(
        find.byKey(const ValueKey('continue_button')),
      );

      expect(continueBtn.onPressed, isNull);
    },
  );
}
