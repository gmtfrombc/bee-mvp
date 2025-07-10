import '../models/ai_tags.dart';
import '../../features/onboarding/models/onboarding_draft.dart';

/// Service that converts onboarding survey answers (Q13, Q14, Q16)
/// into a [MotivationType] classification based on the rules
/// defined in docs/MVP_ROADMAP/1-11 Onboarding/Onboarding_Survey_Scoring.md.
///
/// Each answer choice maps to an integer score. The sum of the
/// three scores is then mapped onto a MotivationType.
class MotivationScoringService {
  MotivationScoringService._();

  /// Calculate the [MotivationType] given the raw radio keys that come from
  /// [MindsetPage] widgets.
  ///
  /// [motivationReasonKey] – value from Q13 radio (e.g. "feel_better").
  /// [satisfactionOutcomeKey] – value from Q14 radio (e.g. "proud").
  /// [coachStyleKey] – value from Q16 radio (e.g. "right_hand").
  static MotivationType calculate({
    required String? motivationReasonKey,
    required String? satisfactionOutcomeKey,
    required String? coachStyleKey,
  }) {
    final score =
        _scoreQ13(motivationReasonKey) +
        _scoreQ14(satisfactionOutcomeKey) +
        _scoreQ16(coachStyleKey);

    if (score >= 5) return MotivationType.internal;
    if (score >= 3) return MotivationType.mixed;
    if (score >= 1) return MotivationType.external;
    return MotivationType.unclear;
  }

  /// Convenience wrapper that pulls answers from an [OnboardingDraft].
  static MotivationType fromDraft(OnboardingDraft draft) => calculate(
    motivationReasonKey: draft.motivationReason,
    satisfactionOutcomeKey: draft.satisfactionOutcome,
    coachStyleKey: draft.mindsetType,
  );

  // ---------------------------------------------------------------------------
  // Private helpers – per-question score lookup tables
  // ---------------------------------------------------------------------------
  static int _scoreQ13(String? key) {
    switch (key) {
      case 'feel_better':
      case 'take_care':
        return 2;
      case 'look_better':
        return 1;
      case 'social_pressure':
      case 'someone_else':
        return 0;
      default:
        return 0; // Treat unknown / null as 0
    }
  }

  static int _scoreQ14(String? key) {
    switch (key) {
      case 'proud':
        return 2;
      case 'prove':
      case 'avoid_health_problems':
        return 1;
      case 'seen_differently':
        return 0;
      default:
        return 0;
    }
  }

  static int _scoreQ16(String? key) {
    switch (key) {
      case 'right_hand':
        return 2;
      case 'cheerleader':
        return 1;
      case 'drill_sergeant':
      case 'not_sure':
        return 0;
      default:
        return 0;
    }
  }
}
