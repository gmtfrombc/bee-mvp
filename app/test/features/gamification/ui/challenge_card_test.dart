import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/gamification/ui/challenge_card.dart';
import 'package:app/features/gamification/models/badge.dart';

void main() {
  group('ChallengeCard', () {
    late Challenge mockChallenge;

    setUp(() {
      mockChallenge = Challenge(
        id: 'test_challenge',
        title: 'Daily Check-in',
        description: 'Chat with your coach for 3 days this week',
        type: ChallengeType.coachChats,
        targetValue: 3,
        currentProgress: 1,
        expiresAt: DateTime.now().add(const Duration(days: 2)),
        isAccepted: false,
        rewardPoints: 50,
      );
    });

    testWidgets('accept button sets status "accepted"', (
      WidgetTester tester,
    ) async {
      bool acceptCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ChallengeCard(
                challenge: mockChallenge,
                onAccept: () {
                  acceptCalled = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify challenge content is displayed
      expect(find.text('Daily Check-in'), findsOneWidget);
      expect(
        find.text('Chat with your coach for 3 days this week'),
        findsOneWidget,
      );

      // Find and tap accept button
      final acceptButton = find.text('Accept Challenge');
      expect(acceptButton, findsOneWidget);

      await tester.tap(acceptButton);
      await tester.pumpAndSettle();

      // Verify accept callback was called
      expect(acceptCalled, isTrue);
    });

    testWidgets('decline triggers callback', (WidgetTester tester) async {
      bool declineCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ChallengeCard(
                challenge: mockChallenge,
                onDecline: () {
                  declineCalled = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap decline button
      final declineButton = find.text('Decline');
      expect(declineButton, findsOneWidget);

      await tester.tap(declineButton);
      await tester.pumpAndSettle();

      // Verify decline callback was called
      expect(declineCalled, isTrue);
    });

    testWidgets('displays progress correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: ChallengeCard(challenge: mockChallenge)),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify progress display
      expect(find.text('33%'), findsOneWidget); // 1/3 = 33%
      expect(find.text('Progress: 1 / 3'), findsOneWidget);
      expect(find.text('Reward: 50 points'), findsOneWidget);

      // Verify progress ring exists
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });
  });
}
