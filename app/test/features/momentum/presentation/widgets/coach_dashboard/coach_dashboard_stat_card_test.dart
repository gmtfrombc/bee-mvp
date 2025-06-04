import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/momentum/presentation/widgets/coach_dashboard/coach_dashboard_stat_card.dart';
import 'package:app/core/services/responsive_service.dart';

void main() {
  group('CoachDashboardStatCard', () {
    testWidgets('renders with all required properties', (
      WidgetTester tester,
    ) async {
      // Given
      const title = 'Active Interventions';
      const value = '15';
      const icon = Icons.psychology;
      const color = Colors.blue;

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CoachDashboardStatCard(
              title: title,
              value: value,
              icon: icon,
              color: color,
            ),
          ),
        ),
      );

      // Then
      expect(find.text(title), findsOneWidget);
      expect(find.text(value), findsOneWidget);
      expect(find.byIcon(icon), findsOneWidget);
    });

    testWidgets('displays icon with responsive color and size', (
      WidgetTester tester,
    ) async {
      // Given
      const color = Colors.red;

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CoachDashboardStatCard(
              title: 'Test',
              value: '5',
              icon: Icons.star,
              color: color,
            ),
          ),
        ),
      );

      // Then
      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.star));
      expect(iconWidget.color, equals(color));

      // Verify responsive icon size is used (should be based on ResponsiveService.getIconSize)
      final context = tester.element(find.byType(CoachDashboardStatCard));
      final expectedIconSize = ResponsiveService.getIconSize(
        context,
        baseSize: 24.0,
      );
      expect(iconWidget.size, equals(expectedIconSize));
    });

    testWidgets('displays value with responsive styling', (
      WidgetTester tester,
    ) async {
      // Given
      const value = '42';
      const color = Colors.green;

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CoachDashboardStatCard(
              title: 'Test Metric',
              value: value,
              icon: Icons.check,
              color: color,
            ),
          ),
        ),
      );

      // Then
      final textWidget = tester.widget<Text>(find.text(value));
      expect(textWidget.style?.color, equals(color));
      expect(textWidget.style?.fontWeight, equals(FontWeight.bold));

      // Verify responsive font size is used
      final context = tester.element(find.byType(CoachDashboardStatCard));
      final fontSizeMultiplier = ResponsiveService.getFontSizeMultiplier(
        context,
      );
      final expectedFontSize = 18 * fontSizeMultiplier;
      expect(textWidget.style?.fontSize, equals(expectedFontSize));
    });

    testWidgets('displays title with responsive styling', (
      WidgetTester tester,
    ) async {
      // Given
      const title = 'Success Rate';

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CoachDashboardStatCard(
              title: title,
              value: '85%',
              icon: Icons.trending_up,
              color: Colors.orange,
            ),
          ),
        ),
      );

      // Then
      final titleWidget = tester.widget<Text>(find.text(title));
      expect(titleWidget.style?.fontWeight, equals(FontWeight.w500));
      expect(titleWidget.style?.color, equals(Colors.grey));

      // Verify responsive font size is used
      final context = tester.element(find.byType(CoachDashboardStatCard));
      final fontSizeMultiplier = ResponsiveService.getFontSizeMultiplier(
        context,
      );
      final expectedFontSize = 14 * fontSizeMultiplier;
      expect(titleWidget.style?.fontSize, equals(expectedFontSize));
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      // Given
      bool wasTapped = false;
      void onTap() {
        wasTapped = true;
      }

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CoachDashboardStatCard(
              title: 'Tappable Card',
              value: '10',
              icon: Icons.touch_app,
              color: Colors.purple,
              onTap: onTap,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CoachDashboardStatCard));
      await tester.pump();

      // Then
      expect(wasTapped, isTrue);
    });

    testWidgets('does not require onTap callback', (WidgetTester tester) async {
      // When - should not throw when onTap is null
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CoachDashboardStatCard(
              title: 'Non-tappable Card',
              value: '7',
              icon: Icons.info,
              color: Colors.grey,
              // onTap is intentionally omitted
            ),
          ),
        ),
      );

      // Then - should render without errors
      expect(find.byType(CoachDashboardStatCard), findsOneWidget);
    });

    testWidgets('uses responsive container styling', (
      WidgetTester tester,
    ) async {
      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CoachDashboardStatCard(
              title: 'Styled Card',
              value: '100',
              icon: Icons.style,
              color: Colors.amber,
            ),
          ),
        ),
      );

      // Then - Find the main container (the outer one with styling)
      final containers = find.byType(Container);
      expect(containers, findsAtLeastNWidgets(1));

      // Get the expected responsive border radius
      final context = tester.element(find.byType(CoachDashboardStatCard));
      final expectedBorderRadius = ResponsiveService.getBorderRadius(context);

      // Check that we have a container with proper responsive decoration
      bool foundStyledContainer = false;
      for (final element in containers.evaluate()) {
        final container = element.widget as Container;
        if (container.decoration is BoxDecoration) {
          final decoration = container.decoration as BoxDecoration;
          if (decoration.color == Colors.white &&
              decoration.borderRadius ==
                  BorderRadius.circular(expectedBorderRadius)) {
            foundStyledContainer = true;
            expect(decoration.border, isA<Border>());
            expect(decoration.boxShadow, isNotNull);
            expect(decoration.boxShadow!.length, equals(1));
            break;
          }
        }
      }
      expect(foundStyledContainer, isTrue);
    });

    testWidgets('handles very long titles gracefully', (
      WidgetTester tester,
    ) async {
      // Given
      const longTitle =
          'This is a very long title that might wrap to multiple lines';

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: CoachDashboardStatCard(
                title: longTitle,
                value: '999',
                icon: Icons.text_fields,
                color: Colors.teal,
              ),
            ),
          ),
        ),
      );

      // Then - should render without overflow
      expect(find.text(longTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles very long values gracefully', (
      WidgetTester tester,
    ) async {
      // Given
      const longValue = '9,999,999';

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: CoachDashboardStatCard(
                title: 'Large Number',
                value: longValue,
                icon: Icons.numbers,
                color: Colors.indigo,
              ),
            ),
          ),
        ),
      );

      // Then - should render with ellipsis and no exceptions
      expect(find.text(longValue), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('maintains consistent layout across different screen sizes', (
      WidgetTester tester,
    ) async {
      // Test small screen
      await tester.binding.setSurfaceSize(const Size(320, 568)); // iPhone SE
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CoachDashboardStatCard(
              title: 'Mobile Test',
              value: '42',
              icon: Icons.phone_android,
              color: Colors.cyan,
            ),
          ),
        ),
      );

      expect(find.byType(CoachDashboardStatCard), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Test large screen
      await tester.binding.setSurfaceSize(
        const Size(428, 926),
      ); // iPhone 14 Plus
      await tester.pump();

      expect(find.byType(CoachDashboardStatCard), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Reset to default size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('uses responsive spacing consistently', (
      WidgetTester tester,
    ) async {
      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CoachDashboardStatCard(
              title: 'Spacing Test',
              value: '123',
              icon: Icons.space_bar,
              color: Colors.blue,
            ),
          ),
        ),
      );

      // Then - verify responsive padding is used
      final context = tester.element(find.byType(CoachDashboardStatCard));
      final expectedPadding = ResponsiveService.getMediumPadding(context);

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(GestureDetector),
              matching: find.byType(Container),
            )
            .first,
      );

      expect(container.padding, equals(expectedPadding));
    });
  });
}
