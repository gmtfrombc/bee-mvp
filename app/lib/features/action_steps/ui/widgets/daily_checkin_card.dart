import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/services/responsive_service.dart';
import '../../state/daily_checkin_controller.dart';
import '../../models/action_step_day_status.dart';
import 'package:app/features/action_steps/widgets/confetti_overlay.dart';

/// Displays today's Action Step check-in state and allows the user to mark it
/// as completed or skipped.
///
/// This widget is *stateless* – all state is managed by Riverpod via
/// [dailyCheckinControllerProvider]. The widget simply rebuilds when the state
/// changes.
class DailyCheckinCard extends ConsumerWidget {
  const DailyCheckinCard({super.key, DateTime? today}) : _today = today;

  /// The calendar day rendered by this card. Primarily for widget tests. If
  /// null, defaults to `DateTime.now()`.
  final DateTime? _today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = _today ?? DateTime.now();
    final statusAsync = ref.watch(dailyCheckinControllerProvider);

    final spacing = ResponsiveService.getMediumSpacing(context);
    final borderRadius = BorderRadius.circular(12);

    return Card(
      margin: EdgeInsets.all(spacing),
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: Padding(
        padding: EdgeInsets.all(spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(date: today),
            SizedBox(height: spacing),
            statusAsync.when(
              data: (status) => _StatusContent(status: status),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Text('Error: $err'),
            ),
            SizedBox(height: spacing),
            _ActionButtons(statusAsync: statusAsync, today: today),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveService.getSmallSpacing(context);
    final weekday = _weekdayLabel(date.weekday);
    final formattedDate =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return Row(
      children: [
        const Icon(Icons.calendar_today, size: 20),
        SizedBox(width: spacing),
        Text(
          '$weekday · $formattedDate',
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ],
    );
  }

  String _weekdayLabel(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    // DateTime.weekday: 1 = Mon, 7 = Sun
    return names[weekday - 1];
  }
}

class _StatusContent extends StatelessWidget {
  const _StatusContent({required this.status});
  final ActionStepDayStatus status;

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveService.getTinySpacing(context);
    Widget icon;
    String label;

    switch (status) {
      case ActionStepDayStatus.completed:
        icon = const Icon(Icons.check_circle, color: Colors.green);
        label = 'Completed';
      case ActionStepDayStatus.skipped:
        icon = const Icon(Icons.cancel, color: Colors.orange);
        label = 'Skipped';
      case ActionStepDayStatus.queued:
        icon = const Icon(Icons.hourglass_empty, color: Colors.grey);
        label = 'Pending';
    }

    return Row(
      children: [
        icon,
        SizedBox(width: spacing),
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}

class _ActionButtons extends ConsumerWidget {
  const _ActionButtons({required this.statusAsync, required this.today});

  final AsyncValue<ActionStepDayStatus> statusAsync;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ResponsiveService.getSmallSpacing(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final controller = ref.read(dailyCheckinControllerProvider.notifier);
    final buttonsDisabled = statusAsync.maybeWhen(
      loading: () => true,
      orElse: () => false,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Semantics(
          button: true,
          label: 'Mark today completed',
          child: ElevatedButton.icon(
            onPressed:
                buttonsDisabled
                    ? null
                    : () {
                      ConfettiOverlay.show(
                        context,
                        reducedMotion: reduceMotion,
                      );
                      controller.markCompleted();
                    },
            icon: const Icon(Icons.check),
            label: const Text('I did it'),
            style: ElevatedButton.styleFrom(
              animationDuration:
                  reduceMotion ? Duration.zero : kThemeAnimationDuration,
            ),
          ),
        ),
        SizedBox(width: spacing),
        Semantics(
          button: true,
          label: 'Skip today',
          child: OutlinedButton.icon(
            onPressed: buttonsDisabled ? null : () => controller.markSkipped(),
            icon: const Icon(Icons.close),
            label: const Text('Skip'),
            style: OutlinedButton.styleFrom(
              animationDuration:
                  reduceMotion ? Duration.zero : kThemeAnimationDuration,
            ),
          ),
        ),
      ],
    );
  }
}
