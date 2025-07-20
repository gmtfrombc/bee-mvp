part of 'health_permission_manager.dart';

/// Permission cache entry with metadata
class PermissionCacheEntry {
  final WearableDataType dataType;
  final bool isGranted;
  final DateTime lastChecked;
  final DateTime? grantedAt;
  final DateTime? deniedAt;
  final int denialCount;

  const PermissionCacheEntry({
    required this.dataType,
    required this.isGranted,
    required this.lastChecked,
    this.grantedAt,
    this.deniedAt,
    this.denialCount = 0,
  });

  PermissionCacheEntry copyWith({
    WearableDataType? dataType,
    bool? isGranted,
    DateTime? lastChecked,
    DateTime? grantedAt,
    DateTime? deniedAt,
    int? denialCount,
  }) {
    return PermissionCacheEntry(
      dataType: dataType ?? this.dataType,
      isGranted: isGranted ?? this.isGranted,
      lastChecked: lastChecked ?? this.lastChecked,
      grantedAt: grantedAt ?? this.grantedAt,
      deniedAt: deniedAt ?? this.deniedAt,
      denialCount: denialCount ?? this.denialCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dataType': dataType.name,
      'isGranted': isGranted,
      'lastChecked': lastChecked.toIso8601String(),
      'grantedAt': grantedAt?.toIso8601String(),
      'deniedAt': deniedAt?.toIso8601String(),
      'denialCount': denialCount,
    };
  }

  factory PermissionCacheEntry.fromMap(Map<String, dynamic> map) {
    return PermissionCacheEntry(
      dataType: WearableDataType.values.firstWhere(
        (e) => e.name == map['dataType'],
        orElse: () => WearableDataType.unknown,
      ),
      isGranted: map['isGranted'] ?? false,
      lastChecked: DateTime.parse(map['lastChecked']),
      grantedAt:
          map['grantedAt'] != null ? DateTime.parse(map['grantedAt']) : null,
      deniedAt:
          map['deniedAt'] != null ? DateTime.parse(map['deniedAt']) : null,
      denialCount: map['denialCount'] ?? 0,
    );
  }
}

/// Permission delta representing changes in permission status
class PermissionDelta {
  final WearableDataType dataType;
  final bool? previousStatus;
  final bool currentStatus;
  final DateTime timestamp;

  const PermissionDelta({
    required this.dataType,
    this.previousStatus,
    required this.currentStatus,
    required this.timestamp,
  });

  bool get isNewlyGranted => previousStatus == false && currentStatus == true;
  bool get isNewlyDenied => previousStatus == true && currentStatus == false;
  bool get isFirstTimeChecked => previousStatus == null;

  @override
  String toString() {
    return 'PermissionDelta(dataType: $dataType, previousStatus: $previousStatus, currentStatus: $currentStatus, timestamp: $timestamp)';
  }
}

/// Configuration for permission manager
class PermissionManagerConfig {
  final Duration cacheExpiration;
  final Duration toastDisplayDuration;
  final bool enableAutoRetry;
  final int maxRetryAttempts;
  final List<WearableDataType> requiredPermissions;

  const PermissionManagerConfig({
    this.cacheExpiration = const Duration(hours: 24),
    this.toastDisplayDuration = const Duration(seconds: 4),
    this.enableAutoRetry = true,
    this.maxRetryAttempts = 3,
    this.requiredPermissions = const [
      WearableDataType.steps,
      WearableDataType.heartRate,
      WearableDataType.sleepDuration,
      WearableDataType.restingHeartRate,
      WearableDataType.activeEnergyBurned,
      WearableDataType.heartRateVariability,
      WearableDataType.weight,
    ],
  });
}
