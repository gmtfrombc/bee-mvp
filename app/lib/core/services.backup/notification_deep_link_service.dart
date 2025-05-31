import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/momentum/presentation/providers/momentum_api_provider.dart';
import 'background_notification_handler.dart';
import 'coach_intervention_service.dart';

/// Service for handling deep links from notifications
class NotificationDeepLinkService {
  /// Process notification deep link
  static Future<void> processNotificationDeepLink({
    required String actionType,
    required Map<String, dynamic> actionData,
    required String notificationId,
    BuildContext? context,
    WidgetRef? ref,
  }) async {
    try {
      if (kDebugMode) {
        print('🔗 Processing deep link: $actionType with data: $actionData');
      }

      switch (actionType) {
        case 'view_momentum':
        case 'open_momentum_meter':
          await _handleMomentumDeepLink(actionData, context, ref);
          break;
        case 'schedule_call':
          await _handleScheduleCallDeepLink(actionData, context, ref);
          break;
        case 'complete_lesson':
          await _handleCompleteLessonDeepLink(actionData, context, ref);
          break;
        case 'open_app':
          await _handleOpenAppDeepLink(actionData, context, ref);
          break;
        default:
          if (kDebugMode) {
            print('⚠️ Unknown action type: $actionType');
          }
          // Default to opening momentum meter
          await _handleMomentumDeepLink(actionData, context, ref);
      }

      // Track the notification interaction
      await _trackNotificationInteraction(notificationId, actionType);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error processing deep link: $e');
      }
    }
  }

  /// Handle momentum meter deep link
  static Future<void> _handleMomentumDeepLink(
    Map<String, dynamic> actionData,
    BuildContext? context,
    WidgetRef? ref,
  ) async {
    if (kDebugMode) {
      print('📊 Opening momentum meter');
    }

    // Check if this is a celebration notification
    final isCelebration = actionData['celebration'] == true;

    if (isCelebration && ref != null) {
      // Trigger momentum refresh to show latest state
      final momentumController = ref.read(momentumControllerProvider);
      await momentumController.refresh();

      // Show celebration message if context available
      if (context != null && context.mounted) {
        _showCelebrationSnackBar(context);
      }
    }

    // For momentum meter, we're already on the main screen
    // Just ensure momentum data is refreshed
    if (ref != null) {
      final momentumController = ref.read(momentumControllerProvider);
      await momentumController.refresh();
    }
  }

  /// Handle schedule call deep link
  static Future<void> _handleScheduleCallDeepLink(
    Map<String, dynamic> actionData,
    BuildContext? context,
    WidgetRef? ref,
  ) async {
    if (kDebugMode) {
      print('📞 Opening schedule call flow');
    }

    final priority = actionData['priority'] as String?;
    final interventionType = actionData['intervention_type'] as String?;

    if (context != null && context.mounted) {
      // Show dialog to schedule call
      await _showScheduleCallDialog(
        context,
        priority: priority,
        interventionType: interventionType,
      );
    }
  }

  /// Handle complete lesson deep link
  static Future<void> _handleCompleteLessonDeepLink(
    Map<String, dynamic> actionData,
    BuildContext? context,
    WidgetRef? ref,
  ) async {
    if (kDebugMode) {
      print('📚 Opening lesson completion flow');
    }

    final suggestedLesson = actionData['suggested_lesson'] as String?;

    if (context != null && context.mounted) {
      // Show dialog with lesson suggestion
      await _showCompleteLessonDialog(
        context,
        suggestedLesson: suggestedLesson,
      );
    }
  }

  /// Handle open app deep link
  static Future<void> _handleOpenAppDeepLink(
    Map<String, dynamic> actionData,
    BuildContext? context,
    WidgetRef? ref,
  ) async {
    if (kDebugMode) {
      print('📱 Opening app with focus');
    }

    final focus = actionData['focus'] as String?;

    if (focus == 'momentum_meter' && ref != null) {
      // Refresh momentum data to show latest state
      final momentumController = ref.read(momentumControllerProvider);
      await momentumController.refresh();
    }

    // App is already open, just ensure latest data is loaded
  }

  /// Show celebration snackbar
  static void _showCelebrationSnackBar(BuildContext context) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.celebration, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Amazing momentum! Keep up the great work! 🎉',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show schedule call dialog
  static Future<void> _showScheduleCallDialog(
    BuildContext context, {
    String? priority,
    String? interventionType,
  }) async {
    if (!context.mounted) return;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.phone, color: Colors.blue),
              SizedBox(width: 8),
              Text('Schedule Support Call'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your coach is here to help you get back on track! Let\'s schedule a support call.',
                style: TextStyle(fontSize: 16),
              ),
              if (priority == 'high') ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.priority_high, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'High priority - We\'re here to support you!',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Maybe Later'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _launchScheduleCall();
              },
              icon: const Icon(Icons.calendar_today),
              label: const Text('Schedule Call'),
            ),
          ],
        );
      },
    );
  }

  /// Show complete lesson dialog
  static Future<void> _showCompleteLessonDialog(
    BuildContext context, {
    String? suggestedLesson,
  }) async {
    if (!context.mounted) return;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.school, color: Colors.green),
              SizedBox(width: 8),
              Text('Complete a Lesson'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Small steps lead to big changes! Let\'s complete a lesson to build momentum.',
                style: TextStyle(fontSize: 16),
              ),
              if (suggestedLesson != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Suggested: ${_formatLessonName(suggestedLesson)}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Not Now'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _launchLessonFlow(suggestedLesson);
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Lesson'),
            ),
          ],
        );
      },
    );
  }

  /// Format lesson name for display
  static String _formatLessonName(String lessonKey) {
    return lessonKey
        .split('_')
        .map((word) => word.substring(0, 1).toUpperCase() + word.substring(1))
        .join(' ');
  }

  /// Launch schedule call (placeholder for future implementation)
  static void _launchScheduleCall() {
    if (kDebugMode) {
      print('🚀 Launching schedule call flow');
    }

    // Schedule a coach intervention
    _scheduleCoachIntervention();
  }

  /// Schedule a coach intervention
  static Future<void> _scheduleCoachIntervention() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        if (kDebugMode) {
          print('❌ No user ID available for scheduling intervention');
        }
        return;
      }

      final result = await CoachInterventionService.instance
          .scheduleIntervention(
            userId: userId,
            type: InterventionType.supportRequest,
            priority: InterventionPriority.high,
            reason: 'User requested support through notification',
          );

      if (result.success) {
        if (kDebugMode) {
          print('✅ Coach intervention scheduled: ${result.interventionId}');
        }
      } else {
        if (kDebugMode) {
          print('❌ Failed to schedule intervention: ${result.error}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error scheduling coach intervention: $e');
      }
    }
  }

  /// Launch lesson flow (placeholder for future implementation)
  static void _launchLessonFlow(String? suggestedLesson) {
    if (kDebugMode) {
      print('🚀 Launching lesson flow: ${suggestedLesson ?? 'general'}');
    }
    // TODO: Implement actual lesson navigation
    // This could navigate to a lessons screen or external learning platform
  }

  /// Track notification interaction for analytics
  static Future<void> _trackNotificationInteraction(
    String notificationId,
    String actionType,
  ) async {
    try {
      if (kDebugMode) {
        print(
          '📊 Tracking notification interaction: $notificationId -> $actionType',
        );
      }

      // TODO: Implement actual analytics tracking
      // This could send events to analytics services like Firebase Analytics
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error tracking notification interaction: $e');
      }
    }
  }

  /// Process pending actions from background notifications
  static Future<void> processPendingActions({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    try {
      final pendingActions =
          await BackgroundNotificationHandler.getPendingActions();

      if (pendingActions.isEmpty) return;

      if (kDebugMode) {
        print(
          '🔄 Processing ${pendingActions.length} pending notification actions',
        );
      }

      // Check if context is still mounted before proceeding
      if (!context.mounted) return;

      // Process the most recent action
      final latestAction = pendingActions.last;

      await processNotificationDeepLink(
        actionType: latestAction.actionType,
        actionData: latestAction.actionData,
        notificationId: latestAction.notificationId,
        context: context,
        ref: ref,
      );

      // If there are multiple pending actions, show a summary
      if (pendingActions.length > 1 && context.mounted) {
        _showMultiplePendingActionsSnackBar(context, pendingActions.length);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error processing pending actions: $e');
      }
    }
  }

  /// Show snackbar for multiple pending actions
  static void _showMultiplePendingActionsSnackBar(
    BuildContext context,
    int actionCount,
  ) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'You have $actionCount notifications while away. Showing the latest.',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  /// Apply cached momentum updates from background processing
  static Future<void> applyCachedMomentumUpdates(WidgetRef ref) async {
    try {
      final cachedUpdate =
          await BackgroundNotificationHandler.getCachedMomentumUpdate();

      if (cachedUpdate != null) {
        if (kDebugMode) {
          print('📊 Applying cached momentum update: $cachedUpdate');
        }

        // Trigger a refresh to get the latest data
        final momentumController = ref.read(momentumControllerProvider);
        await momentumController.refresh();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error applying cached momentum updates: $e');
      }
    }
  }
}
