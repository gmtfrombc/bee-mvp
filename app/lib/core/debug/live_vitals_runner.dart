/// Debug runner for Live Vitals developer screen (T2.2.1.5-4)
///
/// Simple utility to access the Live Vitals developer screen for validation.
/// Debug builds only.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/navigation/routes.dart';

/// Open the Live Vitals developer screen for validation
///
/// This function provides easy access to the live vitals screen that shows:
/// - Last 5 seconds of heart rate & step deltas
/// - Real-time streaming controls
/// - Debug statistics and validation data
///
/// Only available in debug builds.
void openLiveVitalsScreen(BuildContext context) {
  // Only allow in debug builds
  if (kReleaseMode) {
    debugPrint('⚠️ Live Vitals Screen: Not available in release builds');
    return;
  }

  debugPrint('🔴 Opening Live Vitals Developer Screen');

  context.push(kLiveVitalsDebugRoute);
}

/// Check if Live Vitals screen is available
bool isLiveVitalsAvailable() {
  return kDebugMode && !kReleaseMode;
}

/// Get debug information about Live Vitals availability
Map<String, dynamic> getLiveVitalsDebugInfo() {
  return {
    'available': isLiveVitalsAvailable(),
    'debugMode': kDebugMode,
    'releaseMode': kReleaseMode,
    'description': 'Live vitals developer screen for T2.2.1.5-4 validation',
    'features': [
      'Real-time heart rate streaming',
      'Real-time step count streaming',
      'Last 5 seconds data window',
      'Delta calculation display',
      'Debug statistics',
      'Start/stop controls',
    ],
  };
}
