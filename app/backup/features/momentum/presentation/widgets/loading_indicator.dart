import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/responsive_service.dart';
import '../providers/loading_state_provider.dart';
import 'components/loading_animations.dart';

// Export all loading components for external use
export 'components/loading_animations.dart';
export 'components/loading_indicator_variants.dart';

/// Enhanced loading indicator with progress and messages
/// Refactored to use extracted animation and variant components for better maintainability
class MomentumLoadingIndicator extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(loadingProgressProvider);
    final message = ref.watch(loadingMessageProvider);
    final isRefreshing = ref.watch(isAnyComponentRefreshingProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Loading indicator with progress using extracted animations
        LoadingAnimations(
          rotationPulseBuilder: (rotation, pulse) {
            return Transform.scale(
              scale: pulse,
              child: Transform.rotate(
                angle: rotation * 2 * 3.14159,
                child: SizedBox(
                  width: size,
                  height: size,
                  child: Stack(
                    children: [
                      // Background circle
                      CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 3.0,
                        color: (color ?? AppTheme.momentumRising).withValues(
                          alpha: 0.2,
                        ),
                      ),
                      // Progress circle
                      if (showProgress)
                        CircularProgressIndicator(
                          value: isRefreshing ? null : progress,
                          strokeWidth: 3.0,
                          color: color ?? AppTheme.momentumRising,
                        )
                      else
                        CircularProgressIndicator(
                          strokeWidth: 3.0,
                          color: color ?? AppTheme.momentumRising,
                        ),
                      // Center icon
                      Center(
                        child: Icon(
                          isRefreshing ? Icons.refresh : Icons.trending_up,
                          size: size * 0.4,
                          color: color ?? AppTheme.momentumRising,
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
        if (showProgress && !isRefreshing) ...[
          SizedBox(height: ResponsiveService.getSmallSpacing(context)),
          Text(
            '${(progress * 100).round()}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color ?? AppTheme.momentumRising,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],

        // Loading message
        if (showMessage) ...[
          SizedBox(height: ResponsiveService.getMediumSpacing(context)),
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
/// Uses extracted StaggeredAnimationController component
class StaggeredLoadingAnimation extends StatelessWidget {
  final List<Widget> children;
  final Duration staggerDelay;
  final Duration animationDuration;
  final Curve curve;

  const StaggeredLoadingAnimation({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 100),
    this.animationDuration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOut,
  });

  @override
  Widget build(BuildContext context) {
    return StaggeredAnimationController(
      staggerDelay: staggerDelay,
      animationDuration: animationDuration,
      curve: curve,
      children: children,
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
      color: AppTheme.getTextPrimary(context).withValues(alpha: 0.5),
      child: Center(
        child: Card(
          margin: ResponsiveService.getLargePadding(context),
          child: Padding(
            padding: ResponsiveService.getLargePadding(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MomentumLoadingIndicator(
                  showProgress: showProgress,
                  showMessage: message != null,
                ),
                if (message != null) ...[
                  SizedBox(
                    height: ResponsiveService.getResponsiveSpacing(context),
                  ),
                  Text(
                    message!,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
                if (onCancel != null) ...[
                  SizedBox(
                    height: ResponsiveService.getResponsiveSpacing(context),
                  ),
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
