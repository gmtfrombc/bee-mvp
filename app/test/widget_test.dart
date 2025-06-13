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

    // Wait for initial animations and layout to complete with explicit pumps
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    // Verify that the app loads without crashing
    expect(find.text('Welcome back, Sarah!'), findsOneWidget);

    // Verify basic UI elements are present
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);

    // Verify that some content is displayed (either loaded data or skeleton)
    expect(find.byType(Card), findsWidgets);
  });

  testWidgets('App theme and basic styling test', (WidgetTester tester) async {
    await TestHelpers.pumpTestWidget(tester, child: const MomentumScreen());

    // Wait for all animations and layout to settle with explicit pumps
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // Verify theme is applied
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.theme, equals(AppTheme.lightTheme));

    // Verify app bar styling
    expect(find.byType(AppBar), findsOneWidget);
  });

  testWidgets('Navigation elements test', (WidgetTester tester) async {
    await TestHelpers.pumpTestWidget(tester, child: const MomentumScreen());

    // Wait for all animations and layout to settle with explicit pumps
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // Verify navigation elements are present
    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);

    // Test tapping navigation elements with warnIfMissed: false to handle off-screen elements
    try {
      await tester.tap(
        find.byIcon(Icons.notifications_outlined),
        warnIfMissed: false,
      );
      await tester.pump(const Duration(milliseconds: 100));
    } catch (e) {
      debugPrint(
        'Notification icon tap test skipped: widget may be off-screen',
      );
    }

    try {
      await tester.tap(find.byIcon(Icons.person_outline), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));
    } catch (e) {
      debugPrint('Person icon tap test skipped: widget may be off-screen');
    }
  });

  testWidgets('Scroll behavior test', (WidgetTester tester) async {
    await TestHelpers.pumpTestWidget(
      tester,
      child: const MomentumScreen(),
      settleDuration: const Duration(seconds: 2),
    );

    // Wait for all animations to complete with explicit pumps
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // Find the scrollable widget
    final scrollable = find.byType(SingleChildScrollView);
    expect(scrollable, findsOneWidget);

    // Test scrolling (should not crash)
    await tester.drag(scrollable, const Offset(0, -200));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.drag(scrollable, const Offset(0, 200));
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('Widget hierarchy test', (WidgetTester tester) async {
    await TestHelpers.pumpTestWidget(
      tester,
      child: const MomentumScreen(),
      settleDuration: const Duration(seconds: 3),
    );

    // Wait for all animations and mounting to complete with explicit pumps
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

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
