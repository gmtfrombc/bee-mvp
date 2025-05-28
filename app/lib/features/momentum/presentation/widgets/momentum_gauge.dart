import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Circular momentum gauge widget with custom painter
/// Displays momentum state with animated progress ring and emoji center
class MomentumGauge extends StatefulWidget {
  final MomentumState state;
  final double percentage;
  final VoidCallback? onTap;
  final Duration animationDuration;
  final bool showGlow;
  final double size;

  const MomentumGauge({
    super.key,
    required this.state,
    required this.percentage,
    this.onTap,
    this.animationDuration = const Duration(milliseconds: 1800),
    this.showGlow = true,
    this.size = 120.0,
  });

  @override
  State<MomentumGauge> createState() => _MomentumGaugeState();
}

class _MomentumGaugeState extends State<MomentumGauge>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _bounceController;
  late Animation<double> _progressAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  @override
  void didUpdateWidget(MomentumGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percentage != widget.percentage ||
        oldWidget.state != widget.state) {
      _updateAnimations();
    }
  }

  void _setupAnimations() {
    _progressController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.percentage / 100.0,
    ).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: const Cubic(0.25, 0.46, 0.45, 0.94), // Custom easing curve
      ),
    );

    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: const Cubic(0.68, -0.55, 0.265, 1.55), // Bounce effect
      ),
    );
  }

  void _updateAnimations() {
    _progressAnimation = Tween<double>(
      begin: _progressAnimation.value,
      end: widget.percentage / 100.0,
    ).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: const Cubic(0.25, 0.46, 0.45, 0.94),
      ),
    );

    _progressController.reset();
    _startAnimations();
  }

  void _startAnimations() async {
    await _progressController.forward();
    if (mounted) {
      await _bounceController.forward();
      if (mounted) {
        await _bounceController.reverse();
      }
    }
  }

  void _handleTap() {
    if (widget.onTap != null) {
      // Add haptic feedback
      widget.onTap!();

      // Quick bounce animation on tap
      _bounceController.forward().then((_) {
        if (mounted) {
          _bounceController.reverse();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Momentum gauge showing ${widget.state.name} state at ${widget.percentage.round()}%',
      hint: widget.onTap != null ? 'Tap for details' : null,
      child: GestureDetector(
        onTap: _handleTap,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration:
              widget.showGlow
                  ? BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.getMomentumColor(
                          widget.state,
                        ).withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 0,
                      ),
                    ],
                  )
                  : null,
          child: AnimatedBuilder(
            animation: Listenable.merge([_progressAnimation, _bounceAnimation]),
            builder: (context, child) {
              return Transform.scale(
                scale: _bounceAnimation.value,
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: MomentumGaugePainter(
                    progress: _progressAnimation.value,
                    state: widget.state,
                    strokeWidth: _getStrokeWidth(),
                  ),
                  child: Center(
                    child: Text(
                      AppTheme.getMomentumEmoji(widget.state),
                      style: TextStyle(fontSize: _getEmojiSize()),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  double _getStrokeWidth() {
    // Responsive stroke width based on size
    if (widget.size <= 100) return 6.0;
    if (widget.size >= 140) return 10.0;
    return 8.0;
  }

  double _getEmojiSize() {
    // Responsive emoji size based on gauge size
    return widget.size * 0.4; // 40% of gauge size
  }

  @override
  void dispose() {
    _progressController.dispose();
    _bounceController.dispose();
    super.dispose();
  }
}

/// Custom painter for the momentum gauge
class MomentumGaugePainter extends CustomPainter {
  final double progress;
  final MomentumState state;
  final double strokeWidth;

  MomentumGaugePainter({
    required this.progress,
    required this.state,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background ring
    final backgroundPaint =
        Paint()
          ..color = const Color(0xFFE0E0E0)
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress ring
    if (progress > 0) {
      final progressPaint =
          Paint()
            ..color = AppTheme.getMomentumColor(state)
            ..strokeWidth = strokeWidth
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Start from top (12 o'clock position)
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(MomentumGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.state != state ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Responsive momentum gauge that adapts to screen size
class ResponsiveMomentumGauge extends StatelessWidget {
  final MomentumState state;
  final double percentage;
  final VoidCallback? onTap;
  final Duration animationDuration;
  final bool showGlow;

  const ResponsiveMomentumGauge({
    super.key,
    required this.state,
    required this.percentage,
    this.onTap,
    this.animationDuration = const Duration(milliseconds: 1800),
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive sizing based on screen width
    double gaugeSize;
    if (screenWidth <= 375) {
      gaugeSize = 100.0; // Small screens
    } else if (screenWidth >= 429) {
      gaugeSize = 140.0; // Large screens
    } else {
      gaugeSize = 120.0; // Default size
    }

    return MomentumGauge(
      state: state,
      percentage: percentage,
      onTap: onTap,
      animationDuration: animationDuration,
      showGlow: showGlow,
      size: gaugeSize,
    );
  }
}
