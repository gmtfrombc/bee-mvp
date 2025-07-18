import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

/// A calculated metabolic score summarising various biometrics.
@immutable
class MetabolicScore {
  final String id;
  final String userId;
  final double score;
  final DateTime recordedAt;

  const MetabolicScore({
    required this.id,
    required this.userId,
    required this.score,
    required this.recordedAt,
  });

  factory MetabolicScore.newScore({
    required String userId,
    required double score,
    DateTime? recordedAt,
  }) {
    return MetabolicScore(
      id: const Uuid().v4(),
      userId: userId,
      score: score,
      recordedAt: recordedAt ?? DateTime.now(),
    );
  }

  MetabolicScore copyWith({
    String? id,
    String? userId,
    double? score,
    DateTime? recordedAt,
  }) {
    return MetabolicScore(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      score: score ?? this.score,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  factory MetabolicScore.fromJson(Map<String, dynamic> json) {
    return MetabolicScore(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      score: (json['score'] as num).toDouble(),
      recordedAt: DateTime.parse(json['recorded_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'score': score,
    'recorded_at': recordedAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MetabolicScore &&
        other.id == id &&
        other.userId == userId &&
        other.score == score &&
        other.recordedAt == recordedAt;
  }

  @override
  int get hashCode =>
      id.hashCode ^ userId.hashCode ^ score.hashCode ^ recordedAt.hashCode;
}
