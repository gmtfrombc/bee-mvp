import 'package:app/core/services/responsive_service.dart';
import 'package:app/features/health_signals/pes/widgets/energy_input_slider.dart';
import 'package:app/features/health_signals/pes/widgets/pes_trend_sparkline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/health_signals/pes/pes_providers.dart';
import 'package:app/core/health_data/services/health_data_repository.dart';

/// Card that allows the user to log today’s perceived energy score (PES).
///
/// Behaviour:
/// – If no PES entry exists for today, shows an [EnergyInputSlider].
/// – After the user selects a score, calls `insertEnergyLevel()` and then
///   rebuilds to display [_ConfirmationState] followed by [PesTrendSparkline].
/// – If an entry already exists, shows the 7-day sparkline directly.
class PesCheckinCard extends ConsumerWidget {
  const PesCheckinCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayEntryAsync = ref.watch(todayPesEntryProvider);
    final spacing = ResponsiveService.getSmallSpacing(context);

    return todayEntryAsync.when(
      data: (entry) {
        if (entry == null) {
          // No entry – show slider for input
          return Card(
            margin: EdgeInsets.symmetric(
              horizontal: ResponsiveService.getResponsiveSpacing(context),
            ),
            child: Padding(
              padding: EdgeInsets.all(spacing * 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How energised do you feel today?',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  SizedBox(height: spacing * 2),
                  EnergyInputSlider(
                    onScoreSelected: (score) async {
                      // Save to Supabase
                      final repo = ref.read(healthDataRepositoryProvider);
                      await repo.insertEnergyLevel(
                        date: DateTime.now(),
                        score: score,
                      );

                      // Refresh providers
                      ref.invalidate(todayPesEntryProvider);
                      ref.invalidate(pesTrendProvider);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Energy logged!')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        }

        // Entry exists – show sparkline
        return Card(
          margin: EdgeInsets.symmetric(
            horizontal: ResponsiveService.getResponsiveSpacing(context),
          ),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: PesTrendSparkline(),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (err, _) => Card(
            margin: EdgeInsets.symmetric(
              horizontal: ResponsiveService.getResponsiveSpacing(context),
            ),
            child: Padding(
              padding: EdgeInsets.all(spacing * 2),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(width: spacing),
                  const Expanded(child: Text('Unable to load energy status')),
                ],
              ),
            ),
          ),
    );
  }
}
