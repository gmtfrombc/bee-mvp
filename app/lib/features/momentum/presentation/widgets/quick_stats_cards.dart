import 'package:flutter/material.dart';
import '../../domain/models/momentum_data.dart';
import 'components/stats_cards_layout.dart';
import 'dart:async';

/// Quick stats cards component displaying lessons, streak, and today's activity
/// Three horizontal cards with icons, values, and labels
/// Optimized for performance with extracted components and reduced complexity
class QuickStatsCards extends StatefulWidget {
  final MomentumStats stats;
  final EdgeInsets? margin;
  final VoidCallback? onLessonsTap;
  final VoidCallback? onStreakTap;
  final VoidCallback? onTodayTap;
  final VoidCallback? onAchievementsTap;

  const QuickStatsCards({
    super.key,
    required this.stats,
    this.margin,
    this.onLessonsTap,
    this.onStreakTap,
    this.onTodayTap,
    this.onAchievementsTap,
  });

  @override
  State<QuickStatsCards> createState() => _QuickStatsCardsState();
}

class _QuickStatsCardsState extends State<QuickStatsCards>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  Timer? _animationTimer;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimation();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  void _startAnimation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationTimer = Timer(const Duration(milliseconds: 100), () {
          if (mounted) {
            _controller.forward();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin,
      child: StatsCardsLayout(
        stats: widget.stats,
        onLessonsTap: widget.onLessonsTap,
        onStreakTap: widget.onStreakTap,
        onTodayTap: widget.onTodayTap,
        onAchievementsTap: widget.onAchievementsTap,
        cardWrapper: _wrapCardWithAnimation,
      ),
    );
  }

  Widget _wrapCardWithAnimation(Widget card) {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _progressAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOut),
            ),
            child: card,
          ),
        );
      },
    );
  }
}
