import 'package:flutter/foundation.dart';

class OnboardingDraft {
  final DateTime? dateOfBirth;
  final String? gender; // "male", "female", "non_binary", etc.
  final String? culture; // Free-text 64 chars max
  final List<String> preferences; // "activity", "nutrition", etc.
  final List<String> priorities; // Q10: Top 1-2 priorities
  final int? readinessLevel; // Q11: 1–5 Likert scale
  final int? confidenceLevel; // Q12: 1–5 Likert score
  final String? mindsetType; // e.g. "growth", "fixed"
  // Section 4 – Mindset & Motivation (Q13–15)
  final String? motivationReason; // Q13
  final String? satisfactionOutcome; // Q14
  final String? challengeResponse; // Q15

  const OnboardingDraft({
    this.dateOfBirth,
    this.gender,
    this.culture,
    this.preferences = const [],
    this.priorities = const [],
    this.readinessLevel,
    this.confidenceLevel,
    this.mindsetType,
    this.motivationReason,
    this.satisfactionOutcome,
    this.challengeResponse,
  });

  OnboardingDraft copyWith({
    DateTime? dateOfBirth,
    String? gender,
    String? culture,
    List<String>? preferences,
    List<String>? priorities,
    int? readinessLevel,
    int? confidenceLevel,
    String? mindsetType,
    String? motivationReason,
    String? satisfactionOutcome,
    String? challengeResponse,
  }) {
    return OnboardingDraft(
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      culture: culture ?? this.culture,
      preferences: preferences ?? this.preferences,
      priorities: priorities ?? this.priorities,
      readinessLevel: readinessLevel ?? this.readinessLevel,
      confidenceLevel: confidenceLevel ?? this.confidenceLevel,
      mindsetType: mindsetType ?? this.mindsetType,
      motivationReason: motivationReason ?? this.motivationReason,
      satisfactionOutcome: satisfactionOutcome ?? this.satisfactionOutcome,
      challengeResponse: challengeResponse ?? this.challengeResponse,
    );
  }

  factory OnboardingDraft.fromJson(Map<String, dynamic> json) {
    return OnboardingDraft(
      dateOfBirth:
          json['dateOfBirth'] != null
              ? DateTime.parse(json['dateOfBirth'] as String)
              : null,
      gender: json['gender'] as String?,
      culture: json['culture'] as String?,
      preferences:
          (json['preferences'] as List<dynamic>?)?.cast<String>() ?? const [],
      priorities:
          (json['priorities'] as List<dynamic>?)?.cast<String>() ?? const [],
      readinessLevel: json['readinessLevel'] as int?,
      confidenceLevel: json['confidenceLevel'] as int?,
      mindsetType: json['mindsetType'] as String?,
      motivationReason: json['motivationReason'] as String?,
      satisfactionOutcome: json['satisfactionOutcome'] as String?,
      challengeResponse: json['challengeResponse'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'dateOfBirth': dateOfBirth?.toIso8601String(),
    'gender': gender,
    'culture': culture,
    'preferences': preferences,
    'priorities': priorities,
    'readinessLevel': readinessLevel,
    'confidenceLevel': confidenceLevel,
    'mindsetType': mindsetType,
    'motivationReason': motivationReason,
    'satisfactionOutcome': satisfactionOutcome,
    'challengeResponse': challengeResponse,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OnboardingDraft &&
        dateOfBirth == other.dateOfBirth &&
        gender == other.gender &&
        culture == other.culture &&
        listEquals(preferences, other.preferences) &&
        listEquals(priorities, other.priorities) &&
        readinessLevel == other.readinessLevel &&
        confidenceLevel == other.confidenceLevel &&
        mindsetType == other.mindsetType &&
        motivationReason == other.motivationReason &&
        satisfactionOutcome == other.satisfactionOutcome &&
        challengeResponse == other.challengeResponse;
  }

  @override
  int get hashCode => Object.hash(
    dateOfBirth,
    gender,
    culture,
    Object.hashAll(preferences),
    Object.hashAll(priorities),
    readinessLevel,
    confidenceLevel,
    mindsetType,
    motivationReason,
    satisfactionOutcome,
    challengeResponse,
  );

  bool get isValid {
    final age = _ageInYears;
    final ageValid = age != null && age >= 13 && age <= 120;
    final prefsValid = preferences.isNotEmpty && preferences.length <= 5;
    return ageValid && prefsValid;
  }

  int? get _ageInYears {
    if (dateOfBirth == null) return null;
    final today = DateTime.now();
    int age = today.year - dateOfBirth!.year;
    final hadBirthdayThisYear =
        (today.month > dateOfBirth!.month) ||
        (today.month == dateOfBirth!.month && today.day >= dateOfBirth!.day);
    if (!hadBirthdayThisYear) {
      age -= 1;
    }
    return age;
  }
}
