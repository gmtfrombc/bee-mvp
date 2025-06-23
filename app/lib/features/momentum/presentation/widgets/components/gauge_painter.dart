import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

/// Custom painter for the momentum gauge
/// Handles drawing the background ring, progress arc, and visual styling
class MomentumGaugePainter extends CustomPainter {
  final double progress;
  final MomentumState state;
  final double strokeWidth;
  final Color? transitionColor;
  final Color backgroundColor;

  MomentumGaugePainter({
    required this.progress,
    required this.state,
    required this.strokeWidth,
    this.transitionColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background ring with theme-aware color
    final backgroundPaint =
        Paint()
          ..color = backgroundColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress ring with transition color support
    // Show minimum progress even when progress is 0 for better UX
    final displayProgress =
        progress > 0 ? progress : 0.02; // Minimum 2% for visibility

    final progressColor = (transitionColor ?? AppTheme.getMomentumColor(state))
        .withValues(alpha: 0.8);
    final progressPaint =
        Paint()
          ..color = progressColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * displayProgress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top (12 o'clock position)
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(MomentumGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.state != state ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.transitionColor != transitionColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

/// Gauge sizing utilities for responsive design
class GaugeSizing {
  /// Get responsive stroke width based on gauge size
  static double getStrokeWidth(double gaugeSize) {
    if (gaugeSize <= 100) return 6.0;
    if (gaugeSize >= 140) return 10.0;
    return 8.0;
  }

  /// Get responsive emoji size based on gauge size
  static double getEmojiSize(double gaugeSize) {
    return gaugeSize * 0.4; // 40% of gauge size
  }
}
