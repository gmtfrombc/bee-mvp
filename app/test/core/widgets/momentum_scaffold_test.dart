import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/widgets/momentum_scaffold.dart';
import 'package:app/core/theme/app_theme.dart';

void main() {
  group('MomentumScaffold', () {
    testWidgets('renders with correct title and background color', (
      tester,
    ) async {
      const testTitle = 'Test Screen';
      const testBody = Text('Test Body');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MomentumScaffold(title: testTitle, body: testBody),
        ),
      );

      // Verify app bar title
      expect(find.text(testTitle), findsOneWidget);

      // Verify body content
      expect(find.text('Test Body'), findsOneWidget);

      // Verify scaffold background color
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(AppTheme.surfaceSecondary));
    });

    testWidgets('renders with floating action button when provided', (
      tester,
    ) async {
      const fabIcon = Icons.add;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MomentumScaffold(
            title: 'Test',
            body: const Text('Body'),
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              child: const Icon(fabIcon),
            ),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(fabIcon), findsOneWidget);
    });

    testWidgets('renders with custom actions when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MomentumScaffold(
            title: 'Test',
            body: const Text('Body'),
            actions: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.settings)),
            ],
          ),
        ),
      );

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });
  });

  group('MomentumAppBar', () {
    testWidgets('renders with correct title', (tester) async {
      const testTitle = 'App Bar Title';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            appBar: const MomentumAppBar(title: testTitle),
            body: const Text('Body'),
          ),
        ),
      );

      expect(find.text(testTitle), findsOneWidget);
    });

    testWidgets('has correct preferred size', (tester) async {
      const appBar = MomentumAppBar(title: 'Test');
      expect(
        appBar.preferredSize,
        equals(const Size.fromHeight(kToolbarHeight)),
      );
    });
  });
}
