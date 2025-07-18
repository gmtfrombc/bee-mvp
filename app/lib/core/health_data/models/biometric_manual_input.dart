import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

/// Supported manual biometric types.
enum BiometricType {
  weight,
  systolicBP,
  diastolicBP,
  heartRate,
  bodyFat;

  String get label {
    switch (this) {
      case BiometricType.weight:
        return 'Weight';
      case BiometricType.systolicBP:
        return 'Systolic BP';
      case BiometricType.diastolicBP:
        return 'Diastolic BP';
      case BiometricType.heartRate:
        return 'Heart Rate';
      case BiometricType.bodyFat:
        return 'Body Fat %';
    }
  }
}

/// A single manually-entered biometric measurement.
@immutable
class BiometricManualInput {
  final String id;
  final String userId;
  final BiometricType type;
  final double value;
  final String unit;
  final DateTime recordedAt;

  const BiometricManualInput({
    required this.id,
    required this.userId,
    required this.type,
    required this.value,
    required this.unit,
    required this.recordedAt,
  });

  factory BiometricManualInput.newInput({
    required String userId,
    required BiometricType type,
    required double value,
    required String unit,
    DateTime? recordedAt,
  }) {
    return BiometricManualInput(
      id: const Uuid().v4(),
      userId: userId,
      type: type,
      value: value,
      unit: unit,
      recordedAt: recordedAt ?? DateTime.now(),
    );
  }

  BiometricManualInput copyWith({
    String? id,
    String? userId,
    BiometricType? type,
    double? value,
    String? unit,
    DateTime? recordedAt,
  }) {
    return BiometricManualInput(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  factory BiometricManualInput.fromJson(Map<String, dynamic> json) {
    return BiometricManualInput(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: BiometricType.values.firstWhere((e) => e.name == json['type']),
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'type': type.name,
    'value': value,
    'unit': unit,
    'recorded_at': recordedAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BiometricManualInput &&
        other.id == id &&
        other.userId == userId &&
        other.type == type &&
        other.value == value &&
        other.unit == unit &&
        other.recordedAt == recordedAt;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      type.hashCode ^
      value.hashCode ^
      unit.hashCode ^
      recordedAt.hashCode;
}
