import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:app/features/onboarding/ui/readiness_page.dart';
import 'package:app/features/onboarding/onboarding_controller.dart';
import 'package:app/core/widgets/likert_selector.dart';
import 'package:app/l10n/s.dart';

void main() {
  group('ReadinessPage', () {
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
          home: ReadinessPage(),
        ),
      );
    }

    testWidgets('renders all required sections', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check app bar
      expect(find.text('Readiness & Priorities'), findsOneWidget);

      // Check priority selection section
      expect(find.text('Select your top 1-2 priorities:'), findsOneWidget);

      // Check Likert selectors for readiness and confidence
      expect(find.byType(LikertSelector), findsNWidgets(2));

      // Check continue button
      expect(find.byKey(const ValueKey('continue_button')), findsOneWidget);
    });

    testWidgets('priority selection updates controller state', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Initially no priorities selected
      final controller = container.read(onboardingControllerProvider.notifier);
      expect(controller.state.priorities, isEmpty);

      // Tap nutrition chip
      await tester.tap(find.byKey(const ValueKey('priority_nutrition')));
      await tester.pump();

      // Verify priority was added
      expect(controller.state.priorities, contains('nutrition'));

      // Tap exercise chip
      await tester.tap(find.byKey(const ValueKey('priority_exercise')));
      await tester.pump();

      // Verify both priorities are selected
      expect(controller.state.priorities, hasLength(2));
      expect(controller.state.priorities, contains('nutrition'));
      expect(controller.state.priorities, contains('exercise'));
    });

    testWidgets('enforces max 2 priority selections', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final controller = container.read(onboardingControllerProvider.notifier);

      // Select first two priorities
      await tester.tap(find.byKey(const ValueKey('priority_nutrition')));
      await tester.tap(find.byKey(const ValueKey('priority_exercise')));
      await tester.pump();

      expect(controller.state.priorities, hasLength(2));

      // Try to select third priority - should not be added
      await tester.tap(find.byKey(const ValueKey('priority_sleep')));
      await tester.pump();

      expect(controller.state.priorities, hasLength(2));
      expect(controller.state.priorities, isNot(contains('sleep')));
    });

    testWidgets('Likert selectors update readiness and confidence levels', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      final controller = container.read(onboardingControllerProvider.notifier);

      // Initially no levels set
      expect(controller.state.readinessLevel, isNull);
      expect(controller.state.confidenceLevel, isNull);

      // Find and interact with Likert selectors
      final likertSelectors = find.byType(LikertSelector);
      expect(likertSelectors, findsNWidgets(2));

      // Test readiness level (first Likert selector)
      await tester.tap(likertSelectors.first);
      await tester.pump();

      // Simulate selecting value 4 on first selector
      controller.updateReadinessLevel(4);
      await tester.pump();

      expect(controller.state.readinessLevel, equals(4));

      // Test confidence level (second Likert selector)
      controller.updateConfidenceLevel(3);
      await tester.pump();

      expect(controller.state.confidenceLevel, equals(3));
    });

    testWidgets('continue button enabled when all fields completed', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      final controller = container.read(onboardingControllerProvider.notifier);
      final continueButton = find.byKey(const ValueKey('continue_button'));

      // Initially disabled
      expect(tester.widget<ElevatedButton>(continueButton).onPressed, isNull);

      // Complete all required fields
      controller.togglePriority('nutrition');
      controller.updateReadinessLevel(4);
      controller.updateConfidenceLevel(3);
      await tester.pump();

      // Should now be enabled
      expect(
        tester.widget<ElevatedButton>(continueButton).onPressed,
        isNotNull,
      );
    });

    testWidgets('continue button triggers navigation without snackbar', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      final controller = container.read(onboardingControllerProvider.notifier);

      // Complete all required fields
      controller.togglePriority('nutrition');
      controller.updateReadinessLevel(4);
      controller.updateConfidenceLevel(3);
      await tester.pumpAndSettle();

      // Scroll to make continue button visible
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('continue_button')),
        500.0,
        scrollable: find.byType(Scrollable),
      );

      // Tap continue button
      await tester.tap(find.byKey(const ValueKey('continue_button')));
      await tester.pumpAndSettle();

      // Snackbar should NOT appear (UI cleaned up)
      expect(find.text('Readiness assessment saved!'), findsNothing);
    });

    testWidgets('priority chips display correct labels', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check all priority labels are displayed correctly
      expect(find.text('Nutrition'), findsOneWidget);
      expect(find.text('Exercise'), findsOneWidget);
      expect(find.text('Sleep'), findsOneWidget);
      expect(find.text('Stress'), findsOneWidget);
      expect(find.text('Weight'), findsOneWidget);
      expect(find.text('Energy'), findsOneWidget);
      expect(find.text('Mental Health'), findsOneWidget);
    });

    testWidgets('serialization maintains state without data loss', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      final controller = container.read(onboardingControllerProvider.notifier);

      // Set test data
      controller.togglePriority('nutrition');
      controller.togglePriority('exercise');
      controller.updateReadinessLevel(4);
      controller.updateConfidenceLevel(3);

      // Serialize and deserialize
      final json = controller.state.toJson();
      expect(json['priorities'], equals(['nutrition', 'exercise']));
      expect(json['readinessLevel'], equals(4));
      expect(json['confidenceLevel'], equals(3));
    });
  });
}
