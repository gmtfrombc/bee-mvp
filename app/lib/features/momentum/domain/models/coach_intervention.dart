/// Data model for coach interventions in the momentum feature
///
/// This model represents a coach intervention with all necessary properties
/// for dashboard display and management. It follows the domain-driven design
/// patterns established in the momentum feature.
class CoachIntervention {
  final String id;
  final String patientName;
  final InterventionType type;
  final InterventionPriority priority;
  final InterventionStatus status;
  final DateTime? scheduledAt;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final String? notes;
  final String? reason;
  final Map<String, dynamic>? momentumData;

  const CoachIntervention({
    required this.id,
    required this.patientName,
    required this.type,
    required this.priority,
    required this.status,
    this.scheduledAt,
    this.createdAt,
    this.completedAt,
    this.notes,
    this.reason,
    this.momentumData,
  });

  /// Factory constructor for creating sample data
  factory CoachIntervention.sample({
    String? id,
    String? patientName,
    InterventionType? type,
    InterventionPriority? priority,
    InterventionStatus? status,
  }) {
    return CoachIntervention(
      id: id ?? 'sample-intervention-001',
      patientName: patientName ?? 'John Doe',
      type: type ?? InterventionType.checkIn,
      priority: priority ?? InterventionPriority.medium,
      status: status ?? InterventionStatus.pending,
      scheduledAt: DateTime.now().add(const Duration(hours: 2)),
      createdAt: DateTime.now(),
      notes: 'Weekly wellness check-in call',
      reason: 'Scheduled routine wellness assessment',
    );
  }

  /// Copy with method for immutable updates
  CoachIntervention copyWith({
    String? id,
    String? patientName,
    InterventionType? type,
    InterventionPriority? priority,
    InterventionStatus? status,
    DateTime? scheduledAt,
    DateTime? createdAt,
    DateTime? completedAt,
    String? notes,
    String? reason,
    Map<String, dynamic>? momentumData,
  }) {
    return CoachIntervention(
      id: id ?? this.id,
      patientName: patientName ?? this.patientName,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      reason: reason ?? this.reason,
      momentumData: momentumData ?? this.momentumData,
    );
  }

  /// Convert to JSON for API communication and caching
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_name': patientName,
      'type': type.name,
      'priority': priority.name,
      'status': status.name,
      if (scheduledAt != null) 'scheduled_at': scheduledAt!.toIso8601String(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      if (notes != null) 'notes': notes,
      if (reason != null) 'reason': reason,
      if (momentumData != null) 'momentum_data': momentumData,
    };
  }

  /// Create from JSON for API responses and cache restoration
  factory CoachIntervention.fromJson(Map<String, dynamic> json) {
    return CoachIntervention(
      id: json['id'] as String? ?? '',
      patientName: json['patient_name'] as String? ?? 'Unknown Patient',
      type: _parseInterventionType(json['type'] as String?),
      priority: _parseInterventionPriority(json['priority'] as String?),
      status: _parseInterventionStatus(json['status'] as String?),
      scheduledAt:
          json['scheduled_at'] != null
              ? DateTime.tryParse(json['scheduled_at'] as String)
              : null,
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at'] as String)
              : null,
      completedAt:
          json['completed_at'] != null
              ? DateTime.tryParse(json['completed_at'] as String)
              : null,
      notes: json['notes'] as String?,
      reason: json['reason'] as String?,
      momentumData: json['momentum_data'] as Map<String, dynamic>?,
    );
  }

  /// Create from Map for backward compatibility with existing code
  factory CoachIntervention.fromMap(Map<String, dynamic> map) {
    return CoachIntervention.fromJson(map);
  }

  /// Convert to Map for backward compatibility with existing code
  Map<String, dynamic> toMap() {
    return toJson();
  }

  /// Get formatted type string for display
  String get typeDisplayName {
    switch (type) {
      case InterventionType.checkIn:
        return 'Check-in Call';
      case InterventionType.momentumSupport:
        return 'Momentum Support';
      case InterventionType.medicationReminder:
        return 'Medication Reminder';
      case InterventionType.wellnessCheck:
        return 'Wellness Check';
      case InterventionType.crisisIntervention:
        return 'Crisis Intervention';
      case InterventionType.followUp:
        return 'Follow-up Call';
    }
  }

  /// Get formatted priority string for display
  String get priorityDisplayName {
    switch (priority) {
      case InterventionPriority.low:
        return 'Low';
      case InterventionPriority.medium:
        return 'Medium';
      case InterventionPriority.high:
        return 'High';
      case InterventionPriority.urgent:
        return 'Urgent';
    }
  }

  /// Get formatted status string for display
  String get statusDisplayName {
    switch (status) {
      case InterventionStatus.pending:
        return 'Pending';
      case InterventionStatus.inProgress:
        return 'In Progress';
      case InterventionStatus.completed:
        return 'Completed';
      case InterventionStatus.cancelled:
        return 'Cancelled';
      case InterventionStatus.noResponse:
        return 'No Response';
    }
  }

  /// Check if intervention is active (not completed or cancelled)
  bool get isActive {
    return status == InterventionStatus.pending ||
        status == InterventionStatus.inProgress;
  }

  /// Check if intervention is scheduled for today
  bool get isScheduledToday {
    if (scheduledAt == null) return false;
    final now = DateTime.now();
    final scheduled = scheduledAt!;
    return scheduled.year == now.year &&
        scheduled.month == now.month &&
        scheduled.day == now.day;
  }

  /// Get formatted scheduled time string
  String? get formattedScheduledTime {
    if (scheduledAt == null) return null;
    final time = scheduledAt!;
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Get time ago string for display
  String? get timeAgoString {
    if (createdAt == null) return null;
    final now = DateTime.now();
    final difference = now.difference(createdAt!);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays != 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours != 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes != 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoachIntervention &&
        other.id == id &&
        other.patientName == patientName &&
        other.type == type &&
        other.priority == priority &&
        other.status == status &&
        other.scheduledAt == scheduledAt &&
        other.createdAt == createdAt &&
        other.completedAt == completedAt &&
        other.notes == notes &&
        other.reason == reason;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      patientName,
      type,
      priority,
      status,
      scheduledAt,
      createdAt,
      completedAt,
      notes,
      reason,
    );
  }

  @override
  String toString() {
    return 'CoachIntervention(id: $id, patientName: $patientName, type: $type, priority: $priority, status: $status)';
  }

  // Private helper methods for parsing enums with fallbacks
  static InterventionType _parseInterventionType(String? typeString) {
    if (typeString == null) return InterventionType.checkIn;
    switch (typeString.toLowerCase()) {
      case 'check_in':
      case 'checkin':
      case 'check-in':
        return InterventionType.checkIn;
      case 'momentum_support':
      case 'momentumsupport':
      case 'momentum-support':
        return InterventionType.momentumSupport;
      case 'medication_reminder':
      case 'medicationreminder':
      case 'medication-reminder':
        return InterventionType.medicationReminder;
      case 'wellness_check':
      case 'wellnesscheck':
      case 'wellness-check':
        return InterventionType.wellnessCheck;
      case 'crisis_intervention':
      case 'crisisintervention':
      case 'crisis-intervention':
        return InterventionType.crisisIntervention;
      case 'follow_up':
      case 'followup':
      case 'follow-up':
        return InterventionType.followUp;
      default:
        return InterventionType.checkIn;
    }
  }

  static InterventionPriority _parseInterventionPriority(
    String? priorityString,
  ) {
    if (priorityString == null) return InterventionPriority.medium;
    switch (priorityString.toLowerCase()) {
      case 'low':
        return InterventionPriority.low;
      case 'medium':
        return InterventionPriority.medium;
      case 'high':
        return InterventionPriority.high;
      case 'urgent':
        return InterventionPriority.urgent;
      default:
        return InterventionPriority.medium;
    }
  }

  static InterventionStatus _parseInterventionStatus(String? statusString) {
    if (statusString == null) return InterventionStatus.pending;
    switch (statusString.toLowerCase()) {
      case 'pending':
        return InterventionStatus.pending;
      case 'in_progress':
      case 'inprogress':
      case 'in-progress':
        return InterventionStatus.inProgress;
      case 'completed':
        return InterventionStatus.completed;
      case 'cancelled':
      case 'canceled':
        return InterventionStatus.cancelled;
      case 'no_response':
      case 'noresponse':
      case 'no-response':
        return InterventionStatus.noResponse;
      default:
        return InterventionStatus.pending;
    }
  }
}

/// Types of coach interventions available in the system
enum InterventionType {
  checkIn,
  momentumSupport,
  medicationReminder,
  wellnessCheck,
  crisisIntervention,
  followUp,
}

/// Priority levels for coach interventions
enum InterventionPriority { low, medium, high, urgent }

/// Status values for coach interventions
enum InterventionStatus {
  pending,
  inProgress,
  completed,
  cancelled,
  noResponse,
}
