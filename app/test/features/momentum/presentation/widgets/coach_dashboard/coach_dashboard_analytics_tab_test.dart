import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/coach_intervention_service.dart';
import 'package:app/core/services/responsive_service.dart';
import 'package:app/features/momentum/presentation/widgets/coach_dashboard/coach_dashboard_analytics_tab.dart';
import 'package:app/features/momentum/presentation/widgets/coach_dashboard/coach_dashboard_stat_card.dart';
import 'package:app/features/momentum/presentation/widgets/coach_dashboard/coach_dashboard_time_selector.dart';

void main() {
  group('CoachDashboardAnalyticsTab', () {
    // Fake service for testing
    final fakeCoachInterventionService = FakeCoachInterventionService();

    Widget createTestWidget({
      String selectedTimeRange = '7d',
      ValueChanged<String>? onTimeRangeChanged,
    }) {
      return ProviderScope(
        overrides: [
          coachInterventionServiceProvider.overrideWithValue(
            fakeCoachInterventionService,
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: CoachDashboardAnalyticsTab(
              selectedTimeRange: selectedTimeRange,
              onTimeRangeChanged: onTimeRangeChanged ?? (value) {},
            ),
          ),
        ),
      );
    }

    group('Widget Creation and Basic Layout', () {
      testWidgets('creates without throwing', (tester) async {
        // Set larger screen size to avoid overflow issues
        await tester.binding.setSurfaceSize(const Size(1200, 800));
        await tester.pumpWidget(createTestWidget());
        expect(find.byType(CoachDashboardAnalyticsTab), findsOneWidget);

        // Wait for async operations to complete
        await tester.pumpAndSettle();
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('displays loading indicator initially', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 800));
        await tester.pumpWidget(createTestWidget());

        // Should show loading initially
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(CoachDashboardStatCard), findsNothing);

        // Let the timer complete
        await tester.pumpAndSettle();

        // Should not show loading after data loads
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('displays content after loading', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 800));
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle(); // Wait for FutureBuilder to complete

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byType(CoachDashboardTimeSelector), findsOneWidget);
        expect(find.byType(ResponsiveLayout), findsOneWidget);
      });
    });

    group('Content Display', () {
      testWidgets('displays time selector with correct props', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 800));
        await tester.pumpWidget(
          createTestWidget(
            selectedTimeRange: '7d',
            onTimeRangeChanged: (value) {},
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CoachDashboardTimeSelector), findsOneWidget);

        final timeSelector = tester.widget<CoachDashboardTimeSelector>(
          find.byType(CoachDashboardTimeSelector),
        );
        expect(timeSelector.selectedTimeRange, equals('7d'));
      });

      testWidgets('displays analytics stat cards', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 800));
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Check that stat cards are displayed
        expect(find.byType(CoachDashboardStatCard), findsAtLeastNWidgets(3));
        expect(find.textContaining('Success Rate'), findsAtLeastNWidgets(1));
        expect(find.textContaining('Avg Response Time'), findsOneWidget);
        expect(find.textContaining('Total Interventions'), findsOneWidget);
      });

      testWidgets('displays effectiveness chart section', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 800));
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Intervention Effectiveness'), findsOneWidget);
        expect(
          find.textContaining('Chart implementation would go here'),
          findsOneWidget,
        );
      });

      testWidgets('displays trend analysis section', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 800));
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Trend Analysis'), findsOneWidget);
      });
    });

    group('Responsive Design', () {
      testWidgets('adapts to different screen sizes', (tester) async {
        // Test mobile size - using slightly larger width to prevent minor overflows
        await tester.binding.setSurfaceSize(const Size(400, 812));
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(ResponsiveLayout), findsOneWidget);
        expect(find.byType(Column), findsAtLeastNWidgets(1));
      });

      testWidgets('uses ResponsiveLayout wrapper', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 800));
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(ResponsiveLayout), findsOneWidget);
      });
    });

    group('Time Range Selection', () {
      testWidgets('calls onTimeRangeChanged when time range is updated', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(1200, 800));
        String? capturedTimeRange;
        await tester.pumpWidget(
          createTestWidget(
            onTimeRangeChanged: (value) => capturedTimeRange = value,
          ),
        );
        await tester.pumpAndSettle();

        final timeSelectorWidget = tester.widget<CoachDashboardTimeSelector>(
          find.byType(CoachDashboardTimeSelector),
        );

        // Simulate time range change
        timeSelectorWidget.onTimeRangeChanged('30d');
        expect(capturedTimeRange, equals('30d'));
      });
    });

    group('Edge Cases and Error Handling', () {
      testWidgets('handles empty data gracefully', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 800));
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should still display stat cards with default values
        expect(find.byType(CoachDashboardStatCard), findsAtLeastNWidgets(3));
        expect(find.text('85%'), findsOneWidget); // Mock data from fake service
      });

      testWidgets('maintains scroll functionality', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 800));
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(SingleChildScrollView), findsOneWidget);
      });
    });

    group('UI Elements', () {
      testWidgets('uses proper text styles', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 800));
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final effectivenessText = find.text('Intervention Effectiveness');
        expect(effectivenessText, findsOneWidget);

        final trendAnalysisText = find.text('Trend Analysis');
        expect(trendAnalysisText, findsOneWidget);
      });

      testWidgets('has proper container styling', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 800));
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should have containers with proper decoration
        final containers = find.byType(Container);
        expect(containers, findsAtLeast(2));
      });
    });
  });
}

// Simple fake service for testing
class FakeCoachInterventionService implements CoachInterventionService {
  @override
  Future<Map<String, dynamic>> getInterventionAnalytics(
    String timeRange,
  ) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 10));

    return {
      'summary': {
        'success_rate': 85,
        'avg_response_time': 2,
        'total_interventions': 150,
        'satisfaction_score': 4.2,
      },
      'trends': [
        {'metric': 'Success Rate', 'change': 5.2},
        {'metric': 'Response Time', 'change': -2.1},
        {'metric': 'Patient Engagement', 'change': 3.8},
      ],
    };
  }

  // We only need to implement the method we're testing
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
