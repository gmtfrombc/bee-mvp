import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:app/core/services/auth_session_service.dart';

// ------------------------------ Mocks ---------------------------------------
class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  setUpAll(() {
    // No AuthState events needed for these tests
  });

  group('AuthSessionService.restore', () {
    late _MockSupabaseClient mockClient;
    late _MockGoTrueClient mockAuth;
    late _MockSecureStorage mockStorage;
    late AuthSessionService service;

    const testJson =
        '{"provider_token":null,"access_token":"access","refresh_token":"refresh"}';

    setUp(() {
      mockClient = _MockSupabaseClient();
      mockAuth = _MockGoTrueClient();
      mockStorage = _MockSecureStorage();
      when(() => mockClient.auth).thenReturn(mockAuth);
      service = AuthSessionService(client: mockClient, storage: mockStorage);
    });

    test('calls setSession when stored session exists', () async {
      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => testJson);
      when(
        () => mockAuth.setSession(testJson),
      ).thenAnswer((_) async => Future.value());

      await service.restore();

      verify(() => mockAuth.setSession(testJson)).called(1);
    });

    test('does nothing when no stored session', () async {
      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => null);

      await service.restore();

      verifyNever(() => mockAuth.setSession(any<String>()));
    });
  });
}
