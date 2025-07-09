class OnboardingDraft {
  final DateTime? dateOfBirth;
  final String? gender; // "male", "female", "non_binary", etc.
  final String? culture; // Free-text 64 chars max
  final List<String> preferences; // "activity", "nutrition", etc.

  const OnboardingDraft({
    this.dateOfBirth,
    this.gender,
    this.culture,
    this.preferences = const [],
  });

  OnboardingDraft copyWith({
    DateTime? dateOfBirth,
    String? gender,
    String? culture,
    List<String>? preferences,
  }) {
    return OnboardingDraft(
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      culture: culture ?? this.culture,
      preferences: preferences ?? this.preferences,
    );
  }

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
