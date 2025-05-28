import 'package:flutter/material.dart';
import '../../../../core/services/responsive_service.dart';

/// Optimized shimmer effect widget for skeleton loading states
/// Uses more efficient animation approach to reduce memory usage
class ShimmerWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
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
    // Optimized: Use simpler linear animation to reduce GPU overhead
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(_controller);
    _controller.repeat();
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
        return ShaderMask(
          shaderCallback: (bounds) {
            // Optimized: Pre-calculate normalized stops to reduce computation
            final progress = _animation.value;
            final normalizedStops = [
              (progress - 0.3).clamp(0.0, 1.0),
              progress.clamp(0.0, 1.0),
              (progress + 0.3).clamp(0.0, 1.0),
            ];

            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
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
  // Optimized: Cache colors to avoid repeated theme lookups
  static const Color _skeletonColor = Color(0xFFE0E0E0);

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
        color: _skeletonColor,
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

/// Optimized skeleton momentum card with efficient shimmer effect
class SkeletonMomentumCard extends StatelessWidget {
  final double? height;
  final EdgeInsets? margin;

  const SkeletonMomentumCard({super.key, this.height, this.margin});

  @override
  Widget build(BuildContext context) {
    // Optimized: Pre-calculate all dimensions to avoid repeated calls
    final dimensions = _SkeletonDimensions.fromContext(context);
    final cardHeight = height ?? dimensions.cardHeight;
    final cardMargin = margin ?? dimensions.cardMargin;

    return Container(
      margin: cardMargin,
      child: Card(
        elevation: 2,
        child: Container(
          height: cardHeight,
          padding: dimensions.padding,
          child: ShimmerWidget(
            child: _buildOptimizedSkeletonContent(context, dimensions),
          ),
        ),
      ),
    );
  }

  // Optimized: Extract skeleton content to reduce widget rebuilds
  Widget _buildOptimizedSkeletonContent(
    BuildContext context,
    _SkeletonDimensions dimensions,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Header skeleton - responsive width based on screen
        SkeletonContainer(
          width: dimensions.headerWidth,
          height: dimensions.headerHeight,
          borderRadius: BorderRadius.circular(dimensions.borderRadius * 0.5),
        ),

        SizedBox(height: dimensions.spacing * 0.4),

        // Gauge skeleton (circular) - Use responsive size
        Flexible(
          flex: 4,
          child: Container(
            width: dimensions.gaugeSize,
            height: dimensions.gaugeSize,
            decoration: const BoxDecoration(
              color: SkeletonContainer._skeletonColor,
              shape: BoxShape.circle,
            ),
          ),
        ),

        SizedBox(height: dimensions.spacing * 0.3),

        // State text skeleton - responsive sizing
        SkeletonContainer(
          width: dimensions.stateTextWidth,
          height: dimensions.stateTextHeight,
          borderRadius: BorderRadius.circular(dimensions.borderRadius * 0.6),
        ),

        SizedBox(height: dimensions.spacing * 0.3),

        // Message skeleton - responsive and flexible
        Flexible(
          flex: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SkeletonContainer(
                width: double.infinity,
                height: dimensions.messageHeight,
                borderRadius: BorderRadius.circular(
                  dimensions.borderRadius * 0.4,
                ),
              ),
              SizedBox(height: dimensions.spacing * 0.2),
              SkeletonContainer(
                width: dimensions.messageSecondWidth,
                height: dimensions.messageHeight,
                borderRadius: BorderRadius.circular(
                  dimensions.borderRadius * 0.4,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: dimensions.spacing * 0.3),

        // Progress bar skeleton - responsive height
        SkeletonContainer(
          width: double.infinity,
          height: dimensions.progressBarHeight,
          borderRadius: BorderRadius.circular(dimensions.borderRadius * 0.25),
        ),
      ],
    );
  }
}

/// Skeleton weekly trend chart
class SkeletonWeeklyTrendChart extends StatelessWidget {
  final double? height;

  const SkeletonWeeklyTrendChart({super.key, this.height});

  @override
  Widget build(BuildContext context) {
    final chartHeight =
        height ?? ResponsiveService.getWeeklyChartHeight(context);
    final padding = ResponsiveService.getResponsivePadding(context);
    final spacing = ResponsiveService.getResponsiveSpacing(context);
    final borderRadius = ResponsiveService.getBorderRadius(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Container(
        height: chartHeight,
        padding: padding,
        child: ShimmerWidget(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header skeleton - responsive sizing
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonContainer(
                    width: MediaQuery.of(context).size.width * 0.35,
                    height:
                        ResponsiveService.shouldUseCompactLayout(context)
                            ? 16
                            : 18,
                    borderRadius: BorderRadius.circular(borderRadius * 0.5),
                  ),
                  SkeletonContainer(
                    width: MediaQuery.of(context).size.width * 0.2,
                    height:
                        ResponsiveService.shouldUseCompactLayout(context)
                            ? 12
                            : 14,
                    borderRadius: BorderRadius.circular(borderRadius * 0.4),
                  ),
                ],
              ),

              SizedBox(height: spacing * 0.6),

              // Chart area skeleton - fully responsive
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (index) {
                    // Make heights responsive to available space
                    final baseHeights = [0.5, 0.7, 0.6, 0.85, 0.65, 0.8, 0.6];
                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            flex: (baseHeights[index] * 10).round(),
                            child: Container(
                              width:
                                  ResponsiveService.shouldUseCompactLayout(
                                        context,
                                      )
                                      ? 12
                                      : 16,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(
                                  borderRadius * 0.5,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: spacing * 0.2),
                          SkeletonContainer(
                            width:
                                ResponsiveService.shouldUseCompactLayout(
                                      context,
                                    )
                                    ? 10
                                    : 12,
                            height:
                                ResponsiveService.shouldUseCompactLayout(
                                      context,
                                    )
                                    ? 6
                                    : 8,
                            borderRadius: BorderRadius.circular(
                              borderRadius * 0.25,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton quick stats cards
class SkeletonQuickStatsCards extends StatelessWidget {
  const SkeletonQuickStatsCards({super.key});

  @override
  Widget build(BuildContext context) {
    final cardHeight = ResponsiveService.getQuickStatsCardHeight(context);
    final padding = ResponsiveService.getResponsivePadding(context);
    final spacing = ResponsiveService.getResponsiveSpacing(context);
    final borderRadius = ResponsiveService.getBorderRadius(context);

    return Row(
      children: List.generate(3, (index) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < 2 ? spacing * 0.4 : 0),
            child: Card(
              child: Container(
                height: cardHeight,
                padding: EdgeInsets.all(
                  padding.left * 0.75,
                ), // Slightly less padding for cards
                child: ShimmerWidget(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Icon skeleton - responsive sizing
                      SkeletonContainer(
                        width: ResponsiveService.getIconSize(context),
                        height: ResponsiveService.getIconSize(context),
                        borderRadius: BorderRadius.circular(borderRadius * 0.5),
                      ),

                      SizedBox(height: spacing * 0.4),

                      // Value skeleton - flexible
                      Flexible(
                        child: SkeletonContainer(
                          width:
                              ResponsiveService.shouldUseCompactLayout(context)
                                  ? 24
                                  : 30,
                          height:
                              ResponsiveService.shouldUseCompactLayout(context)
                                  ? 16
                                  : 20,
                          borderRadius: BorderRadius.circular(
                            borderRadius * 0.5,
                          ),
                        ),
                      ),

                      SizedBox(height: spacing * 0.4),

                      // Label skeleton - responsive
                      SkeletonContainer(
                        width:
                            ResponsiveService.shouldUseCompactLayout(context)
                                ? 40
                                : 50,
                        height:
                            ResponsiveService.shouldUseCompactLayout(context)
                                ? 10
                                : 12,
                        borderRadius: BorderRadius.circular(borderRadius * 0.3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Skeleton action buttons
class SkeletonActionButtons extends StatelessWidget {
  final double? height;

  const SkeletonActionButtons({super.key, this.height});

  @override
  Widget build(BuildContext context) {
    final buttonHeight =
        height ?? (ResponsiveService.shouldUseCompactLayout(context) ? 50 : 60);
    final padding = ResponsiveService.getResponsivePadding(context);
    final spacing = ResponsiveService.getResponsiveSpacing(context);
    final borderRadius = ResponsiveService.getBorderRadius(context);

    return Card(
      child: Container(
        height: buttonHeight,
        padding: padding,
        child: ShimmerWidget(
          child: Row(
            children: [
              Expanded(
                child: SkeletonContainer(
                  width: double.infinity,
                  height:
                      ResponsiveService.shouldUseCompactLayout(context)
                          ? 32
                          : 36,
                  borderRadius: BorderRadius.circular(borderRadius * 1.5),
                ),
              ),
              SizedBox(width: spacing * 0.6),
              Expanded(
                child: SkeletonContainer(
                  width: double.infinity,
                  height:
                      ResponsiveService.shouldUseCompactLayout(context)
                          ? 32
                          : 36,
                  borderRadius: BorderRadius.circular(borderRadius * 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton momentum gauge (circular)
class SkeletonMomentumGauge extends StatelessWidget {
  final double? size;

  const SkeletonMomentumGauge({super.key, this.size});

  @override
  Widget build(BuildContext context) {
    final gaugeSize = size ?? ResponsiveService.getMomentumGaugeSize(context);

    return ShimmerWidget(
      child: Container(
        width: gaugeSize,
        height: gaugeSize,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: gaugeSize * 0.6,
            height: gaugeSize * 0.6,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
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

/// Skeleton loading state for the entire momentum screen
class SkeletonMomentumScreen extends StatelessWidget {
  const SkeletonMomentumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveService.getResponsivePadding(context);
    final spacing = ResponsiveService.getResponsiveSpacing(context);
    final borderRadius = ResponsiveService.getBorderRadius(context);

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Momentum card skeleton
          const SkeletonMomentumCard(),

          SizedBox(height: spacing),

          // Weekly trend chart skeleton
          const SkeletonWeeklyTrendChart(),

          SizedBox(height: spacing),

          // Quick stats cards skeleton
          const SkeletonQuickStatsCards(),

          SizedBox(height: spacing),

          // Action buttons skeleton
          const SkeletonActionButtons(),

          SizedBox(height: spacing),

          // Demo section skeleton - responsive
          Card(
            margin: ResponsiveService.getResponsiveMargin(context),
            child: Container(
              padding: padding,
              child: ShimmerWidget(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SkeletonText(
                      width: MediaQuery.of(context).size.width * 0.4,
                      height:
                          ResponsiveService.shouldUseCompactLayout(context)
                              ? 16
                              : 18,
                    ),
                    SizedBox(height: spacing * 0.8),
                    Center(
                      child: SkeletonMomentumGauge(
                        size: ResponsiveService.getMomentumGaugeSize(context),
                      ),
                    ),
                    SizedBox(height: spacing * 0.8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(3, (index) {
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: spacing * 0.2,
                            ),
                            child: SkeletonContainer(
                              width: double.infinity,
                              height:
                                  ResponsiveService.shouldUseCompactLayout(
                                        context,
                                      )
                                      ? 28
                                      : 32,
                              borderRadius: BorderRadius.circular(
                                borderRadius * 1.3,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: spacing * 0.6),
                    Center(
                      child: SkeletonText(
                        width: MediaQuery.of(context).size.width * 0.7,
                        height:
                            ResponsiveService.shouldUseCompactLayout(context)
                                ? 12
                                : 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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
class _SkeletonDimensions {
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

  const _SkeletonDimensions({
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

  factory _SkeletonDimensions.fromContext(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = ResponsiveService.shouldUseCompactLayout(context);

    return _SkeletonDimensions(
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

