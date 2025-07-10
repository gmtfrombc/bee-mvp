import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:app/features/onboarding/ui/mindset_page.dart';
import 'package:app/features/onboarding/onboarding_controller.dart';
import 'package:app/l10n/s.dart';

void main() {
  group('MindsetPage', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    Widget createTestWidget() {
      return UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en')],
          home: MindsetPage(),
        ),
      );
    }

    testWidgets('renders all question prompts', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.textContaining('want to make changes'), findsOneWidget);
      expect(find.textContaining('satisfying'), findsOneWidget);
      expect(find.textContaining('challenge'), findsOneWidget);
      expect(find.textContaining('coach'), findsOneWidget);
    });

    testWidgets('selection updates controller state', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final controller = container.read(onboardingControllerProvider.notifier);

      // Tap first option of each section
      Future<void> scrollAndTap(String key) async {
        final finder = find.byKey(ValueKey(key));
        await tester.scrollUntilVisible(
          finder,
          500.0,
          scrollable: find.byType(Scrollable),
        );
        await tester.tap(finder);
        await tester.pump();
      }

      await scrollAndTap('feel_better_radio');
      await scrollAndTap('proud_radio');
      await scrollAndTap('keep_going_radio');
      await scrollAndTap('right_hand_radio');

      expect(controller.state.motivationReason, 'feel_better');
      expect(controller.state.satisfactionOutcome, 'proud');
      expect(controller.state.challengeResponse, 'keep_going');
      expect(controller.state.mindsetType, 'right_hand');
    });

    testWidgets('continue button enables when all selections made', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      final continueBtn = find.byKey(const ValueKey('continue_button'));
      expect(tester.widget<ElevatedButton>(continueBtn).onPressed, isNull);

      final controller = container.read(onboardingControllerProvider.notifier);
      controller.updateMotivationReason('feel_better');
      controller.updateSatisfactionOutcome('proud');
      controller.updateChallengeResponse('keep_going');
      controller.updateMindsetType('right_hand');
      await tester.pump();

      expect(tester.widget<ElevatedButton>(continueBtn).onPressed, isNotNull);
    });
  });
}
