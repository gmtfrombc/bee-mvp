import 'dart:async';

import 'package:app/features/auth/ui/confirmation_pending_page.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app/core/providers/supabase_provider.dart';

class _FakeClient extends Mock implements SupabaseClient {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Stays on ConfirmationPendingPage when signedIn event has null session',
    (tester) async {
      final controller = StreamController<AuthState>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => controller.stream),
            supabaseProvider.overrideWith((ref) async => _FakeClient()),
          ],
          child: const MaterialApp(
            home: ConfirmationPendingPage(email: 'race@test.com'),
          ),
        ),
      );

      // Emit a signedIn event with a null session (race condition).
      controller.add(const AuthState(AuthChangeEvent.signedIn, null));

      // Pump a few frames to process the event without waiting for animations
      // to settle (the spinner runs indefinitely).
      await tester.pump(const Duration(milliseconds: 300));

      // The page should NOT navigate away because session is null.
      expect(find.byType(ConfirmationPendingPage), findsOneWidget);

      controller.close();
    },
  );
}
