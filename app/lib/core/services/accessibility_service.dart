import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import '../../features/momentum/domain/models/momentum_data.dart';
import '../theme/app_theme.dart';

/// Centralized accessibility service for the BEE app
/// Provides semantic labels, screen reader support, and accessibility utilities
class AccessibilityService {
  static const double minimumTouchTarget = 44.0;
  static const double maximumTextScaleFactor = 1.3;
  static const double minimumTextScaleFactor = 0.8;

  /// Get semantic label for momentum state
  static String getMomentumStateLabel(MomentumState state, double percentage) {
    final roundedPercentage = percentage.round();
    final stateDescription = _getStateDescription(state);

    return 'Your momentum is ${state.name} at $roundedPercentage percent. $stateDescription';
  }

  /// Get semantic hint for momentum gauge
  static String getMomentumGaugeHint() {
    return 'Tap to view detailed breakdown of your momentum';
  }

  /// Get semantic label for momentum card
  static String getMomentumCardLabel(MomentumData momentumData) {
    final state = momentumData.state;
    final percentage = momentumData.percentage;
    final message = _getEncouragingMessage(state);

    return 'Momentum card. ${getMomentumStateLabel(state, percentage)} $message';
  }

  /// Get semantic label for weekly trend chart
  static String getWeeklyTrendLabel(List<double> weeklyData) {
    if (weeklyData.isEmpty) return 'Weekly trend chart with no data';

    final average = weeklyData.reduce((a, b) => a + b) / weeklyData.length;
    final trend = _getTrendDirection(weeklyData);

    return 'Weekly momentum trend chart showing $trend trend with average of ${average.round()} percent';
  }

  /// Get semantic label for quick stats card
  static String getQuickStatsLabel(
    String title,
    String value,
    String subtitle,
  ) {
    return '$title: $value. $subtitle. Tap for more details';
  }

  /// Get semantic label for action button
  static String getActionButtonLabel(String title, String description) {
    return '$title. $description. Tap to take action';
  }

  /// Get semantic label for progress indicator
  static String getProgressLabel(double progress, String context) {
    final percentage = (progress * 100).round();
    return '$context progress: $percentage percent complete';
  }

  /// Check if device has reduced motion preference
  static bool shouldReduceMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// Get accessible text scale factor
  static double getAccessibleTextScale(BuildContext context) {
    final textScaler = MediaQuery.of(context).textScaler;
    final textScaleFactor = textScaler.scale(1.0);
    return textScaleFactor.clamp(
      minimumTextScaleFactor,
      maximumTextScaleFactor,
    );
  }

  /// Create accessible button with minimum touch target
  static Widget createAccessibleButton({
    required Widget child,
    required VoidCallback? onPressed,
    required String semanticLabel,
    String? semanticHint,
    EdgeInsets? padding,
  }) {
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: true,
      child: Container(
        constraints: const BoxConstraints(
          minWidth: minimumTouchTarget,
          minHeight: minimumTouchTarget,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: padding ?? const EdgeInsets.all(8.0),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  /// Create accessible text with proper scaling
  static Widget createAccessibleText(
    String text, {
    required TextStyle baseStyle,
    required BuildContext context,
    TextAlign? textAlign,
    int? maxLines,
  }) {
    final textScale = getAccessibleTextScale(context);

    return Text(
      text,
      style: baseStyle.copyWith(fontSize: baseStyle.fontSize! * textScale),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
    );
  }

  /// Announce message to screen reader
  static void announceToScreenReader(BuildContext context, String message) {
    // Use Flutter's built-in semantics announcement
    SemanticsService.announce(message, TextDirection.ltr);
  }

  /// Provide haptic feedback based on momentum state change
  static void provideMomentumHapticFeedback(
    MomentumState oldState,
    MomentumState newState,
  ) {
    if (oldState == newState) return;

    // Different haptic patterns for different transitions
    if (newState == MomentumState.rising) {
      // Positive transition - success haptic
      HapticFeedback.mediumImpact();
    } else if (newState == MomentumState.needsCare) {
      // Needs attention - warning haptic
      HapticFeedback.heavyImpact();
    } else {
      // Steady state - light haptic
      HapticFeedback.lightImpact();
    }
  }

  /// Create semantic wrapper for interactive elements
  static Widget wrapWithSemantics({
    required Widget child,
    required String label,
    String? hint,
    String? value,
    bool? button,
    bool? slider,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      value: value,
      button: button,
      slider: slider,
      onTap: onTap,
      onLongPress: onLongPress,
      child: child,
    );
  }

  // Private helper methods

  static String _getStateDescription(MomentumState state) {
    switch (state) {
      case MomentumState.rising:
        return 'You\'re doing great! Keep up the excellent work.';
      case MomentumState.steady:
        return 'You\'re making good progress. Stay consistent.';
      case MomentumState.needsCare:
        return 'Let\'s work together to get back on track.';
    }
  }

  static String _getEncouragingMessage(MomentumState state) {
    switch (state) {
      case MomentumState.rising:
        return 'Your momentum is building beautifully!';
      case MomentumState.steady:
        return 'Steady progress is still great progress.';
      case MomentumState.needsCare:
        return 'Every small step counts. You\'ve got this!';
    }
  }

  static String _getTrendDirection(List<double> data) {
    if (data.length < 2) return 'stable';

    final first = data.first;
    final last = data.last;

    if (last > first + 5) return 'upward';
    if (last < first - 5) return 'downward';
    return 'stable';
  }
}

/// Extension to add accessibility helpers to BuildContext
extension AccessibilityExtensions on BuildContext {
  bool get shouldReduceMotion => AccessibilityService.shouldReduceMotion(this);
  double get accessibleTextScale =>
      AccessibilityService.getAccessibleTextScale(this);

  void announceToScreenReader(String message) {
    AccessibilityService.announceToScreenReader(this, message);
  }
}
