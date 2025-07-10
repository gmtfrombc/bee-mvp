import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/services/ai_tag_generation_service.dart';
import 'package:app/core/models/ai_tags.dart';
import 'package:app/features/onboarding/models/onboarding_draft.dart';

void main() {
  group('AiTagGenerationService', () {
    test(
      'generates expected tags for typical high readiness internal profile',
      () {
        const draft = OnboardingDraft(
          readinessLevel: 5,
          mindsetType: 'right_hand',
          motivationReason: 'feel_better',
          satisfactionOutcome: 'proud',
        );

        final tags = AiTagGenerationService.generateFromDraft(draft);

        expect(tags.motivationType, MotivationType.internal);
        expect(tags.readinessLevel, ReadinessLevel.high);
        expect(tags.coachStyle, CoachStyle.rightHand);
      },
    );

    test('maps readiness 3 to moderate', () {
      final tags = AiTagGenerationService.generateFromDraft(
        const OnboardingDraft(readinessLevel: 3),
      );
      expect(tags.readinessLevel, ReadinessLevel.moderate);
    });

    test('maps readiness null to low', () {
      final tags = AiTagGenerationService.generateFromDraft(
        const OnboardingDraft(),
      );
      expect(tags.readinessLevel, ReadinessLevel.low);
    });

    test('maps unknown coach style to unsure', () {
      final tags = AiTagGenerationService.generateFromDraft(
        const OnboardingDraft(mindsetType: 'unknown_value'),
      );
      expect(tags.coachStyle, CoachStyle.unsure);
    });
  });
}
