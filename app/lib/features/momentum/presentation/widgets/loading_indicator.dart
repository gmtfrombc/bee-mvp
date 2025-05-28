import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/loading_state_provider.dart';

/// Enhanced loading indicator with progress and messages
class MomentumLoadingIndicator extends ConsumerStatefulWidget {
  final bool showProgress;
  final bool showMessage;
  final double size;
  final Color? color;

  const MomentumLoadingIndicator({
    super.key,
    this.showProgress = true,
    this.showMessage = true,
    this.size = 48.0,
    this.color,
  });

  @override
  ConsumerState<MomentumLoadingIndicator> createState() =>
      _MomentumLoadingIndicatorState();
}

class _MomentumLoadingIndicatorState
    extends ConsumerState<MomentumLoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

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

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() {
    _rotationController.repeat();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(loadingProgressProvider);
    final message = ref.watch(loadingMessageProvider);
    final isRefreshing = ref.watch(isAnyComponentRefreshingProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Loading indicator with progress
        AnimatedBuilder(
          animation: Listenable.merge([_rotationAnimation, _pulseAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value * 2 * 3.14159,
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: Stack(
                    children: [
                      // Background circle
                      CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 3.0,
                        color: (widget.color ?? AppTheme.momentumRising)
                            .withValues(alpha: 0.2),
                      ),
                      // Progress circle
                      if (widget.showProgress)
                        CircularProgressIndicator(
                          value: isRefreshing ? null : progress,
                          strokeWidth: 3.0,
                          color: widget.color ?? AppTheme.momentumRising,
                        )
                      else
                        CircularProgressIndicator(
                          strokeWidth: 3.0,
                          color: widget.color ?? AppTheme.momentumRising,
                        ),
                      // Center icon
                      Center(
                        child: Icon(
                          isRefreshing ? Icons.refresh : Icons.trending_up,
                          size: widget.size * 0.4,
                          color: widget.color ?? AppTheme.momentumRising,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // Progress percentage
        if (widget.showProgress && !isRefreshing) ...[
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).round()}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: widget.color ?? AppTheme.momentumRising,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],

        // Loading message
        if (widget.showMessage) ...[
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              message,
              key: ValueKey(message),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}

/// Compact loading indicator for smaller spaces
class CompactLoadingIndicator extends StatefulWidget {
  final double size;
  final Color? color;
  final bool showDots;

  const CompactLoadingIndicator({
    super.key,
    this.size = 24.0,
    this.color,
    this.showDots = false,
  });

  @override
  State<CompactLoadingIndicator> createState() =>
      _CompactLoadingIndicatorState();
}

class _CompactLoadingIndicatorState extends State<CompactLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showDots) {
      return _buildDotsIndicator();
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animation.value * 2 * 3.14159,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              color: widget.color ?? AppTheme.momentumRising,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDotsIndicator() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final animationValue = (_animation.value + delay) % 1.0;
            final opacity =
                (animationValue < 0.5)
                    ? animationValue * 2
                    : (1.0 - animationValue) * 2;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: opacity.clamp(0.3, 1.0),
                child: Container(
                  width: widget.size * 0.2,
                  height: widget.size * 0.2,
                  decoration: BoxDecoration(
                    color: widget.color ?? AppTheme.momentumRising,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Staggered loading animation for multiple components
class StaggeredLoadingAnimation extends StatefulWidget {
  final List<Widget> children;
  final Duration staggerDelay;
  final Duration animationDuration;
  final Curve curve;

  const StaggeredLoadingAnimation({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 100),
    this.animationDuration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutBack,
  });

  @override
  State<StaggeredLoadingAnimation> createState() =>
      _StaggeredLoadingAnimationState();
}

class _StaggeredLoadingAnimationState extends State<StaggeredLoadingAnimation>
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
      Future.delayed(widget.staggerDelay * i, () {
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
            return Transform.translate(
              offset: Offset(0, 20 * (1 - _animations[index].value)),
              child: Opacity(
                opacity: _animations[index].value,
                child: widget.children[index],
              ),
            );
          },
        );
      }),
    );
  }
}

/// Loading overlay for full-screen loading states
class LoadingOverlay extends ConsumerWidget {
  final bool isVisible;
  final String? message;
  final bool showProgress;
  final VoidCallback? onCancel;

  const LoadingOverlay({
    super.key,
    required this.isVisible,
    this.message,
    this.showProgress = true,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isVisible) return const SizedBox.shrink();

    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MomentumLoadingIndicator(
                  showProgress: showProgress,
                  showMessage: message != null,
                ),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    message!,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
                if (onCancel != null) ...[
                  const SizedBox(height: 16),
                  TextButton(onPressed: onCancel, child: const Text('Cancel')),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Refresh indicator with momentum theming
class MomentumRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? color;

  const MomentumRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? AppTheme.momentumRising,
      backgroundColor: AppTheme.surfacePrimary,
      strokeWidth: 3.0,
      displacement: 60.0,
      child: child,
    );
  }
}
