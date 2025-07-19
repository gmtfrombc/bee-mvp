// ignore_for_file: unused_local_variable

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/features/onboarding/data/onboarding_repository.dart';
import 'package:app/features/onboarding/models/onboarding_draft.dart';
import 'package:app/core/services/onboarding_draft_storage_service.dart';

// ------------------------------ Mocks ---------------------------------------
class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

class _MockStorage extends Mock implements OnboardingDraftStorageService {}

class _MockRpcResult extends Mock implements PostgrestFilterBuilder<dynamic> {}

// The RPC call resolves to a JSON-like map which is ignored by the repository.

class FakeUser extends Fake implements User {
  @override
  String get id => 'test-user';
}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  group('OnboardingRepository.submit', () {
    late _MockSupabaseClient mockClient;
    late _MockGoTrueClient mockAuth;
    late _MockStorage mockStorage;
    late OnboardingRepository repo;
    const testDraft = OnboardingDraft(preferences: ['activity']);

    setUp(() {
      mockClient = _MockSupabaseClient();
      mockAuth = _MockGoTrueClient();
      mockStorage = _MockStorage();

      when(() => mockClient.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentUser).thenReturn(FakeUser());

      repo = OnboardingRepository(client: mockClient, storage: mockStorage);
    });

    test('calls Supabase RPC and clears storage on success', () async {
      // Arrange
      // Stub the Future `then` on the Postgrest builder so that awaiting it resolves.
      final builder = _MockRpcResult();
      when(
        () => builder.then<dynamic>(any(), onError: any(named: 'onError')),
      ).thenAnswer((invocation) {
        final onValue =
            invocation.positionalArguments[0] as dynamic Function(dynamic);
        return Future.value(<String, dynamic>{}).then(onValue);
      });
      when(
        () => mockClient.rpc('submit_onboarding', params: any(named: 'params')),
      ).thenAnswer((_) => builder);
      when(() => mockStorage.clear()).thenAnswer((_) async {});

      // Act
      await repo.submit(draft: testDraft);

      // Assert
      verify(
        () => mockClient.rpc('submit_onboarding', params: any(named: 'params')),
      ).called(1);
      verify(() => mockStorage.clear()).called(1);
    });

    test('throws OnboardingSubmissionException on RPC failure', () async {
      // Arrange
      when(
        () => mockClient.rpc('submit_onboarding', params: any(named: 'params')),
      ).thenThrow(Exception('RPC error'));

      // Act & Assert
      expect(
        () => repo.submit(draft: testDraft),
        throwsA(isA<OnboardingSubmissionException>()),
      );
    });
  });
}
