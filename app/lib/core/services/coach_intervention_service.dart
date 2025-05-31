import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../notifications/domain/services/notification_preferences_service.dart';

/// Service for managing automated coach interventions and call scheduling
class CoachInterventionService {
  static CoachInterventionService? _instance;
  static CoachInterventionService get instance {
    _instance ??= CoachInterventionService._();
    return _instance!;
  }

  CoachInterventionService._();

  final _supabase = Supabase.instance.client;
  final _prefsService = NotificationPreferencesService.instance;

  /// Schedule a coach intervention based on momentum patterns
  Future<InterventionResult> scheduleIntervention({
    required String userId,
    required InterventionType type,
    required InterventionPriority priority,
    String? reason,
    Map<String, dynamic>? momentumData,
  }) async {
    try {
      // Check if user has intervention notifications enabled
      if (!_prefsService.interventionNotificationsEnabled) {
        if (kDebugMode) {
          print('🚫 Coach intervention blocked by user preferences');
        }
        return InterventionResult(
          success: false,
          error: 'Intervention notifications disabled by user',
          interventionId: null,
        );
      }

      // Create intervention record
      final response =
          await _supabase
              .from('coach_interventions')
              .insert({
                'user_id': userId,
                'intervention_type': type.name,
                'priority': priority.name,
                'reason': reason ?? _getDefaultReason(type),
                'status': InterventionStatus.scheduled.name,
                'momentum_data': momentumData,
                'scheduled_at': _calculateScheduledTime(priority),
                'created_at': DateTime.now().toIso8601String(),
              })
              .select()
              .single();

      final interventionId = response['id'] as String;

      // Schedule notification for the intervention
      await _scheduleInterventionNotification(
        interventionId: interventionId,
        userId: userId,
        type: type,
        priority: priority,
      );

      if (kDebugMode) {
        print(
          '✅ Coach intervention scheduled: $interventionId (${type.name}, ${priority.name})',
        );
      }

      return InterventionResult(
        success: true,
        interventionId: interventionId,
        scheduledAt: DateTime.parse(response['scheduled_at']),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error scheduling coach intervention: $e');
      }
      return InterventionResult(
        success: false,
        error: e.toString(),
        interventionId: null,
      );
    }
  }

  /// Get pending interventions for a user
  Future<List<CoachIntervention>> getPendingInterventions({
    String? userId,
  }) async {
    try {
      final currentUserId = userId ?? _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('No user ID provided and no current user');
      }

      final response = await _supabase
          .from('coach_interventions')
          .select()
          .eq('user_id', currentUserId)
          .inFilter('status', [
            InterventionStatus.scheduled.name,
            InterventionStatus.inProgress.name,
          ])
          .order('scheduled_at', ascending: true);

      return (response as List)
          .map((item) => CoachIntervention.fromJson(item))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting pending interventions: $e');
      }
      return [];
    }
  }

  /// Update intervention status
  Future<bool> updateInterventionStatus({
    required String interventionId,
    required InterventionStatus status,
    String? notes,
    DateTime? completedAt,
  }) async {
    try {
      await _supabase
          .from('coach_interventions')
          .update({
            'status': status.name,
            if (notes != null) 'notes': notes,
            if (completedAt != null)
              'completed_at': completedAt.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', interventionId);

      if (kDebugMode) {
        print(
          '✅ Intervention status updated: $interventionId -> ${status.name}',
        );
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating intervention status: $e');
      }
      return false;
    }
  }

  /// Check if user needs intervention based on momentum patterns
  Future<InterventionRecommendation?> checkInterventionNeeded({
    required String userId,
    required Map<String, dynamic> momentumData,
  }) async {
    try {
      // Call Supabase function to analyze momentum patterns
      final response = await _supabase.functions.invoke(
        'analyze-intervention-need',
        body: {'user_id': userId, 'momentum_data': momentumData},
      );

      if (response.status == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (data['needs_intervention'] == true) {
          return InterventionRecommendation.fromJson(data);
        }
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking intervention need: $e');
      }
      return null;
    }
  }

  /// Schedule intervention notification
  Future<void> _scheduleInterventionNotification({
    required String interventionId,
    required String userId,
    required InterventionType type,
    required InterventionPriority priority,
  }) async {
    try {
      await _supabase.functions.invoke(
        'schedule-intervention-notification',
        body: {
          'intervention_id': interventionId,
          'user_id': userId,
          'intervention_type': type.name,
          'priority': priority.name,
          'scheduled_at': _calculateScheduledTime(priority).toIso8601String(),
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error scheduling intervention notification: $e');
      }
    }
  }

  /// Calculate when intervention should be scheduled based on priority
  DateTime _calculateScheduledTime(InterventionPriority priority) {
    final now = DateTime.now();

    switch (priority) {
      case InterventionPriority.urgent:
        // Schedule within 1 hour
        return now.add(const Duration(hours: 1));
      case InterventionPriority.high:
        // Schedule within 4 hours
        return now.add(const Duration(hours: 4));
      case InterventionPriority.medium:
        // Schedule within 24 hours
        return now.add(const Duration(hours: 24));
      case InterventionPriority.low:
        // Schedule within 3 days
        return now.add(const Duration(days: 3));
    }
  }

  /// Get default reason for intervention type
  String _getDefaultReason(InterventionType type) {
    switch (type) {
      case InterventionType.momentumDrop:
        return 'Significant momentum decrease detected';
      case InterventionType.consecutiveNeedsCare:
        return 'Multiple consecutive days in "Needs Care" state';
      case InterventionType.inactivity:
        return 'Extended period of inactivity detected';
      case InterventionType.supportRequest:
        return 'User requested support';
      case InterventionType.checkIn:
        return 'Scheduled wellness check-in';
    }
  }

  /// Get intervention history for analytics
  Future<List<CoachIntervention>> getInterventionHistory({
    String? userId,
    int limit = 50,
  }) async {
    try {
      final currentUserId = userId ?? _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('No user ID provided and no current user');
      }

      final response = await _supabase
          .from('coach_interventions')
          .select()
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((item) => CoachIntervention.fromJson(item))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting intervention history: $e');
      }
      return [];
    }
  }

  /// Get dashboard overview data
  Future<Map<String, dynamic>> getDashboardOverview() async {
    try {
      final response = await _supabase.functions.invoke(
        'get-coach-dashboard-overview',
        body: {},
      );

      if (response.status == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }

      // Return mock data if function not available
      return {
        'stats': {
          'active': 5,
          'scheduled_today': 3,
          'completed_week': 12,
          'high_priority': 2,
        },
        'recent_activities': [
          {
            'type': 'intervention_created',
            'timestamp':
                DateTime.now()
                    .subtract(const Duration(hours: 2))
                    .toIso8601String(),
            'patient_name': 'John Doe',
            'description': 'Momentum drop intervention scheduled',
          },
          {
            'type': 'intervention_completed',
            'timestamp':
                DateTime.now()
                    .subtract(const Duration(hours: 4))
                    .toIso8601String(),
            'patient_name': 'Jane Smith',
            'description': 'Check-in call completed successfully',
          },
        ],
        'priority_breakdown': {'high': 2, 'medium': 8, 'low': 5},
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting dashboard overview: $e');
      }
      return {};
    }
  }

  /// Get active interventions
  Future<List<Map<String, dynamic>>> getActiveInterventions() async {
    try {
      final response = await _supabase
          .from('coach_interventions')
          .select('''
            *,
            profiles!inner(full_name)
          ''')
          .inFilter('status', [
            InterventionStatus.scheduled.name,
            InterventionStatus.inProgress.name,
          ])
          .order('scheduled_at', ascending: true);

      return (response as List).map((item) {
        final intervention = item as Map<String, dynamic>;
        return {
          ...intervention,
          'patient_name': intervention['profiles']?['full_name'] ?? 'Unknown',
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting active interventions: $e');
      }
      return [];
    }
  }

  /// Get scheduled interventions
  Future<List<Map<String, dynamic>>> getScheduledInterventions() async {
    try {
      final response = await _supabase
          .from('coach_interventions')
          .select('''
            *,
            profiles!inner(full_name)
          ''')
          .eq('status', InterventionStatus.scheduled.name)
          .order('scheduled_at', ascending: true);

      return (response as List).map((item) {
        final intervention = item as Map<String, dynamic>;
        return {
          ...intervention,
          'patient_name': intervention['profiles']?['full_name'] ?? 'Unknown',
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting scheduled interventions: $e');
      }
      return [];
    }
  }

  /// Complete an intervention
  Future<bool> completeIntervention(String interventionId) async {
    return updateInterventionStatus(
      interventionId: interventionId,
      status: InterventionStatus.completed,
      completedAt: DateTime.now(),
    );
  }

  /// Cancel an intervention
  Future<bool> cancelIntervention(String interventionId) async {
    return updateInterventionStatus(
      interventionId: interventionId,
      status: InterventionStatus.cancelled,
    );
  }

  /// Get intervention analytics
  Future<Map<String, dynamic>> getInterventionAnalytics(
    String timeRange,
  ) async {
    try {
      final response = await _supabase.functions.invoke(
        'get-intervention-analytics',
        body: {'time_range': timeRange},
      );

      if (response.status == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }

      // Return mock data if function not available
      return {
        'summary': {
          'success_rate': 85,
          'avg_response_time': 2.5,
          'total_interventions': 45,
          'satisfaction_score': 4.2,
        },
        'trends': [
          {'metric': 'Success Rate', 'change': 5.2},
          {'metric': 'Response Time', 'change': -12.3},
          {'metric': 'Patient Satisfaction', 'change': 8.1},
        ],
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting intervention analytics: $e');
      }
      return {};
    }
  }
}

/// Types of coach interventions
enum InterventionType {
  momentumDrop,
  consecutiveNeedsCare,
  inactivity,
  supportRequest,
  checkIn,
}

/// Intervention priority levels
enum InterventionPriority { urgent, high, medium, low }

/// Intervention status
enum InterventionStatus { scheduled, inProgress, completed, cancelled }

/// Result of scheduling an intervention
class InterventionResult {
  final bool success;
  final String? error;
  final String? interventionId;
  final DateTime? scheduledAt;

  InterventionResult({
    required this.success,
    this.error,
    this.interventionId,
    this.scheduledAt,
  });
}

/// Coach intervention model
class CoachIntervention {
  final String id;
  final String userId;
  final InterventionType type;
  final InterventionPriority priority;
  final InterventionStatus status;
  final String reason;
  final DateTime scheduledAt;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? notes;
  final Map<String, dynamic>? momentumData;

  CoachIntervention({
    required this.id,
    required this.userId,
    required this.type,
    required this.priority,
    required this.status,
    required this.reason,
    required this.scheduledAt,
    required this.createdAt,
    this.completedAt,
    this.notes,
    this.momentumData,
  });

  factory CoachIntervention.fromJson(Map<String, dynamic> json) {
    return CoachIntervention(
      id: json['id'],
      userId: json['user_id'],
      type: InterventionType.values.firstWhere(
        (e) => e.name == json['intervention_type'],
      ),
      priority: InterventionPriority.values.firstWhere(
        (e) => e.name == json['priority'],
      ),
      status: InterventionStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      reason: json['reason'],
      scheduledAt: DateTime.parse(json['scheduled_at']),
      createdAt: DateTime.parse(json['created_at']),
      completedAt:
          json['completed_at'] != null
              ? DateTime.parse(json['completed_at'])
              : null,
      notes: json['notes'],
      momentumData: json['momentum_data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'intervention_type': type.name,
      'priority': priority.name,
      'status': status.name,
      'reason': reason,
      'scheduled_at': scheduledAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      if (notes != null) 'notes': notes,
      if (momentumData != null) 'momentum_data': momentumData,
    };
  }
}

/// Recommendation for intervention
class InterventionRecommendation {
  final InterventionType type;
  final InterventionPriority priority;
  final String reason;
  final double confidence;
  final Map<String, dynamic> analysis;

  InterventionRecommendation({
    required this.type,
    required this.priority,
    required this.reason,
    required this.confidence,
    required this.analysis,
  });

  factory InterventionRecommendation.fromJson(Map<String, dynamic> json) {
    return InterventionRecommendation(
      type: InterventionType.values.firstWhere(
        (e) => e.name == json['intervention_type'],
      ),
      priority: InterventionPriority.values.firstWhere(
        (e) => e.name == json['priority'],
      ),
      reason: json['reason'],
      confidence: (json['confidence'] as num).toDouble(),
      analysis: json['analysis'] ?? {},
    );
  }
}

/// Riverpod provider for coach intervention service
final coachInterventionServiceProvider = Provider<CoachInterventionService>((
  ref,
) {
  return CoachInterventionService.instance;
});
