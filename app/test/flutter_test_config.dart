import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
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
  // Ensure fonts load for consistent rendering.
  await loadAppFonts();

  final defaultComparator = goldenFileComparator;
  goldenFileComparator = _ToleranceFileComparator(defaultComparator);

  await testMain();
}
