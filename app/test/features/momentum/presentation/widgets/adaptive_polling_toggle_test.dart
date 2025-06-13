import 'package:app/core/services/vitals_notifier_service.dart';
import 'package:app/features/momentum/presentation/widgets/adaptive_polling_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('AdaptivePollingToggle interacts with SharedPreferences', (
    WidgetTester tester,
  ) async {
    // Set up mock SharedPreferences
    SharedPreferences.setMockInitialValues({
      VitalsNotifierService.adaptivePollingPrefKey: false,
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: AdaptivePollingToggle())),
      ),
    );

    // Allow the widget to load preferences
    await tester.pumpAndSettle();

    // Verify the switch is initially off
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );

    // Tap the switch
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    // Verify the switch is now on
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );

    // Verify SharedPreferences was updated
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(VitalsNotifierService.adaptivePollingPrefKey), isTrue);

    // Tap the switch again
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    // Verify the switch is off again
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );

    // Verify SharedPreferences was updated
    expect(
      prefs.getBool(VitalsNotifierService.adaptivePollingPrefKey),
      isFalse,
    );
  });
}
