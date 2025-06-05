import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/responsive_service.dart';
import '../../../../core/services/accessibility_service.dart';
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
    final cardHeight =
        widget.height ?? ResponsiveService.getMomentumCardHeight(context);
    final cardMargin =
        widget.margin ?? ResponsiveService.getResponsiveMargin(context);
    final borderRadius = ResponsiveService.getBorderRadius(context);

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
                  borderRadius: BorderRadius.circular(borderRadius),
                  child: Semantics(
                    label: AccessibilityService.getMomentumCardLabel(
                      widget.momentumData,
                    ),
                    hint:
                        widget.onTap != null
                            ? AccessibilityService.getMomentumGaugeHint()
                            : null,
                    button: widget.onTap != null,
                    child: Card(
                      elevation: 2,
                      shadowColor: AppTheme.getMomentumColor(
                        widget.momentumData.state,
                      ).withValues(alpha: 0.1),
                      child: Container(
                        height: cardHeight,
                        padding: ResponsiveService.getResponsivePadding(
                          context,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(borderRadius),
                          gradient: _getCardGradient(),
                        ),
                        child: Column(
                          children: [
                            _buildHeader(),
                            _buildGaugeSection(),
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
    final fontSizeMultiplier = ResponsiveService.getFontSizeMultiplier(context);
    return AccessibilityService.createAccessibleText(
      'YOUR MOMENTUM',
      baseStyle: Theme.of(context).textTheme.titleMedium!.copyWith(
        color: AppTheme.getTextSecondary(context),
        letterSpacing: 0.5,
        fontSize:
            Theme.of(context).textTheme.titleMedium!.fontSize! *
            fontSizeMultiplier *
            1.2,
      ),
      context: context,
    );
  }

  Widget _buildGaugeSection() {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: MomentumGauge(
              state: widget.momentumData.state,
              percentage: widget.momentumData.percentage,
              onTap: widget.onTap,
              showGlow: true,
              size: ResponsiveService.getMomentumGaugeSize(context),
            ),
          ),
          if (_getStateDisplayText().isNotEmpty) ...[
            SizedBox(height: ResponsiveService.getTinySpacing(context)),
            Flexible(
              child: AccessibilityService.createAccessibleText(
                _getStateDisplayText(),
                baseStyle: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  color: AppTheme.getMomentumColor(widget.momentumData.state),
                  fontWeight: FontWeight.w600,
                ),
                context: context,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        SizedBox(height: ResponsiveService.getSmallSpacing(context)),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    ResponsiveService.getBorderRadius(context) * 0.25,
                  ),
                  color: AppTheme.getTextTertiary(
                    context,
                  ).withValues(alpha: 0.3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: widget.momentumData.percentage / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        ResponsiveService.getBorderRadius(context) * 0.25,
                      ),
                      color: AppTheme.getMomentumColor(
                        widget.momentumData.state,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: ResponsiveService.getSmallSpacing(context)),
            Text(
              '${widget.momentumData.percentage.round()}% this week',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.getTextSecondary(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  LinearGradient? _getCardGradient() {
    final color = AppTheme.getMomentumColor(widget.momentumData.state);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppTheme.darkSurfaceSecondary : AppTheme.surfacePrimary;

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [surfaceColor, color.withValues(alpha: 0.02)],
    );
  }

  String _getStateDisplayText() {
    switch (widget.momentumData.state) {
      case MomentumState.rising:
        return 'Rising!';
      case MomentumState.steady:
        return 'Steady!';
      case MomentumState.needsCare:
        return '';
    }
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
      height: ResponsiveService.getMomentumCardHeight(context) * 0.6,
      showProgressBar: false,
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveService.getSmallSpacing(context),
      ),
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
          'Momentum meter showing ${momentumData.state.name} state at ${momentumData.percentage.round()} percent.',
      hint: onTap != null ? 'Double tap to view details' : null,
      button: onTap != null,
      child: MomentumCard(momentumData: momentumData, onTap: onTap),
    );
  }
}
