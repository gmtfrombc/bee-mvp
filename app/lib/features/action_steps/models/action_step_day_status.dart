/// Represents a user's check-in status for a single day of an Action Step.
///
/// Values map directly to the `status` column in `action_step_logs` (see
/// Supabase schema). Keep these in sync with database CHECK constraint.
///
/// * queued – User has not taken any action yet.
/// * completed – User marked the step as done.
/// * skipped – User explicitly skipped for the day.
///
/// Do **not** reorder these values; they are stored as strings in Supabase.
/// Prefer adding new values at the end if an extension is ever needed.
///
/// Make sure to update any serialization helpers if adding new values.
///
enum ActionStepDayStatus { queued, completed, skipped }
