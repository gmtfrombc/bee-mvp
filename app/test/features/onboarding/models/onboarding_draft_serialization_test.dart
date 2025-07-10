import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/onboarding/models/onboarding_draft.dart';
import 'package:app/core/models/medical_history.dart';

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
        weightLb: 180,
        heightFt: 5,
        heightIn: 9,
        bpSystolic: 120,
        bpDiastolic: 80,
        medicalConditions: const [
          MedicalCondition.obesity,
          MedicalCondition.hypertension,
        ],
        goalTarget: 'Lose 10 lb',
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
