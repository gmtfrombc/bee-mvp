import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/accessibility_service.dart';

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
  bool _hasStartedAnimations = false;

  // Timer tracking for proper disposal
  Timer? _animationDelayTimer;
  Timer? _transitionDelayTimer;
  Timer? _hapticDelayTimer;

  @override
  void initState() {
    super.initState();
    _previousState = widget.state;
    _setupAnimations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Start animations here instead of initState to ensure MediaQuery is available
    if (!_hasStartedAnimations) {
      _hasStartedAnimations = true;
      _startAnimations();
    }
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
      duration: const Duration(
        milliseconds: 300,
      ), // Slightly longer for more natural feel
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

    // Enhanced bounce animation with spring physics feel
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.elasticOut, // More natural spring physics
      ),
    );

    // State transition animations with improved curves
    _colorTransitionAnimation = ColorTween(
      begin: AppTheme.getMomentumColor(_previousState ?? widget.state),
      end: AppTheme.getMomentumColor(widget.state),
    ).animate(
      CurvedAnimation(
        parent: _stateTransitionController,
        curve: Curves.easeInOutCubic, // Smoother color transitions
      ),
    );

    // Enhanced emoji scale animation with spring physics
    _emojiScaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _stateTransitionController,
        curve: Curves.elasticOut, // Spring physics for emoji
      ),
    );

    // Enhanced glow intensity animation with breathing effect
    _glowIntensityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.3, end: 0.1), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 0.1, end: 0.7), weight: 70),
    ]).animate(
      CurvedAnimation(
        parent: _stateTransitionController,
        curve: Curves.easeInOutSine, // Breathing effect
      ),
    );
  }

  void _handleStateTransition(MomentumState oldState, MomentumState newState) {
    if (_isTransitioning) return;

    setState(() {
      _isTransitioning = true;
      _previousState = oldState;
    });

    // Update color transition animation with enhanced easing
    _colorTransitionAnimation = ColorTween(
      begin: AppTheme.getMomentumColor(oldState),
      end: AppTheme.getMomentumColor(newState),
    ).animate(
      CurvedAnimation(
        parent: _stateTransitionController,
        curve:
            Curves.easeInOutCubic, // Enhanced easing for smoother transitions
      ),
    );

    // Enhanced haptic feedback based on state change direction
    _triggerEnhancedHapticFeedback(oldState, newState);

    // Check if user prefers reduced motion
    final shouldReduce = AccessibilityService.shouldReduceMotion(context);

    if (shouldReduce) {
      // Skip transition animation if user prefers reduced motion
      if (mounted) {
        setState(() {
          _isTransitioning = false;
          _previousState = newState;
        });
      }
    } else {
      // Enhanced state transition animation with celebration effect
      _stateTransitionController.reset();

      // Add subtle pre-animation pause for better visual flow
      _transitionDelayTimer?.cancel();
      _transitionDelayTimer = Timer(const Duration(milliseconds: 50), () {
        if (mounted) {
          _stateTransitionController.forward().then((_) {
            if (mounted) {
              setState(() {
                _isTransitioning = false;
                _previousState = newState;
              });

              // Add celebration bounce for positive transitions
              if (_isPositiveTransition(oldState, newState)) {
                _triggerCelebrationBounce();
              }
            }
          });
        }
      });
    }

    // Also update progress if needed
    _updateProgressAnimation();
  }

  void _triggerEnhancedHapticFeedback(
    MomentumState oldState,
    MomentumState newState,
  ) {
    // Enhanced haptic patterns for different transitions
    if (_isPositiveTransition(oldState, newState)) {
      // Positive transition - success pattern
      HapticFeedback.mediumImpact();
      _hapticDelayTimer?.cancel();
      _hapticDelayTimer = Timer(const Duration(milliseconds: 100), () {
        if (mounted) {
          HapticFeedback.lightImpact();
        }
      });
    } else if (newState == MomentumState.needsCare) {
      // Needs attention - gentle warning pattern
      HapticFeedback.lightImpact();
      _hapticDelayTimer?.cancel();
      _hapticDelayTimer = Timer(const Duration(milliseconds: 80), () {
        if (mounted) {
          HapticFeedback.lightImpact();
        }
      });
    } else {
      // Steady state - single light haptic
      HapticFeedback.lightImpact();
    }
  }

  bool _isPositiveTransition(MomentumState oldState, MomentumState newState) {
    const stateOrder = [
      MomentumState.needsCare,
      MomentumState.steady,
      MomentumState.rising,
    ];
    final oldIndex = stateOrder.indexOf(oldState);
    final newIndex = stateOrder.indexOf(newState);
    return newIndex > oldIndex;
  }

  void _triggerCelebrationBounce() {
    // Enhanced celebration animation for positive state changes
    _bounceController.reset();
    _bounceController.forward().then((_) {
      if (mounted) {
        _bounceController.reverse().then((_) {
          if (mounted) {
            // Second smaller bounce for celebration effect
            _bounceController.animateTo(0.5).then((_) {
              if (mounted) {
                _bounceController.reverse();
              }
            });
          }
        });
      }
    });
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

  void _startAnimations() {
    // Check if user prefers reduced motion
    final shouldReduce = AccessibilityService.shouldReduceMotion(context);

    if (shouldReduce) {
      // Skip animations if user prefers reduced motion
      _progressController.value = 1.0;
      return;
    }

    // Enhanced loading sequence with staggered timing
    // 1. Start progress animation immediately
    _progressController.forward();

    // 2. Wait for progress to reach 80% before starting bounce - use Timer for proper tracking
    _animationDelayTimer?.cancel();
    _animationDelayTimer = Timer(
      Duration(
        milliseconds: (widget.animationDuration.inMilliseconds * 0.8).round(),
      ),
      () async {
        if (mounted) {
          // 3. Trigger celebration bounce when progress completes
          await _bounceController.forward();
          if (mounted) {
            await _bounceController.reverse();

            // 4. Add subtle secondary bounce for polish
            if (mounted) {
              await _bounceController.animateTo(0.4);
              if (mounted) {
                await _bounceController.reverse();
              }
            }
          }
        }
      },
    );
  }

  void _handleTap() {
    if (widget.onTap != null) {
      // Enhanced haptic feedback with double tap pattern
      HapticFeedback.lightImpact();
      _hapticDelayTimer?.cancel();
      _hapticDelayTimer = Timer(const Duration(milliseconds: 50), () {
        if (mounted) {
          HapticFeedback.selectionClick();
        }
      });

      widget.onTap!();

      // Enhanced bounce animation with spring physics feel
      _bounceController.reset();
      _bounceController.forward().then((_) {
        if (mounted) {
          _bounceController.reverse().then((_) {
            if (mounted) {
              // Subtle secondary bounce for more natural feel
              _bounceController.animateTo(0.3).then((_) {
                if (mounted) {
                  _bounceController.reverse();
                }
              });
            }
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AccessibilityService.getMomentumStateLabel(
        widget.state,
        widget.percentage,
      ),
      hint:
          widget.onTap != null
              ? AccessibilityService.getMomentumGaugeHint()
              : null,
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
    _animationDelayTimer?.cancel();
    _transitionDelayTimer?.cancel();
    _hapticDelayTimer?.cancel();
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
