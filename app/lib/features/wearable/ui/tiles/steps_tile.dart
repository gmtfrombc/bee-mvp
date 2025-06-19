import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/providers/vitals_notifier_provider.dart';
import 'package:app/core/services/responsive_service.dart';
import 'package:app/core/services/vitals_notifier_service.dart';
import 'package:app/core/providers/analytics_provider.dart';
import 'package:intl/intl.dart';

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
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: ResponsiveService.getLargePadding(context),
        child: vitalsAsync.when(
          data: (vitals) => _buildContent(context, vitals),
          loading: () {
            final cached = ref.read(currentVitalsProvider);
            if (cached != null) {
              return _buildContent(context, cached);
            }
            return _buildEmptyState(context);
          },
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
    final timeStr = DateFormat('h:mm a').format(vitals.timestamp);

    return Semantics(
      label: 'Steps $stepsValue at $timeStr',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with icon + title and timestamp
          Row(
            children: [
              Icon(
                Icons.directions_walk,
                color: Colors.orange[600],
                size: ResponsiveService.getIconSize(context, baseSize: 20),
                semanticLabel: '',
              ),
              SizedBox(width: ResponsiveService.getSmallSpacing(context)),
              Text(
                'Steps',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.orange[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                timeStr,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveService.getMediumSpacing(context)),
          // Main value display
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$stepsValue',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(width: ResponsiveService.getSmallSpacing(context)),
              Text(
                'steps',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
