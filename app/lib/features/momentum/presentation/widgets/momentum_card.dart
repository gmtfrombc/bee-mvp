import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/momentum_data.dart';
import 'momentum_gauge.dart';

/// Comprehensive momentum card component that displays the user's current momentum state
/// Includes the circular gauge, state labels, encouraging messages, and responsive layout
class MomentumCard extends StatefulWidget {
  final MomentumData momentumData;
  final VoidCallback? onTap;
  final bool showProgressBar;
  final EdgeInsets? margin;
  final double? height;

  const MomentumCard({
    super.key,
    required this.momentumData,
    this.onTap,
    this.showProgressBar = true,
    this.margin,
    this.height,
  });

  @override
  State<MomentumCard> createState() => _MomentumCardState();
}

class _MomentumCardState extends State<MomentumCard>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startEntryAnimation();
  }

  @override
  void didUpdateWidget(MomentumCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.momentumData.state != widget.momentumData.state) {
      _animateStateChange();
    }
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  void _startEntryAnimation() {
    _fadeController.forward();
  }

  void _animateStateChange() {
    // Quick fade out and in for state changes
    _fadeController.reverse().then((_) {
      if (mounted) {
        _fadeController.forward();
      }
    });
  }

  void _handleTap() {
    if (widget.onTap != null) {
      // Haptic feedback
      HapticFeedback.lightImpact();

      // Scale animation
      _scaleController.forward().then((_) {
        if (mounted) {
          _scaleController.reverse();
        }
      });

      widget.onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardHeight = widget.height ?? _getResponsiveHeight(screenWidth);
    final cardMargin = widget.margin ?? _getResponsiveMargin(screenWidth);

    return AnimatedBuilder(
      animation: Listenable.merge([_fadeAnimation, _scaleAnimation]),
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: cardMargin,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap != null ? _handleTap : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Semantics(
                    label:
                        'Momentum card showing ${widget.momentumData.state.name} state',
                    hint: widget.onTap != null ? 'Tap for details' : null,
                    child: Card(
                      elevation: 2,
                      shadowColor: AppTheme.getMomentumColor(
                        widget.momentumData.state,
                      ).withValues(alpha: 0.1),
                      child: Container(
                        height: cardHeight,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: _getCardGradient(),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildHeader(),
                            Expanded(child: _buildGaugeSection()),
                            _buildMessageSection(),
                            if (widget.showProgressBar) _buildProgressBar(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Text(
      'YOUR MOMENTUM',
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: AppTheme.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildGaugeSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: ResponsiveMomentumGauge(
            state: widget.momentumData.state,
            percentage: widget.momentumData.percentage,
            onTap: widget.onTap,
            showGlow: true,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _getStateDisplayText(),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.getMomentumColor(widget.momentumData.state),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageSection() {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          widget.momentumData.message,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: AppTheme.textTertiary.withValues(alpha: 0.3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: widget.momentumData.percentage / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: AppTheme.getMomentumColor(
                        widget.momentumData.state,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${widget.momentumData.percentage.round()}% this week',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  String _getStateDisplayText() {
    switch (widget.momentumData.state) {
      case MomentumState.rising:
        return 'Rising!';
      case MomentumState.steady:
        return 'Steady!';
      case MomentumState.needsCare:
        return 'Growing!';
    }
  }

  LinearGradient? _getCardGradient() {
    final color = AppTheme.getMomentumColor(widget.momentumData.state);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppTheme.surfacePrimary, color.withValues(alpha: 0.02)],
    );
  }

  double _getResponsiveHeight(double screenWidth) {
    if (screenWidth <= 375) {
      return 180; // Compact for small screens
    } else if (screenWidth >= 428) {
      return 220; // Spacious for large screens
    }
    return 200; // Default height
  }

  EdgeInsets _getResponsiveMargin(double screenWidth) {
    if (screenWidth <= 375) {
      return const EdgeInsets.symmetric(horizontal: 12);
    }
    return const EdgeInsets.symmetric(horizontal: 16);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }
}

/// Compact momentum card for smaller spaces
class CompactMomentumCard extends StatelessWidget {
  final MomentumData momentumData;
  final VoidCallback? onTap;

  const CompactMomentumCard({
    super.key,
    required this.momentumData,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MomentumCard(
      momentumData: momentumData,
      onTap: onTap,
      height: 140,
      showProgressBar: false,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

/// Momentum card with enhanced accessibility features
class AccessibleMomentumCard extends StatelessWidget {
  final MomentumData momentumData;
  final VoidCallback? onTap;
  final String? customSemanticLabel;

  const AccessibleMomentumCard({
    super.key,
    required this.momentumData,
    this.onTap,
    this.customSemanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          customSemanticLabel ??
          'Momentum meter showing ${momentumData.state.name} state at ${momentumData.percentage.round()} percent. ${momentumData.message}',
      hint: onTap != null ? 'Double tap to view details' : null,
      button: onTap != null,
      child: MomentumCard(momentumData: momentumData, onTap: onTap),
    );
  }
}
