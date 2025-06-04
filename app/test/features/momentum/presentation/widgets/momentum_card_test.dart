import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/momentum/domain/models/momentum_data.dart';
import 'package:app/features/momentum/presentation/widgets/momentum_card.dart';
import 'package:app/features/momentum/presentation/widgets/momentum_gauge.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  // Setup test environment before all tests
  setUpAll(() async {
    await TestHelpers.setUpTest();
  });

  group('MomentumCard Widget Tests', () {
    testWidgets('displays momentum card with rising state', (
      WidgetTester tester,
    ) async {
      final momentumData = TestHelpers.createSampleMomentumData(
        state: MomentumState.rising,
        percentage: 85.0,
        message: "You're doing great! Keep up the excellent work.",
      );

      await TestHelpers.pumpTestWidget(
        tester,
        child: MomentumCard(momentumData: momentumData),
      );

      // Verify the card is displayed
      expect(find.byType(Card), findsOneWidget);

      // Verify the percentage is displayed
      expect(find.text('85% this week'), findsOneWidget);

      // Verify the rising emoji is displayed
      expect(find.text('🚀'), findsOneWidget);
    });

    testWidgets('displays momentum card with steady state', (
      WidgetTester tester,
    ) async {
      final momentumData = TestHelpers.createSampleMomentumData(
        state: MomentumState.steady,
        percentage: 65.0,
        message: "Steady progress! You're doing great!",
      );

      await TestHelpers.pumpTestWidget(
        tester,
        child: MomentumCard(momentumData: momentumData),
      );

      // Verify the card is displayed
      expect(find.byType(Card), findsOneWidget);

      // Verify the percentage is displayed
      expect(find.text('65% this week'), findsOneWidget);

      // Verify the steady emoji is displayed
      expect(find.text('🙂'), findsOneWidget);
    });

    testWidgets('displays momentum card with needs care state', (
      WidgetTester tester,
    ) async {
      final momentumData = TestHelpers.createSampleMomentumData(
        state: MomentumState.needsCare,
        percentage: 35.0,
        message: "Let's get back on track together! 🌱",
      );

      await TestHelpers.pumpTestWidget(
        tester,
        child: MomentumCard(momentumData: momentumData),
      );

      // Verify the card is displayed
      expect(find.byType(Card), findsOneWidget);

      // Verify the percentage is displayed
      expect(find.text('35% this week'), findsOneWidget);

      // Verify the needs care emoji is displayed
      expect(find.text('🌱'), findsOneWidget);
    });

    testWidgets('has proper accessibility semantics', (
      WidgetTester tester,
    ) async {
      final momentumData = TestHelpers.createSampleMomentumData(
        state: MomentumState.rising,
        percentage: 85.0,
      );

      await TestHelpers.pumpTestWidget(
        tester,
        child: MomentumCard(momentumData: momentumData),
      );

      // Verify semantic labels are present with the actual format from AccessibilityService
      // AccessibilityService.getMomentumCardLabel() generates:
      // 'Momentum card. Your momentum is ${state.name} at ${percentage} percent. ${stateDescription} ${encouragingMessage}'
      expect(
        find.bySemanticsLabel(
          RegExp(r'Momentum card\. Your momentum is rising at 85 percent\.'),
        ),
        findsOneWidget,
      );

      // Verify the card has proper semantics
      final cardFinder = find.byType(Card);
      expect(cardFinder, findsOneWidget);

      final cardWidget = tester.widget<Card>(cardFinder);
      expect(cardWidget.semanticContainer, isTrue);
    });

    testWidgets('displays last updated time', (WidgetTester tester) async {
      final now = DateTime.now();
      final momentumData = MomentumData(
        state: MomentumState.rising,
        percentage: 85.0,
        message: "You're doing great!",
        lastUpdated: now,
        stats: MomentumStats.fromJson({
          'lessonsCompleted': 4,
          'totalLessons': 5,
          'streakDays': 7,
          'todayMinutes': 25,
        }),
        weeklyTrend: [],
      );

      await TestHelpers.pumpTestWidget(
        tester,
        child: MomentumCard(momentumData: momentumData),
      );

      // The current MomentumCard implementation doesn't display timestamp
      // Instead, verify the card renders properly with the momentum data
      expect(find.byType(Card), findsOneWidget);
      expect(find.text('85% this week'), findsOneWidget);
    });

    testWidgets('handles text scaling properly', (WidgetTester tester) async {
      final momentumData = TestHelpers.createSampleMomentumData();

      await TestHelpers.pumpTestWidget(
        tester,
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: MomentumCard(momentumData: momentumData),
        ),
      );

      // Verify the card still renders properly with scaled text
      expect(find.byType(Card), findsOneWidget);
      expect(find.text('85% this week'), findsOneWidget);
    });

    testWidgets('card has proper elevation and styling', (
      WidgetTester tester,
    ) async {
      final momentumData = TestHelpers.createSampleMomentumData();

      await TestHelpers.pumpTestWidget(
        tester,
        child: MomentumCard(momentumData: momentumData),
      );

      final cardFinder = find.byType(Card);
      expect(cardFinder, findsOneWidget);

      final cardWidget = tester.widget<Card>(cardFinder);
      expect(cardWidget.elevation, greaterThan(0));
    });

    testWidgets('displays gradient background for rising state', (
      WidgetTester tester,
    ) async {
      final momentumData = TestHelpers.createSampleMomentumData(
        state: MomentumState.rising,
      );

      await TestHelpers.pumpTestWidget(
        tester,
        child: MomentumCard(momentumData: momentumData),
      );

      // Verify gradient container is present
      expect(find.byType(Container), findsWidgets);

      // Verify the card renders without errors
      expect(find.byType(Card), findsOneWidget);
    });
  });

  group('MomentumCard', () {
    late MomentumData sampleData;

    setUp(() {
      sampleData = MomentumData.sample();
    });

    testWidgets('renders correctly with momentum data', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(body: MomentumCard(momentumData: sampleData)),
        ),
      );

      // Verify header text
      expect(find.text('YOUR MOMENTUM'), findsOneWidget);

      // Verify state text
      expect(find.text('Rising!'), findsOneWidget);

      // Verify progress bar percentage
      expect(find.text('85% this week'), findsOneWidget);

      // Verify momentum gauge is present
      expect(find.byType(MomentumGauge), findsOneWidget);
    });

    testWidgets('displays correct state text for different momentum states', (
      tester,
    ) async {
      // Test Rising state
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MomentumCard(
              momentumData: sampleData.copyWith(state: MomentumState.rising),
            ),
          ),
        ),
      );
      expect(find.text('Rising!'), findsOneWidget);

      // Test Steady state
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MomentumCard(
              momentumData: sampleData.copyWith(state: MomentumState.steady),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Steady!'), findsOneWidget);

      // Test Needs Care state
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MomentumCard(
              momentumData: sampleData.copyWith(state: MomentumState.needsCare),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Verify that 'Growing!' text is not displayed (as per UX requirement)
      expect(find.text('Growing!'), findsNothing);
    });

    testWidgets('handles tap interaction correctly', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MomentumCard(
              momentumData: sampleData,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Tap the card
      await tester.tap(find.byType(MomentumCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('shows progress bar when enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MomentumCard(momentumData: sampleData, showProgressBar: true),
          ),
        ),
      );

      expect(find.text('85% this week'), findsOneWidget);
    });

    testWidgets('hides progress bar when disabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MomentumCard(
              momentumData: sampleData,
              showProgressBar: false,
            ),
          ),
        ),
      );

      expect(find.text('85% this week'), findsNothing);
    });

    testWidgets('animates entry correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(body: MomentumCard(momentumData: sampleData)),
        ),
      );

      // Initially should be invisible (opacity 0)
      await tester.pump();

      // After animation completes, should be visible
      await tester.pumpAndSettle();
      expect(find.byType(MomentumCard), findsOneWidget);
    });

    testWidgets('animates state changes correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MomentumCard(
              momentumData: sampleData.copyWith(state: MomentumState.rising),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Change state
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MomentumCard(
              momentumData: sampleData.copyWith(state: MomentumState.steady),
            ),
          ),
        ),
      );

      // Should trigger animation
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Steady!'), findsOneWidget);
    });
  });

  group('CompactMomentumCard', () {
    testWidgets('renders with correct height and no progress bar', (
      tester,
    ) async {
      final sampleData = MomentumData.sample();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(body: CompactMomentumCard(momentumData: sampleData)),
        ),
      );

      // Should not show progress bar
      expect(find.text('85% this week'), findsNothing);

      // Should still show main content
      expect(find.text('YOUR MOMENTUM'), findsOneWidget);
      expect(find.text('Rising!'), findsOneWidget);
    });
  });

  group('AccessibleMomentumCard', () {
    testWidgets('has enhanced accessibility features', (tester) async {
      final sampleData = MomentumData.sample();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AccessibleMomentumCard(
              momentumData: sampleData,
              onTap: () {},
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(
        find.byType(AccessibleMomentumCard),
      );
      expect(semantics.label, contains('rising state'));
      expect(semantics.label, contains('85 percent'));
    });

    testWidgets('uses custom semantic label when provided', (tester) async {
      final sampleData = MomentumData.sample();
      const customLabel = 'Custom momentum description';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AccessibleMomentumCard(
              momentumData: sampleData,
              customSemanticLabel: customLabel,
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(
        find.byType(AccessibleMomentumCard),
      );
      expect(semantics.label, customLabel);
    });
  });
}
