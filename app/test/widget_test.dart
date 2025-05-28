// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/momentum/presentation/screens/momentum_screen.dart';
import 'package:app/core/theme/app_theme.dart';

import 'helpers/test_helpers.dart';

void main() {
  // Setup test environment before all tests
  setUpAll(() async {
    await TestHelpers.setUpTest();
  });

  testWidgets('BEE app basic UI test', (WidgetTester tester) async {
    // Use TestHelpers to create test app with proper provider overrides
    await TestHelpers.pumpTestWidget(
      tester,
      child: const MomentumScreen(),
      settleDuration: const Duration(milliseconds: 500),
    );

    // Verify that the app loads without crashing
    expect(find.text('Welcome back, Sarah!'), findsOneWidget);

    // Verify basic UI elements are present
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);

    // Wait for any loading states to complete
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify that some content is displayed (either loaded data or skeleton)
    expect(find.byType(Card), findsWidgets);
  });

  testWidgets('App theme and basic styling test', (WidgetTester tester) async {
    await TestHelpers.pumpTestWidget(tester, child: const MomentumScreen());

    // Verify theme is applied
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.theme, equals(AppTheme.lightTheme));

    // Verify app bar styling
    expect(find.byType(AppBar), findsOneWidget);

    // Wait for any animations
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });

  testWidgets('Navigation elements test', (WidgetTester tester) async {
    await TestHelpers.pumpTestWidget(tester, child: const MomentumScreen());

    // Verify navigation elements are present
    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);

    // Test tapping navigation elements (should not crash)
    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pump();

    // Wait for any animations
    await tester.pumpAndSettle();
  });

  testWidgets('Scroll behavior test', (WidgetTester tester) async {
    await TestHelpers.pumpTestWidget(
      tester,
      child: const MomentumScreen(),
      settleDuration: const Duration(seconds: 2),
    );

    // Find the scrollable widget
    final scrollable = find.byType(SingleChildScrollView);
    expect(scrollable, findsOneWidget);

    // Test scrolling (should not crash)
    await tester.drag(scrollable, const Offset(0, -200));
    await tester.pump();

    await tester.drag(scrollable, const Offset(0, 200));
    await tester.pump();

    await tester.pumpAndSettle();
  });

  testWidgets('Widget hierarchy test', (WidgetTester tester) async {
    await TestHelpers.pumpTestWidget(
      tester,
      child: const MomentumScreen(),
      settleDuration: const Duration(seconds: 3),
    );

    // Verify the basic widget hierarchy
    expect(find.byType(ProviderScope), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(SafeArea), findsWidgets);
    expect(find.byType(SingleChildScrollView), findsOneWidget);

    // Verify cards are present (either content or skeleton)
    expect(find.byType(Card), findsWidgets);

    // Verify containers are present
    expect(find.byType(Container), findsWidgets);
  });
}
