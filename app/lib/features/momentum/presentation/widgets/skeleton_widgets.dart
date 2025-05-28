import 'package:flutter/material.dart';

/// Shimmer effect widget for skeleton loading states
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
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops:
                  [
                    _animation.value - 0.3,
                    _animation.value,
                    _animation.value + 0.3,
                  ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Skeleton container with rounded corners
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
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    );
  }
}

/// Skeleton momentum card with shimmer effect
class SkeletonMomentumCard extends StatelessWidget {
  final double? height;
  final EdgeInsets? margin;

  const SkeletonMomentumCard({super.key, this.height, this.margin});

  @override
  Widget build(BuildContext context) {
    final cardHeight = height ?? 200.0;
    final cardMargin = margin ?? const EdgeInsets.all(16);

    return Container(
      margin: cardMargin,
      child: Card(
        elevation: 2,
        child: Container(
          height: cardHeight,
          padding: const EdgeInsets.all(16),
          child: ShimmerWidget(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Header skeleton
                SkeletonContainer(
                  width: 120,
                  height: 16,
                  borderRadius: BorderRadius.circular(8),
                ),

                // Gauge skeleton (circular)
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                ),

                // State text skeleton
                SkeletonContainer(
                  width: 100,
                  height: 24,
                  borderRadius: BorderRadius.circular(12),
                ),

                // Message skeleton
                Column(
                  children: [
                    SkeletonContainer(
                      width: double.infinity,
                      height: 16,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 8),
                    SkeletonContainer(
                      width: 200,
                      height: 16,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ],
                ),

                // Progress bar skeleton
                SkeletonContainer(
                  width: double.infinity,
                  height: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton weekly trend chart
class SkeletonWeeklyTrendChart extends StatelessWidget {
  final double height;

  const SkeletonWeeklyTrendChart({super.key, this.height = 140});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: height,
        padding: const EdgeInsets.all(16),
        child: ShimmerWidget(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header skeleton
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonContainer(
                    width: 140,
                    height: 18,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  SkeletonContainer(
                    width: 80,
                    height: 14,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Chart area skeleton
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (index) {
                    final heights = [40.0, 60.0, 45.0, 70.0, 55.0, 65.0, 50.0];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SkeletonContainer(
                          width: 20,
                          height: heights[index],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        const SizedBox(height: 8),
                        SkeletonContainer(
                          width: 16,
                          height: 12,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
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
    return Row(
      children: List.generate(3, (index) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
            child: Card(
              child: Container(
                height: 84,
                padding: const EdgeInsets.all(12),
                child: ShimmerWidget(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Icon skeleton
                      SkeletonContainer(
                        width: 24,
                        height: 24,
                        borderRadius: BorderRadius.circular(12),
                      ),

                      // Value skeleton
                      SkeletonContainer(
                        width: 30,
                        height: 20,
                        borderRadius: BorderRadius.circular(10),
                      ),

                      // Label skeleton
                      SkeletonContainer(
                        width: 50,
                        height: 12,
                        borderRadius: BorderRadius.circular(6),
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
  final double height;

  const SkeletonActionButtons({super.key, this.height = 60});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        height: height,
        padding: const EdgeInsets.all(16),
        child: ShimmerWidget(
          child: Row(
            children: [
              Expanded(
                child: SkeletonContainer(
                  width: double.infinity,
                  height: 36,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SkeletonContainer(
                  width: double.infinity,
                  height: 36,
                  borderRadius: BorderRadius.circular(18),
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
  final double size;

  const SkeletonMomentumGauge({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return ShimmerWidget(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: size * 0.6,
            height: size * 0.6,
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
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonText({
    super.key,
    required this.width,
    this.height = 16,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonContainer(
      width: width,
      height: height,
      borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
    );
  }
}

/// Skeleton loading state for the entire momentum screen
class SkeletonMomentumScreen extends StatelessWidget {
  const SkeletonMomentumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Momentum card skeleton
          const SkeletonMomentumCard(),

          const SizedBox(height: 24),

          // Weekly trend chart skeleton
          const SkeletonWeeklyTrendChart(),

          const SizedBox(height: 24),

          // Quick stats cards skeleton
          const SkeletonQuickStatsCards(),

          const SizedBox(height: 24),

          // Action buttons skeleton
          const SkeletonActionButtons(),

          const SizedBox(height: 24),

          // Demo section skeleton
          Card(
            margin: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: ShimmerWidget(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonText(width: 160, height: 18),
                    const SizedBox(height: 16),
                    const Center(child: SkeletonMomentumGauge(size: 140)),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(3, (index) {
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: const SkeletonContainer(
                              width: double.infinity,
                              height: 36,
                              borderRadius: BorderRadius.all(
                                Radius.circular(18),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    const Center(child: SkeletonText(width: 280, height: 14)),
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
  final Duration duration;

  const PulseLoadingWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
  });

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
    _controller = AnimationController(duration: widget.duration, vsync: this);
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
