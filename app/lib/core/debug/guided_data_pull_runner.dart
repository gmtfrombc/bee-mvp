/// Debug runner for guided data pull operation (T2.2.1.5-2)
///
/// Simple script to execute health data collection for validation.
/// Debug builds only.
library;

import 'package:flutter/foundation.dart';
import '../services/guided_data_pull_service.dart';

/// Execute guided data pull operation for validation
///
/// This function:
/// 1. Fetches last 24h of steps, heart rate, and sleep data
/// 2. Caches data locally using SharedPreferences
/// 3. Syncs data to Supabase wearable_health_data table
///
/// Returns operation result with metrics and any errors.
Future<Map<String, dynamic>> runGuidedDataPull() async {
  // Only allow in debug builds
  if (kReleaseMode) {
    throw StateError('Guided data pull: Not available in release builds');
  }

  debugPrint('========================================');
  debugPrint('🧪 GUIDED DATA PULL - T2.2.1.5-2');
  debugPrint('========================================');

  try {
    final service = GuidedDataPullService();
    final result = await service.executeDataPull();

    // Print summary
    debugPrint('========================================');
    debugPrint('📋 OPERATION SUMMARY:');
    debugPrint('Success: ${result['success']}');
    debugPrint('Total Samples: ${result['total_samples'] ?? 0}');
    debugPrint('Cached: ${result['cached_samples'] ?? 0}');
    debugPrint('Synced: ${result['synced_samples'] ?? 0}');
    debugPrint('Duration: ${result['execution_time_ms']}ms');

    if (result['data_types'] != null) {
      debugPrint('Data Types:');
      final types = result['data_types'] as Map<String, int>;
      for (final entry in types.entries) {
        debugPrint('  ${entry.key}: ${entry.value} samples');
      }
    }

    if (result['error'] != null) {
      debugPrint('❌ Error: ${result['error']}');
    }

    debugPrint('========================================');

    return result;
  } catch (e) {
    debugPrint('❌ Guided data pull failed: $e');
    debugPrint('========================================');

    return {'success': false, 'error': e.toString()};
  }
}

/// Get recent cached batches for validation
Future<Map<String, dynamic>> getRecentCachedData() async {
  if (kReleaseMode) return {};

  try {
    final service = GuidedDataPullService();
    return await service.getRecentCachedData();
  } catch (e) {
    debugPrint('ℹ️ Cache data unavailable: $e');
    return {};
  }
}

/// Clear cached data (for testing)
Future<void> clearGuidedDataCache() async {
  if (kReleaseMode) return;

  try {
    final service = GuidedDataPullService();
    await service.clearCache();
    debugPrint('✅ Guided data pull cache cleared');
  } catch (e) {
    debugPrint('❌ Failed to clear cache: $e');
  }
}
