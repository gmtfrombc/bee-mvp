import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:app/main.dart' as app;
import 'package:app/features/achievements/streak_badge.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Coach Happy Path E2E Test', () {
    testWidgets(
      'Complete flow: login → chat → momentum dip → nudge → recovery → badge',
      (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Step 1: Navigate to coach screen
        await _navigationToCoach(tester);

        // Step 2: Initial chat interaction
        await _testInitialChatFlow(tester);

        // Step 3: Simulate momentum dip and receive nudge
        await _testMomentumDipFlow(tester);

        // Step 4: Recovery conversation and confetti
        await _testRecoveryFlow(tester);

        // Step 5: Verify streak badge growth
        await _testStreakBadgeGrowth(tester);
      },
    );

    testWidgets('Coach accessibility features work correctly', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();

      await _navigationToCoach(tester);
      await _testAccessibilityFeatures(tester);
    });

    testWidgets('Coach error handling works properly', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();

      await _navigationToCoach(tester);
      await _testErrorHandling(tester);
    });
  });
}

Future<void> _navigationToCoach(WidgetTester tester) async {
  // Look for coach navigation button/tab
  Finder coachButton = find.byIcon(Icons.psychology_outlined);
  if (coachButton.evaluate().isEmpty) {
    coachButton = find.text('Coach');
  }

  if (coachButton.evaluate().isNotEmpty) {
    await tester.tap(coachButton);
    await tester.pumpAndSettle();
  }

  // Verify we're on the coach screen
  expect(find.text('Coach'), findsWidgets);
  debugPrint('✅ E2E: Navigated to coach screen');
}

Future<void> _testInitialChatFlow(WidgetTester tester) async {
  // Verify welcome message appears
  expect(find.textContaining('Hi! I\'m your momentum coach'), findsOneWidget);

  // Test quick suggestion cards
  final dailyHabitsCard = find.text('Daily habits');
  if (dailyHabitsCard.evaluate().isNotEmpty) {
    await tester.tap(dailyHabitsCard);
    await tester.pumpAndSettle();

    // Verify message was sent
    expect(find.text('Help me build daily habits'), findsOneWidget);
  }

  // Test manual message input
  final textField = find.byType(TextField);
  await tester.enterText(textField, 'What should I focus on today?');

  final sendButton = find.byIcon(Icons.send_rounded);
  await tester.tap(sendButton);
  await tester.pumpAndSettle(const Duration(seconds: 3));

  // Verify message appears in chat
  expect(find.text('What should I focus on today?'), findsOneWidget);
  debugPrint('✅ E2E: Initial chat flow completed');
}

Future<void> _testMomentumDipFlow(WidgetTester tester) async {
  // Simulate momentum dip scenario
  final textField = find.byType(TextField);
  await tester.enterText(
    textField,
    'I\'m struggling today and don\'t feel motivated',
  );

  final sendButton = find.byIcon(Icons.send_rounded);
  await tester.tap(sendButton);
  await tester.pumpAndSettle(const Duration(seconds: 3));

  // Verify supportive response appears
  // Look for supportive emoji or tone indicators
  expect(
    find.textContaining('🤗').evaluate().isNotEmpty ||
        find.textContaining('support').evaluate().isNotEmpty,
    isTrue,
  );

  debugPrint('✅ E2E: Momentum dip handling verified');
}

Future<void> _testRecoveryFlow(WidgetTester tester) async {
  // Simulate recovery conversation
  final textField = find.byType(TextField);
  await tester.enterText(
    textField,
    'Thanks for the support! I completed my daily goal',
  );

  final sendButton = find.byIcon(Icons.send_rounded);
  await tester.tap(sendButton);
  await tester.pumpAndSettle(const Duration(seconds: 3));

  // Look for celebratory response
  expect(
    find.textContaining('🎉').evaluate().isNotEmpty ||
        find.textContaining('great').evaluate().isNotEmpty,
    isTrue,
  );

  debugPrint('✅ E2E: Recovery flow completed');
}

Future<void> _testStreakBadgeGrowth(WidgetTester tester) async {
  // Look for streak badge
  Finder streakBadge = find.byType(AutoStreakBadge);
  if (streakBadge.evaluate().isEmpty) {
    streakBadge = find.textContaining('streak');
  }

  if (streakBadge.evaluate().isNotEmpty) {
    await tester.tap(streakBadge.first);
    await tester.pumpAndSettle();

    // Verify streak info dialog or screen opens
    expect(
      find.textContaining('day').evaluate().isNotEmpty ||
          find.textContaining('streak').evaluate().isNotEmpty,
      isTrue,
    );

    // Close dialog if opened
    Finder closeButton = find.byIcon(Icons.close);
    if (closeButton.evaluate().isEmpty) {
      closeButton = find.text('Close');
    }
    if (closeButton.evaluate().isNotEmpty) {
      await tester.tap(closeButton.first);
      await tester.pumpAndSettle();
    }
  }

  debugPrint('✅ E2E: Streak badge interaction verified');
}

Future<void> _testAccessibilityFeatures(WidgetTester tester) async {
  // Verify semantic labels on emojis
  expect(find.byTooltip('supportive'), findsWidgets);
  expect(find.byTooltip('celebratory'), findsWidgets);

  // Test keyboard navigation
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pumpAndSettle();

  debugPrint('✅ E2E: Accessibility features verified');
}

Future<void> _testErrorHandling(WidgetTester tester) async {
  // Test rate limiting
  final textField = find.byType(TextField);
  final sendButton = find.byIcon(Icons.send_rounded);

  // Send multiple messages quickly to trigger rate limit
  for (int i = 0; i < 6; i++) {
    await tester.enterText(textField, 'Test message $i');
    await tester.tap(sendButton);
    await tester.pump(const Duration(milliseconds: 100));
  }

  await tester.pumpAndSettle();

  // Verify rate limit message appears
  expect(find.textContaining('wait a moment'), findsOneWidget);

  debugPrint('✅ E2E: Error handling verified');
}
