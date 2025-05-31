import 'package:flutter/material.dart';

/// Animation controller and wrapper for the momentum detail modal
/// Handles all animation setup and provides animated wrappers for content
class MomentumDetailAnimations extends StatefulWidget {
  final Widget child;
  final VoidCallback? onAnimationComplete;

  const MomentumDetailAnimations({
    super.key,
    required this.child,
    this.onAnimationComplete,
  });

  @override
  State<MomentumDetailAnimations> createState() =>
      _MomentumDetailAnimationsState();
}

class _MomentumDetailAnimationsState extends State<MomentumDetailAnimations>
    with SingleTickerProviderStateMixin {
  // Optimized: Use single animation controller instead of multiple controllers
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupOptimizedAnimations();
    _startEntryAnimation();
  }

  void _setupOptimizedAnimations() {
    // Optimized: Single controller for all animations reduces memory overhead
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Optimized: Simple scale animation for content stagger effect
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  void _startEntryAnimation() {
    // Optimized: Start single animation immediately
    _controller.forward().then((_) {
      widget.onAnimationComplete?.call();
    });
  }

  @override
  void dispose() {
    // Optimized: Only dispose single controller
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: FadeTransition(
              opacity: _scaleAnimation,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }

  /// Provides a staggered animation for child sections
  Widget buildAnimatedSection({required int index, required Widget child}) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, _) {
        return FadeTransition(
          opacity: _scaleAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(_scaleAnimation),
            child: child,
          ),
        );
      },
    );
  }

  /// Get the fade animation for background overlay
  Animation<double> get fadeAnimation => _fadeAnimation;

  /// Get the slide animation for modal positioning
  Animation<Offset> get slideAnimation => _slideAnimation;

  /// Get the scale animation for content
  Animation<double> get scaleAnimation => _scaleAnimation;
}
