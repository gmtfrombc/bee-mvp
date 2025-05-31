import 'package:flutter/material.dart';
import '../../../../core/services/responsive_service.dart';
import '../../../../core/theme/app_theme.dart';

/// Enhanced shimmer widget with optimized performance and smooth animations
class ShimmerWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _setupOptimizedAnimation();
  }

  void _setupOptimizedAnimation() {
    _controller = AnimationController(duration: widget.duration, vsync: this);
    // Enhanced: Use more sophisticated curve for natural shimmer motion
    _animation = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine, // More natural wave motion
      ),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use theme-aware colors
    final baseColor =
        widget.baseColor ??
        AppTheme.getTextTertiary(context).withValues(alpha: 0.2);
    final highlightColor =
        widget.highlightColor ??
        AppTheme.getSurfacePrimary(context).withValues(alpha: 0.8);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            // Enhanced: More sophisticated gradient with better color transitions
            final progress = _animation.value;
            final normalizedStops = [
              (progress - 0.4).clamp(0.0, 1.0),
              (progress - 0.1).clamp(0.0, 1.0),
              progress.clamp(0.0, 1.0),
              (progress + 0.1).clamp(0.0, 1.0),
              (progress + 0.4).clamp(0.0, 1.0),
            ];

            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                baseColor.withValues(alpha: 0.8),
                highlightColor,
                baseColor.withValues(alpha: 0.8),
                baseColor,
              ],
              stops: normalizedStops,
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Optimized skeleton container with pre-calculated dimensions
class SkeletonContainer extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final EdgeInsets? margin;

  const SkeletonContainer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    // Optimized: Cache border radius calculation
    final responsiveBorderRadius =
        borderRadius ?? _getCachedBorderRadius(context);

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: AppTheme.getTextTertiary(context).withValues(alpha: 0.2),
        borderRadius: responsiveBorderRadius,
      ),
    );
  }

  // Optimized: Cached border radius calculation
  static BorderRadius? _cachedBorderRadius;
  static double? _lastScreenWidth;

  BorderRadius _getCachedBorderRadius(BuildContext context) {
    final currentWidth = MediaQuery.of(context).size.width;
    if (_cachedBorderRadius == null || _lastScreenWidth != currentWidth) {
      _lastScreenWidth = currentWidth;
      _cachedBorderRadius = BorderRadius.circular(
        ResponsiveService.getBorderRadius(context),
      );
    }
    return _cachedBorderRadius!;
  }
}

/// Skeleton text line
class SkeletonText extends StatelessWidget {
  final double width;
  final double? height;
  final BorderRadius? borderRadius;

  const SkeletonText({
    super.key,
    required this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final textHeight =
        height ?? (ResponsiveService.shouldUseCompactLayout(context) ? 14 : 16);
    final responsiveBorderRadius =
        borderRadius ??
        BorderRadius.circular(ResponsiveService.getBorderRadius(context) * 0.5);

    return SkeletonContainer(
      width: width,
      height: textHeight,
      borderRadius: responsiveBorderRadius,
    );
  }
}

/// Pulse loading animation for individual components
class PulseLoadingWidget extends StatefulWidget {
  final Widget child;
  final Duration? duration;

  const PulseLoadingWidget({super.key, required this.child, this.duration});

  @override
  State<PulseLoadingWidget> createState() => _PulseLoadingWidgetState();
}

class _PulseLoadingWidgetState extends State<PulseLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Make duration responsive - faster on smaller devices
    final defaultDuration =
        ResponsiveService.shouldUseCompactLayout(context)
            ? const Duration(milliseconds: 800)
            : const Duration(milliseconds: 1000);

    _controller = AnimationController(
      duration: widget.duration ?? defaultDuration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(opacity: _animation.value, child: widget.child);
      },
    );
  }
}

/// Optimized dimensions helper class to cache calculations
class SkeletonDimensions {
  final double cardHeight;
  final EdgeInsets cardMargin;
  final double gaugeSize;
  final double spacing;
  final EdgeInsets padding;
  final double borderRadius;
  final double headerWidth;
  final double headerHeight;
  final double stateTextWidth;
  final double stateTextHeight;
  final double messageHeight;
  final double messageSecondWidth;
  final double progressBarHeight;

  const SkeletonDimensions({
    required this.cardHeight,
    required this.cardMargin,
    required this.gaugeSize,
    required this.spacing,
    required this.padding,
    required this.borderRadius,
    required this.headerWidth,
    required this.headerHeight,
    required this.stateTextWidth,
    required this.stateTextHeight,
    required this.messageHeight,
    required this.messageSecondWidth,
    required this.progressBarHeight,
  });

  factory SkeletonDimensions.fromContext(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = ResponsiveService.shouldUseCompactLayout(context);

    return SkeletonDimensions(
      cardHeight: ResponsiveService.getMomentumCardHeight(context),
      cardMargin: ResponsiveService.getResponsiveMargin(context),
      gaugeSize: ResponsiveService.getMomentumGaugeSize(context),
      spacing: ResponsiveService.getResponsiveSpacing(context),
      padding: ResponsiveService.getResponsivePadding(context),
      borderRadius: ResponsiveService.getBorderRadius(context),
      headerWidth: screenWidth * 0.3,
      headerHeight: isCompact ? 14.0 : 16.0,
      stateTextWidth: screenWidth * 0.25,
      stateTextHeight: isCompact ? 18.0 : 20.0,
      messageHeight: isCompact ? 12.0 : 14.0,
      messageSecondWidth: screenWidth * 0.5,
      progressBarHeight: isCompact ? 4.0 : 6.0,
    );
  }
}
