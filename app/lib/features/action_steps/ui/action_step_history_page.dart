import 'package:app/core/services/responsive_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../action_steps/state/action_step_history_controller.dart';
import '../../action_steps/models/action_step_history_entry.dart';

class ActionStepHistoryPage extends ConsumerStatefulWidget {
  const ActionStepHistoryPage({super.key});

  @override
  ConsumerState<ActionStepHistoryPage> createState() => _ActionStepHistoryPageState();
}

class _ActionStepHistoryPageState extends ConsumerState<ActionStepHistoryPage> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    if (_controller.position.pixels >= _controller.position.maxScrollExtent - 200) {
      ref.read(actionStepHistoryControllerProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncHistory = ref.watch(actionStepHistoryControllerProvider);
    final spacing = ResponsiveService.getMediumSpacing(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Action Step History'),
      ),
      body: asyncHistory.when(
        data: (history) {
          if (history.isEmpty) {
            return const Center(child: Text('No history yet.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.read(actionStepHistoryControllerProvider.notifier).refresh(),
            child: ListView.separated(
              controller: _controller,
              padding: ResponsiveService.getMediumPadding(context),
              itemBuilder: (context, index) {
                if (index >= history.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final entry = history[index];
                return _HistoryListTile(entry: entry);
              },
              separatorBuilder: (_, __) => SizedBox(height: spacing),
              itemCount: history.length + 1, // extra item for loader
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _HistoryListTile extends StatelessWidget {
  const _HistoryListTile({required this.entry});

  final ActionStepHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveService.getSmallSpacing(context);
    return Card(
      child: Padding(
        padding: ResponsiveService.getSmallPadding(context),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              entry.reachedGoal ? Icons.check_circle : Icons.cancel,
              color: entry.reachedGoal ? Colors.green : Colors.red,
            ),
            SizedBox(width: spacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.step.description, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('${entry.completed} / ${entry.step.frequency} completed'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 