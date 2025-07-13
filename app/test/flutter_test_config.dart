import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

/// Allows up to 1% pixel difference to accommodate minor cross-platform
/// rendering variations (fonts, anti-aliasing, etc.). This prevents golden
/// tests from flaking on GitHub Linux runners while still catching real UI
/// regressions.
class _ToleranceFileComparator implements GoldenFileComparator {
  _ToleranceFileComparator(this._base);

  final GoldenFileComparator _base;

  static const double _maxDiffRate = 0.01; // 1%

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    // Delegate to base to obtain golden bytes & diff result.
    if (_base is! LocalFileComparator) {
      // Fallback: just run the original compare.
      return _base.compare(imageBytes, golden);
    }

    final local = _base;
    // ignore: invalid_use_of_protected_member
    final goldenBytes = await local.getGoldenBytes(golden);
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      goldenBytes,
    );

    if (result.passed) return true;
    return result.diffPercent <= _maxDiffRate;
  }

  @override
  Uri getTestUri(Uri key, int? version) => _base.getTestUri(key, version);

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) =>
      _base.update(golden, imageBytes);
}

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Initialise binding & provide fallback Firebase mocks so CI container
  // doesn’t crash on missing platform channels.
  TestWidgetsFlutterBinding.ensureInitialized();

  // TODO(tech-debt/T1.1-FIREBASE-MOCKS): Replace ad-hoc stubs with proper
  // `firebase_testing` mocks once we add integration tests that exercise
  // Firebase interactions.
  try {
    await _setupFirebaseMocks();
  } catch (_) {
    // Ignore; tests that don’t touch Firebase will still run.
  }

  // Ensure fonts load for consistent rendering.
  await loadAppFonts();

  final defaultComparator = goldenFileComparator;
  goldenFileComparator = _ToleranceFileComparator(defaultComparator);

  await testMain();
}

/// Registers no-op handlers for common Firebase method channels so that unit
/// tests can run without a real native Firebase core.
Future<void> _setupFirebaseMocks() async {
  const channels = [
    'plugins.flutter.io/firebase_core',
    'plugins.flutter.io/firebase_auth',
    'plugins.flutter.io/firebase_messaging',
  ];

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final name in channels) {
    final channel = MethodChannel(name);
    messenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async => null,
    );
  }
}
