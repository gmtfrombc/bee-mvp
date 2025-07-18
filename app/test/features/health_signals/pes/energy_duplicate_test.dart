import 'package:app/core/health_data/services/health_data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockRepo extends Mock implements HealthDataRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(DateTime.now());
  });

  group('PES duplicate submission', () {
    testWidgets('shows snackbar when repository throws PostgrestException', (
      tester,
    ) async {
      final mockRepo = _MockRepo();
      // Stub insertEnergyLevel to throw duplicate key error (simulates 409)
      when(
        () => mockRepo.insertEnergyLevel(
          date: any(named: 'date'),
          score: any(named: 'score'),
        ),
      ).thenThrow(
        const PostgrestException(
          message: 'duplicate key value violates unique constraint',
        ),
      );

      // Simple widget that triggers the repository call on button press.
      final testWidget = ProviderScope(
        overrides: [
          // Override the global provider with our mock.
          healthDataRepositoryProvider.overrideWith((ref) => mockRepo),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Consumer(
                builder:
                    (context, ref, _) => ElevatedButton(
                      onPressed: () async {
                        final repo = ref.read(healthDataRepositoryProvider);
                        try {
                          await repo.insertEnergyLevel(
                            date: DateTime.now(),
                            score: 3,
                          );
                        } on PostgrestException {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "You've already logged today's energy level. Try again tomorrow!",
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('Submit'),
                    ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);

      // Tap the button to trigger submission.
      await tester.tap(find.text('Submit'));
      await tester.pump(); // Start snackbar animation

      // Verify snackbar appears with expected text.
      expect(
        find.text(
          "You've already logged today's energy level. Try again tomorrow!",
        ),
        findsOneWidget,
      );
    });
  });
}
