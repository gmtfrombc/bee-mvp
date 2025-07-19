import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/services/responsive_service.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/health_data/mhs_category_mapper.dart';
import 'dart:math' as math;

/// Metabolic Health Score (MHS) circular gauge.
///
/// Shows a coloured progress ring that fills proportionally to the
/// percentile-based MHS value (0 – 100). The ring colour is determined by the
/// [MhsCategory] band obtained via [mapMhsToCategory]. Values below 10 are
/// rendered as the string "<10" per product-spec requirements.
///
/// The gauge animates between values over 200 ms and resizes responsively using
/// [ResponsiveService.getMomentumGaugeSize]. All magic numbers are avoided via
/// constants and responsive helpers to satisfy lint rules.
class MetabolicScoreGauge extends ConsumerWidget {
  const MetabolicScoreGauge({super.key, required this.mhs, this.size});

  /// The Advanced Metabolic Health Score percentile (0–100).
  final double mhs;

  /// Optional diameter in logical pixels. Falls back to a responsive default
  /// when null.
  final double? size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Clamp to valid domain to avoid painting errors.
    final clamped = mhs.clamp(0.0, 100.0);
    final category = mapMhsToCategory(clamped);

    final gaugeSize = size ?? ResponsiveService.getMomentumGaugeSize(context);
    final semanticsLabel = _buildSemanticsLabel(clamped, category);

    return Semantics(
      label: semanticsLabel,
      child: SizedBox(
        width: gaugeSize,
        height: gaugeSize,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 200),
          tween: Tween<double>(begin: 0, end: clamped),
          builder: (context, animatedValue, _) {
            return CustomPaint(
              painter: _GaugePainter(
                progress: animatedValue / 100.0,
                category: category,
              ),
              child: Center(
                child: _GaugeCenterLabel(value: clamped, category: category),
              ),
            );
          },
        ),
      ),
    );
  }

  String _buildSemanticsLabel(double value, MhsCategory category) {
    final readableValue = value < 10 ? '<10' : value.toStringAsFixed(0);
    final band = _labelForCategory(category);
    return 'Metabolic health score $readableValue percent, $band';
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Painter
// ────────────────────────────────────────────────────────────────────────────

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.progress, required this.category});

  final double progress; // 0.0 – 1.0
  final MhsCategory category;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = radius * 0.12; // 12 % of radius (responsive)

    final backgroundPaint =
        Paint()
          ..color = Colors.grey.shade300
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;

    // Always draw full background circle first.
    canvas.drawCircle(center, radius - strokeWidth / 2, backgroundPaint);

    // Progress arc.
    final progressPaint =
        Paint()
          ..color = _colorForCategory(category)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    final Rect arcRect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );
    const double startAngle = -math.pi / 2; // Start at top.
    final double sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(arcRect, startAngle, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.category != category;
}

// ────────────────────────────────────────────────────────────────────────────
// Center label
// ────────────────────────────────────────────────────────────────────────────

class _GaugeCenterLabel extends StatelessWidget {
  const _GaugeCenterLabel({required this.value, required this.category});

  final double value;
  final MhsCategory category;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final displayVal = value < 10 ? '<10' : value.toStringAsFixed(0);
    final bandLabel = _labelForCategory(category);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          displayVal,
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: _colorForCategory(category),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          bandLabel,
          style: textTheme.labelMedium?.copyWith(
            color: AppTheme.getTextSecondary(context),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Helpers
// ────────────────────────────────────────────────────────────────────────────

Color _colorForCategory(MhsCategory category) {
  switch (category) {
    case MhsCategory.firstGear:
      return AppTheme.mhsVeryPoor;
    case MhsCategory.stepItUp:
      return AppTheme.mhsPoor;
    case MhsCategory.onTrack:
      return AppTheme.mhsGood;
    case MhsCategory.inTheZone:
      return AppTheme.mhsExcellent;
    case MhsCategory.peakMomentum:
      return AppTheme.accentPurple;
  }
}

String _labelForCategory(MhsCategory category) {
  switch (category) {
    case MhsCategory.firstGear:
      return 'First Gear';
    case MhsCategory.stepItUp:
      return 'Step It Up';
    case MhsCategory.onTrack:
      return 'On Track';
    case MhsCategory.inTheZone:
      return 'In the Zone';
    case MhsCategory.peakMomentum:
      return 'Peak Momentum';
  }
}
