import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/services/coach_intervention_service.dart';
import '../../widgets/coach_dashboard/coach_intervention_card.dart';

class CoachScheduledInterventionsTab extends ConsumerWidget {
  const CoachScheduledInterventionsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interventionService = ref.watch(coachInterventionServiceProvider);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: interventionService.getScheduledInterventions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final interventions = snapshot.data ?? [];

        return interventions.isEmpty
            ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No scheduled interventions',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
            : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: interventions.length,
              itemBuilder: (context, index) {
                return CoachInterventionCard(
                  intervention: interventions[index],
                  service: interventionService,
                  onUpdate: () {
                    // Trigger rebuild when intervention is updated
                    (context as Element).markNeedsBuild();
                  },
                );
              },
            );
      },
    );
  }
}
