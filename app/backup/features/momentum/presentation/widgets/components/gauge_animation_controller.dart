import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/accessibility_service.dart';

/// Animation controller manager for MomentumGauge
/// Handles all animation setup, state transitions, and timing coordination
class GaugeAnimationController {
  late AnimationController _progressController;
  late AnimationController _bounceController;
  late AnimationController _stateTransitionController;
  late Animation<double> _progressAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<Color?> _colorTransitionAnimation;
  late Animation<double> _emojiScaleAnimation;
  late Animation<double> _glowIntensityAnimation;

  MomentumState? _previousState;
  bool _isTransitioning = false;
  bool _hasStartedAnimations = false;

  // Timer tracking for proper disposal
  Timer? _animationDelayTimer;
  Timer? _transitionDelayTimer;

  final TickerProvider vsync;
  final Duration animationDuration;
  final Duration stateTransitionDuration;

  GaugeAnimationController({
    required this.vsync,
    required this.animationDuration,
    required this.stateTransitionDuration,
    required MomentumState initialState,
  }) {
    _previousState = initialState;
    _setupAnimations();
  }

  // Getters for animations
  Animation<double> get progressAnimation => _progressAnimation;
  Animation<double> get bounceAnimation => _bounceAnimation;
  Animation<Color?> get colorTransitionAnimation => _colorTransitionAnimation;
  Animation<double> get emojiScaleAnimation => _emojiScaleAnimation;
  Animation<double> get glowIntensityAnimation => _glowIntensityAnimation;
  bool get isTransitioning => _isTransitioning;
  bool get hasStartedAnimations => _hasStartedAnimations;

  /// Map momentum state to visual progress fill level
  /// This ensures consistent visual representation regardless of actual percentage
  double _getProgressForState(MomentumState state) {
    switch (state) {
      case MomentumState.needsCare:
        return 0.33; // 1/3 fill for "Needs Care"
      case MomentumState.steady:
        return 0.66; // 2/3 fill for "Steady"
      case MomentumState.rising:
        return 1.0; // Complete fill for "Rising"
    }
  }

  void _setupAnimations() {
    _progressController = AnimationController(
      duration: animationDuration,
      vsync: vsync,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: vsync,
    );

    _stateTransitionController = AnimationController(
      duration: stateTransitionDuration,
      vsync: vsync,
    );

    // Initialize progress animation with state-based target
    final initialProgress = _getProgressForState(
      _previousState ?? MomentumState.steady,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: initialProgress,
    ).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: const Cubic(0.25, 0.46, 0.45, 0.94),
      ),
    );

    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    _colorTransitionAnimation = ColorTween(
      begin: AppTheme.getMomentumColor(_previousState ?? MomentumState.steady),
      end: AppTheme.getMomentumColor(_previousState ?? MomentumState.steady),
    ).animate(
      CurvedAnimation(
        parent: _stateTransitionController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _emojiScaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _stateTransitionController,
        curve: Curves.elasticOut,
      ),
    );

    _glowIntensityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.3, end: 0.1), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 0.1, end: 0.7), weight: 70),
    ]).animate(
      CurvedAnimation(
        parent: _stateTransitionController,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  void startAnimations(BuildContext context) {
    if (_hasStartedAnimations) return;
    _hasStartedAnimations = true;

    final shouldReduce = AccessibilityService.shouldReduceMotion(context);
    if (shouldReduce) {
      _progressController.value = 1.0;
      return;
    }

    _progressController.forward();

    _animationDelayTimer?.cancel();
    _animationDelayTimer = Timer(
      Duration(milliseconds: (animationDuration.inMilliseconds * 0.8).round()),
      () async {
        await _bounceController.forward();
        await _bounceController.reverse();
        await _bounceController.animateTo(0.4);
        await _bounceController.reverse();
      },
    );
  }

  void updateProgress(double percentage) {
    _progressAnimation = Tween<double>(
      begin: _progressAnimation.value,
      end: percentage / 100.0,
    ).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: const Cubic(0.25, 0.46, 0.45, 0.94),
      ),
    );
    _progressController.reset();
    _progressController.forward();
  }

  /// Update progress based on momentum state for consistent visual representation
  /// This ensures the gauge fills correctly: 1/3 for needsCare, 2/3 for steady, full for rising
  void updateProgressForState(MomentumState state) {
    final targetProgress = _getProgressForState(state);
    _progressAnimation = Tween<double>(
      begin: _progressAnimation.value,
      end: targetProgress,
    ).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: const Cubic(0.25, 0.46, 0.45, 0.94),
      ),
    );
    _progressController.reset();
    _progressController.forward();
  }

  Future<void> handleStateTransition(
    BuildContext context,
    MomentumState oldState,
    MomentumState newState,
  ) async {
    if (_isTransitioning) return;

    _isTransitioning = true;
    _previousState = oldState;

    // Update progress to match the new state
    updateProgressForState(newState);

    _colorTransitionAnimation = ColorTween(
      begin: AppTheme.getMomentumColor(oldState),
      end: AppTheme.getMomentumColor(newState),
    ).animate(
      CurvedAnimation(
        parent: _stateTransitionController,
        curve: Curves.easeInOutCubic,
      ),
    );

    final shouldReduce = AccessibilityService.shouldReduceMotion(context);
    if (shouldReduce) {
      _isTransitioning = false;
      _previousState = newState;
      return;
    }

    _stateTransitionController.reset();
    _transitionDelayTimer?.cancel();
    _transitionDelayTimer = Timer(const Duration(milliseconds: 50), () async {
      await _stateTransitionController.forward();
      _isTransitioning = false;
      _previousState = newState;
    });
  }

  Future<void> triggerCelebrationBounce() async {
    _bounceController.reset();
    await _bounceController.forward();
    await _bounceController.reverse();
    await _bounceController.animateTo(0.5);
    await _bounceController.reverse();
  }

  Future<void> triggerTapBounce() async {
    _bounceController.reset();
    await _bounceController.forward();
    await _bounceController.reverse();
    await _bounceController.animateTo(0.3);
    await _bounceController.reverse();
  }

  bool isPositiveTransition(MomentumState oldState, MomentumState newState) {
    const stateOrder = [
      MomentumState.needsCare,
      MomentumState.steady,
      MomentumState.rising,
    ];
    final oldIndex = stateOrder.indexOf(oldState);
    final newIndex = stateOrder.indexOf(newState);
    return newIndex > oldIndex;
  }

  List<Animation> getAllAnimations() {
    return [_progressAnimation, _bounceAnimation, _stateTransitionController];
  }

  void dispose() {
    _progressController.dispose();
    _bounceController.dispose();
    _stateTransitionController.dispose();
    _animationDelayTimer?.cancel();
    _transitionDelayTimer?.cancel();
  }
}
