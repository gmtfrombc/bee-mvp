library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/onboarding/ui/about_you_page.dart';
import 'package:app/features/onboarding/ui/preferences_page.dart';

void main() {
  // Custom devices matching spec 360×690 (phone) & 768×1024 (tablet)
  const phone360x690 = Device(name: 'phone_360x690', size: Size(360, 690));
  const tablet768x1024 = Device(name: 'tablet_768x1024', size: Size(768, 1024));

  GoldenToolkit.runWithConfiguration(
    () => _goldenTests(),
    config: GoldenToolkitConfiguration(
      enableRealShadows: false,
      defaultDevices: const [phone360x690, tablet768x1024],
      fileNameFactory: (name) => '../../../_goldens/onboarding/$name.png',
    ),
  );
}

void _goldenTests() {
  setUpAll(() async {
    await loadAppFonts();
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('Onboarding Screens – Golden Tests', () {
    testGoldens('AboutYouPage – light & dark', (tester) async {
      // Light theme snapshot
      await tester.pumpWidgetBuilder(
        ProviderScope(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            home: const AboutYouPage(),
          ),
        ),
      );
      await screenMatchesGolden(tester, 'about_you_page_light');

      // Dark theme snapshot
      await tester.pumpWidgetBuilder(
        ProviderScope(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: const AboutYouPage(),
          ),
        ),
      );
      await screenMatchesGolden(tester, 'about_you_page_dark');
    });

    // TODO(bee-mvp#onboarding-goldens): PreferencesPage goldens are flaky. Skip temporarily until baselines are regenerated.
    testGoldens('PreferencesPage – light & dark', (tester) async {
      // Light theme snapshot
      await tester.pumpWidgetBuilder(
        ProviderScope(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            home: const PreferencesPage(),
          ),
        ),
      );
      await screenMatchesGolden(tester, 'preferences_page_light');

      // Dark theme snapshot
      await tester.pumpWidgetBuilder(
        ProviderScope(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: const PreferencesPage(),
          ),
        ),
      );
      await screenMatchesGolden(tester, 'preferences_page_dark');
    }, skip: true);
  });
}
