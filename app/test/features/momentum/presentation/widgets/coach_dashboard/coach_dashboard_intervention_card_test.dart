import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/coach_intervention_service.dart';
import 'package:app/features/momentum/presentation/widgets/coach_dashboard/coach_dashboard_intervention_card.dart';

// Mock service for testing
class TestCoachInterventionService implements CoachInterventionService {
  final bool _shouldThrowError;
  final bool _shouldCompleteSuccessfully;

  TestCoachInterventionService({
    bool shouldThrowError = false,
    bool shouldCompleteSuccessfully = true,
  }) : _shouldThrowError = shouldThrowError,
       _shouldCompleteSuccessfully = shouldCompleteSuccessfully;

  @override
  Future<bool> completeIntervention(String id) async {
    if (_shouldThrowError) {
      throw Exception('Failed to complete intervention');
    }
    return _shouldCompleteSuccessfully;
  }

  @override
  Future<bool> cancelIntervention(String id) async {
    if (_shouldThrowError) {
      throw Exception('Failed to cancel intervention');
    }
    return _shouldCompleteSuccessfully;
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

  @override
  Future<List<Map<String, dynamic>>> getActiveInterventions() async {
    return [];
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
}

void main() {
  group('CoachDashboardInterventionCard', () {
    /// Helper function to create test widget with proper providers
    Widget createTestWidget({
      required Map<String, dynamic> intervention,
      VoidCallback? onComplete,
      VoidCallback? onReschedule,
      VoidCallback? onCancel,
      VoidCallback? onUpdate,
      TestCoachInterventionService? testService,
      Size screenSize = const Size(375.0, 667.0), // iPhone SE by default
    }) {
      final service = testService ?? TestCoachInterventionService();

      return ProviderScope(
        overrides: [
          coachInterventionServiceProvider.overrideWithValue(service),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: screenSize, devicePixelRatio: 1.0),
            child: Scaffold(
              body: SingleChildScrollView(
                child: CoachDashboardInterventionCard(
                  intervention: intervention,
                  onComplete: onComplete,
                  onReschedule: onReschedule,
                  onCancel: onCancel,
                  onUpdate: onUpdate,
                ),
              ),
            ),
          ),
        ),
      );
    }

    /// Helper function to create complete intervention data
    Map<String, dynamic> createInterventionData({
      String? id,
      String? patientName,
      String? type,
      String? priority,
      String? status,
      String? scheduledAt,
      String? notes,
    }) {
      return {
        'id': id ?? 'test-id-1',
        'patient_name': patientName ?? 'John Doe',
        'type': type ?? 'medication_reminder',
        'priority': priority ?? 'high',
        'status': status ?? 'pending',
        'scheduled_at': scheduledAt ?? DateTime.now().toIso8601String(),
        'notes': notes ?? 'Important medication reminder',
      };
    }

    group('Widget Creation and Basic Structure', () {
      testWidgets('creates without throwing', (tester) async {
        final intervention = createInterventionData();

        await tester.pumpWidget(createTestWidget(intervention: intervention));
        await tester.pumpAndSettle();

        expect(find.byType(CoachDashboardInterventionCard), findsOneWidget);
        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('displays intervention information correctly', (
        tester,
      ) async {
        final intervention = createInterventionData(
          patientName: 'Jane Smith',
          type: 'wellness_check',
          priority: 'medium',
          status: 'in_progress',
          notes: 'Weekly wellness check',
        );

        await tester.pumpWidget(createTestWidget(intervention: intervention));
        await tester.pumpAndSettle();

        expect(find.text('Jane Smith'), findsOneWidget);
        expect(find.text('Type: WELLNESS CHECK'), findsOneWidget);
        expect(find.text('MEDIUM'), findsOneWidget);
        expect(find.text('IN PROGRESS'), findsOneWidget);
        expect(find.text('Weekly wellness check'), findsOneWidget);
      });
    });

    group('Priority and Status Badges', () {
      testWidgets('displays correct priority colors', (tester) async {
        final highPriorityIntervention = createInterventionData(
          priority: 'high',
        );

        await tester.pumpWidget(
          createTestWidget(intervention: highPriorityIntervention),
        );
        await tester.pumpAndSettle();

        final priorityBadge = find.text('HIGH');
        expect(priorityBadge, findsOneWidget);

        final priorityContainer = tester.widget<Container>(
          find
              .ancestor(of: priorityBadge, matching: find.byType(Container))
              .first,
        );

        final decoration = priorityContainer.decoration as BoxDecoration;
        expect(decoration.color, equals(Colors.red.withValues(alpha: 0.1)));
      });
    });

    group('Action Menu', () {
      testWidgets('displays action menu with all options', (tester) async {
        final intervention = createInterventionData();

        await tester.pumpWidget(createTestWidget(intervention: intervention));
        await tester.pumpAndSettle();

        final menuButton = find.byType(PopupMenuButton<String>);
        expect(menuButton, findsOneWidget);

        await tester.tap(menuButton);
        await tester.pumpAndSettle();

        expect(find.text('Mark Complete'), findsOneWidget);
        expect(find.text('Reschedule'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);

        // Check for the presence of action icons - they should be in popup menu items
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(find.byIcon(Icons.cancel), findsOneWidget);
        // Note: schedule icon might appear twice (menu + content) so we'll check differently
        expect(find.byIcon(Icons.schedule), findsAtLeastNWidgets(1));
      });
    });

    group('Error Handling', () {
      testWidgets('widget remains stable with service that can fail', (
        tester,
      ) async {
        final intervention = createInterventionData();
        final errorService = TestCoachInterventionService(
          shouldThrowError: true,
        );

        await tester.pumpWidget(
          createTestWidget(
            intervention: intervention,
            testService: errorService,
          ),
        );
        await tester.pumpAndSettle();

        // Widget should render successfully despite error-prone service
        expect(find.byType(CoachDashboardInterventionCard), findsOneWidget);
        expect(find.text('John Doe'), findsOneWidget);

        // Menu should be accessible
        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();
        expect(find.text('Mark Complete'), findsOneWidget);
      });
    });
  });
}
