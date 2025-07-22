import 'package:app/core/widgets/launch_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:app/features/auth/ui/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/core/providers/supabase_provider.dart';

class _FakeClient extends Mock implements SupabaseClient {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Splash shows at least 1500ms', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supabaseProvider.overrideWith((ref) async => _FakeClient()),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/',
            routes: [
              GoRoute(path: '/', builder: (_, __) => const LaunchController()),
              GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
            ],
          ),
        ),
      ),
    );

    // Immediately after pump, SplashScreen should be there.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Jump 1 000 ms – still splash.
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Jump past total 1 700 ms (> 1 500 ms) to account for async scheduling.
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
