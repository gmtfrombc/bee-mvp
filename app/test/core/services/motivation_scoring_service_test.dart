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

    test('returns Unclear for zero score / unknown answers', () {
      final type = MotivationScoringService.calculate(
        motivationReasonKey: null,
        satisfactionOutcomeKey: 'seen_differently',
        coachStyleKey: 'not_sure',
      );
      expect(type, MotivationType.unclear);
    });
  });
}
