import 'package:app/core/services/responsive_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/action_steps/data/action_step_repository.dart';
import 'package:app/features/action_steps/services/action_step_analytics.dart';
import 'package:app/core/navigation/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/services/action_step_status_service.dart';
import 'package:app/features/action_steps/ui/widgets/daily_checkin_card.dart';

/// Page showing the user’s current Action Step with progress and actions.
class MyActionStepPage extends ConsumerStatefulWidget {
  const MyActionStepPage({super.key});

  @override
  ConsumerState<MyActionStepPage> createState() => _MyActionStepPageState();
}

class _MyActionStepPageState extends ConsumerState<MyActionStepPage> {
  bool _loggedView = false;

  @override
  Widget build(BuildContext context) {
    final asyncStep = ref.watch(currentActionStepProvider);

    asyncStep.whenData((current) async {
      if (!_loggedView && current != null) {
        _loggedView = true;
        final analytics = ref.read(actionStepAnalyticsProvider);
        await analytics.logView(actionStepId: current.step.id);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Action Step'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () => context.push(kActionStepHistoryRoute),
          ),
        ],
      ),
      body: SafeArea(
        child: asyncStep.when(
          data: (current) {
            if (current == null) {
              return _NoStepView(
                key: const ValueKey('NoStepView'),
                onSetup: () => context.push(kActionStepSetupRoute),
              );
            }
            return _StepDetailView(
              current,
              key: const ValueKey('StepDetailView'),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}

class _NoStepView extends StatelessWidget {
  const _NoStepView({super.key, required this.onSetup});

  final VoidCallback onSetup;

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveService.getMediumSpacing(context);
    return Padding(
      padding: ResponsiveService.getMediumPadding(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'You haven\'t set an Action Step yet.',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: spacing),
          ElevatedButton(onPressed: onSetup, child: const Text('Set Up Now')),
        ],
      ),
    );
  }
}

class _StepDetailView extends ConsumerWidget {
  const _StepDetailView(this.current, {super.key});

  final CurrentActionStep current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ResponsiveService.getMediumSpacing(context);
    final step = current.step;

    // TODO(icon): Map category to icon asset
    return Padding(
      padding: ResponsiveService.getMediumPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Daily check-in card (T12)
          const DailyCheckinCard(),

          SizedBox(height: spacing),

          Row(
            children: [
              const Icon(Icons.flag),
              SizedBox(width: spacing),
              Expanded(
                child: Text(
                  step.description,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing),
          Text('${current.completed} / ${current.target} this week'),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // TODO(T4): Navigate to edit flow
                    context.push(kActionStepSetupRoute, extra: step);
                  },
                  child: const Text('Edit'),
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final repo = ref.read(actionStepRepositoryProvider);
                    final analytics = ref.read(actionStepAnalyticsProvider);
                    await repo.deleteActionStep(step.id);
                    await analytics.logDelete(actionStepId: step.id);
                    await ActionStepStatusService().setHasSetActionStep(false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Action Step deleted')),
                      );
                      context.go(kActionStepSetupRoute);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
