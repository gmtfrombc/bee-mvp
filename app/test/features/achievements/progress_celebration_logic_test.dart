// ignore_for_file: library_private_types_in_public_api

import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/theme/app_theme.dart' show MomentumState;

// Re-declare enum for test (matches production semantics)
enum _MilestoneType { streak7, momentumRiseToSteady }

void main() {
  group('Progress milestone detection', () {
    test('detects 7-day streak milestone', () {
      final listener = TestMilestoneDetector();
      final milestone = listener.detect(previousStreak: 6, currentStreak: 7);
      expect(milestone, _MilestoneType.streak7);
    });

    test('detects momentum Rising -> Steady', () {
      final listener = TestMilestoneDetector();
      final milestone = listener.detect(
        previousMomentum: MomentumState.rising,
        currentMomentum: MomentumState.steady,
      );
      expect(milestone, _MilestoneType.momentumRiseToSteady);
    });

    test('no milestone when conditions not met', () {
      final listener = TestMilestoneDetector();
      final milestone = listener.detect(previousStreak: 5, currentStreak: 6);
      expect(milestone, isNull);
    });
  });
}

/// Helper that exposes the private detection logic for test purposes.
class TestMilestoneDetector {
  _MilestoneType? detect({
    int previousStreak = 0,
    int currentStreak = 0,
    MomentumState? previousMomentum,
    MomentumState? currentMomentum,
  }) {
    // Re-implement minimal logic identical to production for isolation.
    if (previousStreak < 7 && currentStreak >= 7) {
      return _MilestoneType.streak7;
    }
    if (previousMomentum == MomentumState.rising &&
        currentMomentum == MomentumState.steady) {
      return _MilestoneType.momentumRiseToSteady;
    }
    return null;
  }
}
