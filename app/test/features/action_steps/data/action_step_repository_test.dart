import 'package:app/features/action_steps/models/action_step.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/action_steps/data/action_step_repository.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  group('ActionStep model', () {
    test('fromJson maps correctly', () {
      final now = DateTime.now().toUtc();
      final json = {
        'id': '123',
        'category': 'movement',
        'description': 'Walk 5k steps',
        'frequency': 5,
        'week_start': now.toIso8601String(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final model = ActionStep.fromJson(json);
      expect(model.id, '123');
      expect(model.category, 'movement');
      expect(model.frequency, 5);
      expect(model.weekStart, now);
    });
  });

  group('ActionStepRepository', () {
    late _MockSupabaseClient mockClient;
    late _MockGoTrueClient mockAuth;
    late ActionStepRepository repo;

    setUp(() {
      mockClient = _MockSupabaseClient();
      mockAuth = _MockGoTrueClient();
      when(() => mockClient.auth).thenReturn(mockAuth);
      repo = ActionStepRepository(mockClient);
    });

    test('fetchCurrent returns null when unauthenticated', () async {
      when(() => mockAuth.currentUser).thenReturn(null);
      final result = await repo.fetchCurrent();
      expect(result, isNull);
    });
  });
}
