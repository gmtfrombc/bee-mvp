import 'package:flutter/material.dart';
import '../../../../../core/services/accessibility_service.dart';

/// Animation controller system for Today Feed tile interactions
/// Manages entry, tap, pulse, and shimmer animations with accessibility support
/// **OPTIMIZED**: Enhanced for 60fps performance with RepaintBoundary and efficient rebuild patterns
class TodayFeedAnimationController {
  TodayFeedAnimationController({
    required TickerProvider vsync,
    bool enableAnimations = true,
  }) : _vsync = vsync,
       _enableAnimations = enableAnimations;

  final TickerProvider _vsync;
  final bool _enableAnimations;

  // Animation controllers
  late AnimationController _entryController;
  late AnimationController _tapController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;

  // Animations
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;

  // Performance: Separate listenables for different animation groups
  late Listenable _entryAnimationGroup;
  late Listenable _interactionAnimationGroup;
  late Listenable _stateAnimationGroup;

  bool _isInitialized = false;

  // Getters for animations
  Animation<Offset> get slideAnimation => _slideAnimation;
  Animation<double> get fadeAnimation => _fadeAnimation;
  Animation<double> get scaleAnimation => _scaleAnimation;
  Animation<double> get pulseAnimation => _pulseAnimation;
  Animation<double> get shimmerAnimation => _shimmerAnimation;

  // Performance: Grouped animation listenables for efficient rebuilds
  Listenable get entryAnimationGroup => _entryAnimationGroup;
  Listenable get interactionAnimationGroup => _interactionAnimationGroup;
  Listenable get stateAnimationGroup => _stateAnimationGroup;

  // Animation durations - responsive to motion preferences and performance
  Duration get _entryDuration =>
      _enableAnimations
          ? const Duration(milliseconds: 400)
          : Duration.zero; // Reduced from 600ms

  Duration get _tapDuration =>
      _enableAnimations
          ? const Duration(milliseconds: 150)
          : Duration.zero; // Reduced from 200ms

  Duration get _pulseDuration =>
      _enableAnimations
          ? const Duration(milliseconds: 1200)
          : Duration.zero; // Reduced from 1500ms

  /// Initialize all animation controllers and animations
  void setupAnimations() {
    if (_isInitialized) return;

    // Entry animation setup
    _entryController = AnimationController(
      duration: _entryDuration,
      vsync: _vsync,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2), // Reduced from 0.3 for smoother animation
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(
          0.1,
          1.0,
          curve: Curves.easeOut,
        ), // Start fade earlier
      ),
    );

    // Tap animation setup
    _tapController = AnimationController(duration: _tapDuration, vsync: _vsync);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97, // Reduced scale change for smoother animation
    ).animate(CurvedAnimation(parent: _tapController, curve: Curves.easeInOut));

    // Pulse animation setup for fresh state
    _pulseController = AnimationController(
      duration: _pulseDuration,
      vsync: _vsync,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      // Reduced from 1.1 to 1.08
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ), // Changed from elasticOut for smoother performance
    );

    // Shimmer animation setup for loading state
    _shimmerController = AnimationController(
      duration: _pulseDuration,
      vsync: _vsync,
    );

    _shimmerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _shimmerController,
        curve: Curves.linear,
      ), // Linear for consistent shimmer performance
    );

    // Performance: Create grouped animation listenables for efficient rebuilds
    _entryAnimationGroup = Listenable.merge([_fadeAnimation, _slideAnimation]);
    _interactionAnimationGroup = Listenable.merge([_scaleAnimation]);
    _stateAnimationGroup = Listenable.merge([
      _pulseAnimation,
      _shimmerAnimation,
    ]);

    _isInitialized = true;
  }

  /// Start entry animation with accessibility checks
  void startEntryAnimation(BuildContext context) {
    if (!_isInitialized) return;

    if (_enableAnimations &&
        !AccessibilityService.shouldReduceMotion(context)) {
      _entryController.forward();
    } else {
      _entryController.value = 1.0;
    }
  }

  /// Start pulse animation if content is fresh
  void startPulseAnimationIfFresh(BuildContext context, bool isFresh) {
    if (!_isInitialized) return;

    if (_enableAnimations &&
        !AccessibilityService.shouldReduceMotion(context) &&
        isFresh) {
      _pulseController.repeat(reverse: true);
    }
  }

  /// Start shimmer animation for loading state
  void startShimmerAnimationIfLoading(BuildContext context, bool isLoading) {
    if (!_isInitialized) return;

    if (_enableAnimations &&
        !AccessibilityService.shouldReduceMotion(context) &&
        isLoading) {
      _shimmerController.repeat();
    }
  }

  /// Handle tap animation with feedback
  Future<void> handleTapAnimation(BuildContext context) async {
    if (!_isInitialized) return;

    if (_enableAnimations &&
        !AccessibilityService.shouldReduceMotion(context)) {
      await _tapController.forward();
      if (_tapController.isCompleted) {
        await _tapController.reverse();
      }
    }
  }

  /// Handle state transition animations with performance optimization
  Future<void> handleStateTransition(BuildContext context) async {
    if (!_isInitialized || !_enableAnimations) return;

    // Quick fade transition instead of full reverse/forward for better performance
    await _entryController.animateTo(
      0.8,
      duration: const Duration(milliseconds: 100),
    );
    await _entryController.forward();
  }

  /// Update animations for new state
  void updateAnimationsForNewState(
    BuildContext context, {
    required bool isFresh,
    required bool isLoading,
  }) {
    if (!_isInitialized) return;

    // Stop existing state-specific animations
    _pulseController.stop();
    _shimmerController.stop();

    // Start appropriate animation for new state
    if (isFresh) {
      startPulseAnimationIfFresh(context, true);
    } else if (isLoading) {
      startShimmerAnimationIfLoading(context, true);
    }
  }

  /// Get combined animation listenable for AnimatedBuilder (legacy)
  /// **DEPRECATED**: Use grouped animation listenables for better performance
  @Deprecated('Use specific animation groups instead for better performance')
  Listenable get combinedAnimation => Listenable.merge([
    _fadeAnimation,
    _scaleAnimation,
    _pulseAnimation,
    _shimmerAnimation,
  ]);

  /// Check if motion should be animated based on context
  bool shouldAnimateMotion(BuildContext context) {
    try {
      return _enableAnimations &&
          !AccessibilityService.shouldReduceMotion(context);
    } catch (e) {
      // Fallback to widget setting if context not available
      return _enableAnimations;
    }
  }

  /// Dispose all animation controllers
  void dispose() {
    if (!_isInitialized) return;

    _entryController.dispose();
    _tapController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
  }
}

/// High-performance animation wrapper widget with RepaintBoundary optimizations
/// **OPTIMIZED**: Uses separate AnimatedBuilder widgets for different animation groups
class TodayFeedAnimationWrapper extends StatelessWidget {
  const TodayFeedAnimationWrapper({
    super.key,
    required this.animationController,
    required this.child,
    required this.enableAnimations,
  });

  final TodayFeedAnimationController animationController;
  final Widget child;
  final bool enableAnimations;

  @override
  Widget build(BuildContext context) {
    final shouldAnimateMotion = animationController.shouldAnimateMotion(
      context,
    );

    // Performance: Wrap in RepaintBoundary to isolate repaints
    return RepaintBoundary(
      child: _buildEntryAnimationLayer(context, shouldAnimateMotion),
    );
  }

  Widget _buildEntryAnimationLayer(
    BuildContext context,
    bool shouldAnimateMotion,
  ) {
    if (!shouldAnimateMotion) {
      return RepaintBoundary(
        child: _buildInteractionAnimationLayer(context, shouldAnimateMotion),
      );
    }

    return AnimatedBuilder(
      animation: animationController.entryAnimationGroup,
      builder: (context, _) {
        return Opacity(
          opacity: animationController.fadeAnimation.value,
          child: SlideTransition(
            position: animationController.slideAnimation,
            child: RepaintBoundary(
              child: _buildInteractionAnimationLayer(
                context,
                shouldAnimateMotion,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInteractionAnimationLayer(
    BuildContext context,
    bool shouldAnimateMotion,
  ) {
    if (!shouldAnimateMotion) {
      return child;
    }

    return AnimatedBuilder(
      animation: animationController.interactionAnimationGroup,
      builder: (context, _) {
        return Transform.scale(
          scale: animationController.scaleAnimation.value,
          child: child,
        );
      },
    );
  }
}

/// Performance-optimized pulse animation widget for momentum indicators
/// **NEW**: Separate widget for pulse animations to isolate rebuilds
class TodayFeedPulseAnimationWrapper extends StatelessWidget {
  const TodayFeedPulseAnimationWrapper({
    super.key,
    required this.animationController,
    required this.child,
    required this.enableAnimations,
    required this.shouldPulse,
  });

  final TodayFeedAnimationController animationController;
  final Widget child;
  final bool enableAnimations;
  final bool shouldPulse;

  @override
  Widget build(BuildContext context) {
    if (!enableAnimations || !shouldPulse) {
      return RepaintBoundary(child: child);
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: animationController.stateAnimationGroup,
        builder: (context, _) {
          return Transform.scale(
            scale: animationController.pulseAnimation.value,
            child: child,
          );
        },
      ),
    );
  }
}

/// Performance-optimized shimmer animation widget for loading states
/// **NEW**: Separate widget for shimmer animations with efficient gradient updates
class TodayFeedShimmerAnimationWrapper extends StatelessWidget {
  const TodayFeedShimmerAnimationWrapper({
    super.key,
    required this.animationController,
    required this.child,
    required this.enableAnimations,
    required this.isShimmering,
  });

  final TodayFeedAnimationController animationController;
  final Widget child;
  final bool enableAnimations;
  final bool isShimmering;

  @override
  Widget build(BuildContext context) {
    if (!enableAnimations || !isShimmering) {
      return RepaintBoundary(child: child);
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: animationController.stateAnimationGroup,
        builder: (context, _) {
          return ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                colors: const [
                  Colors.transparent,
                  Colors.white24,
                  Colors.transparent,
                ],
                stops:
                    [
                      animationController.shimmerAnimation.value - 0.3,
                      animationController.shimmerAnimation.value,
                      animationController.shimmerAnimation.value + 0.3,
                    ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ).createShader(bounds);
            },
            blendMode: BlendMode.srcATop,
            child: child,
          );
        },
      ),
    );
  }
}
