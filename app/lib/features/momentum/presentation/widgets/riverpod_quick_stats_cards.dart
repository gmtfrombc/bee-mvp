import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/momentum_provider.dart';
import '../providers/ui_state_provider.dart';

/// Riverpod-enhanced quick stats cards component
/// Demonstrates reactive state management with Riverpod providers
class RiverpodQuickStatsCards extends ConsumerStatefulWidget {
  final EdgeInsets? margin;
  final VoidCallback? onLessonsTap;
  final VoidCallback? onStreakTap;
  final VoidCallback? onTodayTap;

  const RiverpodQuickStatsCards({
    super.key,
    this.margin,
    this.onLessonsTap,
    this.onStreakTap,
    this.onTodayTap,
  });

  @override
  ConsumerState<RiverpodQuickStatsCards> createState() =>
      _RiverpodQuickStatsCardsState();
}

class _RiverpodQuickStatsCardsState
    extends ConsumerState<RiverpodQuickStatsCards>
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
    // Watch momentum stats from Riverpod provider
    final stats = ref.watch(momentumStatsProvider);
    final isLoading = ref.watch(isLoadingProvider);

    // Show loading state if stats are not available
    if (stats == null || isLoading) {
      return _buildLoadingState();
    }

    return Container(
      margin: widget.margin,
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              index: 0,
              icon: Icons.menu_book_rounded,
              value: stats.lessonsRatio,
              label: 'Lessons',
              color: AppTheme.momentumRising,
              onTap: () => _handleTap('lessons', widget.onLessonsTap),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              index: 1,
              icon: Icons.local_fire_department_rounded,
              value: stats.streakText,
              label: 'Streak',
              color: AppTheme.momentumCare,
              onTap: () => _handleTap('streak', widget.onStreakTap),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              index: 2,
              icon: Icons.schedule_rounded,
              value: stats.todayText,
              label: 'Today',
              color: AppTheme.momentumSteady,
              onTap: () => _handleTap('today', widget.onTodayTap),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      margin: widget.margin,
      child: Row(
        children: List.generate(
          3,
          (index) => Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
              child: Card(
                child: SizedBox(
                  height: 84,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(String buttonType, VoidCallback? callback) {
    // Update user interaction state using Riverpod
    ref.read(userInteractionProvider.notifier).state = ref
        .read(userInteractionProvider)
        .copyWith(
          lastTappedButton: buttonType,
          lastInteractionTime: DateTime.now(),
        );

    // Call the original callback
    callback?.call();
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
            child: _RiverpodStatCard(
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

/// Individual stat card component using Riverpod for interaction state
class _RiverpodStatCard extends ConsumerStatefulWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _RiverpodStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  ConsumerState<_RiverpodStatCard> createState() => _RiverpodStatCardState();
}

class _RiverpodStatCardState extends ConsumerState<_RiverpodStatCard>
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
      // Update card interaction state using Riverpod
      ref.read(cardInteractionProvider.notifier).onPressStart();

      _scaleController.forward().then((_) {
        if (mounted) {
          _scaleController.reverse();
          ref.read(cardInteractionProvider.notifier).onPressEnd();
        }
      });

      widget.onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch card interaction state from Riverpod
    final cardInteraction = ref.watch(cardInteractionProvider);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Card(
            elevation: cardInteraction.isPressed ? 1 : 2,
            shadowColor: widget.color.withValues(alpha: 0.1),
            child: InkWell(
              onTap: widget.onTap != null ? _handleTap : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.color.withValues(alpha: 0.1),
                      widget.color.withValues(alpha: 0.05),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.icon, color: widget.color, size: 24),
                    const SizedBox(height: 8),
                    Text(
                      widget.value,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
