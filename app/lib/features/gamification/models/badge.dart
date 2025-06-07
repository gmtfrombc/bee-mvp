/// Badge model for achievements and gamification system
class Badge {
  final String id;
  final String title;
  final String description;
  final String imagePath;
  final BadgeCategory category;
  final bool isEarned;
  final DateTime? earnedAt;
  final int requiredPoints;
  final int? currentProgress;

  const Badge({
    required this.id,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.category,
    required this.isEarned,
    this.earnedAt,
    required this.requiredPoints,
    this.currentProgress,
  });

  /// Get progress percentage (0.0 to 1.0)
  double get progressPercentage {
    if (isEarned) return 1.0;
    if (currentProgress == null) return 0.0;
    return (currentProgress! / requiredPoints).clamp(0.0, 1.0);
  }

  /// Create from JSON
  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      imagePath: json['image_path'],
      category: BadgeCategory.fromValue(json['category']),
      isEarned: json['is_earned'] ?? false,
      earnedAt:
          json['earned_at'] != null ? DateTime.parse(json['earned_at']) : null,
      requiredPoints: json['required_points'] ?? 0,
      currentProgress: json['current_progress'],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image_path': imagePath,
      'category': category.value,
      'is_earned': isEarned,
      'earned_at': earnedAt?.toIso8601String(),
      'required_points': requiredPoints,
      'current_progress': currentProgress,
    };
  }

  Badge copyWith({
    String? id,
    String? title,
    String? description,
    String? imagePath,
    BadgeCategory? category,
    bool? isEarned,
    DateTime? earnedAt,
    int? requiredPoints,
    int? currentProgress,
  }) {
    return Badge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      category: category ?? this.category,
      isEarned: isEarned ?? this.isEarned,
      earnedAt: earnedAt ?? this.earnedAt,
      requiredPoints: requiredPoints ?? this.requiredPoints,
      currentProgress: currentProgress ?? this.currentProgress,
    );
  }
}

/// Badge categories for organization
enum BadgeCategory {
  streak('streak'),
  momentum('momentum'),
  engagement('engagement'),
  milestone('milestone'),
  special('special');

  const BadgeCategory(this.value);
  final String value;

  static BadgeCategory fromValue(String value) {
    return BadgeCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => BadgeCategory.special,
    );
  }

  String get displayName {
    switch (this) {
      case BadgeCategory.streak:
        return 'Streak';
      case BadgeCategory.momentum:
        return 'Momentum';
      case BadgeCategory.engagement:
        return 'Engagement';
      case BadgeCategory.milestone:
        return 'Milestone';
      case BadgeCategory.special:
        return 'Special';
    }
  }
}

/// Progress data for charts
class ProgressData {
  final DateTime date;
  final int points;
  final List<Badge> badgesEarned;

  const ProgressData({
    required this.date,
    required this.points,
    required this.badgesEarned,
  });

  factory ProgressData.fromJson(Map<String, dynamic> json) {
    return ProgressData(
      date: DateTime.parse(json['date']),
      points: json['points'] ?? 0,
      badgesEarned:
          (json['badges_earned'] as List<dynamic>?)
              ?.map((badge) => Badge.fromJson(badge))
              .toList() ??
          [],
    );
  }
}

/// Challenge data model
class Challenge {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final int targetValue;
  final int currentProgress;
  final DateTime expiresAt;
  final bool isAccepted;
  final int rewardPoints;

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.targetValue,
    required this.currentProgress,
    required this.expiresAt,
    required this.isAccepted,
    required this.rewardPoints,
  });

  /// Get progress percentage (0.0 to 1.0)
  double get progressPercentage {
    return (currentProgress / targetValue).clamp(0.0, 1.0);
  }

  /// Check if challenge is completed
  bool get isCompleted {
    return currentProgress >= targetValue;
  }

  /// Check if challenge is expired
  bool get isExpired {
    return DateTime.now().isAfter(expiresAt);
  }

  /// Get time remaining as human readable string
  String get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return 'Expired';

    final difference = expiresAt.difference(now);
    if (difference.inDays > 0) {
      return '${difference.inDays}d left';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h left';
    } else {
      return '${difference.inMinutes}m left';
    }
  }

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: ChallengeType.fromValue(json['type']),
      targetValue: json['target_value'] ?? 0,
      currentProgress: json['current_progress'] ?? 0,
      expiresAt: DateTime.parse(json['expires_at']),
      isAccepted: json['is_accepted'] ?? false,
      rewardPoints: json['reward_points'] ?? 0,
    );
  }
}

/// Challenge types
enum ChallengeType {
  dailyStreak('daily_streak'),
  coachChats('coach_chats'),
  momentumPoints('momentum_points'),
  todayFeed('today_feed');

  const ChallengeType(this.value);
  final String value;

  static ChallengeType fromValue(String value) {
    return ChallengeType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ChallengeType.momentumPoints,
    );
  }

  String get displayName {
    switch (this) {
      case ChallengeType.dailyStreak:
        return 'Daily Streak';
      case ChallengeType.coachChats:
        return 'Coach Chats';
      case ChallengeType.momentumPoints:
        return 'Momentum Points';
      case ChallengeType.todayFeed:
        return 'Today Feed';
    }
  }
}
