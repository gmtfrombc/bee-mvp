import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/responsive_service.dart';
import 'loading_animations.dart';

/// Compact loading indicator for smaller spaces
class CompactLoadingIndicator extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return LoadingAnimations(
      enablePulse: false,
      enableRotation: !showDots,
      enableDots: showDots,
      rotationPulseBuilder: (rotation, pulse) {
        return Transform.rotate(
          angle: rotation * 2 * 3.14159,
          child: SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              color: color ?? AppTheme.momentumRising,
            ),
          ),
        );
      },
      dotsBuilder:
          showDots ? (dotOpacities) => _buildDotsIndicator(dotOpacities) : null,
    );
  }

  Widget _buildDotsIndicator(List<double> dotOpacities) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: Opacity(
            opacity: dotOpacities[index],
            child: Container(
              width: size * 0.2,
              height: size * 0.2,
              decoration: BoxDecoration(
                color: color ?? AppTheme.momentumRising,
                shape: BoxShape.circle,
              ),
            ),
          ),
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
  final Widget? loadingIndicator;

  const LoadingOverlay({
    super.key,
    required this.isVisible,
    this.message,
    this.showProgress = true,
    this.onCancel,
    this.loadingIndicator,
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
                loadingIndicator ??
                    const CompactLoadingIndicator(size: 48.0, showDots: false),
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
