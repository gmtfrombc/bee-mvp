import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/accessibility_service.dart';
import 'components/gauge_animation_controller.dart';
import 'components/gauge_haptic_feedback.dart';
import 'components/gauge_painter.dart';
import 'components/gauge_interaction_handler.dart';

/// Circular momentum gauge widget with custom painter
/// Displays momentum state with animated progress ring and emoji center
/// Includes smooth state transition animations
class MomentumGauge extends StatefulWidget {
  final MomentumState state;
  final double percentage;
  final VoidCallback? onTap;
  final Duration animationDuration;
  final Duration stateTransitionDuration;
  final bool showGlow;
  final double size;

  const MomentumGauge({
    super.key,
    required this.state,
    required this.percentage,
    this.onTap,
    this.animationDuration = const Duration(milliseconds: 1000),
    this.stateTransitionDuration = const Duration(milliseconds: 800),
    this.showGlow = true,
    this.size = 120.0,
  });

  @override
  State<MomentumGauge> createState() => _MomentumGaugeState();
}

class _MomentumGaugeState extends State<MomentumGauge>
    with TickerProviderStateMixin {
  late GaugeAnimationController _animationController;
  late GaugeInteractionHandler _interactionHandler;

  @override
  void initState() {
    super.initState();
    _setupControllers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Start animations here instead of initState to ensure MediaQuery is available
    if (!_animationController.hasStartedAnimations) {
      _animationController.startAnimations(context);
      // Ensure progress reflects actual percentage rather than discrete state
      _animationController.updateProgress(widget.percentage);
    }
  }

  @override
  void didUpdateWidget(MomentumGauge oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if state changed for transition animation
    if (oldWidget.state != widget.state) {
      _interactionHandler.handleStateTransition(
        context,
        oldWidget.state,
        widget.state,
      );
    }

    // Update progress whenever percentage or state changes
    if (oldWidget.percentage != widget.percentage ||
        oldWidget.state != widget.state) {
      _animationController.updateProgress(widget.percentage);
    }
  }

  void _setupControllers() {
    _animationController = GaugeAnimationController(
      vsync: this,
      animationDuration: widget.animationDuration,
      stateTransitionDuration: widget.stateTransitionDuration,
      initialState: widget.state,
    );

    _interactionHandler = GaugeInteractionHandler(
      animationController: _animationController,
      onTap: widget.onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AccessibilityService.getMomentumStateLabel(
        widget.state,
        widget.percentage,
      ),
      hint:
          widget.onTap != null
              ? AccessibilityService.getMomentumGaugeHint()
              : null,
      child: GestureDetector(
        onTap: _interactionHandler.handleTap,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: GaugeInteractionHandler.createGlowDecoration(
            showGlow: widget.showGlow,
            isTransitioning: _animationController.isTransitioning,
            state: widget.state,
            transitionColor:
                _animationController.colorTransitionAnimation.value,
            glowIntensity: _animationController.glowIntensityAnimation.value,
          ),
          child: AnimatedBuilder(
            animation: Listenable.merge(
              _animationController.getAllAnimations(),
            ),
            builder: (context, child) {
              return Transform.scale(
                scale: _animationController.bounceAnimation.value,
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: MomentumGaugePainter(
                    progress: _animationController.progressAnimation.value,
                    state: widget.state,
                    strokeWidth: GaugeSizing.getStrokeWidth(widget.size),
                    transitionColor:
                        _animationController.isTransitioning
                            ? _animationController
                                .colorTransitionAnimation
                                .value
                            : null,
                    backgroundColor: AppTheme.getMomentumBackgroundColor(
                      context,
                    ),
                  ),
                  child: Center(
                    child: Transform.scale(
                      scale:
                          _animationController.isTransitioning
                              ? (1.0 +
                                  (_animationController
                                              .emojiScaleAnimation
                                              .value -
                                          1.0) *
                                      0.5) // Dampen the scale effect
                              : 1.0,
                      child: Text(
                        AppTheme.getMomentumEmoji(widget.state),
                        style: TextStyle(
                          fontSize: GaugeSizing.getEmojiSize(widget.size),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    GaugeHapticFeedback.dispose();
    super.dispose();
  }
}
