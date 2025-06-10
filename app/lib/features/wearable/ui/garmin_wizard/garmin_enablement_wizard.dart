/// Garmin→Apple Health Enablement Wizard
///
/// Main wizard widget that orchestrates the step-by-step instructions for
/// enabling Garmin Connect to write health data to Apple Health.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/responsive_service.dart';
import 'garmin_wizard_provider.dart';
import 'garmin_wizard_components.dart';

/// Main Garmin Enablement Wizard Widget
class GarminEnablementWizard extends ConsumerWidget {
  final VoidCallback? onCompleted;
  final VoidCallback? onDismissed;

  const GarminEnablementWizard({super.key, this.onCompleted, this.onDismissed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(garminWizardProvider);

    if (state.isDismissed) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ResponsiveService.getBorderRadius(context)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandleBar(context),
          Flexible(
            child: SingleChildScrollView(
              padding: ResponsiveService.getLargePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const GarminWizardHeader(),
                  SizedBox(height: ResponsiveService.getLargeSpacing(context)),
                  GarminWizardProgressIndicator(state: state),
                  SizedBox(height: ResponsiveService.getLargeSpacing(context)),
                  GarminWizardStepsContent(state: state),
                  SizedBox(height: ResponsiveService.getLargeSpacing(context)),
                  GarminWizardActions(
                    state: state,
                    onCompleted: onCompleted,
                    onDismissed: onDismissed,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandleBar(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      margin: EdgeInsets.only(
        top: ResponsiveService.getSmallSpacing(context),
        bottom: ResponsiveService.getMediumSpacing(context),
      ),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Helper function to show the Garmin enablement wizard
Future<void> showGarminEnablementWizard(
  BuildContext context, {
  VoidCallback? onCompleted,
  VoidCallback? onDismissed,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (context) => GarminEnablementWizard(
          onCompleted: onCompleted,
          onDismissed: onDismissed,
        ),
  );
}
