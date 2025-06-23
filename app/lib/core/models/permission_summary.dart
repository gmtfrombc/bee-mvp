/// Summary of health permission status across all required metrics.
///
/// Useful for UI widgets that need a single tri-state value:
///   • granted  – all required permissions authorised
///   • partial  – some granted, some denied
///   • denied   – none granted
///
/// It also keeps a map of individual metric statuses so detail views can
/// display per-metric rows.
///
/// This file is intentionally standalone (no Flutter imports) so it can be
/// re-used by core services and unit tests without widget deps.
library;

import '../services/wearable_data_models.dart';
import '../services/health_permission_manager.dart' show PermissionCacheEntry;

enum PermissionAggregateState { granted, partial, denied }

class PermissionSummary {
  final Map<WearableDataType, bool> status;
  final DateTime generatedAt;

  PermissionSummary({required this.status}) : generatedAt = DateTime.now();

  int get grantedCount => status.values.where((v) => v).length;
  int get totalCount => status.length;
  int get deniedCount => totalCount - grantedCount;

  PermissionAggregateState get state {
    if (grantedCount == 0) return PermissionAggregateState.denied;
    if (grantedCount == totalCount) return PermissionAggregateState.granted;
    return PermissionAggregateState.partial;
  }

  bool get isGranted => state == PermissionAggregateState.granted;
  bool get isDenied => state == PermissionAggregateState.denied;

  /// Whether at least one permission is granted (used for simple "Connected" indicator)
  bool get isConnected => grantedCount > 0;

  List<WearableDataType> get missingTypes =>
      status.entries.where((e) => !e.value).map((e) => e.key).toList();

  factory PermissionSummary.fromCache(
    Map<WearableDataType, PermissionCacheEntry> cache,
  ) {
    return PermissionSummary(
      status: {
        for (final entry in cache.entries) entry.key: entry.value.isGranted,
      },
    );
  }
}
