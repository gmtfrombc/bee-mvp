import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

/// Single-day perceived energy score (1–5) recorded by the user.
@immutable
class PesEntry {
  final String id;
  final String userId;
  final DateTime date; // Only the calendar date (no time component)
  final int score; // 1–5 inclusive
  final DateTime createdAt;

  const PesEntry({
    required this.id,
    required this.userId,
    required this.date,
    required this.score,
    required this.createdAt,
  });

  /// Convenience factory generating a new entry for [date] with given [score].
  factory PesEntry.newEntry({
    required String userId,
    required DateTime date,
    required int score,
  }) {
    return PesEntry(
      id: const Uuid().v4(),
      userId: userId,
      date: date,
      score: score,
      createdAt: DateTime.now(),
    );
  }

  factory PesEntry.fromJson(Map<String, dynamic> json) {
    return PesEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      score: json['score'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    // Store as ISO8601 but keep only the date portion for DB compatibility.
    'date': date.toIso8601String().split('T').first,
    'score': score,
    'created_at': createdAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PesEntry &&
        other.id == id &&
        other.userId == userId &&
        other.date == date &&
        other.score == score &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      date.hashCode ^
      score.hashCode ^
      createdAt.hashCode;
}
