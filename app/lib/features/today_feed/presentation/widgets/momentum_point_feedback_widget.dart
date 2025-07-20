import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/responsive_service.dart';
import '../../../../core/services/accessibility_service.dart';
import '../../data/services/today_feed_momentum_award_service.dart';
import 'dart:async';
import 'momentum_point_feedback_body.dart';
part 'momentum_point_feedback_animation.dart';

/// Visual feedback widget for momentum point awards
/// Displays celebratory animations and confirmation messages when users earn momentum points
/// Implements T1.3.4.6: Visual feedback for momentum point awards
class MomentumPointFeedbackWidget extends StatefulWidget {
  const MomentumPointFeedbackWidget({
    super.key,
    required this.awardResult,
    this.onAnimationComplete,
    this.enableAnimations = true,
    this.showMessage = true,
    this.autoHide = true,
    this.autoHideDuration = const Duration(seconds: 3),
  });

  /// Result of the momentum award attempt
  final MomentumAwardResult awardResult;

  /// Callback when celebration animation completes
  final VoidCallback? onAnimationComplete;

  /// Whether to enable celebration animations
  final bool enableAnimations;

  /// Whether to show text message
  final bool showMessage;

  /// Whether to auto-hide after animation
  final bool autoHide;

  /// Duration before auto-hiding
  final Duration autoHideDuration;

  @override
  State<MomentumPointFeedbackWidget> createState() =>
      _MomentumPointFeedbackWidgetState();
}

class _MomentumPointFeedbackWidgetState
    extends State<MomentumPointFeedbackWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _bounceController;
  late AnimationController _glowController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _glowAnimation;

  bool _isVisible = false;
  bool _isSetupComplete = false;

  // Timers for proper cleanup
  Timer? _autoHideTimer;
  Timer? _animationTimer1;
  Timer? _animationTimer2;
  Timer? _animationTimer3;
  Timer? _animationTimer4;

  @override
  void initState() {
    super.initState();
    // Initialize controllers without context-dependent setup
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Setup will be completed in didChangeDependencies
    _isSetupComplete = false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isSetupComplete) {
      _setupAnimations();
      _isSetupComplete = true;

      // Check if we should show feedback based on result type
      if (_shouldShowFeedback()) {
        _startCelebrationSequence();
      }
    }
  }

  bool _shouldShowFeedback() {
    return widget.awardResult.success || widget.awardResult.isQueued;
  }

  @override
  void dispose() {
    // Cancel all timers
    _autoHideTimer?.cancel();
    _animationTimer1?.cancel();
    _animationTimer2?.cancel();
    _animationTimer3?.cancel();
    _animationTimer4?.cancel();

    // Dispose animation controllers
    _scaleController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _bounceController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  // Delegates to extracted extension in part file
  void _setupAnimations() => _setupAnimationsExt();

  // Delegates to extracted extension in part file
  Future<void> _startCelebrationSequence() async =>
      _startCelebrationSequenceExt();

  @override
  Widget build(BuildContext context) {
    // Show widget for successful awards (including zero points) or queued awards
    if (!_isVisible || (!_shouldShowFeedback())) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: Semantics(
        liveRegion: true,
        label: _getAccessibilityLabel(),
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _fadeAnimation,
            _scaleAnimation,
            _slideAnimation,
            _bounceAnimation,
            _glowAnimation,
          ]),
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _bounceAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow:
                        widget.enableAnimations
                            ? [
                              BoxShadow(
                                color: AppTheme.momentumRising.withValues(
                                  alpha: _glowAnimation.value * 0.4,
                                ),
                                blurRadius: 20 * _glowAnimation.value,
                                spreadRadius: 2 * _glowAnimation.value,
                              ),
                            ]
                            : null,
                  ),
                  child: RepaintBoundary(child: _buildFeedbackContent(context)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeedbackContent(BuildContext context) {
    return MomentumPointFeedbackBody(
      awardResult: widget.awardResult,
      showMessage: widget.showMessage,
      slideAnimation: _slideAnimation,
      scaleAnimation: _scaleAnimation,
      glowAnimation: _glowAnimation,
    );
  }

  String _getAccessibilityLabel() {
    if (widget.awardResult.isQueued) {
      return 'Momentum point queued for when back online';
    }

    return 'Momentum point awarded! You earned ${widget.awardResult.pointsAwarded} point for reading today\'s health insight';
  }
}
