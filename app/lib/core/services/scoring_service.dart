import '../models/ai_tags.dart';
import 'ai_tag_generation_service.dart';
import '../../features/onboarding/models/onboarding_draft.dart';

/// ScoringService is the public façade used by higher-level layers
/// (controllers, repositories) to compute personalisation tags from an
/// [OnboardingDraft]. It delegates to [AiTagGenerationService] so that the
/// underlying rules live in one place while providing a cleaner, descriptive
/// API name requested by product docs (see T2.1).
class ScoringService {
  ScoringService._();

  /// Compute `motivationType`, `readinessLevel`, and `coachStyle` for the given
  /// [draft].
  static AiTags computeTags(OnboardingDraft draft) {
    return AiTagGenerationService.generateFromDraft(draft);
  }
}
