import 'package:flutter/material.dart';
import '../../../../core/services/responsive_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/services/today_feed_momentum_award_service.dart';
import 'momentum_point_feedback_header.dart';

/// Body of the momentum point feedback – handles success vs queued layouts
class MomentumPointFeedbackBody extends StatelessWidget {
  const MomentumPointFeedbackBody({
    super.key,
    required this.awardResult,
    required this.showMessage,
    required this.slideAnimation,
    required this.scaleAnimation,
    required this.glowAnimation,
  });

  final MomentumAwardResult awardResult;
  final bool showMessage;
  final Animation<Offset> slideAnimation;
  final Animation<double> scaleAnimation;
  final Animation<double> glowAnimation;

  @override
  Widget build(BuildContext context) {
    return awardResult.isQueued
        ? _QueuedFeedback(
          showMessage: showMessage,
          slideAnimation: slideAnimation,
        )
        : _SuccessFeedback(
          awardResult: awardResult,
          showMessage: showMessage,
          slideAnimation: slideAnimation,
          scaleAnimation: scaleAnimation,
          glowAnimation: glowAnimation,
        );
  }
}

class _SuccessFeedback extends StatelessWidget {
  const _SuccessFeedback({
    required this.awardResult,
    required this.showMessage,
    required this.slideAnimation,
    required this.scaleAnimation,
    required this.glowAnimation,
  });

  final MomentumAwardResult awardResult;
  final bool showMessage;
  final Animation<Offset> slideAnimation;
  final Animation<double> scaleAnimation;
  final Animation<double> glowAnimation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveService.getMediumPadding(context),
      decoration: BoxDecoration(
        color: AppTheme.getSurfacePrimary(context),
        borderRadius: BorderRadius.circular(
          ResponsiveService.getBorderRadius(context),
        ),
        border: Border.all(
          color: AppTheme.momentumRising.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MomentumPointIndicator(
            pointsAwarded: awardResult.pointsAwarded,
            scaleAnimation: scaleAnimation,
            glowAnimation: glowAnimation,
          ),
          if (showMessage) ...[
            SizedBox(height: ResponsiveService.getSmallSpacing(context)),
            SlideTransition(
              position: slideAnimation,
              child: Column(
                children: [
                  Text(
                    'Momentum +${awardResult.pointsAwarded}!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.momentumRising,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: ResponsiveService.getTinySpacing(context)),
                  Text(
                    _getSuccessMessage(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.getTextSecondary(context),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getSuccessMessage() {
    final messages = [
      'Great job staying curious about your health!',
      'Learning something new every day! 🌟',
      'Knowledge is momentum! Keep going! 📚',
      'Your daily dose of health wisdom! 💡',
      'Building healthy habits, one read at a time! 🚀',
    ];

    final seedTime = awardResult.awardTime ?? DateTime.now();

    final index =
        awardResult.awardTime != null ? seedTime.day % messages.length : 0;

    return messages[index];
  }
}

class _QueuedFeedback extends StatelessWidget {
  const _QueuedFeedback({
    required this.showMessage,
    required this.slideAnimation,
  });

  final bool showMessage;
  final Animation<Offset> slideAnimation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveService.getMediumPadding(context),
      decoration: BoxDecoration(
        color: AppTheme.getSurfacePrimary(context),
        borderRadius: BorderRadius.circular(
          ResponsiveService.getBorderRadius(context),
        ),
        border: Border.all(
          color: AppTheme.momentumSteady.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule,
            size: ResponsiveService.getIconSize(context, baseSize: 32),
            color: AppTheme.momentumSteady,
          ),
          if (showMessage) ...[
            SizedBox(height: ResponsiveService.getSmallSpacing(context)),
            SlideTransition(
              position: slideAnimation,
              child: Text(
                'Points queued for when back online',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.getTextPrimary(context),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
