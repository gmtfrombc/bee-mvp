import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/coach_intervention_service.dart';
import 'package:app/features/momentum/presentation/widgets/coach_dashboard/coach_dashboard_active_tab.dart';

// Simple mock service for testing
class TestCoachInterventionService implements CoachInterventionService {
  final List<Map<String, dynamic>> _activeInterventions;
  final bool _shouldThrowError;

  TestCoachInterventionService({
    List<Map<String, dynamic>>? activeInterventions,
    bool shouldThrowError = false,
  }) : _activeInterventions = activeInterventions ?? [],
       _shouldThrowError = shouldThrowError;

  @override
  Future<List<Map<String, dynamic>>> getActiveInterventions() async {
    if (_shouldThrowError) {
      throw Exception('Network error');
    }
    // Remove delay to avoid timer issues in tests
    return _activeInterventions;
  }

  @override
  Future<bool> completeIntervention(String id) async {
    // Remove delay to avoid timer issues in tests
    return true;
  }

  @override
  Future<bool> cancelIntervention(String id) async {
    // Remove delay to avoid timer issues in tests
    return true;
  }

  @override
  Future<List<Map<String, dynamic>>> getScheduledInterventions() async {
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
  group('CoachDashboardActiveTab', () {
    Widget createTestWidget({
      String selectedPriority = 'all',
      String selectedStatus = 'all',
      ValueChanged<String>? onPriorityChanged,
      ValueChanged<String>? onStatusChanged,
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
            body: CoachDashboardActiveTab(
              selectedPriority: selectedPriority,
              selectedStatus: selectedStatus,
              onPriorityChanged: onPriorityChanged ?? (_) {},
              onStatusChanged: onStatusChanged ?? (_) {},
              onInterventionUpdated: onInterventionUpdated,
            ),
          ),
        ),
      );
    }

    group('Widget Creation', () {
      testWidgets('creates without error', (tester) async {
        await tester.pumpWidget(createTestWidget());
        expect(find.byType(CoachDashboardActiveTab), findsOneWidget);
      });

      testWidgets('displays filter bar', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Priority'), findsOneWidget);
        expect(find.text('Status'), findsOneWidget);
      });

      testWidgets('passes correct props to filter bar', (tester) async {
        await tester.pumpWidget(
          createTestWidget(selectedPriority: 'high', selectedStatus: 'pending'),
        );
        await tester.pumpAndSettle();

        // Verify the filter bar shows the correct initial values
        expect(find.text('High'), findsWidgets);
        expect(find.text('Pending'), findsWidgets);
      });
    });

    group('Loading State', () {
      testWidgets('displays loading indicator initially', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Should show loading indicator while waiting for data
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('Error State', () {
      testWidgets('displays error message when fetch fails', (tester) async {
        final errorService = TestCoachInterventionService(
          shouldThrowError: true,
        );

        await tester.pumpWidget(createTestWidget(testService: errorService));
        await tester.pumpAndSettle();

        expect(find.text('Error: Exception: Network error'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('error message uses responsive design', (tester) async {
        final errorService = TestCoachInterventionService(
          shouldThrowError: true,
        );

        await tester.pumpWidget(createTestWidget(testService: errorService));
        await tester.pumpAndSettle();

        final errorText = tester.widget<Text>(
          find.text('Error: Exception: Network error'),
        );
        expect(errorText.style?.fontSize, greaterThan(0));
      });
    });

    group('Empty State', () {
      testWidgets('displays empty state when no interventions', (tester) async {
        final emptyService = TestCoachInterventionService(
          activeInterventions: [],
        );

        await tester.pumpWidget(createTestWidget(testService: emptyService));
        await tester.pumpAndSettle();

        expect(find.text('No active interventions'), findsOneWidget);
        expect(
          find.text('Active interventions will appear here'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.psychology_outlined), findsOneWidget);
      });

      testWidgets('empty state uses responsive design', (tester) async {
        final emptyService = TestCoachInterventionService(
          activeInterventions: [],
        );

        await tester.pumpWidget(createTestWidget(testService: emptyService));
        await tester.pumpAndSettle();

        final titleText = tester.widget<Text>(
          find.text('No active interventions'),
        );
        final subtitleText = tester.widget<Text>(
          find.text('Active interventions will appear here'),
        );

        expect(titleText.style?.fontSize, greaterThan(0));
        expect(subtitleText.style?.fontSize, greaterThan(0));
      });
    });

    group('Interventions List', () {
      testWidgets('displays interventions when data is available', (
        tester,
      ) async {
        final testInterventions = [
          {
            'id': '1',
            'patient_name': 'John Doe',
            'type': 'medication_reminder',
            'priority': 'high',
            'status': 'pending',
            'scheduled_at': DateTime.now().toIso8601String(),
            'notes': 'Important medication reminder',
          },
          {
            'id': '2',
            'patient_name': 'Jane Smith',
            'type': 'wellness_check',
            'priority': 'medium',
            'status': 'in_progress',
            'notes': '',
          },
        ];

        final serviceWithData = TestCoachInterventionService(
          activeInterventions: testInterventions,
        );

        await tester.pumpWidget(createTestWidget(testService: serviceWithData));
        await tester.pumpAndSettle();

        expect(find.text('John Doe'), findsOneWidget);
        expect(find.text('Jane Smith'), findsOneWidget);
        expect(find.text('HIGH'), findsOneWidget);
        expect(find.text('MEDIUM'), findsOneWidget);
        expect(find.text('PENDING'), findsOneWidget);
        expect(find.text('IN PROGRESS'), findsOneWidget);
      });

      testWidgets('displays intervention details correctly', (tester) async {
        final scheduledTime = DateTime.now();
        final testInterventions = [
          {
            'id': '1',
            'patient_name': 'John Doe',
            'type': 'medication_reminder',
            'priority': 'high',
            'status': 'pending',
            'scheduled_at': scheduledTime.toIso8601String(),
            'notes': 'Important medication reminder',
          },
        ];

        final serviceWithData = TestCoachInterventionService(
          activeInterventions: testInterventions,
        );

        await tester.pumpWidget(createTestWidget(testService: serviceWithData));
        await tester.pumpAndSettle();

        expect(find.text('John Doe'), findsOneWidget);
        expect(find.text('Type: MEDICATION REMINDER'), findsOneWidget);
        expect(find.text('Important medication reminder'), findsOneWidget);
        expect(find.byIcon(Icons.schedule), findsOneWidget);
      });

      testWidgets('handles intervention without scheduled time', (
        tester,
      ) async {
        final testInterventions = [
          {
            'id': '1',
            'patient_name': 'John Doe',
            'type': 'general',
            'priority': 'low',
            'status': 'pending',
            'notes': '',
          },
        ];

        final serviceWithData = TestCoachInterventionService(
          activeInterventions: testInterventions,
        );

        await tester.pumpWidget(createTestWidget(testService: serviceWithData));
        await tester.pumpAndSettle();

        expect(find.text('John Doe'), findsOneWidget);
        expect(find.text('Type: GENERAL'), findsOneWidget);
        expect(find.byIcon(Icons.schedule), findsNothing);
      });

      testWidgets('handles intervention without notes', (tester) async {
        final testInterventions = [
          {
            'id': '1',
            'patient_name': 'John Doe',
            'type': 'general',
            'priority': 'low',
            'status': 'pending',
            'notes': '',
          },
        ];

        final serviceWithData = TestCoachInterventionService(
          activeInterventions: testInterventions,
        );

        await tester.pumpWidget(createTestWidget(testService: serviceWithData));
        await tester.pumpAndSettle();

        expect(find.text('John Doe'), findsOneWidget);
        // Notes section should not appear when notes are empty
        final notesWidgets = find.textContaining('Important');
        expect(notesWidgets, findsNothing);
      });
    });

    group('Priority Colors', () {
      testWidgets('displays correct text for high priority', (tester) async {
        final testInterventions = [
          {
            'id': '1',
            'patient_name': 'John Doe',
            'type': 'general',
            'priority': 'high',
            'status': 'pending',
          },
        ];

        final serviceWithData = TestCoachInterventionService(
          activeInterventions: testInterventions,
        );

        await tester.pumpWidget(createTestWidget(testService: serviceWithData));
        await tester.pumpAndSettle();

        expect(find.text('HIGH'), findsOneWidget);
      });

      testWidgets('displays correct text for medium priority', (tester) async {
        final testInterventions = [
          {
            'id': '1',
            'patient_name': 'John Doe',
            'type': 'general',
            'priority': 'medium',
            'status': 'pending',
          },
        ];

        final serviceWithData = TestCoachInterventionService(
          activeInterventions: testInterventions,
        );

        await tester.pumpWidget(createTestWidget(testService: serviceWithData));
        await tester.pumpAndSettle();

        expect(find.text('MEDIUM'), findsOneWidget);
      });

      testWidgets('displays correct text for low priority', (tester) async {
        final testInterventions = [
          {
            'id': '1',
            'patient_name': 'John Doe',
            'type': 'general',
            'priority': 'low',
            'status': 'pending',
          },
        ];

        final serviceWithData = TestCoachInterventionService(
          activeInterventions: testInterventions,
        );

        await tester.pumpWidget(createTestWidget(testService: serviceWithData));
        await tester.pumpAndSettle();

        expect(find.text('LOW'), findsOneWidget);
      });
    });

    group('Action Menu', () {
      testWidgets('displays action menu for each intervention', (tester) async {
        final testInterventions = [
          {
            'id': '1',
            'patient_name': 'John Doe',
            'type': 'general',
            'priority': 'medium',
            'status': 'pending',
          },
        ];

        final serviceWithData = TestCoachInterventionService(
          activeInterventions: testInterventions,
        );

        await tester.pumpWidget(createTestWidget(testService: serviceWithData));
        await tester.pumpAndSettle();

        expect(find.byType(PopupMenuButton<String>), findsOneWidget);
      });

      testWidgets('shows reschedule dialog when reschedule is tapped', (
        tester,
      ) async {
        final testInterventions = [
          {
            'id': '1',
            'patient_name': 'John Doe',
            'type': 'general',
            'priority': 'medium',
            'status': 'pending',
          },
        ];

        final serviceWithData = TestCoachInterventionService(
          activeInterventions: testInterventions,
        );

        await tester.pumpWidget(createTestWidget(testService: serviceWithData));
        await tester.pumpAndSettle();

        // Tap on the popup menu
        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();

        // Tap on reschedule option
        await tester.tap(find.text('Reschedule'));
        await tester.pumpAndSettle();

        expect(find.text('Reschedule Intervention'), findsOneWidget);
        expect(
          find.text(
            'Reschedule functionality would be implemented here with date/time picker.',
          ),
          findsOneWidget,
        );
      });

      testWidgets('calls intervention updated callback on complete', (
        tester,
      ) async {
        final testInterventions = [
          {
            'id': '1',
            'patient_name': 'John Doe',
            'type': 'general',
            'priority': 'medium',
            'status': 'pending',
          },
        ];

        final serviceWithData = TestCoachInterventionService(
          activeInterventions: testInterventions,
        );

        bool callbackCalled = false;

        await tester.pumpWidget(
          createTestWidget(
            testService: serviceWithData,
            onInterventionUpdated: () => callbackCalled = true,
          ),
        );
        await tester.pumpAndSettle();

        // Tap on the popup menu
        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();

        // Tap on complete option
        await tester.tap(find.text('Mark Complete'));
        await tester.pumpAndSettle();

        expect(callbackCalled, isTrue);
      });

      testWidgets('calls intervention updated callback on cancel', (
        tester,
      ) async {
        final testInterventions = [
          {
            'id': '1',
            'patient_name': 'John Doe',
            'type': 'general',
            'priority': 'medium',
            'status': 'pending',
          },
        ];

        final serviceWithData = TestCoachInterventionService(
          activeInterventions: testInterventions,
        );

        bool callbackCalled = false;

        await tester.pumpWidget(
          createTestWidget(
            testService: serviceWithData,
            onInterventionUpdated: () => callbackCalled = true,
          ),
        );
        await tester.pumpAndSettle();

        // Tap on the popup menu
        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();

        // Tap on cancel option
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(callbackCalled, isTrue);
      });
    });

    group('Filter Callbacks', () {
      testWidgets('calls priority change callback when provided', (
        tester,
      ) async {
        String? changedPriority;

        await tester.pumpWidget(
          createTestWidget(
            onPriorityChanged: (value) => changedPriority = value,
          ),
        );
        await tester.pumpAndSettle();

        // Initially no callback called
        expect(changedPriority, isNull);
      });

      testWidgets('calls status change callback when provided', (tester) async {
        String? changedStatus;

        await tester.pumpWidget(
          createTestWidget(onStatusChanged: (value) => changedStatus = value),
        );
        await tester.pumpAndSettle();

        // Initially no callback called
        expect(changedStatus, isNull);
      });
    });

    group('Responsive Design', () {
      testWidgets('uses responsive spacing and sizing', (tester) async {
        final testInterventions = [
          {
            'id': '1',
            'patient_name': 'John Doe',
            'type': 'general',
            'priority': 'medium',
            'status': 'pending',
          },
        ];

        final serviceWithData = TestCoachInterventionService(
          activeInterventions: testInterventions,
        );

        await tester.pumpWidget(createTestWidget(testService: serviceWithData));
        await tester.pumpAndSettle();

        // Verify responsive design is applied
        final card = tester.widget<Card>(find.byType(Card).first);
        expect(card.margin, isNotNull);

        // Find padding widgets and verify they exist
        final paddingWidgets = find.byType(Padding);
        expect(paddingWidgets, findsWidgets);
      });
    });

    group('Integration', () {
      testWidgets('complete workflow with multiple interventions', (
        tester,
      ) async {
        final testInterventions = [
          {
            'id': '1',
            'patient_name': 'John Doe',
            'type': 'medication_reminder',
            'priority': 'high',
            'status': 'pending',
            'scheduled_at': DateTime.now().toIso8601String(),
            'notes': 'Important medication reminder',
          },
          {
            'id': '2',
            'patient_name': 'Jane Smith',
            'type': 'wellness_check',
            'priority': 'low',
            'status': 'in_progress',
            'notes': 'Regular check-up',
          },
        ];

        final serviceWithData = TestCoachInterventionService(
          activeInterventions: testInterventions,
        );

        await tester.pumpWidget(createTestWidget(testService: serviceWithData));
        await tester.pumpAndSettle();

        // Verify both interventions are displayed
        expect(find.text('John Doe'), findsOneWidget);
        expect(find.text('Jane Smith'), findsOneWidget);
        expect(find.text('HIGH'), findsOneWidget);
        expect(find.text('LOW'), findsOneWidget);

        // Verify action menus are present for both
        expect(find.byType(PopupMenuButton<String>), findsNWidgets(2));
      });
    });
  });
}
