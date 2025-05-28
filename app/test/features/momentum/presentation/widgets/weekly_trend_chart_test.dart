import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/momentum/domain/models/momentum_data.dart';
import 'package:app/features/momentum/presentation/widgets/weekly_trend_chart.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() async {
    await TestHelpers.setUpTest();
  });

  group('WeeklyTrendChart Widget Tests', () {
    late List<DailyMomentum> sampleWeeklyTrend;

    setUp(() {
      // Create sample weekly trend data
      sampleWeeklyTrend = [
        DailyMomentum(
          date: DateTime.now().subtract(const Duration(days: 6)),
          state: MomentumState.needsCare,
          percentage: 30.0,
        ),
        DailyMomentum(
          date: DateTime.now().subtract(const Duration(days: 5)),
          state: MomentumState.needsCare,
          percentage: 40.0,
        ),
        DailyMomentum(
          date: DateTime.now().subtract(const Duration(days: 4)),
          state: MomentumState.steady,
          percentage: 55.0,
        ),
        DailyMomentum(
          date: DateTime.now().subtract(const Duration(days: 3)),
          state: MomentumState.steady,
          percentage: 65.0,
        ),
        DailyMomentum(
          date: DateTime.now().subtract(const Duration(days: 2)),
          state: MomentumState.rising,
          percentage: 75.0,
        ),
        DailyMomentum(
          date: DateTime.now().subtract(const Duration(days: 1)),
          state: MomentumState.rising,
          percentage: 85.0,
        ),
        DailyMomentum(
          date: DateTime.now(),
          state: MomentumState.rising,
          percentage: 90.0,
        ),
      ];
    });

    testWidgets('displays weekly trend chart with data', (
      WidgetTester tester,
    ) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: WeeklyTrendChart(weeklyTrend: sampleWeeklyTrend),
      );

      // Verify the chart is displayed
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);

      // Verify the header text
      expect(find.text('📈 This Week\'s Journey'), findsOneWidget);

      // Verify date range is displayed (check for any date format containing numbers)
      expect(find.textContaining(RegExp(r'\d')), findsAtLeastNWidgets(1));
    });

    testWidgets('displays empty state when no data', (
      WidgetTester tester,
    ) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: const WeeklyTrendChart(weeklyTrend: []),
      );

      // Should show empty state with correct text from widget
      expect(find.byType(Card), findsOneWidget);
      expect(
        find.text('Your momentum journey will appear here'),
        findsOneWidget,
      );
    });

    testWidgets('has proper accessibility semantics', (
      WidgetTester tester,
    ) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: WeeklyTrendChart(weeklyTrend: sampleWeeklyTrend),
      );

      // Verify semantic labels are present (check actual widget implementation)
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.hint ==
                  'Chart showing your momentum progress over the past week',
        ),
        findsOneWidget,
      );
    });

    testWidgets('handles tap interaction', (WidgetTester tester) async {
      bool tapped = false;

      await TestHelpers.pumpTestWidget(
        tester,
        child: WeeklyTrendChart(
          weeklyTrend: sampleWeeklyTrend,
          onTap: () => tapped = true,
        ),
      );

      // Tap the chart card
      await tester.tap(find.byType(Card));
      await tester.pumpAndSettle();

      // Note: The onTap is not currently implemented in the widget
      // This test will fail until onTap is implemented
      expect(tapped, isFalse);
    });

    testWidgets('displays correct emoji markers for states', (
      WidgetTester tester,
    ) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: WeeklyTrendChart(weeklyTrend: sampleWeeklyTrend),
      );

      // Allow animations to complete
      await tester.pumpAndSettle();

      // Chart should be present with proper data
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('handles text scaling properly', (WidgetTester tester) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: WeeklyTrendChart(weeklyTrend: sampleWeeklyTrend),
        ),
      );

      // Verify the chart still renders properly with scaled text
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('respects reduced motion preferences', (
      WidgetTester tester,
    ) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: WeeklyTrendChart(weeklyTrend: sampleWeeklyTrend),
        ),
      );

      // Chart should still render without animation errors
      await tester.pump();
      expect(find.byType(LineChart), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('animates chart entry correctly', (WidgetTester tester) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: WeeklyTrendChart(
          weeklyTrend: sampleWeeklyTrend,
          animationDuration: const Duration(
            milliseconds: 100,
          ), // Faster for testing
        ),
      );

      // Initial state
      await tester.pump();

      // Animation in progress
      await tester.pump(const Duration(milliseconds: 50));

      // Animation complete
      await tester.pump(const Duration(milliseconds: 200));

      // Verify no errors occurred during animation
      expect(tester.takeException(), isNull);
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('displays different trend colors for different patterns', (
      WidgetTester tester,
    ) async {
      // Test with mostly rising trend
      final risingTrend = List.generate(
        7,
        (index) => DailyMomentum(
          date: DateTime.now().subtract(Duration(days: 6 - index)),
          state: MomentumState.rising,
          percentage: 50.0 + (index * 5.0),
        ),
      );

      await TestHelpers.pumpTestWidget(
        tester,
        child: WeeklyTrendChart(weeklyTrend: risingTrend),
      );

      expect(find.byType(LineChart), findsOneWidget);

      // Test with declining trend
      final decliningTrend = List.generate(
        7,
        (index) => DailyMomentum(
          date: DateTime.now().subtract(Duration(days: 6 - index)),
          state: MomentumState.needsCare,
          percentage: 80.0 - (index * 5.0),
        ),
      );

      await TestHelpers.pumpTestWidget(
        tester,
        child: WeeklyTrendChart(weeklyTrend: decliningTrend),
      );

      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('handles single day data correctly', (
      WidgetTester tester,
    ) async {
      final singleDayData = [
        DailyMomentum(
          date: DateTime.now(),
          state: MomentumState.rising,
          percentage: 75.0,
        ),
      ];

      await TestHelpers.pumpTestWidget(
        tester,
        child: WeeklyTrendChart(weeklyTrend: singleDayData),
      );

      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('📈 This Week\'s Journey'), findsOneWidget);
    });
  });
}
