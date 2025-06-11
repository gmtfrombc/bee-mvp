import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/providers/vitals_notifier_provider.dart';
import 'package:app/core/services/responsive_service.dart';
import 'package:app/core/services/vitals_notifier_service.dart';
import 'package:app/core/providers/analytics_provider.dart';

/// StepsTile widget - shows live steps count from VitalsNotifier
class StepsTile extends ConsumerStatefulWidget {
  const StepsTile({super.key});

  @override
  ConsumerState<StepsTile> createState() => _StepsTileState();
}

class _StepsTileState extends ConsumerState<StepsTile> {
  bool _loggedView = false;
  bool _loggedError = false;

  @override
  Widget build(BuildContext context) {
    final vitalsAsync = ref.watch(vitalsDataStreamProvider);

    // Listen for state changes to emit analytics
    vitalsAsync.when(
      data: (_) => _maybeLogView(),
      error: (_, __) => _maybeLogError(),
      loading: () {},
    );

    return _buildCard(context, vitalsAsync);
  }

  void _maybeLogView() {
    if (_loggedView) return;
    _loggedView = true;
    ref
        .read(analyticsServiceProvider)
        .logEvent('tile_viewed', params: {'tile': 'steps'});
  }

  void _maybeLogError() {
    if (_loggedError) return;
    _loggedError = true;
    ref
        .read(analyticsServiceProvider)
        .logEvent('tile_error', params: {'tile': 'steps'});
  }

  Widget _buildCard(BuildContext context, AsyncValue<VitalsData> vitalsAsync) {
    return Card(
      child: Padding(
        padding: ResponsiveService.getMediumPadding(context),
        child: vitalsAsync.when(
          data: (vitals) => _buildContent(context, vitals),
          loading: () => _buildLoadingState(context),
          error: (error, _) => _buildErrorState(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, VitalsData vitals) {
    if (!vitals.hasSteps) {
      return _buildEmptyState(context);
    }

    final qualityColor = _getQualityColor(vitals.quality);
    final stepsValue = vitals.steps ?? 0;

    return Semantics(
      label: 'Steps $stepsValue',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(Icons.directions_walk, color: qualityColor, semanticLabel: ''),
          SizedBox(width: ResponsiveService.getSmallSpacing(context)),
          Text(
            '$stepsValue',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: qualityColor,
            ),
          ),
          SizedBox(width: ResponsiveService.getTinySpacing(context)),
          Text(
            'steps',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Semantics(
      label: 'Loading steps',
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: ResponsiveService.getSmallSpacing(context)),
          Text(
            'Loading…',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Semantics(
      label: 'Steps data error',
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 16,
          ),
          SizedBox(width: ResponsiveService.getSmallSpacing(context)),
          Text(
            'Error',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Semantics(
      label: 'No steps data',
      child: Text(
        'No steps',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Color _getQualityColor(VitalsQuality quality) {
    switch (quality) {
      case VitalsQuality.excellent:
        return Colors.green[700]!;
      case VitalsQuality.good:
        return Colors.green;
      case VitalsQuality.fair:
        return Colors.orange;
      case VitalsQuality.poor:
        return Colors.red;
      case VitalsQuality.unknown:
        return Colors.grey;
    }
  }
}
