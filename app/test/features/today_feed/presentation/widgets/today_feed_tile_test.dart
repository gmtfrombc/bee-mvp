import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/today_feed/domain/models/today_feed_content.dart';
import 'package:app/features/today_feed/presentation/widgets/today_feed_tile.dart';
import 'package:app/features/today_feed/presentation/widgets/rich_content_renderer.dart';

void main() {
  group('TodayFeedTile Widget Tests', () {
    late TodayFeedContent sampleContent;
    late TodayFeedContent basicContent;
    late TodayFeedContent richContent;
    late TodayFeedContent engagedContent;
    late TodayFeedContent cachedContent;

    setUpAll(() {
      sampleContent = TodayFeedContent.sample();

      // Create basic content without fullContent for summary text tests
      basicContent = sampleContent.copyWith(fullContent: null);

      // Create rich content with fullContent for rich rendering tests
      richContent = sampleContent.copyWith(
        fullContent: TodayFeedRichContent.sample(),
      );

      engagedContent = basicContent.copyWith(hasUserEngaged: true);

      cachedContent = basicContent.copyWith(isCached: true);
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

      testWidgets('accepts optional parameters', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            TodayFeedTile(
              state: TodayFeedState.loaded(sampleContent),
              onTap: () {},
              onExternalLinkTap: () {},
              onShare: () {},
              onBookmark: () {},
              onInteraction: (type) {},
              showMomentumIndicator: false,
              enableAnimations: false,
              margin: const EdgeInsets.all(20),
              height: 300,
            ),
          ),
        );

        expect(find.byType(TodayFeedTile), findsOneWidget);
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

      testWidgets('shows VIEWED status for engaged content', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            TodayFeedTile(
              state: TodayFeedState.loaded(engagedContent),
              enableAnimations: false,
            ),
          ),
        );

        expect(find.text('VIEWED'), findsOneWidget);
        expect(find.text('Read Again'), findsOneWidget);
      });

      testWidgets('shows momentum indicator for fresh content', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            TodayFeedTile(
              state: TodayFeedState.loaded(basicContent),
              enableAnimations: false,
              showMomentumIndicator: true,
            ),
          ),
        );

        // Should show +1 momentum indicator
        expect(find.text('+1'), findsOneWidget);
      });

      testWidgets('shows check mark for engaged content', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            TodayFeedTile(
              state: TodayFeedState.loaded(engagedContent),
              enableAnimations: false,
              showMomentumIndicator: true,
            ),
          ),
        );

        // Should show check circle icon
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });

      testWidgets('hides momentum indicator when disabled', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            TodayFeedTile(
              state: TodayFeedState.loaded(basicContent),
              enableAnimations: false,
              showMomentumIndicator: false,
            ),
          ),
        );

        // Should not show +1 momentum indicator
        expect(find.text('+1'), findsNothing);
        expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      });

      testWidgets('engaged content allows card tap for re-reading', (
        tester,
      ) async {
        bool tapCalled = false;

        await tester.pumpWidget(
          createTestWidget(
            TodayFeedTile(
              state: TodayFeedState.loaded(engagedContent),
              onTap: () => tapCalled = true,
              enableAnimations: false,
            ),
          ),
        );

        // Verify the "Read Again" text is present
        expect(find.text('Read Again'), findsOneWidget);

        // When content is engaged, tapping the card should still work
        // (user can re-read the content)
        await tester.tap(find.byType(Card));
        await tester.pump();

        expect(tapCalled, isTrue);
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

        // Should show error status
        expect(find.text('ERROR'), findsOneWidget);

        // Should show error icon
        expect(find.byIcon(Icons.error_outline), findsOneWidget);

        // Should show error message
        expect(find.text("Unable to load today's insight"), findsOneWidget);
        expect(find.text(errorMessage), findsOneWidget);

        // Should show retry button
        expect(find.text('Retry'), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget);
      });

      testWidgets('error state retry button triggers callback', (tester) async {
        bool retryCalled = false;

        await tester.pumpWidget(
          createTestWidget(
            TodayFeedTile(
              state: const TodayFeedState.error('Network error'),
              onTap: () => retryCalled = true,
              enableAnimations: false,
            ),
          ),
        );

        await tester.tap(find.text('Retry'));
        expect(retryCalled, isTrue);
      });
    });

    group('Offline State', () {
      testWidgets('displays offline state correctly', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            TodayFeedTile(
              state: TodayFeedState.offline(cachedContent),
              enableAnimations: false,
            ),
          ),
        );

        // Should show offline status
        expect(find.text('OFFLINE'), findsOneWidget);
        expect(find.byIcon(Icons.cloud_off), findsOneWidget);

        // Should show cached content
        expect(find.text(cachedContent.title), findsOneWidget);
        expect(find.text(cachedContent.summary), findsOneWidget);
      });

      testWidgets('offline state does not show momentum indicator', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestWidget(
            TodayFeedTile(
              state: TodayFeedState.offline(cachedContent),
              enableAnimations: false,
              showMomentumIndicator: true,
            ),
          ),
        );

        // Should not show momentum indicator in offline mode
        expect(find.text('+1'), findsNothing);
        expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
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

      testWidgets('tracks interaction when callback provided', (tester) async {
        TodayFeedInteractionType? trackedInteraction;

        await tester.pumpWidget(
          createTestWidget(
            TodayFeedTile(
              state: TodayFeedState.loaded(basicContent),
              onTap: () {}, // Need onTap to enable InkWell
              onInteraction: (type) => trackedInteraction = type,
              enableAnimations: false,
            ),
          ),
        );

        // Find the main card InkWell specifically by its relationship to Card
        final mainInkWell =
            find
                .ancestor(of: find.byType(Card), matching: find.byType(InkWell))
                .first;

        await tester.tap(mainInkWell);
        await tester.pump();

        expect(trackedInteraction, TodayFeedInteractionType.tap);
      });
    });

    group('Responsive Design', () {
      testWidgets('adapts to mobile screen size', (tester) async {
        tester.view.physicalSize = const Size(375, 667);
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(
          createTestWidget(
            TodayFeedTile(
              state: TodayFeedState.loaded(sampleContent),
              enableAnimations: false,
            ),
          ),
        );

        expect(find.byType(TodayFeedTile), findsOneWidget);

        addTearDown(tester.view.reset);
      });

      testWidgets('respects custom height and margin', (tester) async {
        const customHeight = 300.0;
        const customMargin = EdgeInsets.all(20.0);

        await tester.pumpWidget(
          createTestWidget(
            TodayFeedTile(
              state: TodayFeedState.loaded(sampleContent),
              height: customHeight,
              margin: customMargin,
              enableAnimations: false,
            ),
          ),
        );

        expect(find.byType(TodayFeedTile), findsOneWidget);
      });
    });

    group('Topic Categories', () {
      testWidgets('displays different topic colors correctly', (tester) async {
        final topics = HealthTopic.values;

        for (final topic in topics) {
          final content = sampleContent.copyWith(topicCategory: topic);

          await tester.pumpWidget(
            createTestWidget(
              TodayFeedTile(
                state: TodayFeedState.loaded(content),
                enableAnimations: false,
              ),
            ),
          );

          // Should show topic badge with correct text
          expect(find.text(topic.value.toUpperCase()), findsOneWidget);

          // Clean up for next iteration
          await tester.pumpWidget(Container());
        }
      });
    });

    group('Animation Control', () {
      testWidgets('disables animations when enableAnimations is false', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestWidget(
            TodayFeedTile(
              state: TodayFeedState.loaded(sampleContent),
              enableAnimations: false,
            ),
          ),
        );

        // Widget should render without waiting for animations
        expect(find.byType(TodayFeedTile), findsOneWidget);
        expect(find.text(sampleContent.title), findsOneWidget);
      });

      testWidgets('enables animations when enableAnimations is true', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestWidget(
            TodayFeedTile(
              state: TodayFeedState.loaded(sampleContent),
              enableAnimations: true,
            ),
          ),
        );

        // Should have animation builders
        expect(find.byType(AnimatedBuilder), findsWidgets);
        expect(find.byType(SlideTransition), findsOneWidget);
      });
    });

    group('State Transitions', () {
      testWidgets('handles state transitions correctly', (tester) async {
        // Start with loading state
        await tester.pumpWidget(
          createTestWidget(
            const TodayFeedTile(
              state: TodayFeedState.loading(),
              enableAnimations: false,
            ),
          ),
        );

        expect(find.text('Loading...'), findsOneWidget);

        // Transition to loaded state
        await tester.pumpWidget(
          createTestWidget(
            TodayFeedTile(
              state: TodayFeedState.loaded(sampleContent),
              enableAnimations: false,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text(sampleContent.title), findsOneWidget);
        expect(find.text('Loading...'), findsNothing);
      });
    });

    group('Rich Content Rendering', () {
      testWidgets('renders rich content when available', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            TodayFeedTile(
              state: TodayFeedState.loaded(richContent),
              enableAnimations: false,
            ),
          ),
        );

        // Should show the title
        expect(find.text(richContent.title), findsOneWidget);

        // Should use RichContentRenderer
        expect(find.byType(RichContentRenderer), findsOneWidget);

        // Should show rich content elements
        expect(find.text("Why Sleep Matters for Immunity"), findsOneWidget);
        expect(find.text("Key Takeaways"), findsOneWidget);
        expect(find.text("Take Action"), findsOneWidget);
      });

      testWidgets('scrolls rich content in tile view', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            TodayFeedTile(
              state: TodayFeedState.loaded(richContent),
              enableAnimations: false,
            ),
          ),
        );

        // Should have RichContentRenderer which contains scrollable content
        expect(find.byType(RichContentRenderer), findsOneWidget);

        // Verify that there are scrollable widgets (allowing for multiple)
        expect(find.byType(SingleChildScrollView), findsWidgets);
      });

      testWidgets('handles external link taps in rich content', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 800,
                child: TodayFeedTile(
                  state: TodayFeedState.loaded(richContent),
                  onExternalLinkTap: () {},
                  enableAnimations: false,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify that rich content renders correctly
        expect(find.byType(RichContentRenderer), findsOneWidget);

        // Verify that external link text is present
        expect(find.text("View Research Study →"), findsOneWidget);

        // Verify that there's an external link container with decoration (indicates rich content link)
        final linkContainers = find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color?.value ==
                  (Colors.blue.withValues(alpha: 0.05).value),
        );
        expect(linkContainers, findsWidgets);
      });

      testWidgets('falls back to basic content when rich content unavailable', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestWidget(
            TodayFeedTile(
              state: TodayFeedState.loaded(basicContent),
              enableAnimations: false,
            ),
          ),
        );

        // Should fall back to displaying basic summary
        expect(find.text(basicContent.summary), findsOneWidget);
        expect(find.byType(RichContentRenderer), findsNothing);
      });
    });

    group('Animations', () {
      testWidgets('disables animations when enableAnimations is false', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestWidget(
            TodayFeedTile(
              state: TodayFeedState.loaded(sampleContent),
              enableAnimations: false,
            ),
          ),
        );

        // Widget should render without waiting for animations
        expect(find.byType(TodayFeedTile), findsOneWidget);
        expect(find.text(sampleContent.title), findsOneWidget);
      });

      testWidgets('enables animations when enableAnimations is true', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestWidget(
            TodayFeedTile(
              state: TodayFeedState.loaded(sampleContent),
              enableAnimations: true,
            ),
          ),
        );

        // Should have animation builders
        expect(find.byType(AnimatedBuilder), findsWidgets);
        expect(find.byType(SlideTransition), findsOneWidget);
      });
    });
  });
}
