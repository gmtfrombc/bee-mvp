import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/services/responsive_service.dart';
import 'package:app/features/momentum/presentation/providers/momentum_provider.dart';
import 'package:app/features/achievements/streak_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/core/theme/app_theme.dart';

/// Simple enum to identify which milestone was triggered.
enum _MilestoneType { streak7, momentumRiseToSteady }

/// Displays a small congratulatory card/toast whenever the user hits an
/// engagement milestone (7-day streak or Momentum *Rising → Steady*).
///
/// This widget should be placed near the top of the widget tree (e.g. inside
/// the main `Scaffold`) so that it can use the nearest [ScaffoldMessenger].
class ProgressCelebrationListener extends ConsumerStatefulWidget {
  const ProgressCelebrationListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ProgressCelebrationListener> createState() =>
      _ProgressCelebrationListenerState();
}

class _ProgressCelebrationListenerState
    extends ConsumerState<ProgressCelebrationListener> {
  int _prevStreak = 0;
  MomentumState? _prevMomentumState;

  @override
  Widget build(BuildContext context) {
    // Register listeners inside build (required by Riverpod v2+)
    ref.listen<AsyncValue<int>>(streakProvider, (previous, next) {
      final prevValue = previous?.value ?? _prevStreak;
      final currentValue = next.value ?? _prevStreak;

      final milestone = _detectMilestone(
        previousStreak: prevValue,
        currentStreak: currentValue,
        previousMomentum: _prevMomentumState,
        currentMomentum: _prevMomentumState, // unchanged in this listener
      );
      if (milestone == _MilestoneType.streak7) {
        _showCelebration(message: '🎉 7-day streak! Keep the momentum going!');
        _awardSevenDayBadge();
      }
      _prevStreak = currentValue;
    });

    ref.listen<MomentumState?>(momentumStateProvider, (previous, next) {
      final milestone = _detectMilestone(
        previousStreak: _prevStreak,
        currentStreak: _prevStreak, // unchanged in this listener
        previousMomentum: previous,
        currentMomentum: next,
      );
      if (milestone == _MilestoneType.momentumRiseToSteady) {
        _showCelebration(message: '👏 Momentum is steady! Great progress!');
      }
      _prevMomentumState = next;
    });

    return widget.child;
  }

  _MilestoneType? _detectMilestone({
    required int previousStreak,
    required int currentStreak,
    required MomentumState? previousMomentum,
    required MomentumState? currentMomentum,
  }) {
    if (previousStreak < 7 && currentStreak >= 7) {
      return _MilestoneType.streak7;
    }

    if (previousMomentum == MomentumState.rising &&
        currentMomentum == MomentumState.steady) {
      return _MilestoneType.momentumRiseToSteady;
    }

    return null;
  }

  Future<void> _awardSevenDayBadge() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await StreakService.incrementSevenDayBadgeCount(user.id);
    }
  }

  void _showCelebration({required String message}) {
    final context = this.context;
    final spacing = ResponsiveService.getMediumSpacing(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('🎉'),
            SizedBox(width: spacing),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
