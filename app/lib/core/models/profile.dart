/// User profile model corresponding to the `public.profiles` Supabase table.
///
/// Fields:
///   • `id` – UUID primary key matching `auth.users.id`.
///   • `onboardingComplete` – whether the user finished onboarding flow.
///   • `createdAt` – timestamp when the profile row was created.
///
/// The file is intentionally Flutter-free so it can be reused by core
/// services and tests without additional dependencies.
library;

class Profile {
  final String id;
  final bool onboardingComplete;
  final DateTime createdAt;

  const Profile({
    required this.id,
    required this.onboardingComplete,
    required this.createdAt,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      onboardingComplete: (map['onboarding_complete'] as bool?) ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'onboarding_complete': onboardingComplete,
    'created_at': createdAt.toIso8601String(),
  };

  Profile copyWith({
    String? id,
    bool? onboardingComplete,
    DateTime? createdAt,
  }) {
    return Profile(
      id: id ?? this.id,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'Profile(id: $id, onboardingComplete: $onboardingComplete, createdAt: $createdAt)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Profile &&
        other.id == id &&
        other.onboardingComplete == onboardingComplete &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode =>
      id.hashCode ^ onboardingComplete.hashCode ^ createdAt.hashCode;
}
