import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/responsive_service.dart';
import '../../domain/models/momentum_data.dart';
import 'momentum_gauge.dart';

/// Detail modal that shows comprehensive momentum breakdown
/// Triggered when user taps on MomentumCard
/// Optimized for performance with reduced animation controllers and improved memory usage
class MomentumDetailModal extends StatefulWidget {
  final MomentumData momentumData;

  const MomentumDetailModal({super.key, required this.momentumData});

  @override
  State<MomentumDetailModal> createState() => _MomentumDetailModalState();
}

class _MomentumDetailModalState extends State<MomentumDetailModal>
    with SingleTickerProviderStateMixin {
  // Optimized: Use single animation controller instead of multiple controllers
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupOptimizedAnimations();
    _startEntryAnimation();
  }

  void _setupOptimizedAnimations() {
    // Optimized: Single controller for all animations reduces memory overhead
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Optimized: Simple scale animation for content stagger effect
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  void _startEntryAnimation() {
    // Optimized: Start single animation immediately
    _controller.forward();
  }

  void _handleClose() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    // Optimized: Only dispose single controller
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Material(
          color: Colors.black.withValues(alpha: 0.5 * _fadeAnimation.value),
          child: SafeArea(
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                margin: const EdgeInsets.only(top: 80),
                decoration: const BoxDecoration(
                  color: AppTheme.surfacePrimary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: FadeTransition(
                          opacity: _scaleAnimation,
                          child: _buildScrollableContent(),
                        ),
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

  // Optimized: Extract scrollable content to reduce rebuild scope
  Widget _buildScrollableContent() {
    return SingleChildScrollView(
      padding: ResponsiveService.getLargePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMomentumOverview(),
          SizedBox(height: ResponsiveService.getExtraLargeSpacing(context)),
          _buildMomentumFactors(),
          SizedBox(height: ResponsiveService.getExtraLargeSpacing(context)),
          _buildRecentActivity(),
          SizedBox(height: ResponsiveService.getExtraLargeSpacing(context)),
          _buildProgressInsights(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: ResponsiveService.getLargePadding(context),
      decoration: BoxDecoration(
        color: AppTheme.getMomentumColor(
          widget.momentumData.state,
        ).withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Momentum Details',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.getMomentumColor(widget.momentumData.state),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: ResponsiveService.getTinySpacing(context)),
                Text(
                  'Last updated ${_formatLastUpdated()}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _handleClose,
            icon: const Icon(Icons.close_rounded),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.surfaceSecondary,
              foregroundColor: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMomentumOverview() {
    return _buildAnimatedSection(
      index: 0,
      child: Card(
        child: Padding(
          padding: ResponsiveService.getResponsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current State',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: ResponsiveService.getResponsiveSpacing(context)),
              Row(
                children: [
                  SizedBox(
                    width:
                        ResponsiveService.getMomentumGaugeSize(context) * 0.8,
                    height:
                        ResponsiveService.getMomentumGaugeSize(context) * 0.8,
                    child: MomentumGauge(
                      state: widget.momentumData.state,
                      percentage: widget.momentumData.percentage,
                      showGlow: false,
                      size:
                          ResponsiveService.getMomentumGaugeSize(context) * 0.8,
                    ),
                  ),
                  SizedBox(
                    width: ResponsiveService.getResponsiveSpacing(context),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getStateDisplayText(),
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            color: AppTheme.getMomentumColor(
                              widget.momentumData.state,
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(
                          height: ResponsiveService.getSmallSpacing(context),
                        ),
                        Text(
                          '${widget.momentumData.percentage.toInt()}% momentum',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        SizedBox(
                          height: ResponsiveService.getSmallSpacing(context),
                        ),
                        Text(
                          widget.momentumData.message,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMomentumFactors() {
    return _buildAnimatedSection(
      index: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Momentum Factors',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: ResponsiveService.getResponsiveSpacing(context)),
          Card(
            child: Padding(
              padding: ResponsiveService.getResponsivePadding(context),
              child: Column(
                children: [
                  _buildFactorItem(
                    'Learning Progress',
                    widget.momentumData.stats.lessonsRatio,
                    Icons.school_rounded,
                    widget.momentumData.stats.lessonsCompleted /
                        widget.momentumData.stats.totalLessons,
                  ),
                  SizedBox(
                    height: ResponsiveService.getResponsiveSpacing(context),
                  ),
                  _buildFactorItem(
                    'Consistency Streak',
                    widget.momentumData.stats.streakText,
                    Icons.local_fire_department_rounded,
                    widget.momentumData.stats.streakDays /
                        30.0, // Assume 30 days max
                  ),
                  SizedBox(
                    height: ResponsiveService.getResponsiveSpacing(context),
                  ),
                  _buildFactorItem(
                    'Daily Engagement',
                    widget.momentumData.stats.todayText,
                    Icons.timer_rounded,
                    widget.momentumData.stats.todayMinutes /
                        60.0, // Assume 60 min max
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactorItem(
    String title,
    String value,
    IconData icon,
    double progress,
  ) {
    return Row(
      children: [
        Container(
          width: ResponsiveService.getIconSize(context, baseSize: 40),
          height: ResponsiveService.getIconSize(context, baseSize: 40),
          decoration: BoxDecoration(
            color: AppTheme.getMomentumColor(
              widget.momentumData.state,
            ).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(
              ResponsiveService.getBorderRadius(context),
            ),
          ),
          child: Icon(
            icon,
            color: AppTheme.getMomentumColor(widget.momentumData.state),
            size: ResponsiveService.getIconSize(context, baseSize: 20),
          ),
        ),
        SizedBox(width: ResponsiveService.getResponsiveSpacing(context)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyLarge),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveService.getSmallSpacing(context)),
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: AppTheme.surfaceSecondary,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.getMomentumColor(widget.momentumData.state),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return _buildAnimatedSection(
      index: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: ResponsiveService.getResponsiveSpacing(context)),
          Card(
            child: Padding(
              padding: ResponsiveService.getResponsivePadding(context),
              child: Column(
                children:
                    widget.momentumData.weeklyTrend
                        .take(3) // Show last 3 days
                        .map((daily) => _buildActivityItem(daily))
                        .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(DailyMomentum daily) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveService.getSmallSpacing(context),
      ),
      child: Row(
        children: [
          Container(
            width: ResponsiveService.getIconSize(context, baseSize: 32),
            height: ResponsiveService.getIconSize(context, baseSize: 32),
            decoration: BoxDecoration(
              color: AppTheme.getMomentumColor(
                daily.state,
              ).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(
                ResponsiveService.getBorderRadius(context),
              ),
            ),
            child: Icon(
              _getStateIcon(daily.state),
              color: AppTheme.getMomentumColor(daily.state),
              size: ResponsiveService.getIconSize(context, baseSize: 16),
            ),
          ),
          SizedBox(width: ResponsiveService.getResponsiveSpacing(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(daily.date),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  '${daily.percentage.toInt()}% momentum',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Text(
            daily.state.name.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppTheme.getMomentumColor(daily.state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressInsights() {
    return _buildAnimatedSection(
      index: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress Insights',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: ResponsiveService.getResponsiveSpacing(context)),
          Card(
            child: Padding(
              padding: ResponsiveService.getResponsivePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInsightItem(
                    'Weekly Trend',
                    _getWeeklyTrendInsight(),
                    Icons.trending_up_rounded,
                  ),
                  SizedBox(
                    height: ResponsiveService.getResponsiveSpacing(context),
                  ),
                  _buildInsightItem(
                    'Next Goal',
                    _getNextGoalInsight(),
                    Icons.flag_rounded,
                  ),
                  SizedBox(
                    height: ResponsiveService.getResponsiveSpacing(context),
                  ),
                  _buildInsightItem(
                    'Recommendation',
                    _getRecommendationInsight(),
                    Icons.lightbulb_rounded,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String title, String content, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: ResponsiveService.getIconSize(context, baseSize: 32),
          height: ResponsiveService.getIconSize(context, baseSize: 32),
          decoration: BoxDecoration(
            color: AppTheme.momentumSteady.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(
              ResponsiveService.getBorderRadius(context),
            ),
          ),
          child: Icon(
            icon,
            color: AppTheme.momentumSteady,
            size: ResponsiveService.getIconSize(context, baseSize: 16),
          ),
        ),
        SizedBox(width: ResponsiveService.getResponsiveSpacing(context)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: ResponsiveService.getTinySpacing(context)),
              Text(content, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedSection({required int index, required Widget child}) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, _) {
        return FadeTransition(
          opacity: _scaleAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(_scaleAnimation),
            child: child,
          ),
        );
      },
    );
  }

  String _getStateDisplayText() {
    switch (widget.momentumData.state) {
      case MomentumState.rising:
        return 'Rising 🚀';
      case MomentumState.steady:
        return 'Steady 🙂';
      case MomentumState.needsCare:
        return 'Needs Care 🌱';
    }
  }

  IconData _getStateIcon(MomentumState state) {
    switch (state) {
      case MomentumState.rising:
        return Icons.trending_up_rounded;
      case MomentumState.steady:
        return Icons.trending_flat_rounded;
      case MomentumState.needsCare:
        return Icons.trending_down_rounded;
    }
  }

  String _formatLastUpdated() {
    final now = DateTime.now();
    final difference = now.difference(widget.momentumData.lastUpdated);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[date.weekday - 1];
    }
  }

  String _getWeeklyTrendInsight() {
    final recent = widget.momentumData.weeklyTrend.take(3).toList();
    final average =
        recent.map((d) => d.percentage).reduce((a, b) => a + b) / recent.length;

    if (average >= 80) {
      return 'Excellent momentum this week! You\'re consistently performing well.';
    } else if (average >= 60) {
      return 'Good momentum this week. Keep building on your progress.';
    } else {
      return 'Your momentum is building. Focus on small, consistent actions.';
    }
  }

  String _getNextGoalInsight() {
    final stats = widget.momentumData.stats;

    if (stats.lessonsCompleted < stats.totalLessons) {
      final remaining = stats.totalLessons - stats.lessonsCompleted;
      return 'Complete $remaining more lesson${remaining != 1 ? 's' : ''} to finish your current module.';
    } else {
      return 'Great job! You\'ve completed all lessons. Ready for the next challenge?';
    }
  }

  String _getRecommendationInsight() {
    switch (widget.momentumData.state) {
      case MomentumState.rising:
        return 'You\'re doing great! Consider sharing your progress to inspire others.';
      case MomentumState.steady:
        return 'Maintain your consistency. Try adding one new learning activity today.';
      case MomentumState.needsCare:
        return 'Start small today. Even 5 minutes of engagement can rebuild momentum.';
    }
  }
}

/// Show the momentum detail modal
void showMomentumDetailModal(BuildContext context, MomentumData momentumData) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => MomentumDetailModal(momentumData: momentumData),
  );
}
