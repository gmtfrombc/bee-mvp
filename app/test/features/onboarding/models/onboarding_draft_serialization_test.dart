import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/onboarding/models/onboarding_draft.dart';

void main() {
  group('OnboardingDraft JSON serialization', () {
    test('round-trip retains all fields', () {
      final draft = OnboardingDraft(
        dateOfBirth: DateTime(1990, 1, 1),
        gender: 'female',
        culture: 'US',
        preferences: const ['activity', 'nutrition'],
        readinessLevel: 4,
        mindsetType: 'growth',
      );

      final json = draft.toJson();
      final restored = OnboardingDraft.fromJson(json);
      expect(restored, equals(draft));
    });

    test('default constructor serialises/deserialises', () {
      const draft = OnboardingDraft();
      final json = draft.toJson();
      final restored = OnboardingDraft.fromJson(json);
      expect(restored, equals(draft));
    });
  });
}
