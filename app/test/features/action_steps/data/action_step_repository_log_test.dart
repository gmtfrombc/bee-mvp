import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/features/action_steps/data/action_step_repository.dart';
import 'package:app/features/action_steps/models/action_step_day_status.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  group('ActionStepRepository logs', () {
    late _MockSupabaseClient mockClient;
    late _MockGoTrueClient mockAuth;
    late ActionStepRepository repo;

    setUp(() {
      mockClient = _MockSupabaseClient();
      mockAuth = _MockGoTrueClient();
      when(() => mockClient.auth).thenReturn(mockAuth);
      repo = ActionStepRepository(mockClient);
    });

    test('fetchDayStatus returns queued when unauthenticated', () async {
      when(() => mockAuth.currentUser).thenReturn(null);
      final status = await repo.fetchDayStatus(
        actionStepId: 'step-1',
        date: DateTime.utc(2025, 7, 24),
      );
      expect(status, ActionStepDayStatus.queued);
    });

    test('createLog short-circuits when unauthenticated', () async {
      when(() => mockAuth.currentUser).thenReturn(null);
      await repo.createLog(
        actionStepId: 'step-1',
        day: DateTime.utc(2025, 7, 24),
        status: ActionStepDayStatus.completed,
      );
      verifyNever(() => mockClient.from(any()));
    });
  });
}
