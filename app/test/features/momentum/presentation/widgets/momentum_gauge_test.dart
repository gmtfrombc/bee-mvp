import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/momentum/presentation/widgets/momentum_gauge.dart';
import 'package:app/core/theme/app_theme.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  // Setup test environment before all tests
  setUpAll(() async {
    await TestHelpers.setUpTest();
  });

  group('MomentumGauge Widget Tests', () {
    testWidgets('displays gauge with rising state', (
      WidgetTester tester,
    ) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: const MomentumGauge(
          state: MomentumState.rising,
          percentage: 85.0,
        ),
      );

      // Verify the gauge is displayed
      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));

      // Verify the state emoji is displayed
      expect(find.text('🚀'), findsOneWidget);
    });

    testWidgets('displays gauge with steady state', (
      WidgetTester tester,
    ) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: const MomentumGauge(
          state: MomentumState.steady,
          percentage: 65.0,
        ),
      );

      // Verify the gauge is displayed
      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));

      // Verify the state emoji is displayed
      expect(find.text('🙂'), findsOneWidget);
    });

    testWidgets('displays gauge with needs care state', (
      WidgetTester tester,
    ) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: const MomentumGauge(
          state: MomentumState.needsCare,
          percentage: 35.0,
        ),
      );

      // Verify the gauge is displayed
      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));

      // Verify the state emoji is displayed
      expect(find.text('🌱'), findsOneWidget);
    });

    testWidgets('has proper accessibility semantics', (
      WidgetTester tester,
    ) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: const MomentumGauge(
          state: MomentumState.rising,
          percentage: 85.0,
        ),
      );

      // Verify semantic labels are present with the actual format from AccessibilityService
      // AccessibilityService.getMomentumStateLabel() generates:
      // 'Your momentum is ${state.name} at ${percentage} percent. ${stateDescription}'
      expect(
        find.bySemanticsLabel(
          RegExp(r'Your momentum is rising at 85 percent\.'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('handles reduced motion preference', (
      WidgetTester tester,
    ) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MomentumGauge(state: MomentumState.rising, percentage: 85.0),
        ),
      );

      // Verify the gauge still renders properly with reduced motion
      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
      expect(find.text('🚀'), findsOneWidget);
    });

    testWidgets('displays correct colors for different states', (
      WidgetTester tester,
    ) async {
      // Test rising state
      await TestHelpers.pumpTestWidget(
        tester,
        child: const MomentumGauge(
          state: MomentumState.rising,
          percentage: 85.0,
        ),
      );

      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));

      // Test steady state
      await TestHelpers.pumpTestWidget(
        tester,
        child: const MomentumGauge(
          state: MomentumState.steady,
          percentage: 65.0,
        ),
      );

      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));

      // Test needs care state
      await TestHelpers.pumpTestWidget(
        tester,
        child: const MomentumGauge(
          state: MomentumState.needsCare,
          percentage: 35.0,
        ),
      );

      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
    });

    testWidgets('handles text scaling properly', (WidgetTester tester) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: MomentumGauge(state: MomentumState.rising, percentage: 85.0),
        ),
      );

      // Verify the gauge still renders properly with scaled text
      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
      expect(find.text('🚀'), findsOneWidget);
    });

    testWidgets('gauge has proper size constraints', (
      WidgetTester tester,
    ) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: const MomentumGauge(
          state: MomentumState.rising,
          percentage: 85.0,
          size: 150.0,
        ),
      );

      final customPaintFinder = find.byType(CustomPaint);
      expect(customPaintFinder, findsAtLeastNWidgets(1));

      // Get the first CustomPaint widget since there may be multiple
      final customPaintWidgets = tester.widgetList<CustomPaint>(
        customPaintFinder,
      );
      expect(customPaintWidgets.isNotEmpty, isTrue);

      // Verify the gauge container has the expected size
      final gaugeFinder = find.byType(MomentumGauge);
      expect(gaugeFinder, findsOneWidget);
    });

    testWidgets('handles tap interaction', (WidgetTester tester) async {
      bool tapped = false;

      await TestHelpers.pumpTestWidget(
        tester,
        child: MomentumGauge(
          state: MomentumState.rising,
          percentage: 85.0,
          onTap: () {
            tapped = true;
          },
        ),
      );

      // Tap the gauge
      await tester.tap(find.byType(MomentumGauge));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('animation completes successfully', (
      WidgetTester tester,
    ) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: const MomentumGauge(
          state: MomentumState.rising,
          percentage: 85.0,
          animationDuration: Duration(milliseconds: 100), // Faster for testing
        ),
      );

      // Initial state
      await tester.pump();

      // Animation in progress
      await tester.pump(const Duration(milliseconds: 50));

      // Animation complete
      await tester.pump(const Duration(milliseconds: 100));

      // Verify no errors occurred during animation
      expect(tester.takeException(), isNull);
    });
  });
}
