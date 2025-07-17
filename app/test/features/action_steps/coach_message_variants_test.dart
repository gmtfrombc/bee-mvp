import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:app/features/action_steps/services/action_step_coach_messenger.dart';
import 'package:app/l10n/s.dart';

void main() {
  group('ActionStepCoachMessenger', () {
    const messenger = ActionStepCoachMessenger();

    Widget buildTestApp() {
      return ProviderScope(
        child: MaterialApp(
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: Scaffold(
            body: Builder(
              builder:
                  (context) => Center(
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text('Test'),
                    ),
                  ),
            ),
          ),
        ),
      );
    }

    testWidgets('shows success coach snackbar', (tester) async {
      await tester.pumpWidget(buildTestApp());
      final scaffoldContext = tester.element(find.byType(Scaffold));

      // Act
      expect(
        () => messenger.sendSuccessMessage(scaffoldContext),
        returnsNormally,
      );
    });

    testWidgets('shows failure coach snackbar', (tester) async {
      await tester.pumpWidget(buildTestApp());
      final scaffoldContext = tester.element(find.byType(Scaffold));

      // Act
      expect(
        () => messenger.sendFailureMessage(scaffoldContext),
        returnsNormally,
      );
    });
  });
}
