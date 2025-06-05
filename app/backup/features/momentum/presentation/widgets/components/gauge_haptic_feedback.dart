import 'dart:async';
import 'package:flutter/services.dart';
import '../../../../../core/theme/app_theme.dart';

/// Haptic feedback system for MomentumGauge
/// Handles enhanced haptic patterns for different interactions and state transitions
class GaugeHapticFeedback {
  static Timer? _hapticDelayTimer;

  /// Trigger enhanced haptic feedback for state transitions
  static void triggerStateTransitionFeedback(
    MomentumState oldState,
    MomentumState newState,
  ) {
    if (_isPositiveTransition(oldState, newState)) {
      // Positive transition - success pattern
      _triggerSuccessPattern();
    } else if (newState == MomentumState.needsCare) {
      // Needs attention - gentle warning pattern
      _triggerWarningPattern();
    } else {
      // Steady state - single light haptic
      HapticFeedback.lightImpact();
    }
  }

  /// Trigger haptic feedback for tap interactions
  static void triggerTapFeedback() {
    // Enhanced haptic feedback with double tap pattern
    HapticFeedback.lightImpact();
    _hapticDelayTimer?.cancel();
    _hapticDelayTimer = Timer(const Duration(milliseconds: 50), () {
      HapticFeedback.selectionClick();
    });
  }

  /// Success haptic pattern for positive transitions
  static void _triggerSuccessPattern() {
    HapticFeedback.mediumImpact();
    _hapticDelayTimer?.cancel();
    _hapticDelayTimer = Timer(const Duration(milliseconds: 100), () {
      HapticFeedback.lightImpact();
    });
  }

  /// Warning haptic pattern for attention needed
  static void _triggerWarningPattern() {
    HapticFeedback.lightImpact();
    _hapticDelayTimer?.cancel();
    _hapticDelayTimer = Timer(const Duration(milliseconds: 80), () {
      HapticFeedback.lightImpact();
    });
  }

  /// Check if state transition is positive (moving up the momentum scale)
  static bool _isPositiveTransition(
    MomentumState oldState,
    MomentumState newState,
  ) {
    const stateOrder = [
      MomentumState.needsCare,
      MomentumState.steady,
      MomentumState.rising,
    ];
    final oldIndex = stateOrder.indexOf(oldState);
    final newIndex = stateOrder.indexOf(newState);
    return newIndex > oldIndex;
  }

  /// Dispose of any active timers
  static void dispose() {
    _hapticDelayTimer?.cancel();
    _hapticDelayTimer = null;
  }
}
