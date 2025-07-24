/// Model representing one row in the `action_step_logs` table.
///
/// This model intentionally contains only the columns we need on the client
/// (primary key, foreign key, date and status). Add new fields if they become
/// required in future iterations.
///
/// The `status` column maps to [ActionStepDayStatus] enum values.
///
/// Be mindful that the Supabase row serialises `day` as an ISO-8601 string in
/// UTC (yyyy-mm-dd). We store it as a local [DateTime] for easier comparison
/// but always truncate the time component when serialising back to JSON.
///
/// Keep this file in sync with any database migrations that touch the
/// `action_step_logs` table.

library action_step_log;

import 'package:app/features/action_steps/models/action_step_day_status.dart';

class ActionStepLog {
  const ActionStepLog({
    required this.id,
    required this.actionStepId,
    required this.day,
    required this.status,
  });

  final String id;
  final String actionStepId;
  final DateTime day;
  final ActionStepDayStatus status;

  factory ActionStepLog.fromJson(Map<String, dynamic> json) {
    return ActionStepLog(
      id: json['id'] as String,
      actionStepId: json['action_step_id'] as String,
      day: DateTime.parse(json['day'] as String),
      status: _statusFromJson(json['status'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action_step_id': actionStepId,
      'day': _formatDate(day),
      'status': status.name,
    };
  }

  static ActionStepDayStatus _statusFromJson(String raw) {
    return ActionStepDayStatus.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => ActionStepDayStatus.queued,
    );
  }

  /// Returns an ISO-8601 formatted **date** string (no time component).
  String _formatDate(DateTime d) => d.toIso8601String().substring(0, 10);
}
