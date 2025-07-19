import 'package:meta/meta.dart';

/// Supported biometric flag types.
/// Matches `flag_type` CHECK constraint in the `biometric_flags` table.
/// Values **must** remain in sync with Supabase migration.
enum BiometricFlagType {
  lowSteps,
  lowSleep;

  String get dbValue {
    switch (this) {
      case BiometricFlagType.lowSteps:
        return 'low_steps';
      case BiometricFlagType.lowSleep:
        return 'low_sleep';
    }
  }

  static BiometricFlagType fromDb(String value) {
    switch (value) {
      case 'low_steps':
        return BiometricFlagType.lowSteps;
      case 'low_sleep':
        return BiometricFlagType.lowSleep;
      default:
        throw ArgumentError('Unknown flag_type: $value');
    }
  }
}

/// Immutable model representing a row in the `biometric_flags` table.
@immutable
class BiometricFlag {
  final String id;
  final String userId;
  final BiometricFlagType type;
  final DateTime detectedOn;
  final Map<String, dynamic>? details;
  final bool resolved;

  const BiometricFlag({
    required this.id,
    required this.userId,
    required this.type,
    required this.detectedOn,
    this.details,
    required this.resolved,
  });

  factory BiometricFlag.fromJson(Map<String, dynamic> json) {
    return BiometricFlag(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: BiometricFlagType.fromDb(json['flag_type'] as String),
      detectedOn: DateTime.parse(json['detected_on'] as String),
      details: json['details'] as Map<String, dynamic>?,
      resolved: json['resolved'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'flag_type': type.dbValue,
    'detected_on': detectedOn.toIso8601String(),
    'details': details,
    'resolved': resolved,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BiometricFlag &&
        other.id == id &&
        other.userId == userId &&
        other.type == type &&
        other.detectedOn == detectedOn &&
        other.resolved == resolved;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      type.hashCode ^
      detectedOn.hashCode ^
      resolved.hashCode;
}
