import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:app/core/services/auth_session_service.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('AuthSessionService integration', () {
    late _MockSupabaseClient mockClient;
    late _MockGoTrueClient mockAuth;
    late _MockSecureStorage mockStorage;
    late AuthSessionService service;

    const jsonSession =
        '{"provider_token":null,"access_token":"access","refresh_token":"refresh"}';

    setUp(() {
      mockClient = _MockSupabaseClient();
      mockAuth = _MockGoTrueClient();
      mockStorage = _MockSecureStorage();
      when(() => mockClient.auth).thenReturn(mockAuth);
      service = AuthSessionService(client: mockClient, storage: mockStorage);
    });

    test('session restored in under 300ms', () async {
      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => jsonSession);
      when(
        () => mockAuth.setSession(jsonSession),
      ).thenAnswer((_) async => AuthResponse(session: null, user: null));

      final stopwatch = Stopwatch()..start();
      await service.restore();
      stopwatch.stop();

      verify(() => mockAuth.setSession(jsonSession)).called(1);
      expect(stopwatch.elapsedMilliseconds, lessThan(300));
    });
  });
}
