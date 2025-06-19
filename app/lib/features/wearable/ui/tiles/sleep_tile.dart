import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/providers/vitals_notifier_provider.dart';
import 'package:app/core/services/responsive_service.dart';
import 'package:app/core/services/vitals_notifier_service.dart';
import 'package:app/core/providers/analytics_provider.dart';
import 'package:intl/intl.dart';

/// SleepTile widget - shows total hours slept from VitalsNotifier
class SleepTile extends ConsumerStatefulWidget {
  const SleepTile({super.key});

  @override
  ConsumerState<SleepTile> createState() => _SleepTileState();
}

class _SleepTileState extends ConsumerState<SleepTile> {
  bool _loggedView = false;
  bool _loggedError = false;

  @override
  Widget build(BuildContext context) {
    final vitalsAsync = ref.watch(vitalsDataStreamProvider);

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
        .logEvent('tile_viewed', params: {'tile': 'sleep'});
  }

  void _maybeLogError() {
    if (_loggedError) return;
    _loggedError = true;
    ref
        .read(analyticsServiceProvider)
        .logEvent('tile_error', params: {'tile': 'sleep'});
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
    if (!vitals.hasSleep) {
      return _buildEmptyState(context);
    }

    final qualityColor = _getQualityColor(vitals.quality);

    final hours = vitals.sleepHours ?? 0;
    final timeStr = DateFormat('h:mm a').format(vitals.timestamp);

    // Format hours and minutes separately like Apple Health
    final totalMinutes = (hours * 60).round();
    final displayHours = totalMinutes ~/ 60;
    final displayMinutes = totalMinutes % 60;

    return Semantics(
      label: 'Sleep $displayHours hours $displayMinutes minutes at $timeStr',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with icon + title and timestamp
          Row(
            children: [
              Icon(
                Icons.bedtime,
                color: Colors.cyan[400],
                size: ResponsiveService.getIconSize(context, baseSize: 20),
                semanticLabel: '',
              ),
              SizedBox(width: ResponsiveService.getSmallSpacing(context)),
              Text(
                'Sleep',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.cyan[400],
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
          SizedBox(height: ResponsiveService.getSmallSpacing(context)),
          // Subtitle
          Text(
            'Time Asleep',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: ResponsiveService.getSmallSpacing(context)),
          // Main value display - Apple style with hours and minutes
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$displayHours',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                'hr ',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$displayMinutes',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                'min',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
      label: 'Sleep data error',
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
      label: 'No sleep data',
      child: Text(
        'No sleep data',
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
