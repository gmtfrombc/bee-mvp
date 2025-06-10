/// Live Vitals Developer Screen for T2.2.1.5-4
///
/// Developer screen showing last 5 seconds of heart-rate & step deltas
/// for ad-hoc validation. Hidden behind debug flag.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/responsive_service.dart';
import '../../../core/providers/live_vitals_provider.dart';
import '../../../core/services/live_vitals_models.dart';

/// Live Vitals Developer Screen (Debug builds only)
class LiveVitalsDeveloperScreen extends ConsumerStatefulWidget {
  const LiveVitalsDeveloperScreen({super.key});

  @override
  ConsumerState<LiveVitalsDeveloperScreen> createState() =>
      _LiveVitalsDeveloperScreenState();
}

class _LiveVitalsDeveloperScreenState
    extends ConsumerState<LiveVitalsDeveloperScreen> {
  late Timer _refreshTimer;

  @override
  void initState() {
    super.initState();

    // Auto-refresh every second for real-time feel
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    // Initialize service on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(liveVitalsStreamingStateProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only show in debug builds
    if (kReleaseMode) {
      return const Scaffold(
        body: Center(
          child: Text('Live Vitals: Not available in release builds'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔴 Live Vitals (Dev)'),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
        actions: [_buildStreamingToggle(), const SizedBox(width: 8)],
      ),
      body: Column(
        children: [
          _buildStatusHeader(),
          Expanded(child: _buildVitalsDisplay()),
          _buildDebugStats(),
        ],
      ),
    );
  }

  /// Build streaming toggle button
  Widget _buildStreamingToggle() {
    final streamingState = ref.watch(liveVitalsStreamingStateProvider);

    return IconButton(
      icon: Icon(
        streamingState.isStreaming
            ? CupertinoIcons.stop_circle_fill
            : CupertinoIcons.play_circle_fill,
      ),
      onPressed: () {
        if (streamingState.isStreaming) {
          ref.read(liveVitalsStreamingStateProvider.notifier).stopStreaming();
        } else {
          ref.read(liveVitalsStreamingStateProvider.notifier).startStreaming();
        }
      },
      tooltip:
          streamingState.isStreaming ? 'Stop Streaming' : 'Start Streaming',
    );
  }

  /// Build status header
  Widget _buildStatusHeader() {
    final streamingState = ref.watch(liveVitalsStreamingStateProvider);

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (!streamingState.isInitialized) {
      statusColor = Colors.grey;
      statusText = 'Initializing...';
      statusIcon = CupertinoIcons.clock;
    } else if (streamingState.hasError) {
      statusColor = Colors.red;
      statusText = 'Error: ${streamingState.error}';
      statusIcon = CupertinoIcons.exclamationmark_triangle;
    } else if (streamingState.isStreaming) {
      statusColor = Colors.green;
      statusText = 'Live Streaming';
      statusIcon = CupertinoIcons.dot_radiowaves_left_right;
    } else {
      statusColor = Colors.orange;
      statusText = 'Ready (Tap play to start)';
      statusIcon = CupertinoIcons.pause_circle;
    }

    return Container(
      width: double.infinity,
      padding: ResponsiveService.getMediumPadding(context),
      color: statusColor.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor),
          SizedBox(width: ResponsiveService.getSmallSpacing(context)),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
            ),
          ),
          if (streamingState.lastUpdate != null)
            Text(
              'Updated: ${_formatTime(streamingState.lastUpdate!)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: statusColor.withValues(alpha: 0.7),
              ),
            ),
        ],
      ),
    );
  }

  /// Build main vitals display
  Widget _buildVitalsDisplay() {
    final vitalsAsync = ref.watch(liveVitalsUpdateStreamProvider);

    return vitalsAsync.when(
      data: (update) => _buildVitalsContent(update),
      loading:
          () => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading live vitals data...'),
              ],
            ),
          ),
      error:
          (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  size: 48,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text('Error: $error'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => ref.refresh(liveVitalsUpdateStreamProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
    );
  }

  /// Build vitals content when data is available
  Widget _buildVitalsContent(LiveVitalsUpdate update) {
    return SingleChildScrollView(
      padding: ResponsiveService.getMediumPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVitalsSection(
            title: '❤️ Heart Rate',
            points: update.heartRatePoints,
            emptyMessage: 'No heart rate data in last 5 seconds',
          ),
          SizedBox(height: ResponsiveService.getLargeSpacing(context)),
          _buildVitalsSection(
            title: '👟 Steps',
            points: update.stepPoints,
            emptyMessage: 'No step data in last 5 seconds',
          ),
          SizedBox(height: ResponsiveService.getLargeSpacing(context)),
          _buildDataSummary(update),
        ],
      ),
    );
  }

  /// Build vitals section for a specific data type
  Widget _buildVitalsSection({
    required String title,
    required List<LiveVitalsDataPoint> points,
    required String emptyMessage,
  }) {
    return Card(
      child: Padding(
        padding: ResponsiveService.getMediumPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: ResponsiveService.getSmallSpacing(context)),
            if (points.isEmpty)
              Text(
                emptyMessage,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ...points.reversed
                  .take(10)
                  .map((point) => _buildDataPointTile(point)),
          ],
        ),
      ),
    );
  }

  /// Build individual data point tile
  Widget _buildDataPointTile(LiveVitalsDataPoint point) {
    final deltaColor =
        point.delta == null
            ? Colors.grey
            : point.delta! > 0
            ? Colors.green
            : point.delta! < 0
            ? Colors.red
            : Colors.grey;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              _formatTime(point.timestamp),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${point.value.toStringAsFixed(1)} ${point.unit}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child:
                point.delta != null
                    ? Text(
                      '${point.delta! >= 0 ? '+' : ''}${point.delta!.toStringAsFixed(1)}',
                      style: TextStyle(
                        color: deltaColor,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                    )
                    : Text('--', style: TextStyle(color: Colors.grey[400])),
          ),
          Expanded(
            flex: 3,
            child: Text(
              point.source,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Build data summary section
  Widget _buildDataSummary(LiveVitalsUpdate update) {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: ResponsiveService.getMediumPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 Summary',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: ResponsiveService.getSmallSpacing(context)),
            _buildSummaryRow('Data Window', '${update.dataWindow.inSeconds}s'),
            _buildSummaryRow(
              'Heart Rate Points',
              '${update.heartRatePoints.length}',
            ),
            _buildSummaryRow('Step Points', '${update.stepPoints.length}'),
            _buildSummaryRow('Total Points', '${update.totalDataPoints}'),
            _buildSummaryRow('Last Update', _formatTime(update.updateTime)),
            if (update.latestHeartRate != null)
              _buildSummaryRow(
                'Latest HR',
                '${update.latestHeartRate!.value.toStringAsFixed(1)} bpm',
              ),
            if (update.latestSteps != null)
              _buildSummaryRow(
                'Latest Steps',
                update.latestSteps!.value.toStringAsFixed(0),
              ),
          ],
        ),
      ),
    );
  }

  /// Build summary row
  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label)),
          Expanded(
            flex: 1,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// Build debug statistics footer
  Widget _buildDebugStats() {
    final debugStats = ref.watch(liveVitalsDebugStatsProvider);

    return Container(
      width: double.infinity,
      padding: ResponsiveService.getSmallPadding(context),
      color: Colors.grey[100],
      child: Text(
        'Debug: ${debugStats['platform']} | '
        'Points: ${debugStats['totalDataPoints']} | '
        'Window: ${debugStats['dataWindowSeconds']}s | '
        'Interval: ${debugStats['updateIntervalSeconds']}s',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
          color: Colors.grey[600],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Format time for display
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }
}
