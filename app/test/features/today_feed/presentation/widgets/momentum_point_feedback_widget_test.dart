import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/today_feed/presentation/widgets/momentum_point_feedback_widget.dart';
import 'package:app/features/today_feed/data/services/today_feed_momentum_award_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MomentumPointFeedbackWidget', () {
    testWidgets('renders success feedback when award succeeds', (tester) async {
      final result = MomentumAwardResult.success(
        pointsAwarded: 2,
        message: 'Well done!',
        awardTime: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MomentumPointFeedbackWidget(
              awardResult: result,
              enableAnimations: false, // Skip animations for deterministic test
              autoHide: false,
            ),
          ),
        ),
      );

      // Allow any internal timers/animations to complete
      await tester.pumpAndSettle();

      expect(find.text('Momentum +${result.pointsAwarded}!'), findsOneWidget);
    });

    testWidgets('renders queued feedback when award is queued', (tester) async {
      final result = MomentumAwardResult.queued(message: 'Queued');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MomentumPointFeedbackWidget(
              awardResult: result,
              enableAnimations: false,
              autoHide: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Points queued for when back online'), findsOneWidget);
    });
  });
}
