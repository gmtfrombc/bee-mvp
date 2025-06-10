/// Garmin Wizard Models
///
/// Data structures and step definitions for the Garmin→Apple Health
/// enablement wizard functionality.
library;

import 'package:flutter/cupertino.dart';

/// Data class for wizard step information
class GarminWizardStep {
  final String title;
  final String description;
  final List<String> instructions;
  final IconData icon;
  final bool isCompleted;

  const GarminWizardStep({
    required this.title,
    required this.description,
    required this.instructions,
    required this.icon,
    this.isCompleted = false,
  });

  GarminWizardStep copyWith({bool? isCompleted}) {
    return GarminWizardStep(
      title: title,
      description: description,
      instructions: instructions,
      icon: icon,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// State for the Garmin wizard
class GarminWizardState {
  final List<GarminWizardStep> steps;
  final int currentStepIndex;
  final bool isCompleted;
  final bool isDismissed;

  const GarminWizardState({
    required this.steps,
    this.currentStepIndex = 0,
    this.isCompleted = false,
    this.isDismissed = false,
  });

  GarminWizardState copyWith({
    List<GarminWizardStep>? steps,
    int? currentStepIndex,
    bool? isCompleted,
    bool? isDismissed,
  }) {
    return GarminWizardState(
      steps: steps ?? this.steps,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isCompleted: isCompleted ?? this.isCompleted,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }
}

/// Predefined wizard steps for Garmin→Apple Health setup
class GarminWizardSteps {
  static List<GarminWizardStep> getInitialSteps() {
    return [
      const GarminWizardStep(
        title: 'Install Garmin Connect',
        description: 'Ensure you have the Garmin Connect app installed',
        icon: CupertinoIcons.download_circle,
        instructions: [
          'Download Garmin Connect from the App Store if not already installed',
          'Sign in to your Garmin account',
          'Make sure your Garmin device is connected and syncing data',
        ],
      ),
      const GarminWizardStep(
        title: 'Open Garmin Connect Settings',
        description: 'Navigate to the connected apps section',
        icon: CupertinoIcons.settings,
        instructions: [
          'Open the Garmin Connect app',
          'Tap "More" in the bottom right navigation',
          'Tap "Settings"',
          'Scroll down and tap "Connected Apps"',
        ],
      ),
      const GarminWizardStep(
        title: 'Connect to Apple Health',
        description: 'Enable Apple Health integration in Garmin Connect',
        icon: CupertinoIcons.heart,
        instructions: [
          'In Connected Apps, look for "Apple Health"',
          'Tap "Apple Health" to open the connection page',
          'Tap "Connect" or "Enable" button',
          'Allow Garmin Connect to access Apple Health when prompted',
        ],
      ),
      const GarminWizardStep(
        title: 'Configure Health Permissions',
        description: 'Set Garmin as primary data source in Apple Health',
        icon: CupertinoIcons.lock_shield,
        instructions: [
          'Open the Apple Health app',
          'Tap "Sharing" at the bottom center',
          'Scroll down and tap "Apps"',
          'Tap "Garmin Connect" and verify all data types are enabled',
          'Go back and tap "Summary" tab',
          'Tap "Steps" → "Data Sources & Access" → "Edit"',
          'Drag Garmin Connect to the top of the list',
        ],
      ),
      const GarminWizardStep(
        title: 'Disable iPhone Step Tracking',
        description: 'Prevent duplicate step counting from iPhone',
        icon: CupertinoIcons.device_phone_portrait,
        instructions: [
          'Open iPhone Settings app',
          'Scroll down to "Privacy & Security"',
          'Tap "Motion & Fitness"',
          'Turn OFF "Fitness Tracking"',
          'This prevents duplicate step counting from your iPhone',
        ],
      ),
      const GarminWizardStep(
        title: 'Verify Data Sync',
        description: 'Confirm Garmin data is flowing to Apple Health',
        icon: CupertinoIcons.checkmark_circle,
        instructions: [
          'Take a short walk (50+ steps) with your Garmin device',
          'Open Garmin Connect and wait for sync to complete',
          'Open Apple Health and check if new steps appear',
          'Verify heart rate and other data is also syncing',
          'Data may take 5-15 minutes to appear in Apple Health',
        ],
      ),
    ];
  }
}
