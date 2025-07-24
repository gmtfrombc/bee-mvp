import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/action_steps/ui/my_action_step_page.dart';
import 'package:app/features/action_steps/data/action_step_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements ActionStepRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MyActionStepPage', () {
    testWidgets('shows NoStep view when provider returns null', (tester) async {
      final mockRepo = _MockRepo();
      when(() => mockRepo.fetchCurrent()).thenAnswer((_) async => null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [actionStepRepositoryProvider.overrideWithValue(mockRepo)],
          child: const MaterialApp(home: MyActionStepPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("You haven't set an Action Step yet."), findsOneWidget);
    });
  });
}
