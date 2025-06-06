import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/confetti_overlay.dart';
import '../../../../core/theme/app_theme.dart';

/// Provider that tracks momentum state transitions for confetti triggers
class MomentumRecoveryNotifier extends StateNotifier<MomentumState?> {
  MomentumRecoveryNotifier() : super(null);

  /// Check if transition represents a recovery (needs_care → rising/steady)
  @visibleForTesting
  bool isRecoveryTransition(MomentumState? oldState, MomentumState newState) {
    if (oldState == null) return false;

    return oldState == MomentumState.needsCare &&
        (newState == MomentumState.rising || newState == MomentumState.steady);
  }

  /// Update state and check for recovery transition
  void updateState(MomentumState newState, BuildContext? context) {
    final oldState = state;

    if (isRecoveryTransition(oldState, newState) && context != null) {
      // Trigger confetti celebration
      ConfettiOverlay.show(context);
    }

    state = newState;
  }
}

/// Provider for momentum recovery detection
final momentumRecoveryProvider =
    StateNotifierProvider<MomentumRecoveryNotifier, MomentumState?>((ref) {
      return MomentumRecoveryNotifier();
    });

/// Extension on WidgetRef to easily trigger recovery checks
extension MomentumRecoveryExtension on WidgetRef {
  void checkMomentumRecovery(MomentumState newState, BuildContext context) {
    read(momentumRecoveryProvider.notifier).updateState(newState, context);
  }
}
