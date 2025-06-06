import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../momentum/presentation/providers/momentum_recovery_provider.dart';
import '../../../../momentum/presentation/providers/momentum_provider.dart';
import '../../../../momentum/domain/models/momentum_data.dart';
import '../../../../../core/widgets/confetti_overlay.dart';
import '../../../../../core/theme/app_theme.dart';

/// Integration helper for momentum celebration in Today Feed
/// Monitors momentum state changes and triggers confetti on recovery
class MomentumCelebrationIntegration extends ConsumerWidget {
  final Widget child;

  const MomentumCelebrationIntegration({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to momentum state changes
    ref.listen<AsyncValue<MomentumData?>>(momentumProvider, (previous, next) {
      if (previous != null && next.hasValue) {
        final previousData = previous.valueOrNull;
        final currentData = next.valueOrNull;

        if (previousData != null && currentData != null) {
          // Check for momentum recovery transition
          ref.checkMomentumRecovery(currentData.state, context);
        }
      }
    });

    return child;
  }
}

/// Mixin for widgets that need momentum celebration functionality
mixin MomentumCelebrationMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  /// Call this method when momentum state changes are detected
  void checkForMomentumRecovery(MomentumState newState) {
    if (mounted) {
      ref.checkMomentumRecovery(newState, context);
    }
  }

  /// Manually trigger confetti (for testing or special events)
  void triggerCelebration() {
    if (mounted) {
      ConfettiOverlay.show(context);
    }
  }
}

/// Example widget showing how to integrate momentum celebrations
class TodayFeedWithCelebrations extends ConsumerStatefulWidget {
  final Widget todayFeedContent;

  const TodayFeedWithCelebrations({super.key, required this.todayFeedContent});

  @override
  ConsumerState<TodayFeedWithCelebrations> createState() =>
      _TodayFeedWithCelebrationsState();
}

class _TodayFeedWithCelebrationsState
    extends ConsumerState<TodayFeedWithCelebrations>
    with MomentumCelebrationMixin {
  @override
  Widget build(BuildContext context) {
    return MomentumCelebrationIntegration(
      child: Column(
        children: [
          // Example celebration trigger button (for demo purposes)
          if (ref.watch(demoStateProvider) == MomentumState.rising) ...[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: triggerCelebration,
                icon: const Icon(Icons.celebration),
                label: const Text('Celebrate!'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.getMomentumColor(
                    MomentumState.rising,
                  ),
                ),
              ),
            ),
          ],
          Expanded(child: widget.todayFeedContent),
        ],
      ),
    );
  }
}
