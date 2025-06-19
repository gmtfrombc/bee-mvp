import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/providers/vitals_notifier_provider.dart';
import 'package:app/core/services/responsive_service.dart';
import 'package:app/core/services/vitals_notifier_service.dart';
import 'package:app/core/providers/analytics_provider.dart';
import 'package:intl/intl.dart';

/// HeartRateTile widget - shows live heart rate from VitalsNotifier
class HeartRateTile extends ConsumerStatefulWidget {
  const HeartRateTile({super.key});

  @override
  ConsumerState<HeartRateTile> createState() => _HeartRateTileState();
}

class _HeartRateTileState extends ConsumerState<HeartRateTile> {
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
        .logEvent('tile_viewed', params: {'tile': 'heart_rate'});
  }

  void _maybeLogError() {
    if (_loggedError) return;
    _loggedError = true;
    ref
        .read(analyticsServiceProvider)
        .logEvent('tile_error', params: {'tile': 'heart_rate'});
  }

  Widget _buildCard(BuildContext context, AsyncValue<VitalsData> vitalsAsync) {
    return Card(
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withAlpha(77),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: ResponsiveService.getMediumPadding(context),
        child: vitalsAsync.when(
          data: (vitals) => _buildContent(context, vitals),
          loading: () {
            // While waiting for fresh data, fall back to current cached value
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
    if (!vitals.hasHeartRate) {
      return _buildEmptyState(context);
    }

    final qualityColor = _getQualityColor(vitals.quality);
    final hrValue = vitals.heartRate?.toStringAsFixed(0) ?? '—';
    final timeStr = DateFormat('h:mm a').format(vitals.timestamp);
    final range = vitals.metadata['hrRange'] as String?; // set later

    return Semantics(
      label: 'Heart rate $hrValue beats per minute at $timeStr',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with icon + title and timestamp
          Row(
            children: [
              Icon(
                Icons.favorite,
                color: qualityColor,
                size: ResponsiveService.getIconSize(context, baseSize: 20),
                semanticLabel: '',
              ),
              SizedBox(width: ResponsiveService.getSmallSpacing(context)),
              Text(
                'Heart Rate',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: qualityColor,
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
            'Average Heart Rate',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: ResponsiveService.getTinySpacing(context) * 0.5),
          // Main value display
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                hrValue,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(width: ResponsiveService.getSmallSpacing(context)),
              Text(
                'BPM',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (range != null) ...[
            SizedBox(height: ResponsiveService.getSmallSpacing(context)),
            Text(
              range,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Semantics(
      label: 'Heart rate data error',
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
      label: 'No heart rate data',
      child: Text(
        'No heart rate',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
