import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';

/// Circular momentum gauge widget with custom painter
/// Displays momentum state with animated progress ring and emoji center
/// Includes smooth state transition animations
class MomentumGauge extends StatefulWidget {
  final MomentumState state;
  final double percentage;
  final VoidCallback? onTap;
  final Duration animationDuration;
  final Duration stateTransitionDuration;
  final bool showGlow;
  final double size;

  const MomentumGauge({
    super.key,
    required this.state,
    required this.percentage,
    this.onTap,
    this.animationDuration = const Duration(milliseconds: 1800),
    this.stateTransitionDuration = const Duration(milliseconds: 800),
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
  late AnimationController _stateTransitionController;
  late Animation<double> _progressAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<Color?> _colorTransitionAnimation;
  late Animation<double> _emojiScaleAnimation;
  late Animation<double> _glowIntensityAnimation;

  MomentumState? _previousState;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    _previousState = widget.state;
    _setupAnimations();
    _startAnimations();
  }

  @override
  void didUpdateWidget(MomentumGauge oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if state changed for transition animation
    if (oldWidget.state != widget.state) {
      _handleStateTransition(oldWidget.state, widget.state);
    } else if (oldWidget.percentage != widget.percentage) {
      _updateProgressAnimation();
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

    _stateTransitionController = AnimationController(
      duration: widget.stateTransitionDuration,
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

    // State transition animations
    _colorTransitionAnimation = ColorTween(
      begin: AppTheme.getMomentumColor(_previousState ?? widget.state),
      end: AppTheme.getMomentumColor(widget.state),
    ).animate(
      CurvedAnimation(
        parent: _stateTransitionController,
        curve: Curves.easeInOut,
      ),
    );

    // Simpler emoji scale animation to avoid TweenSequence bounds issues
    _emojiScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _stateTransitionController,
        curve: Curves.elasticOut,
      ),
    );

    // Simpler glow intensity animation
    _glowIntensityAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(
        parent: _stateTransitionController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _handleStateTransition(MomentumState oldState, MomentumState newState) {
    if (_isTransitioning) return;

    setState(() {
      _isTransitioning = true;
      _previousState = oldState;
    });

    // Update color transition animation
    _colorTransitionAnimation = ColorTween(
      begin: AppTheme.getMomentumColor(oldState),
      end: AppTheme.getMomentumColor(newState),
    ).animate(
      CurvedAnimation(
        parent: _stateTransitionController,
        curve: Curves.easeInOut,
      ),
    );

    // Trigger haptic feedback based on state change
    _triggerHapticFeedback(oldState, newState);

    // Start state transition animation
    _stateTransitionController.reset();
    _stateTransitionController.forward().then((_) {
      if (mounted) {
        setState(() {
          _isTransitioning = false;
          _previousState = newState;
        });
      }
    });

    // Also update progress if needed
    _updateProgressAnimation();
  }

  void _triggerHapticFeedback(MomentumState oldState, MomentumState newState) {
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

  void _updateProgressAnimation() {
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
      HapticFeedback.lightImpact();
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
                        color:
                            _isTransitioning
                                ? (_colorTransitionAnimation.value ??
                                        AppTheme.getMomentumColor(widget.state))
                                    .withValues(
                                      alpha: _glowIntensityAnimation.value,
                                    )
                                : AppTheme.getMomentumColor(
                                  widget.state,
                                ).withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 0,
                      ),
                    ],
                  )
                  : null,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _progressAnimation,
              _bounceAnimation,
              _stateTransitionController,
            ]),
            builder: (context, child) {
              return Transform.scale(
                scale: _bounceAnimation.value,
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: MomentumGaugePainter(
                    progress: _progressAnimation.value,
                    state: widget.state,
                    strokeWidth: _getStrokeWidth(),
                    transitionColor:
                        _isTransitioning
                            ? _colorTransitionAnimation.value
                            : null,
                  ),
                  child: Center(
                    child: Transform.scale(
                      scale:
                          _isTransitioning
                              ? (1.0 +
                                  (_emojiScaleAnimation.value - 1.0) *
                                      0.5) // Dampen the scale effect
                              : 1.0,
                      child: Text(
                        AppTheme.getMomentumEmoji(widget.state),
                        style: TextStyle(fontSize: _getEmojiSize()),
                        textAlign: TextAlign.center,
                      ),
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
    _stateTransitionController.dispose();
    super.dispose();
  }
}

/// Custom painter for the momentum gauge
class MomentumGaugePainter extends CustomPainter {
  final double progress;
  final MomentumState state;
  final double strokeWidth;
  final Color? transitionColor;

  MomentumGaugePainter({
    required this.progress,
    required this.state,
    required this.strokeWidth,
    this.transitionColor,
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

    // Progress ring with transition color support
    if (progress > 0) {
      final progressPaint =
          Paint()
            ..color = transitionColor ?? AppTheme.getMomentumColor(state)
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
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.transitionColor != transitionColor;
  }
}

/// Responsive momentum gauge that adapts to screen size
class ResponsiveMomentumGauge extends StatelessWidget {
  final MomentumState state;
  final double percentage;
  final VoidCallback? onTap;
  final Duration animationDuration;
  final Duration stateTransitionDuration;
  final bool showGlow;

  const ResponsiveMomentumGauge({
    super.key,
    required this.state,
    required this.percentage,
    this.onTap,
    this.animationDuration = const Duration(milliseconds: 1800),
    this.stateTransitionDuration = const Duration(milliseconds: 800),
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
      stateTransitionDuration: stateTransitionDuration,
      showGlow: showGlow,
      size: gaugeSize,
    );
  }
}
