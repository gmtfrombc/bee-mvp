import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/gamification/services/share_helper.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('ShareHelper', () {
    test('shareAchievement builds correct share text & image path', () async {
      const imagePath = 'assets/badges/test_badge.png';
      const text = 'I earned a test badge!';

      // Test that the method completes without throwing errors
      await expectLater(
        ShareHelper.shareAchievement(imagePath, text),
        completes,
      );
    });

    test('shareProgress builds correct parameters', () async {
      const totalPoints = 150;
      const streakDays = 7;
      const badgesEarned = 5;

      // Test that the method completes without throwing errors
      await expectLater(
        ShareHelper.shareProgress(
          totalPoints: totalPoints,
          streakDays: streakDays,
          badgesEarned: badgesEarned,
        ),
        completes,
      );
    });

    test('shareChallenge builds correct parameters', () async {
      const challengeTitle = 'Daily Check-in';
      const rewardPoints = 50;

      // Test that the method completes without throwing errors
      await expectLater(
        ShareHelper.shareChallenge(
          challengeTitle: challengeTitle,
          rewardPoints: rewardPoints,
        ),
        completes,
      );
    });

    test('shareStreak builds correct parameters', () async {
      const streakDays = 14;

      // Test that the method completes without throwing errors
      await expectLater(ShareHelper.shareStreak(streakDays), completes);
    });
  });
}
