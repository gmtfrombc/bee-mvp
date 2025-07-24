import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/features/action_steps/data/action_step_repository.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}
class _MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  group('ActionStepRepository.fetchHistory', () {
    late _MockSupabaseClient mockClient;
    late _MockGoTrueClient mockAuth;
    late ActionStepRepository repo;

    setUp(() {
      mockClient = _MockSupabaseClient();
      mockAuth = _MockGoTrueClient();
      when(() => mockClient.auth).thenReturn(mockAuth);
      repo = ActionStepRepository(mockClient);
    });

    test('returns empty list when unauthenticated', () async {
      // Arrange: unauthenticated user
      when(() => mockAuth.currentUser).thenReturn(null);

      // Act
      final result = await repo.fetchHistory();

      // Assert
      expect(result, isEmpty);
      // No DB query should occur
      verifyNever(() => mockClient.from(any()));
    });
  });
} 