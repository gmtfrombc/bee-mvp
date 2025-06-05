import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import 'gauge_haptic_feedback.dart';
import 'gauge_animation_controller.dart';

/// Interaction handler for MomentumGauge
/// Manages tap gestures, celebrations, and user interactions
class GaugeInteractionHandler {
  final GaugeAnimationController animationController;
  final VoidCallback? onTap;

  GaugeInteractionHandler({required this.animationController, this.onTap});

  /// Handle tap gesture with haptic feedback and bounce animation
  Future<void> handleTap() async {
    if (onTap != null) {
      // Trigger haptic feedback
      GaugeHapticFeedback.triggerTapFeedback();

      // Execute callback
      onTap!();

      // Trigger bounce animation
      await animationController.triggerTapBounce();
    }
  }

  /// Handle state transitions with celebration effects
  Future<void> handleStateTransition(
    BuildContext context,
    MomentumState oldState,
    MomentumState newState,
  ) async {
    // Trigger haptic feedback for state change
    GaugeHapticFeedback.triggerStateTransitionFeedback(oldState, newState);

    // Handle animation transition
    await animationController.handleStateTransition(
      context,
      oldState,
      newState,
    );

    // Add celebration bounce for positive transitions
    if (animationController.isPositiveTransition(oldState, newState)) {
      await animationController.triggerCelebrationBounce();
    }
  }

  /// Create glow decoration for the gauge container
  static BoxDecoration? createGlowDecoration({
    required bool showGlow,
    required bool isTransitioning,
    required MomentumState state,
    Color? transitionColor,
    required double glowIntensity,
  }) {
    if (!showGlow) return null;

    return BoxDecoration(
      boxShadow: [
        BoxShadow(
          color:
              isTransitioning
                  ? (transitionColor ?? AppTheme.getMomentumColor(state))
                      .withValues(alpha: glowIntensity)
                  : AppTheme.getMomentumColor(state).withValues(alpha: 0.3),
          blurRadius: 20,
          spreadRadius: 0,
        ),
      ],
    );
  }
}
