import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/coach_intervention_service.dart';
import 'package:app/core/services/responsive_service.dart';
import 'package:app/features/momentum/presentation/widgets/coach_dashboard/coach_dashboard_scheduled_tab.dart';

// Mock service for testing
class TestCoachInterventionService implements CoachInterventionService {
  final List<Map<String, dynamic>> _scheduledInterventions;
  final bool _shouldThrowError;

  TestCoachInterventionService({
    List<Map<String, dynamic>>? scheduledInterventions,
    bool shouldThrowError = false,
  }) : _scheduledInterventions = scheduledInterventions ?? [],
       _shouldThrowError = shouldThrowError;

  @override
  Future<List<Map<String, dynamic>>> getScheduledInterventions() async {
    if (_shouldThrowError) {
      throw Exception('Network error');
    }
    return _scheduledInterventions;
  }

  @override
  Future<bool> completeIntervention(String id) async {
    return true;
  }

  @override
  Future<bool> cancelIntervention(String id) async {
    return true;
  }

  @override
  Future<List<Map<String, dynamic>>> getActiveInterventions() async {
    return [];
  }

  @override
  Future<Map<String, dynamic>> getInterventionAnalytics(
    String timeRange,
  ) async {
    return {};
  }

  @override
  Future<Map<String, dynamic>> getDashboardOverview() async {
    return {};
  }

  // Implement other required methods as stubs for testing
  @override
  Future<InterventionResult> scheduleIntervention({
    required String userId,
    required InterventionType type,
    required InterventionPriority priority,
    String? reason,
    Map<String, dynamic>? momentumData,
  }) async {
    return InterventionResult(success: true, interventionId: 'test-id');
  }

  @override
  Future<List<CoachIntervention>> getPendingInterventions({
    String? userId,
  }) async {
    return [];
  }

  @override
  Future<bool> updateInterventionStatus({
    required String interventionId,
    required InterventionStatus status,
    String? notes,
    DateTime? completedAt,
  }) async {
    return true;
  }

  @override
  Future<InterventionRecommendation?> checkInterventionNeeded({
    required String userId,
    required Map<String, dynamic> momentumData,
  }) async {
    return null;
  }

  @override
  Future<List<CoachIntervention>> getInterventionHistory({
    String? userId,
    int limit = 50,
  }) async {
    return [];
  }
}

void main() {
  group('CoachDashboardScheduledTab', () {
    Widget createTestWidget({
      VoidCallback? onInterventionUpdated,
      TestCoachInterventionService? testService,
    }) {
      final service = testService ?? TestCoachInterventionService();

      return ProviderScope(
        overrides: [
          coachInterventionServiceProvider.overrideWithValue(service),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: CoachDashboardScheduledTab(
              onInterventionUpdated: onInterventionUpdated,
            ),
          ),
        ),
      );
    }

    group('Widget Creation', () {
      testWidgets('creates without error', (tester) async {
        await tester.pumpWidget(createTestWidget());
        expect(find.byType(CoachDashboardScheduledTab), findsOneWidget);
      });

      testWidgets('accepts onInterventionUpdated callback', (tester) async {
        bool callbackCalled = false;
        await tester.pumpWidget(
          createTestWidget(onInterventionUpdated: () => callbackCalled = true),
        );

        expect(find.byType(CoachDashboardScheduledTab), findsOneWidget);
        // Callback should not be called during initial creation
        expect(callbackCalled, false);
      });
    });

    group('Loading State', () {
      testWidgets('displays loading indicator initially', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Should show loading indicator while waiting for data
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Loading scheduled interventions...'), findsOneWidget);
      });

      testWidgets('loading state uses responsive design', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Verify loading text has responsive font size
        final loadingText = tester.widget<Text>(
          find.text('Loading scheduled interventions...'),
        );
        expect(loadingText.style?.fontSize, greaterThan(0));
      });

      testWidgets('loading indicator has responsive size', (tester) async {
        await tester.pumpWidget(createTestWidget());

        final progressIndicator = tester.widget<SizedBox>(
          find
              .ancestor(
                of: find.byType(CircularProgressIndicator),
                matching: find.byType(SizedBox),
              )
              .first,
        );
        expect(progressIndicator.width, greaterThan(0));
        expect(progressIndicator.height, greaterThan(0));
      });
    });

    group('Error State', () {
      testWidgets('displays error message when fetch fails', (tester) async {
        final errorService = TestCoachInterventionService(
          shouldThrowError: true,
        );

        await tester.pumpWidget(createTestWidget(testService: errorService));
        await tester.pumpAndSettle();

        expect(
          find.text('Error loading scheduled interventions'),
          findsOneWidget,
        );
        expect(find.text('Exception: Network error'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('error state uses responsive design', (tester) async {
        final errorService = TestCoachInterventionService(
          shouldThrowError: true,
        );

        await tester.pumpWidget(createTestWidget(testService: errorService));
        await tester.pumpAndSettle();

        // Verify error title has responsive font size
        final errorTitle = tester.widget<Text>(
          find.text('Error loading scheduled interventions'),
        );
        expect(errorTitle.style?.fontSize, greaterThan(0));

        // Verify error message has responsive font size
        final errorMessage = tester.widget<Text>(
          find.text('Exception: Network error'),
        );
        expect(errorMessage.style?.fontSize, greaterThan(0));
      });

      testWidgets('error state displays retry button', (tester) async {
        final errorService = TestCoachInterventionService(
          shouldThrowError: true,
        );

        await tester.pumpWidget(createTestWidget(testService: errorService));
        await tester.pumpAndSettle();

        expect(find.text('Retry'), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget);
      });

      testWidgets('retry button calls onInterventionUpdated', (tester) async {
        final errorService = TestCoachInterventionService(
          shouldThrowError: true,
        );

        bool callbackCalled = false;
        await tester.pumpWidget(
          createTestWidget(
            testService: errorService,
            onInterventionUpdated: () => callbackCalled = true,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Retry'));
        expect(callbackCalled, true);
      });

      testWidgets('error icon has responsive size', (tester) async {
        final errorService = TestCoachInterventionService(
          shouldThrowError: true,
        );

        await tester.pumpWidget(createTestWidget(testService: errorService));
        await tester.pumpAndSettle();

        final errorIcon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
        expect(errorIcon.size, greaterThan(0));
      });
    });

    group('Empty State', () {
      testWidgets('displays empty state when no interventions', (tester) async {
        final emptyService = TestCoachInterventionService(
          scheduledInterventions: [],
        );

        await tester.pumpWidget(createTestWidget(testService: emptyService));
        await tester.pumpAndSettle();

        expect(find.text('No scheduled interventions'), findsOneWidget);
        expect(
          find.text('Scheduled interventions will appear here when created.'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.schedule_outlined), findsOneWidget);
      });

      testWidgets('empty state uses responsive design', (tester) async {
        final emptyService = TestCoachInterventionService(
          scheduledInterventions: [],
        );

        await tester.pumpWidget(createTestWidget(testService: emptyService));
        await tester.pumpAndSettle();

        // Verify empty title has responsive font size
        final emptyTitle = tester.widget<Text>(
          find.text('No scheduled interventions'),
        );
        expect(emptyTitle.style?.fontSize, greaterThan(0));

        // Verify empty message has responsive font size
        final emptyMessage = tester.widget<Text>(
          find.text('Scheduled interventions will appear here when created.'),
        );
        expect(emptyMessage.style?.fontSize, greaterThan(0));
      });

      testWidgets('empty state icon has responsive size', (tester) async {
        final emptyService = TestCoachInterventionService(
          scheduledInterventions: [],
        );

        await tester.pumpWidget(createTestWidget(testService: emptyService));
        await tester.pumpAndSettle();

        final emptyIcon = tester.widget<Icon>(
          find.byIcon(Icons.schedule_outlined),
        );
        expect(emptyIcon.size, greaterThan(0));
      });
    });

    group('Interventions List', () {
      testWidgets('displays list of scheduled interventions', (tester) async {
        final testInterventions = [
          {
            'id': '1',
            'patient_name': 'John Doe',
            'intervention_type': 'Motivational Check-in',
            'priority': 'high',
            'status': 'scheduled',
            'scheduled_at': '2024-01-15T10:00:00Z',
            'created_at': '2024-01-15T09:00:00Z',
          },
          {
            'id': '2',
            'patient_name': 'Jane Smith',
            'intervention_type': 'Goal Setting',
            'priority': 'medium',
            'status': 'scheduled',
            'scheduled_at': '2024-01-15T14:00:00Z',
            'created_at': '2024-01-15T09:30:00Z',
          },
        ];

        final serviceWithData = TestCoachInterventionService(
          scheduledInterventions: testInterventions,
        );

        await tester.pumpWidget(createTestWidget(testService: serviceWithData));
        await tester.pumpAndSettle();

        // Should display the interventions using CoachDashboardInterventionCard
        expect(find.text('John Doe'), findsOneWidget);
        expect(find.text('Jane Smith'), findsOneWidget);
      });

      testWidgets('uses ListView.builder for interventions list', (
        tester,
      ) async {
        final testInterventions = List.generate(
          10,
          (index) => {
            'id': 'intervention_$index',
            'patient_name': 'Patient $index',
            'intervention_type': 'Check-in',
            'priority': 'medium',
            'status': 'scheduled',
            'scheduled_at': '2024-01-15T${10 + index}:00:00Z',
            'created_at': '2024-01-15T09:00:00Z',
          },
        );

        final serviceWithData = TestCoachInterventionService(
          scheduledInterventions: testInterventions,
        );

        await tester.pumpWidget(createTestWidget(testService: serviceWithData));
        await tester.pumpAndSettle();

        expect(find.byType(ListView), findsOneWidget);
        // Should only render visible items (ListView.builder optimization)
        expect(find.text('Patient 0'), findsOneWidget);
      });

      testWidgets('list uses responsive padding', (tester) async {
        final testInterventions = [
          {
            'id': '1',
            'patient_name': 'Test Patient',
            'intervention_type': 'Check-in',
            'priority': 'medium',
            'status': 'scheduled',
            'scheduled_at': '2024-01-15T10:00:00Z',
            'created_at': '2024-01-15T09:00:00Z',
          },
        ];

        final serviceWithData = TestCoachInterventionService(
          scheduledInterventions: testInterventions,
        );

        await tester.pumpWidget(createTestWidget(testService: serviceWithData));
        await tester.pumpAndSettle();

        final listView = tester.widget<ListView>(find.byType(ListView));
        expect(listView.padding, isNotNull);
        expect(listView.padding!.vertical, greaterThan(0));
      });
    });

    group('Intervention Actions', () {
      testWidgets('handles complete action feedback', (tester) async {
        final testInterventions = [
          {
            'id': '1',
            'patient_name': 'John Doe',
            'intervention_type': 'Check-in',
            'priority': 'medium',
            'status': 'scheduled',
            'scheduled_at': '2024-01-15T10:00:00Z',
            'created_at': '2024-01-15T09:00:00Z',
          },
        ];

        final serviceWithData = TestCoachInterventionService(
          scheduledInterventions: testInterventions,
        );

        await tester.pumpWidget(createTestWidget(testService: serviceWithData));
        await tester.pumpAndSettle();

        // Find the popup menu button and tap it
        final popupMenuButton = find.byType(PopupMenuButton<String>);
        await tester.tap(popupMenuButton);
        await tester.pumpAndSettle();

        // Find and tap the complete action
        final completeAction = find.text('Mark Complete');
        await tester.tap(completeAction);
        await tester.pumpAndSettle();

        // Should show success snackbar
        expect(
          find.text('Intervention for John Doe completed successfully'),
          findsOneWidget,
        );
      });

      testWidgets('handles cancel action feedback', (tester) async {
        final testInterventions = [
          {
            'id': '1',
            'patient_name': 'Jane Smith',
            'intervention_type': 'Check-in',
            'priority': 'medium',
            'status': 'scheduled',
            'scheduled_at': '2024-01-15T10:00:00Z',
            'created_at': '2024-01-15T09:00:00Z',
          },
        ];

        final serviceWithData = TestCoachInterventionService(
          scheduledInterventions: testInterventions,
        );

        await tester.pumpWidget(createTestWidget(testService: serviceWithData));
        await tester.pumpAndSettle();

        // Find the popup menu button and tap it
        final popupMenuButton = find.byType(PopupMenuButton<String>);
        await tester.tap(popupMenuButton);
        await tester.pumpAndSettle();

        // Find and tap the cancel action
        final cancelAction = find.text('Cancel');
        await tester.tap(cancelAction);
        await tester.pumpAndSettle();

        // Should show cancel snackbar
        expect(
          find.text('Intervention for Jane Smith cancelled successfully'),
          findsOneWidget,
        );
      });

      testWidgets('handles reschedule dialog', (tester) async {
        final testInterventions = [
          {
            'id': '1',
            'patient_name': 'Bob Wilson',
            'intervention_type': 'Check-in',
            'priority': 'medium',
            'status': 'scheduled',
            'scheduled_at': '2024-01-15T10:00:00Z',
            'created_at': '2024-01-15T09:00:00Z',
          },
        ];

        final serviceWithData = TestCoachInterventionService(
          scheduledInterventions: testInterventions,
        );

        await tester.pumpWidget(createTestWidget(testService: serviceWithData));
        await tester.pumpAndSettle();

        // Find the popup menu button and tap it
        final popupMenuButton = find.byType(PopupMenuButton<String>);
        await tester.tap(popupMenuButton);
        await tester.pumpAndSettle();

        // Find and tap the reschedule action
        final rescheduleAction = find.text('Reschedule');
        await tester.tap(rescheduleAction);
        await tester.pumpAndSettle();

        // Should show reschedule dialog
        expect(find.text('Reschedule Intervention'), findsOneWidget);
        expect(find.text('Patient: Bob Wilson'), findsOneWidget);
      });

      testWidgets('reschedule dialog uses responsive design', (tester) async {
        final testInterventions = [
          {
            'id': '1',
            'patient_name': 'Test Patient',
            'intervention_type': 'Check-in',
            'priority': 'medium',
            'status': 'scheduled',
            'scheduled_at': '2024-01-15T10:00:00Z',
            'created_at': '2024-01-15T09:00:00Z',
          },
        ];

        final serviceWithData = TestCoachInterventionService(
          scheduledInterventions: testInterventions,
        );

        await tester.pumpWidget(createTestWidget(testService: serviceWithData));
        await tester.pumpAndSettle();

        final popupMenuButton = find.byType(PopupMenuButton<String>);
        await tester.tap(popupMenuButton);
        await tester.pumpAndSettle();

        final rescheduleAction = find.text('Reschedule');
        await tester.tap(rescheduleAction);
        await tester.pumpAndSettle();

        // Verify dialog title has responsive font size
        final dialogTitle = tester.widget<Text>(
          find.text('Reschedule Intervention'),
        );
        expect(dialogTitle.style?.fontSize, greaterThan(0));

        // Verify dialog content has responsive font size
        final patientText = tester.widget<Text>(
          find.text('Patient: Test Patient'),
        );
        expect(patientText.style?.fontSize, greaterThan(0));
      });

      testWidgets('reschedule dialog calls onInterventionUpdated', (
        tester,
      ) async {
        final testInterventions = [
          {
            'id': '1',
            'patient_name': 'Test Patient',
            'intervention_type': 'Check-in',
            'priority': 'medium',
            'status': 'scheduled',
            'scheduled_at': '2024-01-15T10:00:00Z',
            'created_at': '2024-01-15T09:00:00Z',
          },
        ];

        final serviceWithData = TestCoachInterventionService(
          scheduledInterventions: testInterventions,
        );

        bool callbackCalled = false;
        await tester.pumpWidget(
          createTestWidget(
            testService: serviceWithData,
            onInterventionUpdated: () => callbackCalled = true,
          ),
        );
        await tester.pumpAndSettle();

        final popupMenuButton = find.byType(PopupMenuButton<String>);
        await tester.tap(popupMenuButton);
        await tester.pumpAndSettle();

        final rescheduleAction = find.text('Reschedule');
        await tester.tap(rescheduleAction);
        await tester.pumpAndSettle();

        // Tap the reschedule button in the dialog
        final confirmButton = find.text('Reschedule').last;
        await tester.tap(confirmButton);
        await tester.pumpAndSettle();

        expect(callbackCalled, true);
      });
    });

    group('Responsive Design', () {
      testWidgets('uses ResponsiveLayout wrapper', (tester) async {
        final testInterventions = [
          {
            'id': '1',
            'patient_name': 'Test Patient',
            'intervention_type': 'Check-in',
            'priority': 'medium',
            'status': 'scheduled',
            'scheduled_at': '2024-01-15T10:00:00Z',
            'created_at': '2024-01-15T09:00:00Z',
          },
        ];

        final serviceWithData = TestCoachInterventionService(
          scheduledInterventions: testInterventions,
        );

        await tester.pumpWidget(createTestWidget(testService: serviceWithData));
        await tester.pumpAndSettle();

        expect(find.byType(ResponsiveLayout), findsOneWidget);
      });

      testWidgets('snackbar messages use responsive font size', (tester) async {
        final testInterventions = [
          {
            'id': '1',
            'patient_name': 'Test Patient',
            'intervention_type': 'Check-in',
            'priority': 'medium',
            'status': 'scheduled',
            'scheduled_at': '2024-01-15T10:00:00Z',
            'created_at': '2024-01-15T09:00:00Z',
          },
        ];

        final serviceWithData = TestCoachInterventionService(
          scheduledInterventions: testInterventions,
        );

        await tester.pumpWidget(createTestWidget(testService: serviceWithData));
        await tester.pumpAndSettle();

        final popupMenuButton = find.byType(PopupMenuButton<String>);
        await tester.tap(popupMenuButton);
        await tester.pumpAndSettle();

        final completeButton = find.text('Mark Complete');
        await tester.tap(completeButton);
        await tester.pumpAndSettle();

        final snackbarText = tester.widget<Text>(
          find.text('Intervention for Test Patient completed successfully'),
        );
        expect(snackbarText.style?.fontSize, greaterThan(0));
      });
    });

    group('Edge Cases', () {
      testWidgets('handles null patient name gracefully', (tester) async {
        final testInterventions = [
          {
            'id': '1',
            'patient_name': null,
            'intervention_type': 'Check-in',
            'priority': 'medium',
            'status': 'scheduled',
            'scheduled_at': '2024-01-15T10:00:00Z',
            'created_at': '2024-01-15T09:00:00Z',
          },
        ];

        final serviceWithData = TestCoachInterventionService(
          scheduledInterventions: testInterventions,
        );

        await tester.pumpWidget(createTestWidget(testService: serviceWithData));
        await tester.pumpAndSettle();

        // Should handle null patient name and use 'Unknown'
        final popupMenuButton = find.byType(PopupMenuButton<String>);
        await tester.tap(popupMenuButton);
        await tester.pumpAndSettle();

        final completeButton = find.text('Mark Complete');
        await tester.tap(completeButton);
        await tester.pumpAndSettle();

        expect(
          find.text('Intervention for Unknown completed successfully'),
          findsOneWidget,
        );
      });

      testWidgets('handles missing intervention data', (tester) async {
        final testInterventions = [
          {
            'id': '1',
            // Missing other fields
          },
        ];

        final serviceWithData = TestCoachInterventionService(
          scheduledInterventions: testInterventions,
        );

        await tester.pumpWidget(createTestWidget(testService: serviceWithData));
        await tester.pumpAndSettle();

        // Should not crash and still render the intervention card
        expect(find.byType(ListView), findsOneWidget);
      });
    });
  });
}
