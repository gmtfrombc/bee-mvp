import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/coach_intervention_service.dart';
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
    });

    group('Loading State', () {
      testWidgets('displays loading indicator initially', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Should show loading indicator while waiting for data
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Loading scheduled interventions...'), findsOneWidget);
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
          find.text(
            'Scheduled interventions for your patients will appear here',
          ),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.schedule_outlined), findsOneWidget);
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
    });
  });
}
