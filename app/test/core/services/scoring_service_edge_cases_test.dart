import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/services/scoring_service.dart';
import 'package:app/core/models/ai_tags.dart';
import 'package:app/features/onboarding/models/onboarding_draft.dart';

void main() {
  group('ScoringService.computeTags – edge cases', () {
    test('null readiness returns ReadinessLevel.low', () {
      const draft = OnboardingDraft();
      final tags = ScoringService.computeTags(draft);
      expect(tags.readinessLevel, ReadinessLevel.low);
    });

    test('readiness = 1 returns ReadinessLevel.low', () {
      const draft = OnboardingDraft(readinessLevel: 1);
      final tags = ScoringService.computeTags(draft);
      expect(tags.readinessLevel, ReadinessLevel.low);
    });

    test('coachStyle "right_hand" maps to CoachStyle.rightHand', () {
      const draft = OnboardingDraft(mindsetType: 'right_hand');
      final tags = ScoringService.computeTags(draft);
      expect(tags.coachStyle, CoachStyle.rightHand);
    });

    test('coachStyle "drill_sergeant" maps to CoachStyle.drillSergeant', () {
      const draft = OnboardingDraft(mindsetType: 'drill_sergeant');
      final tags = ScoringService.computeTags(draft);
      expect(tags.coachStyle, CoachStyle.drillSergeant);
    });

    test('low aggregate score (2) yields MotivationType.external', () {
      const draft = OnboardingDraft(
        motivationReason: 'look_better', // +1
        satisfactionOutcome: 'prove', // +1
        mindsetType: 'not_sure', // +0
      );
      final tags = ScoringService.computeTags(draft);
      expect(tags.motivationType, MotivationType.external);
    });

    test('all unknown answers yield MotivationType.unclear', () {
      const draft = OnboardingDraft(
        motivationReason: 'unknown_key',
        satisfactionOutcome: 'unknown_key',
        mindsetType: 'unknown_key',
      );
      final tags = ScoringService.computeTags(draft);
      expect(tags.motivationType, MotivationType.unclear);
      expect(tags.coachStyle, CoachStyle.unsure);
      expect(tags.readinessLevel, ReadinessLevel.low);
    });
  });
}
