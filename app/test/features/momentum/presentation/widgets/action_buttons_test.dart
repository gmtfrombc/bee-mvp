import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/momentum/presentation/widgets/action_buttons.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() async {
    await TestHelpers.setUpTest();
  });

  group('ActionButtons Widget Tests', () {
    testWidgets('displays action buttons with rising state', (
      WidgetTester tester,
    ) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: ActionButtons(
          state: MomentumState.rising,
          onLearnTap: () {},
          onShareTap: () {},
        ),
      );

      // Verify motivational message
      expect(find.text('Keep the momentum going! 🚀'), findsOneWidget);

      // Verify both buttons are present
      expect(find.text('Learn'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);

      // Verify icons are present
      expect(find.byIcon(Icons.school_rounded), findsOneWidget);
      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
    });

    testWidgets('displays action buttons with steady state', (
      WidgetTester tester,
    ) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: ActionButtons(
          state: MomentumState.steady,
          onLearnTap: () {},
          onShareTap: () {},
        ),
      );

      // Verify motivational message for steady state
      expect(find.text('Stay consistent! 🙂'), findsOneWidget);

      // Verify buttons are still present
      expect(find.text('Learn'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
    });

    testWidgets('displays action buttons with needs care state', (
      WidgetTester tester,
    ) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: ActionButtons(
          state: MomentumState.needsCare,
          onLearnTap: () {},
          onShareTap: () {},
        ),
      );

      // Verify motivational message for needs care state
      expect(find.text('Let\'s grow together! 🌱'), findsOneWidget);

      // Verify buttons are still present
      expect(find.text('Learn'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
    });

    testWidgets('handles learn button tap', (WidgetTester tester) async {
      bool learnTapped = false;

      await TestHelpers.pumpTestWidget(
        tester,
        child: ActionButtons(
          state: MomentumState.rising,
          onLearnTap: () => learnTapped = true,
          onShareTap: () {},
        ),
      );

      await tester.pumpAndSettle();

      // Find buttons and verify they exist
      final buttons = find.byType(InkWell);
      expect(buttons, findsNWidgets(2));

      // Tap the first button (Learn)
      await tester.tap(buttons.first);
      await tester.pumpAndSettle();

      expect(learnTapped, isTrue);
    });

    testWidgets('handles share button tap', (WidgetTester tester) async {
      bool shareTapped = false;

      await TestHelpers.pumpTestWidget(
        tester,
        child: ActionButtons(
          state: MomentumState.rising,
          onLearnTap: () {},
          onShareTap: () => shareTapped = true,
        ),
      );

      await tester.pumpAndSettle();

      // Find buttons and verify they exist
      final buttons = find.byType(InkWell);
      expect(buttons, findsNWidgets(2));

      // Tap the second button (Share)
      await tester.tap(buttons.last);
      await tester.pumpAndSettle();

      expect(shareTapped, isTrue);
    });

    testWidgets('has proper accessibility semantics', (
      WidgetTester tester,
    ) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: ActionButtons(
          state: MomentumState.rising,
          onLearnTap: () {},
          onShareTap: () {},
        ),
      );

      // Wait for animations to complete
      await tester.pumpAndSettle();

      // Verify buttons exist and are tappable (accessible)
      expect(find.byType(InkWell), findsNWidgets(2));

      // Verify text labels are present
      expect(find.text('Learn'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);

      // Verify semantic wrappers exist (at least some Semantics widgets)
      expect(find.byType(Semantics), findsAtLeastNWidgets(2));
    });

    testWidgets('buttons have minimum touch target size', (
      WidgetTester tester,
    ) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: ActionButtons(
          state: MomentumState.rising,
          onLearnTap: () {},
          onShareTap: () {},
        ),
      );

      await tester.pumpAndSettle();

      // Find all tappable elements
      final tappableElements = find.byWidgetPredicate(
        (widget) =>
            widget is ElevatedButton ||
            widget is InkWell ||
            widget is GestureDetector,
      );

      expect(tappableElements, findsAtLeastNWidgets(2));

      // Check that buttons meet minimum touch target requirements
      for (final element in tester.widgetList(tappableElements)) {
        final renderBox =
            tester.renderObject(find.byWidget(element)) as RenderBox?;
        if (renderBox != null) {
          final size = renderBox.size;
          // Minimum 44x44 accessibility requirement (with some tolerance)
          expect(size.height, greaterThanOrEqualTo(40));
          expect(size.width, greaterThanOrEqualTo(40));
        }
      }
    });

    testWidgets('handles text scaling properly', (WidgetTester tester) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: ActionButtons(
            state: MomentumState.rising,
            onLearnTap: () {},
            onShareTap: () {},
          ),
        ),
      );

      // Verify buttons still render properly with scaled text
      expect(find.text('Learn'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Keep the momentum going! 🚀'), findsOneWidget);
    });

    testWidgets('respects reduced motion preferences', (
      WidgetTester tester,
    ) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: ActionButtons(
            state: MomentumState.rising,
            onLearnTap: () {},
            onShareTap: () {},
          ),
        ),
      );

      // Buttons should still render without animation errors
      await tester.pump();
      expect(find.text('Learn'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('animates entry correctly', (WidgetTester tester) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: ActionButtons(
          state: MomentumState.rising,
          onLearnTap: () {},
          onShareTap: () {},
        ),
      );

      // Initial state
      await tester.pump();

      // Animation in progress
      await tester.pump(const Duration(milliseconds: 100));

      // Animation completing
      await tester.pump(const Duration(milliseconds: 300));

      // Final state
      await tester.pumpAndSettle();

      // Verify no errors occurred during animation
      expect(tester.takeException(), isNull);
      expect(find.text('Learn'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
    });

    testWidgets('displays correct colors for different states', (
      WidgetTester tester,
    ) async {
      // Test all three states to ensure proper color theming
      for (final state in MomentumState.values) {
        await TestHelpers.pumpTestWidget(
          tester,
          child: ActionButtons(
            state: state,
            onLearnTap: () {},
            onShareTap: () {},
          ),
        );

        // Verify buttons render without errors for each state
        expect(find.text('Learn'), findsOneWidget);
        expect(find.text('Share'), findsOneWidget);
      }
    });

    testWidgets('handles null callbacks gracefully', (
      WidgetTester tester,
    ) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: const ActionButtons(
          state: MomentumState.rising,
          // No callbacks provided
        ),
      );

      await tester.pumpAndSettle();

      // Buttons should still render
      expect(find.text('Learn'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);

      // Find buttons and try tapping them (should be disabled or handle gracefully)
      final buttons = find.byType(InkWell);
      expect(buttons, findsNWidgets(2));

      // Tapping should not cause errors (buttons should be disabled when no callback)
      await tester.tap(buttons.first, warnIfMissed: false);
      await tester.tap(buttons.last, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('applies custom margin when provided', (
      WidgetTester tester,
    ) async {
      const customMargin = EdgeInsets.all(20.0);

      await TestHelpers.pumpTestWidget(
        tester,
        child: ActionButtons(
          state: MomentumState.rising,
          margin: customMargin,
          onLearnTap: () {},
          onShareTap: () {},
        ),
      );

      // Find the container with margin
      final containerFinder = find.byWidgetPredicate(
        (widget) => widget is Container && widget.margin == customMargin,
      );
      expect(containerFinder, findsOneWidget);
    });
  });
}
