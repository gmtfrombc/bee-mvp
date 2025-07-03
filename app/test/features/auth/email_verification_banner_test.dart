import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/auth/ui/widgets/email_verification_banner.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EmailVerificationBanner', () {
    testWidgets('is hidden when no verification needed', (tester) async {
      const authState = AuthState(AuthChangeEvent.signedIn, null); // no user

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(authState)),
          ],
          child: const MaterialApp(
            home: Scaffold(body: EmailVerificationBanner()),
          ),
        ),
      );

      // Banner widget exists in tree but should render nothing meaningful
      expect(find.byIcon(Icons.email), findsNothing);
    });
  });
}
