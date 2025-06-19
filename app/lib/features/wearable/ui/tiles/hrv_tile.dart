import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/providers/vitals_notifier_provider.dart';
import 'package:app/core/services/responsive_service.dart';
import 'package:app/core/services/vitals_notifier_service.dart';
import 'package:app/core/providers/analytics_provider.dart';
import 'package:intl/intl.dart';

class HrvTile extends ConsumerStatefulWidget {
  const HrvTile({super.key});

  @override
  ConsumerState<HrvTile> createState() => _HrvTileState();
}

class _HrvTileState extends ConsumerState<HrvTile> {
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
        .logEvent('tile_viewed', params: {'tile': 'hrv'});
  }

  void _maybeLogError() {
    if (_loggedError) return;
    _loggedError = true;
    ref
        .read(analyticsServiceProvider)
        .logEvent('tile_error', params: {'tile': 'hrv'});
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
            final cached = ref.read(currentVitalsProvider);
            return _buildContent(
              context,
              cached ?? VitalsData(timestamp: DateTime.now()),
            );
          },
          error: (_, __) => _buildErrorState(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, VitalsData vitals) {
    final hrv = vitals.heartRateVariability;
    final timeStr = DateFormat('h:mm a').format(vitals.timestamp);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.favorite,
              color: Colors.red[400],
              size: ResponsiveService.getIconSize(context, baseSize: 20),
              semanticLabel: '',
            ),
            SizedBox(width: ResponsiveService.getSmallSpacing(context)),
            Text(
              'HRV',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.red[400],
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
        Text(
          'Heart Rate Variability',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: ResponsiveService.getTinySpacing(context) * 0.5),
        hrv == null
            ? Text(
              'No stats',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
            : Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  hrv.toStringAsFixed(0),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(width: ResponsiveService.getSmallSpacing(context)),
                Text(
                  'ms',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) => Text(
    'Error',
    style: Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
  );
}
