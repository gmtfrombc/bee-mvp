import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/services/scoring_service.dart';
import 'package:app/core/models/ai_tags.dart';
import 'package:app/features/onboarding/models/onboarding_draft.dart';

void main() {
  group('ScoringService.computeTags', () {
    test('returns correct tags for high readiness internal profile', () {
      const draft = OnboardingDraft(
        readinessLevel: 5,
        mindsetType: 'cheerleader',
        motivationReason: 'feel_better',
        satisfactionOutcome: 'proud',
      );
      final tags = ScoringService.computeTags(draft);
      expect(tags.readinessLevel, ReadinessLevel.high);
      expect(tags.coachStyle, CoachStyle.cheerleader);
      expect(tags.motivationType, MotivationType.internal);
    });

    test('maps unknown coachStyle to unsure', () {
      const draft = OnboardingDraft(mindsetType: 'unknown');
      final tags = ScoringService.computeTags(draft);
      expect(tags.coachStyle, CoachStyle.unsure);
    });

    test('maps readiness 3 to moderate', () {
      const draft = OnboardingDraft(readinessLevel: 3);
      final tags = ScoringService.computeTags(draft);
      expect(tags.readinessLevel, ReadinessLevel.moderate);
    });
  });
}
