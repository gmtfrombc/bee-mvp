/// Vitals Tile Widget for T2.2.2.6
///
/// Example UI widget that consumes VitalsNotifier data through providers.
/// Demonstrates integration for UI widgets consuming real-time vitals data.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/vitals_notifier_provider.dart';
import '../services/vitals_notifier_service.dart';

import '../services/responsive_service.dart';

/// Compact vitals display tile for UI integration
class VitalsTileWidget extends ConsumerWidget {
  final bool showConnectionStatus;
  final VoidCallback? onTap;

  const VitalsTileWidget({
    super.key,
    this.showConnectionStatus = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vitalsAsync = ref.watch(vitalsDataStreamProvider);
    final connectionAsync = ref.watch(vitalsConnectionStatusProvider);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: ResponsiveService.getMediumPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context, connectionAsync),
              SizedBox(height: ResponsiveService.getSmallSpacing(context)),
              _buildVitalsContent(context, vitalsAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AsyncValue<VitalsConnectionStatus> connectionAsync,
  ) {
    return Row(
      children: [
        Icon(
          Icons.favorite,
          color: Theme.of(context).primaryColor,
          size: ResponsiveService.getIconSize(context),
        ),
        SizedBox(width: ResponsiveService.getSmallSpacing(context)),
        Expanded(
          child: Text(
            'Live Vitals',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        if (showConnectionStatus) _buildConnectionIndicator(connectionAsync),
      ],
    );
  }

  Widget _buildConnectionIndicator(
    AsyncValue<VitalsConnectionStatus> connectionAsync,
  ) {
    return connectionAsync.when(
      data: (status) {
        Color color;
        IconData icon;

        switch (status) {
          case VitalsConnectionStatus.connected:
            color = Colors.green;
            icon = Icons.radio_button_checked;
            break;
          case VitalsConnectionStatus.polling:
            color = Colors.blue;
            icon = Icons.sync;
            break;
          case VitalsConnectionStatus.connecting:
            color = Colors.orange;
            icon = Icons.sync;
            break;
          case VitalsConnectionStatus.error:
            color = Colors.red;
            icon = Icons.error_outline;
            break;
          case VitalsConnectionStatus.disconnected:
            color = Colors.grey;
            icon = Icons.radio_button_unchecked;
            break;
        }

        return Icon(icon, color: color, size: 16);
      },
      loading:
          () => const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      error: (_, __) => const Icon(Icons.error, color: Colors.red, size: 16),
    );
  }

  Widget _buildVitalsContent(
    BuildContext context,
    AsyncValue<VitalsData> vitalsAsync,
  ) {
    return vitalsAsync.when(
      data: (vitals) => _buildVitalsData(context, vitals),
      loading: () => _buildLoadingState(context),
      error: (error, _) => _buildErrorState(context, error),
    );
  }

  Widget _buildVitalsData(BuildContext context, VitalsData vitals) {
    return Row(
      children: [
        if (vitals.hasHeartRate) ...[
          _buildVitalItem(
            context,
            icon: Icons.favorite,
            value: '${vitals.heartRate!.toInt()}',
            unit: 'bpm',
            quality: vitals.quality,
          ),
          SizedBox(width: ResponsiveService.getMediumSpacing(context)),
        ],
        if (vitals.hasSteps) ...[
          _buildVitalItem(
            context,
            icon: Icons.directions_walk,
            value: '${vitals.steps}',
            unit: 'steps',
            quality: vitals.quality,
          ),
        ],
        if (!vitals.hasValidData) ...[
          Text(
            'No data available',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      ],
    );
  }

  Widget _buildVitalItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String unit,
    required VitalsQuality quality,
  }) {
    final qualityColor = _getQualityColor(quality);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: qualityColor),
        const SizedBox(width: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: qualityColor,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          unit,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: ResponsiveService.getSmallSpacing(context)),
        Text(
          'Loading vitals...',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Row(
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 16),
        SizedBox(width: ResponsiveService.getSmallSpacing(context)),
        Expanded(
          child: Text(
            'Connection error',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.red),
          ),
        ),
      ],
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
