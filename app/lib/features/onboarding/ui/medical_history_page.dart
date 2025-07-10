import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/medical_history.dart';
import '../../../core/services/responsive_service.dart';
import '../onboarding_controller.dart';

/// Onboarding step for selecting relevant medical conditions (Section 6).
class MedicalHistoryPage extends ConsumerWidget {
  const MedicalHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ResponsiveService.getSmallSpacing(context);
    final controller = ref.watch(onboardingControllerProvider.notifier);
    final draft = ref.watch(onboardingControllerProvider);

    final crossAxisCount = _getCrossAxisCount(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Medical History')),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: ResponsiveService.getMediumPadding(context),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: 3.5,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final condition = MedicalCondition.values[index];
                return _ConditionTile(
                  condition: condition,
                  selected: draft.medicalConditions.contains(condition),
                  onChanged: () => controller.toggleMedicalCondition(condition),
                );
              }, childCount: MedicalCondition.values.length),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(spacing * 2),
              child: Center(
                child: ElevatedButton(
                  key: const ValueKey('continue_button'),
                  onPressed:
                      draft.medicalConditions.isNotEmpty
                          ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Medical history saved!'),
                              ),
                            );
                            Navigator.of(context).pop(); // Finish onboarding
                          }
                          : null,
                  child: const Text('Finish'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    switch (ResponsiveService.getDeviceType(context)) {
      case DeviceType.mobileSmall:
      case DeviceType.mobile:
        return 2;
      case DeviceType.mobileLarge:
        return 3;
      case DeviceType.tablet:
      case DeviceType.desktop:
        return 4;
    }
  }
}

class _ConditionTile extends StatelessWidget {
  const _ConditionTile({
    required this.condition,
    required this.selected,
    required this.onChanged,
  });

  final MedicalCondition condition;
  final bool selected;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final label = kMedicalConditionLabels[condition] ?? condition.name;
    return InkWell(
      onTap: onChanged,
      child: Row(
        children: [
          Checkbox(value: selected, onChanged: (_) => onChanged()),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
