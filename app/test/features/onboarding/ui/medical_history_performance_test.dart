import 'package:app/features/onboarding/ui/medical_history_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('MedicalHistoryPage Performance Benchmarks', () {
    testWidgets('builds and scrolls within performance budget', (tester) async {
      // ═════════════════════════════════════════════════════════════════════
      // 1. Build time benchmark – should render quickly (<800 ms).
      // ═════════════════════════════════════════════════════════════════════
      final buildWatch = Stopwatch()..start();

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: MedicalHistoryPage())),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));
      buildWatch.stop();

      expect(
        buildWatch.elapsedMilliseconds,
        lessThan(800),
        reason: 'MedicalHistoryPage must build quickly to sustain 60 fps UX.',
      );

      // ═════════════════════════════════════════════════════════════════════
      // 2. Scroll benchmark – a fast drag should settle quickly (<300 ms)
      //    This is a proxy for maintaining ~60 fps during interactions.
      // ═════════════════════════════════════════════════════════════════════
      final scrollable = find.byType(CustomScrollView);
      final scrollWatch = Stopwatch()..start();

      await tester.drag(scrollable, const Offset(0, -600));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      scrollWatch.stop();

      expect(
        scrollWatch.elapsedMilliseconds,
        lessThan(300),
        reason:
            'Scrolling grid should finish within 300 ms to approximate 60 fps.',
      );
    });
  });
}
