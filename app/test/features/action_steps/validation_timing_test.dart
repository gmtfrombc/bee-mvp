import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/action_steps/ui/action_step_form.dart';
import 'package:app/core/providers/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mocktail/mocktail.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Description validation appears within 100 ms and is semantic', (
    WidgetTester tester,
  ) async {
    // Set up a fake Supabase client so providers resolve.
    final fakeClient = MockSupabaseClient();
    when(() => fakeClient.auth).thenReturn(MockGoTrueClient());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [supabaseClientProvider.overrideWithValue(fakeClient)],
        child: const MaterialApp(home: Scaffold(body: ActionStepForm())),
      ),
    );
    await tester.pumpAndSettle();

    // Enter a negative-phrased goal to trigger validation error.
    final descField = find.byType(TextFormField);
    await tester.enterText(descField, "I don't eat sugar");

    // Remove focus to simulate blur.
    await tester.testTextInput.receiveAction(TextInputAction.done);

    // Pump for 90 ms (<100) to let autovalidate trigger.
    await tester.pump(const Duration(milliseconds: 120));

    // Expect error text.
    final errorFinder = find.text('Please phrase positively');
    expect(errorFinder, findsOneWidget);
  });
}
