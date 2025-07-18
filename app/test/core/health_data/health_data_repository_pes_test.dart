import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/core/health_data/services/health_data_repository.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  group('HealthDataRepository.insertEnergyLevel', () {
    late _MockSupabaseClient mockClient;
    late _MockGoTrueClient mockAuth;
    // No need for PostgrestFilterBuilder for this minimal test set.
    late HealthDataRepository repo;

    setUp(() {
      mockClient = _MockSupabaseClient();
      mockAuth = _MockGoTrueClient();
      when(() => mockClient.auth).thenReturn(mockAuth);
      repo = HealthDataRepository(supabaseClient: mockClient);
    });

    test('throws StateError when no authenticated user', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      expect(
        () => repo.insertEnergyLevel(date: DateTime.now(), score: 3),
        throwsStateError,
      );
    });
  });
}
