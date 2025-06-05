import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/momentum/presentation/widgets/coach_dashboard/coach_dashboard_filter_bar.dart';

void main() {
  group('CoachDashboardFilterBar', () {
    Widget createTestWidget({
      String selectedPriority = 'all',
      String selectedStatus = 'all',
      ValueChanged<String>? onPriorityChanged,
      ValueChanged<String>? onStatusChanged,
      Size? screenSize,
    }) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: screenSize ?? const Size(375.0, 667.0),
            devicePixelRatio: 1.0,
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 300, maxWidth: 800),
                child: CoachDashboardFilterBar(
                  selectedPriority: selectedPriority,
                  selectedStatus: selectedStatus,
                  onPriorityChanged: onPriorityChanged ?? (value) {},
                  onStatusChanged: onStatusChanged ?? (value) {},
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('should render with default values', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      // Verify priority dropdown exists with correct default value
      expect(find.text('Priority'), findsOneWidget);
      expect(find.text('All Priorities'), findsOneWidget);

      // Verify status dropdown exists with correct default value
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('All Statuses'), findsOneWidget);
    });

    testWidgets('should handle priority filter changes', (
      WidgetTester tester,
    ) async {
      String? priorityChanged;
      String? statusChanged;

      await tester.pumpWidget(
        createTestWidget(
          onPriorityChanged: (value) => priorityChanged = value,
          onStatusChanged: (value) => statusChanged = value,
        ),
      );

      // Find and tap the priority dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();

      // Select 'High' priority
      await tester.tap(
        find.text('High').last,
      ); // Use .last to avoid multiple matches
      await tester.pumpAndSettle();

      expect(priorityChanged, 'high');
      expect(statusChanged, isNull);
    });

    testWidgets('should handle status filter changes', (
      WidgetTester tester,
    ) async {
      String? priorityChanged;
      String? statusChanged;

      await tester.pumpWidget(
        createTestWidget(
          onPriorityChanged: (value) => priorityChanged = value,
          onStatusChanged: (value) => statusChanged = value,
        ),
      );

      // Find and tap the status dropdown (second dropdown)
      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();

      // Select 'Pending' status
      await tester.tap(
        find.text('Pending').last,
      ); // Use .last to avoid multiple matches
      await tester.pumpAndSettle();

      expect(priorityChanged, isNull);
      expect(statusChanged, 'pending');
    });

    testWidgets('should display all priority options', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      // Tap priority dropdown to open
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();

      // Verify all priority options are present (allow multiple matches)
      expect(find.text('All Priorities'), findsAtLeastNWidgets(1));
      expect(find.text('High'), findsAtLeastNWidgets(1));
      expect(find.text('Medium'), findsAtLeastNWidgets(1));
      expect(find.text('Low'), findsAtLeastNWidgets(1));
    });

    testWidgets('should display all status options', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      // Tap status dropdown to open
      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();

      // Verify all status options are present (allow multiple matches)
      expect(find.text('All Statuses'), findsAtLeastNWidgets(1));
      expect(find.text('Pending'), findsAtLeastNWidgets(1));
      expect(find.text('In Progress'), findsAtLeastNWidgets(1));
      expect(find.text('Completed'), findsAtLeastNWidgets(1));
    });

    testWidgets('should use responsive layout for large screens', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          selectedPriority: 'high',
          selectedStatus: 'pending',
          screenSize: const Size(800, 600), // Tablet size
        ),
      );

      // On larger screens, should use Row layout (side-by-side)
      expect(find.byType(Row), findsWidgets);

      // Both dropdowns should be present
      expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));
    });

    testWidgets('should use compact layout for small screens', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          selectedPriority: 'medium',
          selectedStatus: 'in_progress',
          screenSize: const Size(320, 568), // Small mobile size
        ),
      );

      // On small screens, should use Column layout (stacked)
      expect(find.byType(Column), findsWidgets);

      // Both dropdowns should still be present
      expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));
    });

    testWidgets('should show selected values correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(selectedPriority: 'high', selectedStatus: 'completed'),
      );

      // Should show selected values in dropdowns
      expect(find.text('High'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('should handle multiple priority changes', (
      WidgetTester tester,
    ) async {
      String? lastPriorityChanged;

      await tester.pumpWidget(
        createTestWidget(
          onPriorityChanged: (value) {
            lastPriorityChanged = value;
          },
        ),
      );

      // Change to High
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('High').last);
      await tester.pumpAndSettle();

      expect(lastPriorityChanged, 'high');

      // Rebuild widget with new state
      await tester.pumpWidget(
        createTestWidget(
          selectedPriority: 'high',
          onPriorityChanged: (value) {
            lastPriorityChanged = value;
          },
        ),
      );

      // Change to Low
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Low').last);
      await tester.pumpAndSettle();

      expect(lastPriorityChanged, 'low');
    });

    testWidgets('should handle multiple status changes', (
      WidgetTester tester,
    ) async {
      String? lastStatusChanged;

      await tester.pumpWidget(
        createTestWidget(
          onStatusChanged: (value) {
            lastStatusChanged = value;
          },
        ),
      );

      // Change to Pending
      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pending').last);
      await tester.pumpAndSettle();

      expect(lastStatusChanged, 'pending');

      // Rebuild widget with new state
      await tester.pumpWidget(
        createTestWidget(
          selectedStatus: 'pending',
          onStatusChanged: (value) {
            lastStatusChanged = value;
          },
        ),
      );

      // Change to In Progress
      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('In Progress').last);
      await tester.pumpAndSettle();

      expect(lastStatusChanged, 'in_progress');
    });

    testWidgets('should apply responsive styles correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      // Widget should be rendered without overflow or layout issues
      expect(tester.takeException(), isNull);

      // Container should have proper styling
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.decoration, isA<BoxDecoration>());
    });
  });
}
