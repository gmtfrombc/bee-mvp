import 'package:flutter/foundation.dart';

class OnboardingDraft {
  final DateTime? dateOfBirth;
  final String? gender; // "male", "female", "non_binary", etc.
  final String? culture; // Free-text 64 chars max
  final List<String> preferences; // "activity", "nutrition", etc.
  final int? readinessLevel; // 1–5 Likert scale score
  final String? mindsetType; // e.g. "growth", "fixed"

  const OnboardingDraft({
    this.dateOfBirth,
    this.gender,
    this.culture,
    this.preferences = const [],
    this.readinessLevel,
    this.mindsetType,
  });

  OnboardingDraft copyWith({
    DateTime? dateOfBirth,
    String? gender,
    String? culture,
    List<String>? preferences,
    int? readinessLevel,
    String? mindsetType,
  }) {
    return OnboardingDraft(
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      culture: culture ?? this.culture,
      preferences: preferences ?? this.preferences,
      readinessLevel: readinessLevel ?? this.readinessLevel,
      mindsetType: mindsetType ?? this.mindsetType,
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
      readinessLevel: json['readinessLevel'] as int?,
      mindsetType: json['mindsetType'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'dateOfBirth': dateOfBirth?.toIso8601String(),
    'gender': gender,
    'culture': culture,
    'preferences': preferences,
    'readinessLevel': readinessLevel,
    'mindsetType': mindsetType,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OnboardingDraft &&
        dateOfBirth == other.dateOfBirth &&
        gender == other.gender &&
        culture == other.culture &&
        listEquals(preferences, other.preferences) &&
        readinessLevel == other.readinessLevel &&
        mindsetType == other.mindsetType;
  }

  @override
  int get hashCode => Object.hash(
    dateOfBirth,
    gender,
    culture,
    Object.hashAll(preferences),
    readinessLevel,
    mindsetType,
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
