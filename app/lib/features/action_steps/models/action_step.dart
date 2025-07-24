// ignore_for_file: public_member_api_docs

import 'package:equatable/equatable.dart';

/// Immutable model representing a saved Action Step fetched from Supabase.
///
/// Follows architecture rule – keep models in their own file under
/// `features/.../models`.
class ActionStep extends Equatable {
  const ActionStep({
    required this.id,
    required this.category,
    required this.description,
    required this.frequency,
    required this.weekStart,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String category;
  final String description;
  final int frequency;
  final DateTime weekStart;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ActionStep.fromJson(Map<String, dynamic> json) {
    return ActionStep(
      id: json['id'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      frequency: json['frequency'] as int,
      weekStart: DateTime.parse(json['week_start'] as String).toUtc(),
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'description': description,
      'frequency': frequency,
      'week_start': weekStart.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    category,
    description,
    frequency,
    weekStart,
    createdAt,
    updatedAt,
  ];
}
