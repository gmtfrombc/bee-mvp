import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_provider.dart';
import '../models/onboarding_draft.dart';
import '../../../core/services/onboarding_draft_storage_service.dart';
import 'onboarding_serializer.dart';

/// Exception thrown when onboarding submission fails.
class OnboardingSubmissionException implements Exception {
  final String message;
  OnboardingSubmissionException(this.message);

  @override
  String toString() => 'OnboardingSubmissionException: $message';
}

/// Repository responsible for persisting onboarding data to Supabase.
class OnboardingRepository {
  final SupabaseClient _client;
  final OnboardingDraftStorageService _storage;

  OnboardingRepository({
    required SupabaseClient client,
    OnboardingDraftStorageService? storage,
  }) : _client = client,
       _storage = storage ?? OnboardingDraftStorageService();

  /// Submits the given [draft] and optional personalisation tags to Supabase.
  ///
  /// On success the locally persisted draft is cleared.
  /// Throws [OnboardingSubmissionException] on any failure.
  Future<void> submit({
    required OnboardingDraft draft,
    String? motivationType,
    String? readinessLevel,
    String? coachStyle,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw OnboardingSubmissionException('No authenticated user.');
    }

    // Build RPC params (omit nulls for optional tags)
    final params = <String, dynamic>{
      'p_user_id': user.id,
      'p_answers': OnboardingSerializer.toJson(draft),
      if (motivationType != null) 'p_motivation_type': motivationType,
      if (readinessLevel != null) 'p_readiness_level': readinessLevel,
      if (coachStyle != null) 'p_coach_style': coachStyle,
    };

    try {
      final result = await _client.rpc('submit_onboarding', params: params);
      debugPrint('✅ submit_onboarding RPC returned: $result');
      await _storage.clear();
    } on PostgrestException catch (e, st) {
      debugPrint(
        '❌ PostgrestException during onboarding submit → '
        'code: ${e.code}, message: ${e.message}\n'
        'details: ${e.details}, hint: ${e.hint}\nStack: $st',
      );

      throw OnboardingSubmissionException(e.message);
    } catch (e, st) {
      debugPrint('❌ Unknown error during onboarding submit: $e\nStack: $st');
      throw OnboardingSubmissionException(e.toString());
    }
  }
}

/// Riverpod provider for [OnboardingRepository].
final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return OnboardingRepository(client: client);
});
