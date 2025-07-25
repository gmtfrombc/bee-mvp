import 'package:app/features/action_steps/ui/action_step_history_page.dart';
import 'package:app/features/action_steps/data/action_step_repository.dart';
import 'package:app/features/action_steps/models/action_step_history_entry.dart';
import 'package:app/features/action_steps/models/action_step.dart';
import 'package:app/features/action_steps/services/action_step_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements ActionStepRepository {}
class _FakeAnalytics extends Mock implements ActionStepAnalytics {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeAnalytics fakeAnalytics;

  setUpAll(() {
    fakeAnalytics = _FakeAnalytics();
    when(() => fakeAnalytics.logHistoryView()).thenAnswer((_) async {});
  });

  // Helper to generate a dummy ActionStep with minimal unique fields.
  ActionStep step(int idx) => ActionStep(
    id: 'id-$idx',
    category: 'fitness',
    description: 'Step $idx',
    frequency: 7,
    weekStart: DateTime.utc(2025, 7, 20).add(Duration(days: idx)),
    createdAt: DateTime.utc(2025, 7, 20),
    updatedAt: DateTime.utc(2025, 7, 20),
  );

  Widget buildTestApp({required ActionStepRepository repo}) {
    return ProviderScope(
      overrides: [
        actionStepRepositoryProvider.overrideWithValue(repo),
        actionStepAnalyticsProvider.overrideWithValue(fakeAnalytics),
      ],
      child: const MaterialApp(home: ActionStepHistoryPage()),
    );
  }

  group('ActionStepHistoryPage', () {
    late _MockRepo mockRepo;

    setUp(() {
      mockRepo = _MockRepo();
    });

    testWidgets('renders history entries from repository', (tester) async {
      // Arrange – repo returns 2 history items.
      when(
        () => mockRepo.fetchHistory(offset: 0, limit: any(named: 'limit')),
      ).thenAnswer(
        (_) async => [
          ActionStepHistoryEntry(step: step(0), completed: 5),
          ActionStepHistoryEntry(step: step(1), completed: 7),
        ],
      );

      await tester.pumpWidget(buildTestApp(repo: mockRepo));
      // Allow async fetch.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Assert – both descriptions appear.
      expect(find.text('Step 0'), findsOneWidget);
      expect(find.text('Step 1'), findsOneWidget);
    });

    testWidgets('loads more items when scrolled near bottom', (tester) async {
      // First page – 10 items.
      when(
        () => mockRepo.fetchHistory(offset: 0, limit: any(named: 'limit')),
      ).thenAnswer((invocation) async {
        final limit = invocation.namedArguments[#limit] as int;
        return List.generate(
          limit,
          (i) => ActionStepHistoryEntry(step: step(i), completed: 3),
        );
      });
      // Second page – 4 additional items.
      when(
        () => mockRepo.fetchHistory(offset: 10, limit: any(named: 'limit')),
      ).thenAnswer((invocation) async {
        return List.generate(
          4,
          (i) => ActionStepHistoryEntry(step: step(10 + i), completed: 3),
        );
      });

      await tester.pumpWidget(buildTestApp(repo: mockRepo));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Verify some initial items are present.
      expect(find.text('Step 0'), findsOneWidget);
      expect(find.text('Step 1'), findsOneWidget);

      // Scroll to trigger loadMore.
      await tester.drag(find.byType(ListView), const Offset(0, -4000));
      await tester.pump(); // start scroll
      await tester.pump(const Duration(seconds: 1)); // allow listener & fetch

      // Verify items from second page are present.
      expect(find.text('Step 10'), findsOneWidget);

      // Repository should have been called twice.
      verify(
        () => mockRepo.fetchHistory(offset: 0, limit: any(named: 'limit')),
      ).called(1);
      verify(
        () => mockRepo.fetchHistory(offset: 10, limit: any(named: 'limit')),
      ).called(1);
    });
  });
}
