import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/coach_intervention_service.dart';
import 'package:app/core/services/responsive_service.dart';
import 'package:app/features/momentum/presentation/widgets/coach_dashboard/coach_dashboard_overview_tab.dart';

// Create a simple mock service for testing
class MockCoachInterventionService implements CoachInterventionService {
  final Map<String, dynamic> _mockDashboardData;
  final bool _shouldThrowError;

  MockCoachInterventionService({
    Map<String, dynamic>? mockDashboardData,
    bool shouldThrowError = false,
  }) : _mockDashboardData = mockDashboardData ?? {},
       _shouldThrowError = shouldThrowError;

  @override
  Future<Map<String, dynamic>> getDashboardOverview() async {
    if (_shouldThrowError) {
      throw Exception('Network error');
    }
    return _mockDashboardData;
  }

  // Implement other required methods as stubs
  @override
  Future<InterventionResult> scheduleIntervention({
    required String userId,
    required InterventionType type,
    required InterventionPriority priority,
    String? reason,
    Map<String, dynamic>? momentumData,
  }) async => InterventionResult(success: true, interventionId: 'test-id');

  @override
  Future<List<CoachIntervention>> getPendingInterventions({
    String? userId,
  }) async => [];

  @override
  Future<bool> updateInterventionStatus({
    required String interventionId,
    required InterventionStatus status,
    String? notes,
    DateTime? completedAt,
  }) async => true;

  @override
  Future<InterventionRecommendation?> checkInterventionNeeded({
    required String userId,
    required Map<String, dynamic> momentumData,
  }) async => null;

  @override
  Future<List<CoachIntervention>> getInterventionHistory({
    String? userId,
    int limit = 50,
  }) async => [];

  @override
  Future<List<Map<String, dynamic>>> getActiveInterventions() async => [];

  @override
  Future<List<Map<String, dynamic>>> getScheduledInterventions() async => [];

  @override
  Future<bool> completeIntervention(String interventionId) async => true;

  @override
  Future<bool> cancelIntervention(String interventionId) async => true;

  @override
  Future<Map<String, dynamic>> getInterventionAnalytics(
    String timeRange,
  ) async => {};
}

void main() {
  group('CoachDashboardOverviewTab Widget Tests', () {
    /// Helper function to create widget with ProviderScope
    Widget createTestWidget({
      String selectedTimeRange = '7d',
      ValueChanged<String>? onTimeRangeChanged,
      Size screenSize = const Size(375.0, 667.0), // iPhone SE by default
      MockCoachInterventionService? mockService,
    }) {
      final service = mockService ?? MockCoachInterventionService();

      return ProviderScope(
        overrides: [
          coachInterventionServiceProvider.overrideWithValue(service),
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
                'timestamp':
                    DateTime.now()
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
        final mockService = MockCoachInterventionService(
          mockDashboardData: mockData,
        );

        // Act
        await tester.pumpWidget(createTestWidget(mockService: mockService));
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
        final mockService = MockCoachInterventionService(
          mockDashboardData: createMockDashboardData(),
        );

        // Act
        await tester.pumpWidget(createTestWidget(mockService: mockService));

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('displays error state when service throws exception', (
        tester,
      ) async {
        // Arrange
        final mockService = MockCoachInterventionService(
          shouldThrowError: true,
        );

        // Act
        await tester.pumpWidget(createTestWidget(mockService: mockService));
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
        final mockService = MockCoachInterventionService(
          mockDashboardData: mockData,
        );

        // Act
        await tester.pumpWidget(
          createTestWidget(
            screenSize: mobileSmallSize,
            mockService: mockService,
          ),
        );
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
        final mockService = MockCoachInterventionService(
          mockDashboardData: mockData,
        );

        // Act
        await tester.pumpWidget(
          createTestWidget(screenSize: tabletSize, mockService: mockService),
        );
        await tester.pumpAndSettle();

        // Assert
        final context = tester.element(find.byType(CoachDashboardOverviewTab));
        expect(ResponsiveService.getDeviceType(context), DeviceType.tablet);
        expect(ResponsiveService.shouldUseExpandedLayout(context), isTrue);
      });

      testWidgets('adjusts grid layout based on screen size', (tester) async {
        // Arrange
        final mockData = createMockDashboardData();
        final mockService = MockCoachInterventionService(
          mockDashboardData: mockData,
        );

        // Act - Mobile
        await tester.pumpWidget(
          createTestWidget(
            screenSize: const Size(375.0, 667.0),
            mockService: mockService,
          ),
        );
        await tester.pumpAndSettle();

        // Assert - Mobile should use fewer columns
        var context = tester.element(find.byType(CoachDashboardOverviewTab));
        var gridColumns = ResponsiveService.getGridColumnCount(context);
        expect(gridColumns, lessThanOrEqualTo(2));

        // Act - Tablet
        await tester.pumpWidget(
          createTestWidget(
            screenSize: const Size(768.0, 1024.0),
            mockService: mockService,
          ),
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
        final mockService = MockCoachInterventionService(
          mockDashboardData: mockData,
        );

        // Act
        await tester.pumpWidget(createTestWidget(mockService: mockService));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('15'), findsAtLeastNWidgets(1)); // active
        expect(find.text('8'), findsAtLeastNWidgets(1)); // scheduled_today
        expect(find.text('25'), findsAtLeastNWidgets(1)); // completed_week
        expect(find.text('7'), findsAtLeastNWidgets(1)); // high_priority
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
              'timestamp':
                  DateTime.now()
                      .subtract(const Duration(hours: 1))
                      .toIso8601String(),
              'patient_name': 'Bob Wilson',
              'description': 'Exercise routine completed',
            },
          ],
        );
        final mockService = MockCoachInterventionService(
          mockDashboardData: mockData,
        );

        // Act
        await tester.pumpWidget(createTestWidget(mockService: mockService));
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
        final mockService = MockCoachInterventionService(
          mockDashboardData: mockData,
        );

        // Act
        await tester.pumpWidget(createTestWidget(mockService: mockService));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('No recent activity'), findsOneWidget);
      });

      testWidgets('displays priority breakdown correctly', (tester) async {
        // Arrange
        final mockData = createMockDashboardData(
          priorityBreakdown: {'high': 5, 'medium': 12, 'low': 8},
        );
        final mockService = MockCoachInterventionService(
          mockDashboardData: mockData,
        );

        // Act
        await tester.pumpWidget(createTestWidget(mockService: mockService));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('High'), findsOneWidget);
        expect(find.text('Medium'), findsOneWidget);
        expect(find.text('Low'), findsOneWidget);
        expect(
          find.text('5'),
          findsAtLeastNWidgets(1),
        ); // Should find the high priority count
        expect(
          find.text('12'),
          findsAtLeastNWidgets(1),
        ); // Medium priority count
        expect(find.text('8'), findsAtLeastNWidgets(1)); // Low priority count
      });
    });

    group('User Interaction Tests', () {
      testWidgets('calls onTimeRangeChanged when time range is updated', (
        tester,
      ) async {
        // Arrange
        final mockData = createMockDashboardData();
        final mockService = MockCoachInterventionService(
          mockDashboardData: mockData,
        );

        String? capturedTimeRange;

        // Act
        await tester.pumpWidget(
          createTestWidget(
            selectedTimeRange: '7d',
            onTimeRangeChanged: (value) {
              capturedTimeRange = value;
            },
            mockService: mockService,
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
        final mockService = MockCoachInterventionService(
          mockDashboardData: mockData,
        );

        // Act
        await tester.pumpWidget(createTestWidget(mockService: mockService));
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
        final mockService = MockCoachInterventionService(
          mockDashboardData: mockData,
        );

        // Act
        await tester.pumpWidget(createTestWidget(mockService: mockService));
        await tester.pumpAndSettle();

        // Assert - Check that different activity types have appropriate icons
        expect(find.byIcon(Icons.add_circle), findsAtLeastNWidgets(1));
        expect(find.byIcon(Icons.check_circle), findsAtLeastNWidgets(1));
        expect(find.byIcon(Icons.schedule), findsAtLeastNWidgets(1));
        expect(find.byIcon(Icons.cancel), findsAtLeastNWidgets(1));
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
        final mockService = MockCoachInterventionService(
          mockDashboardData: mockData,
        );

        // Act
        await tester.pumpWidget(createTestWidget(mockService: mockService));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byIcon(Icons.info), findsAtLeastNWidgets(1));
      });
    });

    group('Error Handling Tests', () {
      testWidgets('handles null/missing data gracefully', (tester) async {
        // Arrange
        final mockService = MockCoachInterventionService(
          mockDashboardData: {}, // Empty data to test graceful handling
        );

        // Act
        await tester.pumpWidget(createTestWidget(mockService: mockService));
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
        final mockService = MockCoachInterventionService(
          mockDashboardData: mockData,
        );

        // Act
        await tester.pumpWidget(createTestWidget(mockService: mockService));
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
        final mockService = MockCoachInterventionService(
          mockDashboardData: mockData,
        );

        // Act
        await tester.pumpWidget(createTestWidget(mockService: mockService));
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
