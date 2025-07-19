import 'package:app/core/services/responsive_service.dart';
import 'package:app/features/health_signals/biometrics/providers/metabolic_health_providers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A profile-screen tile displaying the latest Metabolic Health Score (MHS)
/// and a 30-day spark-line trend.
class MetabolicHealthTile extends ConsumerWidget {
  const MetabolicHealthTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestScoreAsync = ref.watch(latestMhsProvider);
    final historyAsync = ref.watch(mhsThirtyDayHistoryProvider);

    return Card(
      margin: ResponsiveService.getResponsiveMargin(context),
      child: Padding(
        padding: ResponsiveService.getMediumPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Metabolic Health',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            latestScoreAsync.when(
              data: (score) => _ScoreDisplay(score: score),
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (e, st) => Text(
                    '—',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: historyAsync.when(
                data:
                    (history) => _SparkLine(history: history.reversed.toList()),
                loading: () => const SizedBox.shrink(),
                error: (e, st) => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreDisplay extends StatelessWidget {
  const _ScoreDisplay({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    final color = Color.lerp(Colors.red, Colors.green, score / 100)!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          score.toStringAsFixed(0),
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Text('/100', style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _SparkLine extends StatelessWidget {
  const _SparkLine({required this.history});

  final List<double> history;

  @override
  Widget build(BuildContext context) {
    final spots = List.generate(
      history.length,
      (i) => FlSpot(i.toDouble(), history[i]),
    );

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            dotData: const FlDotData(show: false),
            spots: spots,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 2,
          ),
        ],
        minY: 0,
        maxY: 100,
      ),
    );
  }
}
