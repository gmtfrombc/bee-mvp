import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/ui/bee_toast.dart';

// Helper widget to obtain a BuildContext via tester.element()
class _Host extends StatelessWidget {
  const _Host();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Placeholder());
  }
}

void main() {
  group('BeeToast', () {
    testWidgets('shows success SnackBar with correct styling', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: _Host()));

      // Obtain a context from the Placeholder widget
      final context = tester.element(find.byType(Placeholder));

      // Show toast
      showBeeToast(context, 'Saved!', type: BeeToastType.success);

      // Allow snackbar animation to start
      await tester.pump();

      // Verify message appears
      expect(find.text('Saved!'), findsOneWidget);

      // Verify background colour matches success mapping
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      final expectedColor = Theme.of(
        context,
      ).colorScheme.primary.withAlpha((0.9 * 255).round());
      expect(snackBar.backgroundColor, expectedColor);
    });

    testWidgets('shows error SnackBar with correct styling', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: _Host()));
      final context = tester.element(find.byType(Placeholder));

      showBeeToast(context, 'Failed!', type: BeeToastType.error);
      await tester.pump();

      expect(find.text('Failed!'), findsOneWidget);
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      final expectedColor = Theme.of(
        context,
      ).colorScheme.error.withAlpha((0.9 * 255).round());
      expect(snackBar.backgroundColor, expectedColor);
    });
  });
}
