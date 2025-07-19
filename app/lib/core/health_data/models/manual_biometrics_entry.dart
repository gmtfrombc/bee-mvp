import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

/// A row in the `manual_biometrics` Supabase table.
///
/// Values are stored in **metric units only** (kg and cm).
@immutable
class ManualBiometricsEntry {
  final String id;
  final String userId;
  final double weightKg;
  final double heightCm;
  final DateTime createdAt;

  const ManualBiometricsEntry({
    required this.id,
    required this.userId,
    required this.weightKg,
    required this.heightCm,
    required this.createdAt,
  });

  factory ManualBiometricsEntry.newEntry({
    required String userId,
    required double weightKg,
    required double heightCm,
    DateTime? createdAt,
  }) {
    return ManualBiometricsEntry(
      id: const Uuid().v4(),
      userId: userId,
      weightKg: weightKg,
      heightCm: heightCm,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  ManualBiometricsEntry copyWith({
    String? id,
    String? userId,
    double? weightKg,
    double? heightCm,
    DateTime? createdAt,
  }) {
    return ManualBiometricsEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ManualBiometricsEntry.fromJson(Map<String, dynamic> json) {
    return ManualBiometricsEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      weightKg: (json['weight_kg'] as num).toDouble(),
      heightCm: (json['height_cm'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'weight_kg': weightKg,
    'height_cm': heightCm,
    'created_at': createdAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ManualBiometricsEntry &&
        other.id == id &&
        other.userId == userId &&
        other.weightKg == weightKg &&
        other.heightCm == heightCm &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      weightKg.hashCode ^
      heightCm.hashCode ^
      createdAt.hashCode;
}
