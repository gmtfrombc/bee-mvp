import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal performance tests to debug hanging issue
void main() {
  group('Minimal Performance Tests', () {
    testWidgets('Basic widget rendering', (tester) async {
      debugPrint('DEBUG: Starting basic widget test');

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Text('Hello World'))),
      );

      debugPrint('DEBUG: Widget pumped, calling pump()');
      await tester.pump();
      debugPrint('DEBUG: pump() completed successfully');

      expect(find.text('Hello World'), findsOneWidget);
      debugPrint('DEBUG: Test completed successfully');
    });

    test('Pure Dart performance test', () {
      debugPrint('DEBUG: Starting pure Dart test');
      final stopwatch = Stopwatch()..start();

      // Simple computation
      var sum = 0;
      for (int i = 0; i < 1000; i++) {
        sum += i;
      }

      stopwatch.stop();
      debugPrint('Pure Dart computation time: ${stopwatch.elapsedMilliseconds}ms');

      expect(sum, equals(499500));
      debugPrint('DEBUG: Pure Dart test completed');
    });
  });
}
