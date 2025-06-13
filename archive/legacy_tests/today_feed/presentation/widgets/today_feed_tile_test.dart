import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/today_feed/domain/models/today_feed_content.dart';
import 'package:app/features/today_feed/presentation/widgets/today_feed_tile.dart';

void main() {
  group('TodayFeedTile Widget Tests', () {
    late TodayFeedContent sampleContent;
    late TodayFeedContent basicContent;

    setUpAll(() {
      sampleContent = TodayFeedContent.sample();

      // Create basic content without fullContent for summary text tests
      basicContent = sampleContent.copyWith(fullContent: null);
    });

    Widget createTestWidget(Widget child) {
      return MaterialApp(home: Scaffold(body: child));
    }

    group('Widget Construction', () {
      testWidgets('creates widget with required parameters', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            TodayFeedTile(state: TodayFeedState.loaded(sampleContent)),
          ),
        );

        expect(find.byType(TodayFeedTile), findsOneWidget);
        expect(find.byType(Card), findsOneWidget);
      });
    });

    group('Loading State', () {
      testWidgets('displays loading state correctly', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            const TodayFeedTile(
              state: TodayFeedState.loading(),
              enableAnimations: false,
            ),
          ),
        );

        // Should show loading status
        expect(find.text('Loading...'), findsOneWidget);

        // Should show reading time placeholder
        expect(find.text('-- min read'), findsOneWidget);
      });
    });

    group('Loaded State', () {
      testWidgets('displays content correctly in loaded state', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            TodayFeedTile(
              state: TodayFeedState.loaded(basicContent),
              enableAnimations: false,
            ),
          ),
        );

        // Should show header
        expect(find.text("Today's Health Insight"), findsOneWidget);

        // Should show content title and summary
        expect(find.text(basicContent.title), findsOneWidget);
        expect(find.text(basicContent.summary), findsOneWidget);

        // Should show topic badge
        expect(
          find.text(basicContent.topicCategory.value.toUpperCase()),
          findsOneWidget,
        );

        // Should show reading time
        expect(find.text(basicContent.readingTimeText), findsOneWidget);

        // Should show read more button
        expect(find.text('Read More'), findsOneWidget);
      });

      testWidgets('shows NEW status for fresh content', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            TodayFeedTile(
              state: TodayFeedState.loaded(basicContent),
              enableAnimations: false,
            ),
          ),
        );

        expect(find.text('NEW'), findsOneWidget);
      });
    });

    group('Error State', () {
      testWidgets('displays error state correctly', (tester) async {
        const errorMessage = 'Network connection failed';

        await tester.pumpWidget(
          createTestWidget(
            const TodayFeedTile(
              state: TodayFeedState.error(errorMessage),
              enableAnimations: false,
            ),
          ),
        );

        // Should show error status (updated to match new enhanced error widget)
        expect(
          find.byWidgetPredicate((widget) {
            return widget is Text &&
                widget.data != null &&
                (widget.data!.contains('ERROR') ||
                    widget.data!.contains('NETWORK') ||
                    widget.data!.contains('OFFLINE') ||
                    widget.data!.contains('SERVER'));
          }),
          findsAtLeastNWidgets(1),
        ); // Can be "ERROR", "NETWORK", "OFFLINE", etc.

        // Should show error icons (updated to match enhanced error widget icons)
        expect(
          find.byWidgetPredicate((widget) {
            return widget is Icon &&
                (widget.icon == Icons.error_outline ||
                    widget.icon == Icons.network_check ||
                    widget.icon == Icons.wifi_off ||
                    widget.icon == Icons.cloud_off);
          }),
          findsAtLeastNWidgets(1),
        );

        // Should show error message (updated to match enhanced error widget titles)
        expect(
          find.byWidgetPredicate((widget) {
            return widget is Text &&
                widget.data != null &&
                (widget.data!.contains("Something went wrong") ||
                    widget.data!.contains("Connection problem") ||
                    widget.data!.contains("You're offline") ||
                    widget.data!.contains("Service temporarily unavailable"));
          }),
          findsAtLeastNWidgets(1),
        );
        expect(find.text(errorMessage), findsOneWidget);

        // Should show retry button
        expect(find.text('Retry'), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget);
      });
    });

    group('Interactions', () {
      testWidgets('handles tap when callback provided', (tester) async {
        bool tapCalled = false;

        await tester.pumpWidget(
          createTestWidget(
            TodayFeedTile(
              state: TodayFeedState.loaded(basicContent),
              onTap: () => tapCalled = true,
              enableAnimations: false,
            ),
          ),
        );

        // Find the main card InkWell specifically - it's a direct child of Material and wraps Card
        final mainInkWell =
            find
                .ancestor(of: find.byType(Card), matching: find.byType(InkWell))
                .first;

        await tester.tap(mainInkWell);
        await tester.pump();

        expect(tapCalled, isTrue);
      });
    });
  });
}
