part of 'momentum_point_feedback_widget.dart';

/// Animation helpers extracted to keep the main widget file lightweight.
extension _MomentumPointFeedbackAnimation on _MomentumPointFeedbackWidgetState {
  /// Configure all animation controllers with context-aware durations.
  void _setupAnimationsExt() {
    _scaleController
        .duration = ResponsiveServiceAnimations.getAnimationDuration(
      context,
      baseDuration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeController.duration = ResponsiveServiceAnimations.getAnimationDuration(
      context,
      baseDuration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideController
        .duration = ResponsiveServiceAnimations.getAnimationDuration(
      context,
      baseDuration: const Duration(milliseconds: 500),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _bounceController
        .duration = ResponsiveServiceAnimations.getAnimationDuration(
      context,
      baseDuration: const Duration(milliseconds: 300),
    );

    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    _glowController.duration = ResponsiveServiceAnimations.getAnimationDuration(
      context,
      baseDuration: const Duration(milliseconds: 1200),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  /// Runs celebratory animation sequence and handles auto-hide logic.
  Future<void> _startCelebrationSequenceExt() async {
    // ignore: invalid_use_of_protected_member
    setState(() => _isVisible = true);

    if (!widget.enableAnimations ||
        AccessibilityService.shouldReduceMotion(context)) {
      _fadeController.value = 1.0;
      _scaleController.value = 1.0;
      _slideController.value = 1.0;

      if (widget.autoHide) {
        _autoHideTimer?.cancel();
        _autoHideTimer = Timer(
          Duration(milliseconds: widget.autoHideDuration.inMilliseconds + 50),
          () {
            if (mounted) _hideFeedbackExt();
          },
        );
      }

      widget.onAnimationComplete?.call();
      return;
    }

    // Haptic feedback for success
    HapticFeedback.mediumImpact();

    _fadeController.forward();

    _animationTimer1 = Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        _scaleController.forward();
        _glowController.forward();
      }
    });

    _animationTimer2 = Timer(const Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });

    _animationTimer3 = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        _bounceController.forward().then((_) {
          if (mounted) _bounceController.reverse();
        });
      }
    });

    _animationTimer4 = Timer(const Duration(milliseconds: 450), () {
      if (mounted) HapticFeedback.lightImpact();
    });

    if (widget.autoHide) {
      _autoHideTimer?.cancel();
      _autoHideTimer = Timer(widget.autoHideDuration, () {
        if (mounted) _hideFeedbackExt();
      });
    }

    widget.onAnimationComplete?.call();
  }

  /// Reverses animations and hides the widget safely.
  Future<void> _hideFeedbackExt() async {
    _autoHideTimer?.cancel();
    _animationTimer1?.cancel();
    _animationTimer2?.cancel();
    _animationTimer3?.cancel();
    _animationTimer4?.cancel();

    if (!widget.enableAnimations ||
        AccessibilityService.shouldReduceMotion(context)) {
      // ignore: invalid_use_of_protected_member
      if (mounted) setState(() => _isVisible = false);
      return;
    }

    await _fadeController.reverse();
    // ignore: invalid_use_of_protected_member
    if (mounted) setState(() => _isVisible = false);
  }
}

/// Utility extension that scales animation durations based on device type and
/// honours the user’s reduced-motion preference.
extension ResponsiveServiceAnimations on ResponsiveService {
  static Duration getAnimationDuration(
    BuildContext context, {
    required Duration baseDuration,
  }) {
    if (AccessibilityService.shouldReduceMotion(context)) {
      return Duration.zero;
    }

    final deviceType = ResponsiveService.getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobileSmall:
        return Duration(
          milliseconds: (baseDuration.inMilliseconds * 0.85).round(),
        );
      case DeviceType.mobile:
        return baseDuration;
      case DeviceType.mobileLarge:
        return Duration(
          milliseconds: (baseDuration.inMilliseconds * 1.1).round(),
        );
      case DeviceType.tablet:
        return Duration(
          milliseconds: (baseDuration.inMilliseconds * 1.15).round(),
        );
      case DeviceType.desktop:
        return Duration(
          milliseconds: (baseDuration.inMilliseconds * 1.2).round(),
        );
    }
  }
}
