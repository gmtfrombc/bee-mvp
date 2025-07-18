import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

/// Discrete buckets for perceived energy level reported by the user.
enum EnergyLevel {
  veryLow,
  low,
  medium,
  high,
  veryHigh;

  /// Returns a human-readable label.
  String get label {
    switch (this) {
      case EnergyLevel.veryLow:
        return 'Very Low';
      case EnergyLevel.low:
        return 'Low';
      case EnergyLevel.medium:
        return 'Medium';
      case EnergyLevel.high:
        return 'High';
      case EnergyLevel.veryHigh:
        return 'Very High';
    }
  }
}

/// Single entry of user-reported [EnergyLevel] at a point in time.
@immutable
class EnergyLevelEntry {
  final String id;
  final String userId;
  final EnergyLevel level;
  final DateTime recordedAt;

  const EnergyLevelEntry({
    required this.id,
    required this.userId,
    required this.level,
    required this.recordedAt,
  });

  /// Convenience constructor generating a new UUID and default timestamp.
  factory EnergyLevelEntry.newEntry({
    required String userId,
    required EnergyLevel level,
    DateTime? recordedAt,
  }) {
    return EnergyLevelEntry(
      id: const Uuid().v4(),
      userId: userId,
      level: level,
      recordedAt: recordedAt ?? DateTime.now(),
    );
  }

  EnergyLevelEntry copyWith({
    String? id,
    String? userId,
    EnergyLevel? level,
    DateTime? recordedAt,
  }) {
    return EnergyLevelEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      level: level ?? this.level,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  factory EnergyLevelEntry.fromJson(Map<String, dynamic> json) {
    return EnergyLevelEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      level: EnergyLevel.values.firstWhere((e) => e.name == json['level']),
      recordedAt: DateTime.parse(json['recorded_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'level': level.name,
    'recorded_at': recordedAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EnergyLevelEntry &&
        other.id == id &&
        other.userId == userId &&
        other.level == level &&
        other.recordedAt == recordedAt;
  }

  @override
  int get hashCode =>
      id.hashCode ^ userId.hashCode ^ level.hashCode ^ recordedAt.hashCode;
}
