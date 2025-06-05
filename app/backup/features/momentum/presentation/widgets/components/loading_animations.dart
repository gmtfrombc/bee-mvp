import 'package:flutter/material.dart';

/// Handles various loading animations for indicators
/// Provides rotation, pulse, and dots animations with proper disposal
class LoadingAnimations extends StatefulWidget {
  final Widget Function(double rotation, double pulse) rotationPulseBuilder;
  final Widget Function(List<double> dotOpacities)? dotsBuilder;
  final bool enablePulse;
  final bool enableRotation;
  final bool enableDots;

  const LoadingAnimations({
    super.key,
    required this.rotationPulseBuilder,
    this.dotsBuilder,
    this.enablePulse = true,
    this.enableRotation = true,
    this.enableDots = false,
  });

  @override
  State<LoadingAnimations> createState() => _LoadingAnimationsState();
}

class _LoadingAnimationsState extends State<LoadingAnimations>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _dotsController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _dotsAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _dotsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _dotsController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() {
    if (widget.enableRotation) {
      _rotationController.repeat();
    }
    if (widget.enablePulse) {
      _pulseController.repeat(reverse: true);
    }
    if (widget.enableDots) {
      _dotsController.repeat();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.enableDots && widget.dotsBuilder != null) {
      return AnimatedBuilder(
        animation: _dotsAnimation,
        builder: (context, child) {
          final dotOpacities = List.generate(3, (index) {
            final delay = index * 0.2;
            final animationValue = (_dotsAnimation.value + delay) % 1.0;
            final opacity =
                (animationValue < 0.5)
                    ? animationValue * 2
                    : (1.0 - animationValue) * 2;
            return opacity.clamp(0.3, 1.0);
          });
          return widget.dotsBuilder!(dotOpacities);
        },
      );
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_rotationAnimation, _pulseAnimation]),
      builder: (context, child) {
        return widget.rotationPulseBuilder(
          widget.enableRotation ? _rotationAnimation.value : 0.0,
          widget.enablePulse ? _pulseAnimation.value : 1.0,
        );
      },
    );
  }
}

/// Staggered animation controller for multiple widgets
class StaggeredAnimationController extends StatefulWidget {
  final List<Widget> children;
  final Duration staggerDelay;
  final Duration animationDuration;
  final Curve curve;

  const StaggeredAnimationController({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 100),
    this.animationDuration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOut,
  });

  @override
  State<StaggeredAnimationController> createState() =>
      _StaggeredAnimationControllerState();
}

class _StaggeredAnimationControllerState
    extends State<StaggeredAnimationController>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startStaggeredAnimations();
  }

  void _setupAnimations() {
    _controllers = List.generate(
      widget.children.length,
      (index) =>
          AnimationController(duration: widget.animationDuration, vsync: this),
    );

    _animations =
        _controllers
            .map(
              (controller) => Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: controller, curve: widget.curve),
              ),
            )
            .toList();
  }

  void _startStaggeredAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      final delay = Duration(
        milliseconds:
            (widget.staggerDelay.inMilliseconds * (1 + i * 0.3)).round(),
      );

      Future.delayed(delay, () {
        if (mounted) {
          _controllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(widget.children.length, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            final animationValue = _animations[index].value.clamp(0.0, 1.0);
            final slideOffset = 30 * (1 - animationValue);
            final scaleValue = 0.8 + (0.2 * animationValue);

            return Transform.translate(
              offset: Offset(0, slideOffset),
              child: Transform.scale(
                scale: scaleValue,
                child: Opacity(
                  opacity: animationValue,
                  child: widget.children[index],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
