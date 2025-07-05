import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/core/services/auth_service.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  group('AuthService.signUpWithEmail', () {
    late _MockSupabaseClient mockClient;
    late _MockGoTrueClient mockAuth;
    late AuthService service;

    setUp(() {
      mockClient = _MockSupabaseClient();
      mockAuth = _MockGoTrueClient();
      when(() => mockClient.auth).thenReturn(mockAuth);
      service = AuthService(mockClient);
    });

    test(
      'passes emailRedirectTo="https://storage.googleapis.com/bee-auth-redirect/index.html" to Supabase',
      () async {
        const email = 'test@example.com';
        const password = 'password123';

        // Stub signUp to succeed.
        when(
          () => mockAuth.signUp(
            email: email,
            password: password,
            data: any(named: 'data'),
            emailRedirectTo:
                'https://storage.googleapis.com/bee-auth-redirect/index.html',
          ),
        ).thenAnswer((_) async => AuthResponse(session: null, user: null));

        await service.signUpWithEmail(email: email, password: password);

        verify(
          () => mockAuth.signUp(
            email: email,
            password: password,
            data: any(named: 'data'),
            emailRedirectTo:
                'https://storage.googleapis.com/bee-auth-redirect/index.html',
          ),
        ).called(1);
      },
    );
  });
}
