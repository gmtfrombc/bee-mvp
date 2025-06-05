import 'package:share_plus/share_plus.dart';

// Data models for Today Feed sharing service results

/// Result of sharing action
class SharingResult {
  final bool success;
  final String message;
  final ShareResultStatus? shareStatus;
  final MomentumBonusResult? momentumBonus;
  final String? shareText;
  final String? error;
  final bool isQueued;
  final int? dailyCount;
  final int? maxDailyCount;

  const SharingResult({
    required this.success,
    required this.message,
    this.shareStatus,
    this.momentumBonus,
    this.shareText,
    this.error,
    this.isQueued = false,
    this.dailyCount,
    this.maxDailyCount,
  });

  factory SharingResult.success({
    required ShareResultStatus shareStatus,
    MomentumBonusResult? momentumBonus,
    String? shareText,
  }) {
    return SharingResult(
      success: true,
      message: 'Content shared successfully',
      shareStatus: shareStatus,
      momentumBonus: momentumBonus,
      shareText: shareText,
    );
  }

  factory SharingResult.limitExceeded({
    required String message,
    required int dailyCount,
    required int maxDailyCount,
  }) {
    return SharingResult(
      success: false,
      message: message,
      dailyCount: dailyCount,
      maxDailyCount: maxDailyCount,
    );
  }

  factory SharingResult.queued({required String message}) {
    return SharingResult(success: true, message: message, isQueued: true);
  }

  factory SharingResult.failed({required String message, String? error}) {
    return SharingResult(success: false, message: message, error: error);
  }
}

/// Result of bookmark action
class BookmarkResult {
  final bool success;
  final String message;
  final MomentumBonusResult? momentumBonus;
  final String? bookmarkId;
  final String? error;
  final bool isQueued;
  final bool isAlreadyBookmarked;
  final bool isRemoved;
  final int? dailyCount;
  final int? maxDailyCount;

  const BookmarkResult({
    required this.success,
    required this.message,
    this.momentumBonus,
    this.bookmarkId,
    this.error,
    this.isQueued = false,
    this.isAlreadyBookmarked = false,
    this.isRemoved = false,
    this.dailyCount,
    this.maxDailyCount,
  });

  factory BookmarkResult.success({
    MomentumBonusResult? momentumBonus,
    String? bookmarkId,
  }) {
    return BookmarkResult(
      success: true,
      message: 'Content bookmarked successfully',
      momentumBonus: momentumBonus,
      bookmarkId: bookmarkId,
    );
  }

  factory BookmarkResult.alreadyBookmarked({required String message}) {
    return BookmarkResult(
      success: false,
      message: message,
      isAlreadyBookmarked: true,
    );
  }

  factory BookmarkResult.notBookmarked({required String message}) {
    return BookmarkResult(success: false, message: message);
  }

  factory BookmarkResult.removed({required String message}) {
    return BookmarkResult(success: true, message: message, isRemoved: true);
  }

  factory BookmarkResult.limitExceeded({
    required String message,
    required int dailyCount,
    required int maxDailyCount,
  }) {
    return BookmarkResult(
      success: false,
      message: message,
      dailyCount: dailyCount,
      maxDailyCount: maxDailyCount,
    );
  }

  factory BookmarkResult.queued({required String message}) {
    return BookmarkResult(success: true, message: message, isQueued: true);
  }

  factory BookmarkResult.failed({required String message, String? error}) {
    return BookmarkResult(success: false, message: message, error: error);
  }
}

/// Result of momentum bonus award
class MomentumBonusResult {
  final bool success;
  final int bonusPoints;
  final String message;
  final DateTime? awardTime;
  final String? error;

  const MomentumBonusResult({
    required this.success,
    required this.bonusPoints,
    required this.message,
    this.awardTime,
    this.error,
  });

  factory MomentumBonusResult.success({
    required int bonusPoints,
    required String message,
    required DateTime awardTime,
  }) {
    return MomentumBonusResult(
      success: true,
      bonusPoints: bonusPoints,
      message: message,
      awardTime: awardTime,
    );
  }

  factory MomentumBonusResult.failed({required String message, String? error}) {
    return MomentumBonusResult(
      success: false,
      bonusPoints: 0,
      message: message,
      error: error,
    );
  }
}

/// Result of action limit checking
class ActionLimitResult {
  final bool canProceed;
  final String reason;
  final int currentCount;

  const ActionLimitResult({
    required this.canProceed,
    required this.reason,
    required this.currentCount,
  });
}

/// Social engagement statistics
class SocialEngagementStats {
  final int totalShares;
  final int totalBookmarks;
  final int todayShares;
  final int todayBookmarks;
  final int sharesRemaining;
  final int bookmarksRemaining;
  final int monthlyShares;
  final int monthlyBookmarks;

  const SocialEngagementStats({
    required this.totalShares,
    required this.totalBookmarks,
    required this.todayShares,
    required this.todayBookmarks,
    required this.sharesRemaining,
    required this.bookmarksRemaining,
    required this.monthlyShares,
    required this.monthlyBookmarks,
  });

  const SocialEngagementStats.empty()
    : totalShares = 0,
      totalBookmarks = 0,
      todayShares = 0,
      todayBookmarks = 0,
      sharesRemaining = 3, // maxDailyShareBonuses
      bookmarksRemaining = 5, // maxDailyBookmarkBonuses
      monthlyShares = 0,
      monthlyBookmarks = 0;
}
