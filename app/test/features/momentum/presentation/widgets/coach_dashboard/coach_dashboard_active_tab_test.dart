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
    });
  });
}
