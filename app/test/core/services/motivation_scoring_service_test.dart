import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/services/motivation_scoring_service.dart';
import 'package:app/core/models/ai_tags.dart';

void main() {
  group('MotivationScoringService', () {
    test('returns Internal for highest internalisation answers', () {
      final type = MotivationScoringService.calculate(
        motivationReasonKey: 'feel_better',
        satisfactionOutcomeKey: 'proud',
        coachStyleKey: 'right_hand',
      );
      expect(type, MotivationType.internal);
    });

    test('returns Mixed for mid-range answers', () {
      final type = MotivationScoringService.calculate(
        motivationReasonKey: 'look_better',
        satisfactionOutcomeKey: 'prove',
        coachStyleKey: 'cheerleader',
      );
      expect(type, MotivationType.mixed);
    });

    test('returns External for low but non-zero score', () {
      final type = MotivationScoringService.calculate(
        motivationReasonKey: 'look_better', // +1
        satisfactionOutcomeKey: 'prove', // +1
        coachStyleKey: 'drill_sergeant', // +0
      );
      expect(type, MotivationType.external);
    });

    test('returns Mixed for boundary score of 4', () {
      // Score breakdown: take_care (2) + avoid_health_problems (1) + cheerleader (1) = 4
      final type = MotivationScoringService.calculate(
        motivationReasonKey: 'take_care',
        satisfactionOutcomeKey: 'avoid_health_problems',
        coachStyleKey: 'cheerleader',
      );
      expect(type, MotivationType.mixed);
    });

    test('returns Internal for boundary score of 5', () {
      // Score breakdown: take_care (2) + proud (2) + cheerleader (1) = 5
      final type = MotivationScoringService.calculate(
        motivationReasonKey: 'take_care',
        satisfactionOutcomeKey: 'proud',
        coachStyleKey: 'cheerleader',
      );
      expect(type, MotivationType.internal);
    });

    test('treats unknown keys as 0 points leading to Unclear', () {
      final type = MotivationScoringService.calculate(
        motivationReasonKey: 'unknown_key', // 0
        satisfactionOutcomeKey: 'unknown_key', // 0
        coachStyleKey: 'unknown_key', // 0
      );
      expect(type, MotivationType.unclear);
    });
  });
}
