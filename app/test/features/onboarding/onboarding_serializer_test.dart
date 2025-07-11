import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/onboarding/data/onboarding_serializer.dart';
import 'package:app/features/onboarding/models/onboarding_draft.dart';
import 'package:app/core/models/medical_history.dart';

void main() {
  group('OnboardingSerializer', () {
    test('round-trip preserves all data', () {
      final original = OnboardingDraft(
        dateOfBirth: DateTime(1990, 1, 1),
        gender: 'female',
        culture: 'en-US',
        preferences: const ['activity', 'nutrition'],
        priorities: const ['nutrition'],
        readinessLevel: 4,
        confidenceLevel: 5,
        mindsetType: 'growth',
        motivationReason: 'Feel better',
        satisfactionOutcome: 'Lose weight',
        challengeResponse: 'Time',
        weightLb: 140,
        heightFt: 5,
        heightIn: 6,
        bpSystolic: 120,
        bpDiastolic: 80,
        medicalConditions: const [MedicalCondition.hypertension],
        goalTarget: 'Lose 10 lb',
      );

      final json = OnboardingSerializer.toJson(original);
      final restored = OnboardingSerializer.fromJson(json);

      expect(restored, equals(original));
    });

    test('null and empty list fields are omitted', () {
      const partial = OnboardingDraft(
        gender: 'male',
        preferences: ['activity'],
      );

      final json = OnboardingSerializer.toJson(partial);

      expect(json.containsKey('dateOfBirth'), isFalse);
      expect(json.containsKey('culture'), isFalse);
      expect(json['preferences'], isNotEmpty);
      expect(json['gender'], equals('male'));
    });

    test('medical conditions encode and decode correctly', () {
      const draft = OnboardingDraft(
        preferences: ['nutrition'],
        medicalConditions: [MedicalCondition.anxiety, MedicalCondition.none],
      );

      final json = OnboardingSerializer.toJson(draft);
      expect(json['medicalConditions'], equals(['anxiety', 'none']));

      final back = OnboardingSerializer.fromJson(json);
      expect(back.medicalConditions, equals(draft.medicalConditions));
    });
  });
}
