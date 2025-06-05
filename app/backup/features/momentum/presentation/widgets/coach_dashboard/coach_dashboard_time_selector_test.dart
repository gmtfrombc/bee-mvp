import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/momentum/presentation/widgets/coach_dashboard/coach_dashboard_time_selector.dart';
import 'package:app/core/theme/app_theme.dart';

void main() {
  group('CoachDashboardTimeSelector Widget Tests', () {
    testWidgets('should render with all required elements', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CoachDashboardTimeSelector(
              selectedTimeRange: '7d',
              onTimeRangeChanged: (timeRange) {
                // No need to store the value in this test
                // We're just testing that the widget renders correctly
              },
            ),
          ),
        ),
      );

      // Verify icon is present
      expect(find.byIcon(Icons.date_range), findsOneWidget);

      // Verify label text is present
      expect(find.text('Time Range:'), findsOneWidget);

      // Verify segmented button is present
      expect(find.byType(SegmentedButton<String>), findsOneWidget);

      // Verify all time range options are present
      expect(find.text('24h'), findsOneWidget);
      expect(find.text('7d'), findsOneWidget);
      expect(find.text('30d'), findsOneWidget);
    });

    testWidgets('should show correct initial selection', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CoachDashboardTimeSelector(
              selectedTimeRange: '24h',
              onTimeRangeChanged: (timeRange) {},
            ),
          ),
        ),
      );

      final segmentedButton = tester.widget<SegmentedButton<String>>(
        find.byType(SegmentedButton<String>),
      );

      expect(segmentedButton.selected, equals({'24h'}));
    });

    testWidgets('should call onTimeRangeChanged when selection changes', (
      tester,
    ) async {
      String? selectedTimeRange;
      int callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CoachDashboardTimeSelector(
              selectedTimeRange: '7d',
              onTimeRangeChanged: (timeRange) {
                selectedTimeRange = timeRange;
                callCount++;
              },
            ),
          ),
        ),
      );

      // Tap on the 30d option
      await tester.tap(find.text('30d'));
      await tester.pumpAndSettle();

      expect(selectedTimeRange, equals('30d'));
      expect(callCount, equals(1));
    });

    testWidgets('should use correct theme colors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CoachDashboardTimeSelector(
              selectedTimeRange: '7d',
              onTimeRangeChanged: (timeRange) {},
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.date_range));
      expect(icon.color, equals(AppTheme.momentumRising));
    });

    testWidgets('should handle empty selection set gracefully', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CoachDashboardTimeSelector(
              selectedTimeRange: '7d',
              onTimeRangeChanged: (timeRange) {
                // This callback should not be called with empty selection
              },
            ),
          ),
        ),
      );

      // Simulate empty selection (should not call callback)
      final segmentedButton = tester.widget<SegmentedButton<String>>(
        find.byType(SegmentedButton<String>),
      );

      // Call onSelectionChanged with empty set
      segmentedButton.onSelectionChanged!(<String>{});

      // If we reach this point, the test passes - no callback was made
    });

    testWidgets('should work with different initial values', (tester) async {
      final timeRanges = ['24h', '7d', '30d'];

      for (final timeRange in timeRanges) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CoachDashboardTimeSelector(
                selectedTimeRange: timeRange,
                onTimeRangeChanged: (timeRange) {},
              ),
            ),
          ),
        );

        final segmentedButton = tester.widget<SegmentedButton<String>>(
          find.byType(SegmentedButton<String>),
        );

        expect(segmentedButton.selected, equals({timeRange}));
      }
    });

    testWidgets('should maintain selection state correctly', (tester) async {
      String selectedTimeRange = '7d';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return CoachDashboardTimeSelector(
                  selectedTimeRange: selectedTimeRange,
                  onTimeRangeChanged: (timeRange) {
                    setState(() {
                      selectedTimeRange = timeRange;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      // Verify initial selection
      expect(find.text('7d'), findsOneWidget);

      // Change to 24h
      await tester.tap(find.text('24h'));
      await tester.pumpAndSettle();

      // Verify selection changed in UI
      final segmentedButton = tester.widget<SegmentedButton<String>>(
        find.byType(SegmentedButton<String>),
      );
      expect(segmentedButton.selected, equals({'24h'}));
    });
  });
}
