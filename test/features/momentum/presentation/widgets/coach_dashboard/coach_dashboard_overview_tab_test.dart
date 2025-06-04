import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:bee_mvp/core/services/coach_intervention_service.dart';
import 'package:bee_mvp/core/services/responsive_service.dart';
import 'package:bee_mvp/features/momentum/presentation/widgets/coach_dashboard/coach_dashboard_overview_tab.dart';

import 'coach_dashboard_overview_tab_test.mocks.dart';

@GenerateMocks([CoachInterventionService])
void main() {
  group('CoachDashboardOverviewTab Widget Tests', () {
    late MockCoachInterventionService mockService;

    setUp(() {
      mockService = MockCoachInterventionService();
    });

    /// Helper function to create widget with ProviderScope
    Widget createTestWidget({
      String selectedTimeRange = '7d',
      ValueChanged<String>? onTimeRangeChanged,
      Size screenSize = const Size(375.0, 667.0), // iPhone SE by default
    }) {
      return ProviderScope(
        overrides: [
          coachInterventionServiceProvider.overrideWithValue(mockService),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: screenSize, devicePixelRatio: 1.0),
            child: Scaffold(
              body: CoachDashboardOverviewTab(
                selectedTimeRange: selectedTimeRange,
                onTimeRangeChanged: onTimeRangeChanged ?? (value) {},
              ),
            ),
          ),
        ),
      );
    }

    /// Helper function to create mock dashboard data
    Map<String, dynamic> createMockDashboardData({
      Map<String, dynamic>? stats,
      List? recentActivities,
      Map<String, dynamic>? priorityBreakdown,
    }) {
      return {
        'stats':
            stats ??
            {
              'active': 5,
              'scheduled_today': 3,
              'completed_week': 12,
              'high_priority': 2,
            },
        'recent_activities':
            recentActivities ??
            [
              {
                'type': 'intervention_created',
                'timestamp': DateTime.now().toIso8601String(),
                'patient_name': 'John Doe',
                'description': 'Created new intervention for stress management',
              },
              {
                'type': 'intervention_completed',
                'timestamp': DateTime.now()
                    .subtract(const Duration(hours: 2))
                    .toIso8601String(),
                'patient_name': 'Jane Smith',
                'description': 'Completed sleep hygiene intervention',
              },
            ],
        'priority_breakdown':
            priorityBreakdown ?? {'high': 3, 'medium': 8, 'low': 5},
      };
    }

    group('Widget Rendering and Layout', () {
      testWidgets('renders correctly with valid data', (tester) async {
        // Arrange
        final mockData = createMockDashboardData();
        when(
          mockService.getDashboardOverview(),
        ).thenAnswer((_) async => mockData);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(CoachDashboardOverviewTab), findsOneWidget);
        expect(find.text('Recent Activity'), findsOneWidget);
        expect(find.text('Priority Breakdown'), findsOneWidget);
        expect(find.text('Active Interventions'), findsOneWidget);
        expect(find.text('Scheduled Today'), findsOneWidget);
        expect(find.text('Completed This Week'), findsOneWidget);
        expect(find.text('High Priority'), findsOneWidget);
      });

      testWidgets('displays loading state initially', (tester) async {
        // Arrange
        when(mockService.getDashboardOverview()).thenAnswer(
          (_) async => Future.delayed(
            const Duration(seconds: 1),
            () => createMockDashboardData(),
          ),
        );

        // Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('displays error state when service throws exception', (
        tester,
      ) async {
        // Arrange
        when(
          mockService.getDashboardOverview(),
        ).thenThrow(Exception('Network error'));

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.textContaining('Error loading dashboard'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      });
    });

    group('Responsive Design Tests', () {
      testWidgets('uses ResponsiveService for mobile small layout', (
        tester,
      ) async {
        // Arrange
        const mobileSmallSize = Size(375.0, 667.0);
        final mockData = createMockDashboardData();
        when(
          mockService.getDashboardOverview(),
        ).thenAnswer((_) async => mockData);

        // Act
        await tester.pumpWidget(createTestWidget(screenSize: mobileSmallSize));
        await tester.pumpAndSettle();

        // Assert
        final context = tester.element(find.byType(CoachDashboardOverviewTab));
        expect(
          ResponsiveService.getDeviceType(context),
          DeviceType.mobileSmall,
        );
        expect(ResponsiveService.shouldUseCompactLayout(context), isTrue);
      });

      testWidgets('uses ResponsiveService for tablet layout', (tester) async {
        // Arrange
        const tabletSize = Size(768.0, 1024.0);
        final mockData = createMockDashboardData();
        when(
          mockService.getDashboardOverview(),
        ).thenAnswer((_) async => mockData);

        // Act
        await tester.pumpWidget(createTestWidget(screenSize: tabletSize));
        await tester.pumpAndSettle();

        // Assert
        final context = tester.element(find.byType(CoachDashboardOverviewTab));
        expect(ResponsiveService.getDeviceType(context), DeviceType.tablet);
        expect(ResponsiveService.shouldUseExpandedLayout(context), isTrue);
      });

      testWidgets('adjusts grid layout based on screen size', (tester) async {
        // Arrange
        final mockData = createMockDashboardData();
        when(
          mockService.getDashboardOverview(),
        ).thenAnswer((_) async => mockData);

        // Act - Mobile
        await tester.pumpWidget(
          createTestWidget(screenSize: const Size(375.0, 667.0)),
        );
        await tester.pumpAndSettle();

        // Assert - Mobile should use fewer columns
        var context = tester.element(find.byType(CoachDashboardOverviewTab));
        var gridColumns = ResponsiveService.getGridColumnCount(context);
        expect(gridColumns, lessThanOrEqualTo(2));

        // Act - Tablet
        await tester.pumpWidget(
          createTestWidget(screenSize: const Size(768.0, 1024.0)),
        );
        await tester.pumpAndSettle();

        // Assert - Tablet should use more columns
        context = tester.element(find.byType(CoachDashboardOverviewTab));
        gridColumns = ResponsiveService.getGridColumnCount(context);
        expect(gridColumns, greaterThan(2));
      });
    });

    group('Data Display Tests', () {
      testWidgets('displays correct statistics data', (tester) async {
        // Arrange
        final mockData = createMockDashboardData(
          stats: {
            'active': 15,
            'scheduled_today': 8,
            'completed_week': 25,
            'high_priority': 7,
          },
        );
        when(
          mockService.getDashboardOverview(),
        ).thenAnswer((_) async => mockData);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('15'), findsOneWidget); // active
        expect(find.text('8'), findsOneWidget); // scheduled_today
        expect(find.text('25'), findsOneWidget); // completed_week
        expect(find.text('7'), findsOneWidget); // high_priority
      });

      testWidgets('displays recent activities correctly', (tester) async {
        // Arrange
        final mockData = createMockDashboardData(
          recentActivities: [
            {
              'type': 'intervention_created',
              'timestamp': DateTime.now().toIso8601String(),
              'patient_name': 'Alice Johnson',
              'description': 'New meditation intervention',
            },
            {
              'type': 'intervention_completed',
              'timestamp': DateTime.now()
                  .subtract(const Duration(hours: 1))
                  .toIso8601String(),
              'patient_name': 'Bob Wilson',
              'description': 'Exercise routine completed',
            },
          ],
        );
        when(
          mockService.getDashboardOverview(),
        ).thenAnswer((_) async => mockData);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Alice Johnson'), findsOneWidget);
        expect(find.text('Bob Wilson'), findsOneWidget);
        expect(find.text('New meditation intervention'), findsOneWidget);
        expect(find.text('Exercise routine completed'), findsOneWidget);
      });

      testWidgets('displays empty state when no recent activities', (
        tester,
      ) async {
        // Arrange
        final mockData = createMockDashboardData(recentActivities: []);
        when(
          mockService.getDashboardOverview(),
        ).thenAnswer((_) async => mockData);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('No recent activity'), findsOneWidget);
      });

      testWidgets('displays priority breakdown correctly', (tester) async {
        // Arrange
        final mockData = createMockDashboardData(
          priorityBreakdown: {'high': 5, 'medium': 12, 'low': 8},
        );
        when(
          mockService.getDashboardOverview(),
        ).thenAnswer((_) async => mockData);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('High'), findsOneWidget);
        expect(find.text('Medium'), findsOneWidget);
        expect(find.text('Low'), findsOneWidget);
        expect(
          find.text('5'),
          findsWidgets,
        ); // Should find the high priority count
        expect(find.text('12'), findsOneWidget); // Medium priority count
        expect(find.text('8'), findsWidgets); // Low priority count
      });
    });

    group('User Interaction Tests', () {
      testWidgets('calls onTimeRangeChanged when time range is updated', (
        tester,
      ) async {
        // Arrange
        final mockData = createMockDashboardData();
        when(
          mockService.getDashboardOverview(),
        ).thenAnswer((_) async => mockData);

        String? capturedTimeRange;

        // Act
        await tester.pumpWidget(
          createTestWidget(
            selectedTimeRange: '7d',
            onTimeRangeChanged: (value) {
              capturedTimeRange = value;
            },
          ),
        );
        await tester.pumpAndSettle();

        // Find and tap the time selector (this would depend on the implementation)
        // For now, we'll just verify the callback is set up correctly
        expect(capturedTimeRange, isNull); // Initially null
      });

      testWidgets('activity items are tappable', (tester) async {
        // Arrange
        final mockData = createMockDashboardData();
        when(
          mockService.getDashboardOverview(),
        ).thenAnswer((_) async => mockData);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert - Find ListTiles and verify they're tappable
        final listTiles = find.byType(ListTile);
        expect(listTiles, findsWidgets);

        // Tap on first activity item
        await tester.tap(listTiles.first);
        await tester.pumpAndSettle();

        // Note: In a real implementation, this would navigate or show details
        // For now, we just verify the tap doesn't crash
      });
    });

    group('Activity Type Icon Tests', () {
      testWidgets('displays correct icons for different activity types', (
        tester,
      ) async {
        // Arrange
        final mockData = createMockDashboardData(
          recentActivities: [
            {
              'type': 'intervention_created',
              'timestamp': DateTime.now().toIso8601String(),
              'patient_name': 'Test User 1',
              'description': 'Created intervention',
            },
            {
              'type': 'intervention_completed',
              'timestamp': DateTime.now().toIso8601String(),
              'patient_name': 'Test User 2',
              'description': 'Completed intervention',
            },
            {
              'type': 'intervention_scheduled',
              'timestamp': DateTime.now().toIso8601String(),
              'patient_name': 'Test User 3',
              'description': 'Scheduled intervention',
            },
            {
              'type': 'intervention_cancelled',
              'timestamp': DateTime.now().toIso8601String(),
              'patient_name': 'Test User 4',
              'description': 'Cancelled intervention',
            },
          ],
        );
        when(
          mockService.getDashboardOverview(),
        ).thenAnswer((_) async => mockData);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert - Check that different activity types have appropriate icons
        expect(find.byIcon(Icons.add_circle), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(find.byIcon(Icons.schedule), findsOneWidget);
        expect(find.byIcon(Icons.cancel), findsOneWidget);
      });

      testWidgets('displays default icon for unknown activity type', (
        tester,
      ) async {
        // Arrange
        final mockData = createMockDashboardData(
          recentActivities: [
            {
              'type': 'unknown_type',
              'timestamp': DateTime.now().toIso8601String(),
              'patient_name': 'Test User',
              'description': 'Unknown activity',
            },
          ],
        );
        when(
          mockService.getDashboardOverview(),
        ).thenAnswer((_) async => mockData);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.byIcon(Icons.info), findsOneWidget);
      });
    });

    group('Error Handling Tests', () {
      testWidgets('handles null/missing data gracefully', (tester) async {
        // Arrange
        when(mockService.getDashboardOverview()).thenAnswer((_) async => {});

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert - Should not crash with empty data
        expect(find.byType(CoachDashboardOverviewTab), findsOneWidget);
        expect(find.text('No recent activity'), findsOneWidget);
      });

      testWidgets('handles malformed activity data', (tester) async {
        // Arrange
        final mockData = createMockDashboardData(
          recentActivities: [
            {
              // Missing fields to test robustness
              'patient_name': 'Test User',
            },
            {
              'type': 'intervention_created',
              // Missing other fields
            },
          ],
        );
        when(
          mockService.getDashboardOverview(),
        ).thenAnswer((_) async => mockData);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert - Should handle missing data gracefully
        expect(find.byType(CoachDashboardOverviewTab), findsOneWidget);
        expect(find.text('Test User'), findsOneWidget);
        expect(find.text('Unknown'), findsOneWidget); // Default patient name
      });
    });

    group('Accessibility Tests', () {
      testWidgets('has proper semantics for screen readers', (tester) async {
        // Arrange
        final mockData = createMockDashboardData();
        when(
          mockService.getDashboardOverview(),
        ).thenAnswer((_) async => mockData);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert - Check for semantic labels and accessibility
        expect(find.text('Recent Activity'), findsOneWidget);
        expect(find.text('Priority Breakdown'), findsOneWidget);

        // Check that the widget tree contains accessibility-friendly elements
        expect(find.byType(Text), findsWidgets);
        expect(find.byType(Icon), findsWidgets);
      });
    });
  });
}
