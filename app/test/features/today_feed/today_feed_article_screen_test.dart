import 'package:app/features/today_feed/domain/models/today_feed_content.dart';
import 'package:app/features/today_feed/presentation/screens/today_feed_article_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TodayFeedArticleScreen', () {
    testWidgets('renders header, actions and content on small device', (
      WidgetTester tester,
    ) async {
      // Simulate iPhone 13 mini screen
      const Size phoneSize = Size(375, 812);
      tester.view.physicalSize = phoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final content = TodayFeedContent.sample().copyWith(contentUrl: '');

      await tester.pumpWidget(
        MaterialApp(home: TodayFeedArticleScreen(content: content)),
      );
      await tester.pumpAndSettle();

      // Title appears
      expect(find.text(content.title), findsOneWidget);
      // Hero image placeholder or asset renders
      expect(find.byType(Image), findsWidgets);
      // Share & Bookmark icons present
      expect(find.byIcon(Icons.share), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_add_outlined), findsOneWidget);
      // First paragraph appears
      final String firstParagraph = content.fullContent!.elements.first.text;
      expect(
        find.textContaining(firstParagraph.substring(0, 20)),
        findsWidgets,
      );
    });

    testWidgets('layout scales on large device', (WidgetTester tester) async {
      // Simulate iPad Pro 11" portrait
      const Size tabletSize = Size(834, 1194);
      tester.view.physicalSize = tabletSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final content = TodayFeedContent.sample().copyWith(contentUrl: '');

      await tester.pumpWidget(
        MaterialApp(home: TodayFeedArticleScreen(content: content)),
      );
      await tester.pumpAndSettle();

      // Ensure hero image present and reasonably tall
      final Finder imageFinder = find.byType(Image).first;
      final Size imageSize = tester.getSize(imageFinder);
      expect(imageSize.height, greaterThanOrEqualTo(200));
      // Actions row still present
      expect(find.byIcon(Icons.share), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_add_outlined), findsOneWidget);
    });
  });
}
