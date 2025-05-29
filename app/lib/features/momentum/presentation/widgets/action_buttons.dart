import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/responsive_service.dart';
import '../../../../core/services/accessibility_service.dart';

/// Action buttons component with state-appropriate suggestions
/// Two buttons: "Learn" and "Share" with animations and proper styling
class ActionButtons extends StatefulWidget {
  final MomentumState state;
  final EdgeInsets? margin;
  final VoidCallback? onLearnTap;
  final VoidCallback? onShareTap;

  const ActionButtons({
    super.key,
    required this.state,
    this.margin,
    this.onLearnTap,
    this.onShareTap,
  });

  @override
  State<ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends State<ActionButtons>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;
  List<Timer>? _staggerTimers; // Store timer references for cleanup

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startStaggeredAnimation();
  }

  void _setupAnimations() {
    const buttonCount = 2; // Learn and Share buttons
    _controllers = List.generate(
      buttonCount,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    _fadeAnimations =
        _controllers
            .map(
              (controller) => Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: controller, curve: Curves.easeOut),
              ),
            )
            .toList();

    _slideAnimations =
        _controllers
            .map(
              (controller) => Tween<Offset>(
                begin: const Offset(0, 0.5),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: controller, curve: Curves.easeOut),
              ),
            )
            .toList();
  }

  void _startStaggeredAnimation() {
    // Store timer references for proper cleanup
    _staggerTimers = [];

    // Staggered animation with 100ms delay between buttons
    for (int i = 0; i < _controllers.length; i++) {
      final timer = Timer(Duration(milliseconds: i * 100), () {
        if (mounted) {
          _controllers[i].forward();
        }
      });
      _staggerTimers!.add(timer);
    }
  }

  @override
  void dispose() {
    // Cancel any pending timers first
    if (_staggerTimers != null) {
      for (final timer in _staggerTimers!) {
        timer.cancel();
      }
    }

    // Then dispose animation controllers
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String _getMotivationalMessage() {
    switch (widget.state) {
      case MomentumState.rising:
        return 'Keep the momentum going! 🚀';
      case MomentumState.steady:
        return 'Stay consistent! 🙂';
      case MomentumState.needsCare:
        return 'Let\'s grow together! 🌱';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getMotivationalMessage(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: ResponsiveService.getResponsiveSpacing(context)),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  index: 0,
                  icon: Icons.school_rounded,
                  label: 'Learn',
                  color: AppTheme.getMomentumColor(widget.state),
                  onTap: widget.onLearnTap,
                ),
              ),
              SizedBox(width: ResponsiveService.getMediumSpacing(context)),
              Expanded(
                child: _buildActionButton(
                  index: 1,
                  icon: Icons.share_rounded,
                  label: 'Share',
                  color: AppTheme.momentumSteady,
                  onTap: widget.onShareTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required int index,
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _fadeAnimations[index],
        _slideAnimations[index],
      ]),
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimations[index],
          child: SlideTransition(
            position: _slideAnimations[index],
            child: _ActionButton(
              icon: icon,
              label: label,
              color: color,
              onTap: onTap,
            ),
          ),
        );
      },
    );
  }
}

/// Individual action button component
class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onTap != null) {
      _scaleController.forward().then((_) {
        if (mounted) {
          _scaleController.reverse();
        }
      });
      widget.onTap!();
    }
  }

  Color _getContrastColor(Color color) {
    // Calculate the relative luminance of the color
    final luminance = color.computeLuminance();
    // Use white text on dark colors, black text on light colors
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Semantics(
            label: AccessibilityService.getActionButtonLabel(
              widget.label,
              'Action button',
            ),
            hint: 'Tap to ${widget.label.toLowerCase()}',
            button: true,
            child: ElevatedButton.icon(
              onPressed: widget.onTap != null ? _handleTap : null,
              icon: Icon(widget.icon, size: 18),
              label: Text(widget.label),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.color,
                foregroundColor: _getContrastColor(widget.color),
                elevation: 2,
                shadowColor: widget.color.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveService.getBorderRadius(context),
                  ),
                ),
                minimumSize: const Size(double.infinity, 48),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
