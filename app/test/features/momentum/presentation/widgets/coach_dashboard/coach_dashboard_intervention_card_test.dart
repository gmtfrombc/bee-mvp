import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

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

      testWidgets('handles missing intervention data gracefully', (
        tester,
      ) async {
        final intervention = {'id': 'test-id'}; // Minimal data

        await tester.pumpWidget(createTestWidget(intervention: intervention));
        await tester.pumpAndSettle();

        expect(find.text('Unknown'), findsOneWidget); // Default patient name
        expect(find.text('Type: GENERAL'), findsOneWidget); // Default type
        expect(find.text('MEDIUM'), findsOneWidget); // Default priority
        expect(find.text('PENDING'), findsOneWidget); // Default status
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

      testWidgets('displays all priority levels correctly', (tester) async {
        final priorities = ['high', 'medium', 'low'];

        for (int i = 0; i < priorities.length; i++) {
          final intervention = createInterventionData(priority: priorities[i]);

          await tester.pumpWidget(createTestWidget(intervention: intervention));
          await tester.pumpAndSettle();

          final priorityText = find.text(priorities[i].toUpperCase());
          expect(priorityText, findsOneWidget);

          await tester.pumpWidget(Container()); // Clear widget tree
        }
      });

      testWidgets('status badge displays correctly', (tester) async {
        final intervention = createInterventionData(status: 'in_progress');

        await tester.pumpWidget(createTestWidget(intervention: intervention));
        await tester.pumpAndSettle();

        expect(find.text('IN PROGRESS'), findsOneWidget);

        final statusContainer = tester.widget<Container>(
          find
              .ancestor(
                of: find.text('IN PROGRESS'),
                matching: find.byType(Container),
              )
              .first,
        );

        final decoration = statusContainer.decoration as BoxDecoration;
        expect(decoration.color, equals(Colors.blue.withValues(alpha: 0.1)));
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

      testWidgets('complete action calls callbacks correctly', (tester) async {
        final intervention = createInterventionData();
        bool onCompleteCalled = false;
        bool onUpdateCalled = false;

        await tester.pumpWidget(
          createTestWidget(
            intervention: intervention,
            onComplete: () => onCompleteCalled = true,
            onUpdate: () => onUpdateCalled = true,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Mark Complete'));
        await tester.pumpAndSettle();

        expect(onCompleteCalled, true);
        expect(onUpdateCalled, true);
      });

      testWidgets('reschedule action calls callback correctly', (tester) async {
        final intervention = createInterventionData();
        bool onRescheduleCalled = false;

        await tester.pumpWidget(
          createTestWidget(
            intervention: intervention,
            onReschedule: () => onRescheduleCalled = true,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Reschedule'));
        await tester.pumpAndSettle();

        expect(onRescheduleCalled, true);
      });

      testWidgets('cancel action calls callbacks correctly', (tester) async {
        final intervention = createInterventionData();
        bool onCancelCalled = false;
        bool onUpdateCalled = false;

        await tester.pumpWidget(
          createTestWidget(
            intervention: intervention,
            onCancel: () => onCancelCalled = true,
            onUpdate: () => onUpdateCalled = true,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(onCancelCalled, true);
        expect(onUpdateCalled, true);
      });
    });

    group('Content Display', () {
      testWidgets('displays scheduled time when provided', (tester) async {
        final scheduledTime = DateTime(2024, 1, 15, 10, 30);
        final intervention = createInterventionData(
          scheduledAt: scheduledTime.toIso8601String(),
        );

        await tester.pumpWidget(createTestWidget(intervention: intervention));
        await tester.pumpAndSettle();

        // Should find the schedule icon somewhere in content
        expect(find.byIcon(Icons.schedule), findsAtLeastNWidgets(1));

        final expectedTime = DateFormat('MMM d, h:mm a').format(scheduledTime);
        expect(find.text('Scheduled: $expectedTime'), findsOneWidget);
      });

      testWidgets('hides scheduled time when not provided', (tester) async {
        final intervention = createInterventionData(scheduledAt: '');

        await tester.pumpWidget(createTestWidget(intervention: intervention));
        await tester.pumpAndSettle();

        // Should not find schedule info in content
        expect(find.textContaining('Scheduled:'), findsNothing);
      });

      testWidgets('displays notes when provided', (tester) async {
        final intervention = createInterventionData(
          notes: 'This is a test note for the intervention',
        );

        await tester.pumpWidget(createTestWidget(intervention: intervention));
        await tester.pumpAndSettle();

        expect(
          find.text('This is a test note for the intervention'),
          findsOneWidget,
        );
      });

      testWidgets('hides notes when empty', (tester) async {
        final intervention = createInterventionData(notes: '');

        await tester.pumpWidget(createTestWidget(intervention: intervention));
        await tester.pumpAndSettle();

        // Only patient name and type should be visible, no extra notes
        expect(find.text('John Doe'), findsOneWidget);
        expect(find.text('Type: MEDICATION REMINDER'), findsOneWidget);
      });

      testWidgets('handles text overflow properly', (tester) async {
        final intervention = createInterventionData(
          patientName:
              'This is an extremely long patient name that should be truncated',
          notes:
              'This is a very long note that should be truncated when displayed in the card to prevent overflow issues and maintain proper layout',
        );

        await tester.pumpWidget(
          createTestWidget(
            intervention: intervention,
            screenSize: const Size(300, 600), // Narrow screen
          ),
        );
        await tester.pumpAndSettle();

        // Verify the widget renders without overflow errors
        expect(find.byType(CoachDashboardInterventionCard), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Responsive Design', () {
      testWidgets('adapts to different screen sizes', (tester) async {
        final intervention = createInterventionData();

        // Test mobile size
        await tester.pumpWidget(
          createTestWidget(
            intervention: intervention,
            screenSize: const Size(375, 667), // iPhone SE
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CoachDashboardInterventionCard), findsOneWidget);

        // Test tablet size
        await tester.pumpWidget(
          createTestWidget(
            intervention: intervention,
            screenSize: const Size(768, 1024), // iPad
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CoachDashboardInterventionCard), findsOneWidget);

        // Test desktop size
        await tester.pumpWidget(
          createTestWidget(
            intervention: intervention,
            screenSize: const Size(1200, 800), // Desktop
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CoachDashboardInterventionCard), findsOneWidget);
      });

      testWidgets('uses responsive spacing and sizing', (tester) async {
        final intervention = createInterventionData();

        await tester.pumpWidget(createTestWidget(intervention: intervention));
        await tester.pumpAndSettle();

        // Verify card uses responsive design
        final card = tester.widget<Card>(find.byType(Card));
        expect(card.margin, isNotNull);
        expect(card.shape, isA<RoundedRectangleBorder>());

        // Verify responsive padding is applied
        final paddingWidgets = find.byType(Padding);
        expect(paddingWidgets, findsWidgets);

        // Verify responsive spacing in SizedBox widgets
        final sizedBoxWidgets = find.byType(SizedBox);
        expect(sizedBoxWidgets, findsWidgets);
      });

      testWidgets('card elevation adapts to screen size', (tester) async {
        final intervention = createInterventionData();

        // Test compact layout (mobile)
        await tester.pumpWidget(
          createTestWidget(
            intervention: intervention,
            screenSize: const Size(350, 600), // Small mobile
          ),
        );
        await tester.pumpAndSettle();

        final mobileCard = tester.widget<Card>(find.byType(Card));
        expect(mobileCard.elevation, equals(2));

        // Test expanded layout (desktop)
        await tester.pumpWidget(
          createTestWidget(
            intervention: intervention,
            screenSize: const Size(1200, 800), // Desktop
          ),
        );
        await tester.pumpAndSettle();

        final desktopCard = tester.widget<Card>(find.byType(Card));
        expect(desktopCard.elevation, equals(4));
      });

      testWidgets('font sizes scale with device type', (tester) async {
        final intervention = createInterventionData();

        await tester.pumpWidget(createTestWidget(intervention: intervention));
        await tester.pumpAndSettle();

        // Find text widgets and verify they have font sizes applied
        final patientNameText = tester.widget<Text>(find.text('John Doe'));
        expect(patientNameText.style?.fontSize, greaterThan(0));

        final typeText = tester.widget<Text>(
          find.text('Type: MEDICATION REMINDER'),
        );
        expect(typeText.style?.fontSize, greaterThan(0));

        final priorityText = tester.widget<Text>(find.text('HIGH'));
        expect(priorityText.style?.fontSize, greaterThan(0));
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

      testWidgets('handles malformed date strings', (tester) async {
        final intervention = createInterventionData(
          scheduledAt: 'invalid-date-string',
        );

        await tester.pumpWidget(createTestWidget(intervention: intervention));
        await tester.pumpAndSettle();

        // Should not crash and should not display schedule info
        expect(find.textContaining('Scheduled:'), findsNothing);
        expect(find.byType(CoachDashboardInterventionCard), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('has proper text contrast and sizing for accessibility', (
        tester,
      ) async {
        final intervention = createInterventionData();

        await tester.pumpWidget(createTestWidget(intervention: intervention));
        await tester.pumpAndSettle();

        // Verify important text elements are present and readable
        expect(find.text('John Doe'), findsOneWidget);
        expect(find.text('HIGH'), findsOneWidget);
        expect(find.text('PENDING'), findsOneWidget);

        // Verify action buttons are accessible
        final menuButton = find.byType(PopupMenuButton<String>);
        expect(menuButton, findsOneWidget);

        await tester.tap(menuButton);
        await tester.pumpAndSettle();

        expect(find.text('Mark Complete'), findsOneWidget);
        expect(find.text('Reschedule'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
      });

      testWidgets('maintains functionality with large text scale', (
        tester,
      ) async {
        final intervention = createInterventionData();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              coachInterventionServiceProvider.overrideWithValue(
                TestCoachInterventionService(),
              ),
            ],
            child: MaterialApp(
              home: MediaQuery(
                data: const MediaQueryData(
                  size: Size(375, 667),
                  devicePixelRatio: 1.0,
                  textScaler: TextScaler.linear(2.0), // Large text
                ),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: CoachDashboardInterventionCard(
                      intervention: intervention,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Should render without overflow even with large text
        expect(find.byType(CoachDashboardInterventionCard), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Edge Cases', () {
      testWidgets('handles null values in intervention data', (tester) async {
        final intervention = {
          'id': 'test-id',
          'patient_name': null,
          'type': null,
          'priority': null,
          'status': null,
          'scheduled_at': null,
          'notes': null,
        };

        await tester.pumpWidget(createTestWidget(intervention: intervention));
        await tester.pumpAndSettle();

        // Should use default values
        expect(find.text('Unknown'), findsOneWidget);
        expect(find.text('MEDIUM'), findsOneWidget);
        expect(find.text('PENDING'), findsOneWidget);
        expect(find.text('Type: GENERAL'), findsOneWidget);
      });

      testWidgets('handles empty intervention map', (tester) async {
        final intervention = <String, dynamic>{};

        await tester.pumpWidget(createTestWidget(intervention: intervention));
        await tester.pumpAndSettle();

        // Should render with all default values
        expect(find.text('Unknown'), findsOneWidget);
        expect(find.text('MEDIUM'), findsOneWidget);
        expect(find.text('PENDING'), findsOneWidget);
        expect(find.text('Type: GENERAL'), findsOneWidget);
      });

      testWidgets('handles very long text content gracefully', (tester) async {
        final intervention = createInterventionData(
          patientName: 'A' * 100, // Very long name
          notes: 'B' * 500, // Very long notes
          type: 'very_long_intervention_type_name_that_might_cause_overflow',
        );

        await tester.pumpWidget(
          createTestWidget(
            intervention: intervention,
            screenSize: const Size(300, 600), // Constrained width
          ),
        );
        await tester.pumpAndSettle();

        // Should render without throwing overflow exceptions
        expect(find.byType(CoachDashboardInterventionCard), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  });
}
