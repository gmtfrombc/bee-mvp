import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

/// Confetti overlay widget for celebrating momentum recovery
/// Triggers when momentum transitions from needs_care → rising/steady
class ConfettiOverlay extends StatefulWidget {
  final Widget child;
  final bool isVisible;
  final VoidCallback? onComplete;

  const ConfettiOverlay({
    super.key,
    required this.child,
    this.isVisible = false,
    this.onComplete,
  });

  /// Show confetti overlay on the given context
  static void show(BuildContext context, {VoidCallback? onComplete}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder:
          (context) => ConfettiAnimationWidget(
            onComplete: () {
              entry.remove();
              onComplete?.call();
            },
          ),
    );

    overlay.insert(entry);
  }

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    if (widget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _controller.forward();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.isVisible)
          AnimatedBuilder(
            animation: _controller,
            builder:
                (context, _) => ConfettiAnimation(
                  animation: _controller,
                  onComplete: widget.onComplete,
                ),
          ),
      ],
    );
  }
}

/// Standalone confetti animation widget for overlay display
class ConfettiAnimationWidget extends StatefulWidget {
  final VoidCallback? onComplete;

  const ConfettiAnimationWidget({super.key, this.onComplete});

  @override
  State<ConfettiAnimationWidget> createState() =>
      _ConfettiAnimationWidgetState();
}

class _ConfettiAnimationWidgetState extends State<ConfettiAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ConfettiAnimation(
        animation: _controller,
        onComplete: widget.onComplete,
      ),
    );
  }
}

/// Core confetti animation painter and controller
class ConfettiAnimation extends StatelessWidget {
  final Animation<double> animation;
  final VoidCallback? onComplete;

  const ConfettiAnimation({
    super.key,
    required this.animation,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return CustomPaint(
          size: Size.infinite,
          painter: ConfettiPainter(
            progress: animation.value,
            screenSize: MediaQuery.of(context).size,
          ),
        );
      },
    );
  }
}

/// Custom painter for confetti particles
class ConfettiPainter extends CustomPainter {
  final double progress;
  final Size screenSize;
  final List<ConfettiParticle> particles;

  ConfettiPainter({required this.progress, required this.screenSize})
    : particles = _generateParticles(screenSize);

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      particle.paint(canvas, progress, screenSize);
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }

  static List<ConfettiParticle> _generateParticles(Size screenSize) {
    final random = math.Random();
    final particles = <ConfettiParticle>[];

    // Generate 50-80 particles
    final particleCount = 50 + random.nextInt(31);

    for (int i = 0; i < particleCount; i++) {
      particles.add(
        ConfettiParticle(
          startX: random.nextDouble() * screenSize.width,
          startY: -20 - random.nextDouble() * 50,
          color: _getRandomColor(random),
          size: 4 + random.nextDouble() * 8,
          velocity: 2 + random.nextDouble() * 4,
          rotationSpeed: (random.nextDouble() - 0.5) * 6,
          swayAmplitude: 20 + random.nextDouble() * 30,
          swayFrequency: 0.5 + random.nextDouble() * 1.5,
        ),
      );
    }

    return particles;
  }

  static Color _getRandomColor(math.Random random) {
    final colors = [
      AppTheme.momentumRising,
      AppTheme.momentumSteady,
      const Color(0xFFFFD700), // Gold
      const Color(0xFFFF69B4), // Hot pink
      const Color(0xFF00CED1), // Dark turquoise
      const Color(0xFFFF6347), // Tomato
      const Color(0xFF98FB98), // Pale green
      const Color(0xFFDDA0DD), // Plum
    ];
    return colors[random.nextInt(colors.length)];
  }
}

/// Individual confetti particle
class ConfettiParticle {
  final double startX;
  final double startY;
  final Color color;
  final double size;
  final double velocity;
  final double rotationSpeed;
  final double swayAmplitude;
  final double swayFrequency;

  ConfettiParticle({
    required this.startX,
    required this.startY,
    required this.color,
    required this.size,
    required this.velocity,
    required this.rotationSpeed,
    required this.swayAmplitude,
    required this.swayFrequency,
  });

  void paint(Canvas canvas, double progress, Size screenSize) {
    // Calculate current position
    final currentY =
        startY + (screenSize.height + 100) * progress * velocity * 0.1;
    final currentX =
        startX +
        math.sin(progress * swayFrequency * math.pi * 2) * swayAmplitude;

    // Skip if particle is off screen
    if (currentY > screenSize.height + 50 ||
        currentX < -size ||
        currentX > screenSize.width + size) {
      return;
    }

    // Calculate rotation
    final rotation = progress * rotationSpeed * math.pi * 2;

    // Calculate opacity (fade out towards the end)
    final opacity =
        progress < 0.8 ? 1.0 : (1.0 - (progress - 0.8) / 0.2).clamp(0.0, 1.0);

    final paint =
        Paint()
          ..color = color.withValues(alpha: opacity)
          ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(currentX, currentY);
    canvas.rotate(rotation);

    // Draw confetti piece (rectangle or circle)
    if (math.Random().nextBool()) {
      // Rectangle confetti
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: size, height: size * 0.6),
        paint,
      );
    } else {
      // Circular confetti
      canvas.drawCircle(Offset.zero, size * 0.4, paint);
    }

    canvas.restore();
  }
}
