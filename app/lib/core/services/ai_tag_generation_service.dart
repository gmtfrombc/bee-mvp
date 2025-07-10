import '../models/ai_tags.dart';
import 'motivation_scoring_service.dart';
import '../../features/onboarding/models/onboarding_draft.dart';

/// Service responsible for producing an [AiTags] object that
/// combines the user’s motivation type, readiness level and preferred
/// coaching style based on their onboarding answers.
///
/// This is the single entry-point used downstream by repositories and edge
/// functions so that the mapping logic lives in one place.
class AiTagGenerationService {
  AiTagGenerationService._();

  /// Create the full set of AI tags from an [OnboardingDraft].
  static AiTags generateFromDraft(OnboardingDraft draft) {
    final motivation = MotivationScoringService.fromDraft(draft);
    final readiness = _mapReadinessLevel(draft.readinessLevel);
    final coachStyle = _mapCoachStyle(draft.mindsetType);

    return AiTags(
      motivationType: motivation,
      readinessLevel: readiness,
      coachStyle: coachStyle,
    );
  }

  // -------------------------------------------------------------------------
  // Private helpers – mapping functions
  // -------------------------------------------------------------------------
  static ReadinessLevel _mapReadinessLevel(int? likert) {
    if (likert == null) return ReadinessLevel.low;
    if (likert >= 4) return ReadinessLevel.high;
    if (likert == 3) return ReadinessLevel.moderate;
    return ReadinessLevel.low;
  }

  static CoachStyle _mapCoachStyle(String? key) {
    switch (key) {
      case 'right_hand':
        return CoachStyle.rightHand;
      case 'cheerleader':
        return CoachStyle.cheerleader;
      case 'drill_sergeant':
        return CoachStyle.drillSergeant;
      default:
        return CoachStyle.unsure;
    }
  }
}
