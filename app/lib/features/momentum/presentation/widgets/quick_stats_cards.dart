import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/momentum_data.dart';

/// Quick stats cards component displaying lessons, streak, and today's activity
/// Three horizontal cards with icons, values, and labels
class QuickStatsCards extends StatefulWidget {
  final MomentumStats stats;
  final EdgeInsets? margin;
  final VoidCallback? onLessonsTap;
  final VoidCallback? onStreakTap;
  final VoidCallback? onTodayTap;

  const QuickStatsCards({
    super.key,
    required this.stats,
    this.margin,
    this.onLessonsTap,
    this.onStreakTap,
    this.onTodayTap,
  });

  @override
  State<QuickStatsCards> createState() => _QuickStatsCardsState();
}

class _QuickStatsCardsState extends State<QuickStatsCards>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startStaggeredAnimation();
  }

  void _setupAnimations() {
    _controllers = List.generate(
      3,
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
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: controller, curve: Curves.easeOut),
              ),
            )
            .toList();
  }

  void _startStaggeredAnimation() {
    // Staggered animation with 100ms delay between cards
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          _controllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin,
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              index: 0,
              icon: Icons.menu_book_rounded,
              value: widget.stats.lessonsRatio,
              label: 'Lessons',
              color: AppTheme.momentumRising,
              onTap: widget.onLessonsTap,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              index: 1,
              icon: Icons.local_fire_department_rounded,
              value: widget.stats.streakText,
              label: 'Streak',
              color: AppTheme.momentumCare,
              onTap: widget.onStreakTap,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              index: 2,
              icon: Icons.schedule_rounded,
              value: widget.stats.todayText,
              label: 'Today',
              color: AppTheme.momentumSteady,
              onTap: widget.onTodayTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required int index,
    required IconData icon,
    required String value,
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
            child: _StatCard(
              icon: icon,
              value: value,
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

/// Individual stat card component
class _StatCard extends StatefulWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard>
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap != null ? _handleTap : null,
              borderRadius: BorderRadius.circular(8),
              child: Semantics(
                label: '${widget.label}: ${widget.value}',
                hint: widget.onTap != null ? 'Tap for details' : null,
                child: Card(
                  elevation: 1,
                  shadowColor: widget.color.withValues(alpha: 0.1),
                  child: Container(
                    height: 84,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: widget.color.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.icon, color: widget.color, size: 18),
                        const SizedBox(height: 2),
                        Flexible(
                          child: Text(
                            widget.value,
                            style: Theme.of(
                              context,
                            ).textTheme.titleSmall?.copyWith(
                              color: widget.color,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Flexible(
                          child: Text(
                            widget.label,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
}
