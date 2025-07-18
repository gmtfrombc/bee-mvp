import 'package:app/core/services/responsive_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/l10n/s.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/health_data/models/energy_level.dart';

import '../pes_providers.dart';

/// Small sparkline visualising the user’s perceived energy score over the
/// last 7 days. Displays a placeholder when no data is available.
class PesTrendSparkline extends ConsumerWidget {
  const PesTrendSparkline({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(pesTrendProvider);

    return trendAsync.when(
      data: (entries) {
        if (entries.isEmpty) return _EmptyState();
        return _SparklineChart(entries: entries);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (err, _) => const Center(child: Text('Error loading energy trend')),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Chart
// --------------------------------------------------------------------------
class _SparklineChart extends StatelessWidget {
  const _SparklineChart({required this.entries});

  final List<EnergyLevelEntry> entries;

  static const _levelToNumeric = {
    EnergyLevel.veryLow: 1.0,
    EnergyLevel.low: 2.0,
    EnergyLevel.medium: 3.0,
    EnergyLevel.high: 4.0,
    EnergyLevel.veryHigh: 5.0,
  };

  @override
  Widget build(BuildContext context) {
    final spots =
        entries.asMap().entries.map((entry) {
          final idx = entry.key;
          final level = entry.value.level;
          return FlSpot(idx.toDouble(), _levelToNumeric[level]!);
        }).toList();

    final colour = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: ResponsiveService.getQuickStatsCardHeight(context) * 0.6,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minY: 1,
          maxY: 5,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 2,
              color: colour,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 250),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Empty state
// --------------------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(ResponsiveService.getSmallSpacing(context)),
      child: Text(
        S.of(context).pes_trend_empty_state,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppTheme.getTextSecondary(context),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
