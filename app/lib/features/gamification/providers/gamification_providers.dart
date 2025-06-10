import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/badge.dart';
import 'package:flutter/foundation.dart';

/// Provider for achievements/badges data
final achievementsProvider = FutureProvider<List<Badge>>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) return [];

  try {
    // Mock data for now - replace with actual Supabase query when backend is ready
    final mockBadges = [
      Badge(
        id: 'streak_7',
        title: 'Week Warrior',
        description: 'Complete 7 days in a row',
        imagePath: 'assets/badges/streak_7.png',
        category: BadgeCategory.streak,
        isEarned: true,
        earnedAt: DateTime.now().subtract(const Duration(days: 2)),
        requiredPoints: 7,
        currentProgress: 7,
      ),
      const Badge(
        id: 'momentum_100',
        title: 'Momentum Master',
        description: 'Earn 100 momentum points',
        imagePath: 'assets/badges/momentum_100.png',
        category: BadgeCategory.momentum,
        isEarned: false,
        requiredPoints: 100,
        currentProgress: 75,
      ),
      const Badge(
        id: 'coach_chat_10',
        title: 'Chat Champion',
        description: 'Have 10 conversations with your coach',
        imagePath: 'assets/badges/chat_10.png',
        category: BadgeCategory.engagement,
        isEarned: false,
        requiredPoints: 10,
        currentProgress: 6,
      ),
      Badge(
        id: 'first_week',
        title: 'Getting Started',
        description: 'Complete your first week with BEE',
        imagePath: 'assets/badges/first_week.png',
        category: BadgeCategory.milestone,
        isEarned: true,
        earnedAt: DateTime.now().subtract(const Duration(days: 5)),
        requiredPoints: 1,
        currentProgress: 1,
      ),
    ];

    return mockBadges;
  } catch (e) {
    return [];
  }
});

/// Provider for weekly progress data
final progressProvider = FutureProvider<List<ProgressData>>((ref) async {
  try {
    // Mock weekly progress data
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final mockProgressData = List.generate(7, (index) {
      final date = weekAgo.add(Duration(days: index));
      final points =
          15 + (index * 5) + (index % 3 == 0 ? 10 : 0); // Variable points

      return ProgressData(
        date: date,
        points: points,
        badgesEarned:
            index == 6
                ? [
                  Badge(
                    id: 'streak_7',
                    title: 'Week Warrior',
                    description: 'Complete 7 days in a row',
                    imagePath: 'assets/badges/streak_7.png',
                    category: BadgeCategory.streak,
                    isEarned: true,
                    earnedAt: date,
                    requiredPoints: 7,
                    currentProgress: 7,
                  ),
                ]
                : [],
      );
    });

    return mockProgressData;
  } catch (e) {
    return [];
  }
});

/// Provider for active challenges
final challengeProvider = StreamProvider<List<Challenge>>((ref) async* {
  try {
    // Mock challenges data - replace with real stream when backend ready
    final mockChallenges = [
      Challenge(
        id: 'daily_chat',
        title: 'Daily Check-in',
        description: 'Chat with your coach for 3 days this week',
        type: ChallengeType.coachChats,
        targetValue: 3,
        currentProgress: 2,
        expiresAt: DateTime.now().add(const Duration(days: 2)),
        isAccepted: true,
        rewardPoints: 50,
      ),
      Challenge(
        id: 'momentum_burst',
        title: 'Momentum Burst',
        description: 'Earn 30 momentum points this week',
        type: ChallengeType.momentumPoints,
        targetValue: 30,
        currentProgress: 18,
        expiresAt: DateTime.now().add(const Duration(days: 4)),
        isAccepted: false,
        rewardPoints: 25,
      ),
      Challenge(
        id: 'feed_reader',
        title: 'Knowledge Seeker',
        description: 'Read 5 Today Feed articles',
        type: ChallengeType.todayFeed,
        targetValue: 5,
        currentProgress: 3,
        expiresAt: DateTime.now().add(const Duration(days: 6)),
        isAccepted: true,
        rewardPoints: 30,
      ),
    ];

    yield mockChallenges;

    // Simulate real-time updates
    await Future.delayed(const Duration(seconds: 30));

    // Update progress slightly
    final updatedChallenges =
        mockChallenges.map((challenge) {
          if (challenge.id == 'daily_chat' &&
              challenge.currentProgress < challenge.targetValue) {
            return Challenge(
              id: challenge.id,
              title: challenge.title,
              description: challenge.description,
              type: challenge.type,
              targetValue: challenge.targetValue,
              currentProgress: challenge.currentProgress + 1,
              expiresAt: challenge.expiresAt,
              isAccepted: challenge.isAccepted,
              rewardPoints: challenge.rewardPoints,
            );
          }
          return challenge;
        }).toList();

    yield updatedChallenges;
  } catch (e) {
    yield [];
  }
});

/// Provider for total points
final totalPointsProvider = FutureProvider<int>((ref) async {
  try {
    // Calculate from progress data
    final progressData = await ref.read(progressProvider.future);
    return progressData.fold<int>(0, (total, data) => total + data.points);
  } catch (e) {
    return 0;
  }
});

/// Provider for earned badges count
final earnedBadgesCountProvider = FutureProvider<int>((ref) async {
  try {
    final badges = await ref.read(achievementsProvider.future);
    return badges.where((badge) => badge.isEarned).length;
  } catch (e) {
    return 0;
  }
});

/// Provider for current streak (reusing existing streak provider)
final currentStreakProvider = FutureProvider<int>((ref) async {
  try {
    // This would integrate with existing streak service
    return 7; // Mock value
  } catch (e) {
    return 0;
  }
});

/// Provider for challenge acceptance action
final challengeActionProvider =
    Provider<Future<void> Function(String challengeId, bool accept)>((ref) {
      return (String challengeId, bool accept) async {
        try {
          // Mock challenge acceptance - replace with actual API call
          debugPrint('Challenge $challengeId ${accept ? 'accepted' : 'declined'}');

          // Refresh challenges after action
          ref.invalidate(challengeProvider);
        } catch (e) {
          debugPrint('Error updating challenge: $e');
        }
      };
    });
