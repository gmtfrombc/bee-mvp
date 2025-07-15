@Skip('Baseline images not committed yet – regenerate before enabling')
library;

import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  GoldenToolkit.runWithConfiguration(
    () => _main(),
    config: GoldenToolkitConfiguration(
      enableRealShadows: false,
      defaultDevices: const [Device.phone, Device.tabletPortrait],
      fileNameFactory: (name) => '../../_goldens/$name.png',
    ),
  );
}

void _main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  testGoldens('Action Step prompt dialog', (tester) async {
    // Build an app that opens the dialog at start.
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            Future.microtask(
              () => showDialog(
                context: context,
                barrierDismissible: false,
                builder:
                    (_) => AlertDialog(
                      title: const Text('Set your first Action Step?'),
                      content: const Text(
                        'You can track weekly goals to build momentum. Would you like to set your first Action Step now?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Later'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Set Now'),
                        ),
                      ],
                    ),
              ),
            );
            return const Scaffold();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await screenMatchesGolden(tester, 'action_step_prompt_dialog');
  });
}
