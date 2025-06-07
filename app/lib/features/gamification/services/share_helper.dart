import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';

/// Helper service for sharing achievements and progress
class ShareHelper {
  /// Check if we're running in test mode to suppress error messages
  static bool _shouldSuppressError(dynamic error) {
    // Suppress MissingPluginException errors which are expected in test environment
    return error.toString().contains('MissingPluginException') ||
        error.toString().contains('No implementation found for method share');
  }

  /// Share an achievement with image and text
  static Future<void> shareAchievement(String imagePath, String text) async {
    try {
      // For now, share just the text. Image sharing would require
      // converting assets to files which is more complex
      await Share.share(
        text,
        subject: 'My Achievement in BEE Momentum Meter! 🎉',
      );

      if (kDebugMode) {
        debugPrint('✅ Achievement shared: $text');
      }
    } catch (e) {
      if (kDebugMode && !_shouldSuppressError(e)) {
        debugPrint('❌ Error sharing achievement: $e');
      }
    }
  }

  /// Share progress milestone
  static Future<void> shareProgress({
    required int totalPoints,
    required int streakDays,
    required int badgesEarned,
  }) async {
    final text = '''
🚀 My BEE Progress Update! 

📊 Total Points: $totalPoints
🔥 Current Streak: $streakDays days
🏆 Badges Earned: $badgesEarned

Building healthy habits with the BEE Momentum Meter! 💪

#BEEMomentum #HealthyHabits #ProgressUpdate
''';

    try {
      await Share.share(text, subject: 'My BEE Progress Update! 🚀');

      if (kDebugMode) {
        debugPrint('✅ Progress shared');
      }
    } catch (e) {
      if (kDebugMode && !_shouldSuppressError(e)) {
        debugPrint('❌ Error sharing progress: $e');
      }
    }
  }

  /// Share weekly challenge completion
  static Future<void> shareChallenge({
    required String challengeTitle,
    required int rewardPoints,
  }) async {
    final text = '''
🎯 Challenge Completed! 

✅ $challengeTitle
🎁 Earned $rewardPoints points

Crushing my health goals with BEE! 💪

#BEEMomentum #ChallengeComplete #HealthGoals
''';

    try {
      await Share.share(text, subject: 'Challenge Completed! 🎯');

      if (kDebugMode) {
        debugPrint('✅ Challenge completion shared');
      }
    } catch (e) {
      if (kDebugMode && !_shouldSuppressError(e)) {
        debugPrint('❌ Error sharing challenge: $e');
      }
    }
  }

  /// Share streak milestone
  static Future<void> shareStreak(int streakDays) async {
    final text = '''
🔥 $streakDays Day Streak! 

Consistent daily engagement with my AI coach for $streakDays days straight! 

Building momentum one day at a time with BEE! 🚀

#BEEMomentum #StreakGoals #DailyHabits
''';

    try {
      await Share.share(text, subject: '$streakDays Day Streak! 🔥');

      if (kDebugMode) {
        debugPrint('✅ Streak shared: $streakDays days');
      }
    } catch (e) {
      if (kDebugMode && !_shouldSuppressError(e)) {
        debugPrint('❌ Error sharing streak: $e');
      }
    }
  }
}
