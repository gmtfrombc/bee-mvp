import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/momentum_data.dart';
import 'momentum_detail_animations.dart';
import 'momentum_detail_actions.dart';
import 'momentum_detail_content.dart';

/// Detail modal that shows comprehensive momentum breakdown
/// Triggered when user taps on MomentumCard
/// Optimized for performance with extracted components and improved structure
class MomentumDetailModal extends StatelessWidget {
  final MomentumData momentumData;

  const MomentumDetailModal({super.key, required this.momentumData});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: MomentumDetailAnimations(
          child: Container(
            margin: const EdgeInsets.only(top: 80),
            decoration: BoxDecoration(
              color: AppTheme.getSurfacePrimary(context),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                MomentumDetailActions(
                  momentumData: momentumData,
                  onClose: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: MomentumDetailContent(momentumData: momentumData),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Show the momentum detail modal
void showMomentumDetailModal(BuildContext context, MomentumData momentumData) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => MomentumDetailModal(momentumData: momentumData),
  );
}
