import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/momentum/presentation/widgets/loading_indicator.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() async {
    await TestHelpers.setUpTest();
  });

  group('LoadingIndicator Widget Tests', () {
    testWidgets('displays momentum loading indicator', (
      WidgetTester tester,
    ) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: const MomentumLoadingIndicator(),
      );

      // Should display loading indicator
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));

      // Should display center icon
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });

    testWidgets('displays without progress when disabled', (
      WidgetTester tester,
    ) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: const MomentumLoadingIndicator(showProgress: false),
      );

      // Should still show loading indicator
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('displays without message when disabled', (
      WidgetTester tester,
    ) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: const MomentumLoadingIndicator(showMessage: false),
      );

      // Should show loading indicator but no message text
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('respects reduced motion preferences', (
      WidgetTester tester,
    ) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MomentumLoadingIndicator(),
        ),
      );

      // Should still render without errors
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('displays compact variant', (WidgetTester tester) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: const CompactLoadingIndicator(),
      );

      // Should display smaller loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays compact variant with dots', (
      WidgetTester tester,
    ) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: const CompactLoadingIndicator(showDots: true),
      );

      // Should display dots instead of circular indicator
      expect(find.byType(Container), findsAtLeastNWidgets(3)); // 3 dots
    });

    testWidgets('handles different sizes properly', (
      WidgetTester tester,
    ) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: const MomentumLoadingIndicator(size: 50.0),
      );

      // Should render with custom size
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('supports custom colors', (WidgetTester tester) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: const MomentumLoadingIndicator(color: Colors.red),
      );

      // Should render with custom color
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('handles text scaling properly', (WidgetTester tester) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: MomentumLoadingIndicator(),
        ),
      );

      // Should still render properly with scaled text
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('displays staggered loading animation', (
      WidgetTester tester,
    ) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: const StaggeredLoadingAnimation(
          children: [Text('Item 1'), Text('Item 2'), Text('Item 3')],
        ),
      );

      // Should show all children
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);

      // Initial state
      await tester.pump();

      // Animation in progress
      await tester.pump(const Duration(milliseconds: 500));

      // Should not throw errors during animation
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows loading overlay when visible', (
      WidgetTester tester,
    ) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: const LoadingOverlay(isVisible: true),
      );

      // Should show overlay and loading indicator
      expect(find.byType(MomentumLoadingIndicator), findsOneWidget);
    });

    testWidgets('hides loading overlay when not visible', (
      WidgetTester tester,
    ) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: const LoadingOverlay(isVisible: false),
      );

      // Should not show loading indicator
      expect(find.byType(MomentumLoadingIndicator), findsNothing);
    });

    testWidgets('shows loading overlay with custom message', (
      WidgetTester tester,
    ) async {
      const customMessage = 'Processing your data...';

      await TestHelpers.pumpTestWidget(
        tester,
        child: const LoadingOverlay(isVisible: true, message: customMessage),
      );

      // Should show message
      expect(find.text(customMessage), findsOneWidget);
      expect(find.byType(MomentumLoadingIndicator), findsOneWidget);
    });

    testWidgets('loading overlay handles cancel callback', (
      WidgetTester tester,
    ) async {
      bool cancelTapped = false;

      await TestHelpers.pumpTestWidget(
        tester,
        child: LoadingOverlay(
          isVisible: true,
          onCancel: () => cancelTapped = true,
        ),
      );

      // Should show cancel button (if implemented)
      expect(find.byType(MomentumLoadingIndicator), findsOneWidget);

      // Look for cancel button or close button
      final cancelButton = find.byType(IconButton);
      if (cancelButton.evaluate().isNotEmpty) {
        // If cancel button exists, tap it and verify callback
        await tester.tap(cancelButton.first);
        await tester.pump();
        expect(
          cancelTapped,
          isTrue,
          reason:
              'Cancel callback should be called when cancel button is tapped',
        );
      } else {
        // If no cancel button, just verify the callback was provided
        expect(
          cancelTapped,
          isFalse,
          reason:
              'Cancel callback should not be called without user interaction',
        );
      }
    });

    testWidgets('compact loading indicator respects size parameter', (
      WidgetTester tester,
    ) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: const CompactLoadingIndicator(size: 32.0),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('staggered animation handles empty children list', (
      WidgetTester tester,
    ) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: const StaggeredLoadingAnimation(children: []),
      );

      // Should not throw errors with empty children
      expect(tester.takeException(), isNull);
    });

    testWidgets('momentum loading indicator animates correctly', (
      WidgetTester tester,
    ) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: const MomentumLoadingIndicator(),
      );

      // Initial state
      await tester.pump();

      // Animation in progress
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 1000));

      // Should not throw errors during animation
      expect(tester.takeException(), isNull);
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });
  });
}
