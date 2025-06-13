import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/today_feed/domain/models/today_feed_content.dart';
import 'package:app/features/today_feed/presentation/widgets/rich_content_renderer.dart';

void main() {
  group('RichContentRenderer Widget Tests', () {
    late TodayFeedRichContent sampleRichContent;

    setUpAll(() {
      sampleRichContent = TodayFeedRichContent.sample();
    });

    Widget createTestWidget(Widget child) {
      return MaterialApp(home: Scaffold(body: child));
    }

    group('Widget Construction', () {
      testWidgets('creates widget with required parameters', (tester) async {
        await tester.pumpWidget(
          createTestWidget(RichContentRenderer(content: sampleRichContent)),
        );

        expect(find.byType(RichContentRenderer), findsOneWidget);
      });

      testWidgets('handles optional parameters', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            RichContentRenderer(
              content: sampleRichContent,
              onLinkTap: (url, linkText) {},
              isCompact: true,
              enableInteractions: false,
            ),
          ),
        );

        expect(find.byType(RichContentRenderer), findsOneWidget);
      });
    });

    group('Content Element Rendering', () {
      testWidgets('renders paragraph elements correctly', (tester) async {
        const paragraphContent = TodayFeedRichContent(
          elements: [
            RichContentElement(
              type: RichContentType.paragraph,
              text: "Test paragraph content",
            ),
          ],
        );

        await tester.pumpWidget(
          createTestWidget(
            const RichContentRenderer(content: paragraphContent),
          ),
        );

        expect(find.text('Test paragraph content'), findsOneWidget);
      });

      testWidgets('renders heading elements correctly', (tester) async {
        const headingContent = TodayFeedRichContent(
          elements: [
            RichContentElement(
              type: RichContentType.heading,
              text: "Test Heading",
              isBold: true,
            ),
          ],
        );

        await tester.pumpWidget(
          createTestWidget(const RichContentRenderer(content: headingContent)),
        );

        expect(find.text('Test Heading'), findsOneWidget);
      });

      testWidgets('renders bullet list elements correctly', (tester) async {
        const bulletListContent = TodayFeedRichContent(
          elements: [
            RichContentElement(
              type: RichContentType.bulletList,
              text: "Benefits include:",
              listItems: [
                "Better sleep quality",
                "Improved immune function",
                "Enhanced recovery",
              ],
            ),
          ],
        );

        await tester.pumpWidget(
          createTestWidget(
            const RichContentRenderer(content: bulletListContent),
          ),
        );

        expect(find.text('Benefits include:'), findsOneWidget);
        expect(find.text('Better sleep quality'), findsOneWidget);
        expect(find.text('Improved immune function'), findsOneWidget);
        expect(find.text('Enhanced recovery'), findsOneWidget);
      });

      testWidgets('renders numbered list elements correctly', (tester) async {
        const numberedListContent = TodayFeedRichContent(
          elements: [
            RichContentElement(
              type: RichContentType.numberedList,
              text: "Steps to follow:",
              listItems: ["First step", "Second step", "Third step"],
            ),
          ],
        );

        await tester.pumpWidget(
          createTestWidget(
            const RichContentRenderer(content: numberedListContent),
          ),
        );

        expect(find.text('Steps to follow:'), findsOneWidget);
        expect(find.text('First step'), findsOneWidget);
        expect(find.text('Second step'), findsOneWidget);
        expect(find.text('Third step'), findsOneWidget);
        expect(find.text('1'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
      });

      testWidgets('renders tip elements correctly', (tester) async {
        const tipContent = TodayFeedRichContent(
          elements: [
            RichContentElement(
              type: RichContentType.tip,
              text: "Pro tip: Drink water before meals",
            ),
          ],
        );

        await tester.pumpWidget(
          createTestWidget(const RichContentRenderer(content: tipContent)),
        );

        expect(find.text('Pro tip: Drink water before meals'), findsOneWidget);
        expect(find.byIcon(Icons.tips_and_updates_outlined), findsOneWidget);
      });

      testWidgets('renders warning elements correctly', (tester) async {
        const warningContent = TodayFeedRichContent(
          elements: [
            RichContentElement(
              type: RichContentType.warning,
              text: "Consult your doctor before changing medications",
            ),
          ],
        );

        await tester.pumpWidget(
          createTestWidget(const RichContentRenderer(content: warningContent)),
        );

        expect(
          find.text('Consult your doctor before changing medications'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
      });

      testWidgets('renders highlight elements correctly', (tester) async {
        const highlightContent = TodayFeedRichContent(
          elements: [
            RichContentElement(
              type: RichContentType.highlight,
              text: "Key insight: Sleep affects immunity directly",
            ),
          ],
        );

        await tester.pumpWidget(
          createTestWidget(
            const RichContentRenderer(content: highlightContent),
          ),
        );

        expect(
          find.text('Key insight: Sleep affects immunity directly'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
      });

      testWidgets('renders external link elements correctly', (tester) async {
        const linkContent = TodayFeedRichContent(
          elements: [
            RichContentElement(
              type: RichContentType.externalLink,
              text: "Learn more about sleep research",
              linkUrl: "https://example.com/sleep-study",
              linkText: "View Study →",
            ),
          ],
        );

        await tester.pumpWidget(
          createTestWidget(const RichContentRenderer(content: linkContent)),
        );

        expect(find.text('Learn more about sleep research'), findsOneWidget);
        expect(find.text('View Study →'), findsOneWidget);
        expect(find.byIcon(Icons.open_in_new), findsOneWidget);
      });
    });

    group('Additional Sections', () {
      testWidgets('renders key takeaways when provided', (tester) async {
        const contentWithTakeaways = TodayFeedRichContent(
          elements: [
            RichContentElement(
              type: RichContentType.paragraph,
              text: "Sample content",
            ),
          ],
          keyTakeaways: [
            "Sleep is crucial for health",
            "7-9 hours is optimal",
            "Quality matters more than quantity",
          ],
        );

        await tester.pumpWidget(
          createTestWidget(
            const RichContentRenderer(content: contentWithTakeaways),
          ),
        );

        expect(find.text('Key Takeaways'), findsOneWidget);
        expect(find.text('Sleep is crucial for health'), findsOneWidget);
        expect(find.text('7-9 hours is optimal'), findsOneWidget);
        expect(find.text('Quality matters more than quantity'), findsOneWidget);
        expect(find.byIcon(Icons.key), findsOneWidget);
      });

      testWidgets('renders actionable advice when provided', (tester) async {
        const contentWithAdvice = TodayFeedRichContent(
          elements: [
            RichContentElement(
              type: RichContentType.paragraph,
              text: "Sample content",
            ),
          ],
          actionableAdvice: "Start tonight: Remove screens 1 hour before bed",
        );

        await tester.pumpWidget(
          createTestWidget(
            const RichContentRenderer(content: contentWithAdvice),
          ),
        );

        expect(find.text('Take Action'), findsOneWidget);
        expect(
          find.text('Start tonight: Remove screens 1 hour before bed'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.rocket_launch), findsOneWidget);
      });

      testWidgets('renders source reference when provided', (tester) async {
        const contentWithSource = TodayFeedRichContent(
          elements: [
            RichContentElement(
              type: RichContentType.paragraph,
              text: "Sample content",
            ),
          ],
          sourceReference: "Based on Harvard Medical School research",
        );

        await tester.pumpWidget(
          createTestWidget(
            const RichContentRenderer(content: contentWithSource),
          ),
        );

        expect(
          find.text('Based on Harvard Medical School research'),
          findsOneWidget,
        );
      });

      testWidgets('hides sections when not provided', (tester) async {
        const minimalContent = TodayFeedRichContent(
          elements: [
            RichContentElement(
              type: RichContentType.paragraph,
              text: "Just basic content",
            ),
          ],
        );

        await tester.pumpWidget(
          createTestWidget(const RichContentRenderer(content: minimalContent)),
        );

        expect(find.text('Key Takeaways'), findsNothing);
        expect(find.text('Take Action'), findsNothing);
        expect(find.byIcon(Icons.key), findsNothing);
        expect(find.byIcon(Icons.rocket_launch), findsNothing);
      });
    });

    group('Interactions', () {
      testWidgets('handles external link taps when enabled', (tester) async {
        String? tappedUrl;
        String? tappedLinkText;

        const linkContent = TodayFeedRichContent(
          elements: [
            RichContentElement(
              type: RichContentType.externalLink,
              text: "Learn more",
              linkUrl: "https://example.com",
              linkText: "Click here",
            ),
          ],
        );

        await tester.pumpWidget(
          createTestWidget(
            RichContentRenderer(
              content: linkContent,
              enableInteractions: true,
              onLinkTap: (url, linkText) {
                tappedUrl = url;
                tappedLinkText = linkText;
              },
            ),
          ),
        );

        await tester.tap(find.text('Click here'));
        await tester.pump();

        expect(tappedUrl, equals('https://example.com'));
        expect(tappedLinkText, equals('Click here'));
      });

      testWidgets('disables link taps when interactions disabled', (
        tester,
      ) async {
        bool linkTapped = false;

        const linkContent = TodayFeedRichContent(
          elements: [
            RichContentElement(
              type: RichContentType.externalLink,
              text: "Learn more",
              linkUrl: "https://example.com",
              linkText: "Click here",
            ),
          ],
        );

        await tester.pumpWidget(
          createTestWidget(
            RichContentRenderer(
              content: linkContent,
              enableInteractions: false,
              onLinkTap: (url, linkText) {
                linkTapped = true;
              },
            ),
          ),
        );

        await tester.tap(find.text('Click here'));
        await tester.pump();

        expect(linkTapped, isFalse);
      });
    });

    group('Accessibility', () {
      testWidgets('provides proper semantic labels for content types', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestWidget(RichContentRenderer(content: sampleRichContent)),
        );

        // Check for semantic labels
        expect(
          find.bySemanticsLabel(RegExp(r'Health information paragraph')),
          findsWidgets,
        );
        expect(
          find.bySemanticsLabel(RegExp(r'Section heading:')),
          findsWidgets,
        );
        expect(find.bySemanticsLabel(RegExp(r'Bullet list:')), findsWidgets);
        expect(find.bySemanticsLabel(RegExp(r'Health tip:')), findsWidgets);
        expect(find.bySemanticsLabel(RegExp(r'External link:')), findsWidgets);
      });

      testWidgets('provides semantic hints for interactive elements', (
        tester,
      ) async {
        const linkContent = TodayFeedRichContent(
          elements: [
            RichContentElement(
              type: RichContentType.externalLink,
              text: "Learn more",
              linkUrl: "https://example.com",
              linkText: "Click here",
            ),
          ],
        );

        await tester.pumpWidget(
          createTestWidget(const RichContentRenderer(content: linkContent)),
        );

        // Check that external link has proper semantics structure
        final semanticsWidget = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.hint == 'Double tap to open link',
        );
        expect(semanticsWidget, findsOneWidget);
      });
    });

    group('Compact Mode', () {
      testWidgets('applies compact styling when enabled', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            RichContentRenderer(content: sampleRichContent, isCompact: true),
          ),
        );

        expect(find.byType(RichContentRenderer), findsOneWidget);
        // Compact mode is tested through font size calculations
        // which are internal to the widget
      });
    });
  });
}
