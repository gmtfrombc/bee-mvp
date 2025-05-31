import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/services/notification_core_service.dart';
import '../../../features/momentum/presentation/providers/momentum_api_provider.dart';

/// Infrastructure service for handling notification navigation and routing
/// Focused purely on navigation logic without business rules
class NotificationDeepLinkService {
  /// Process notification deep link routing
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

      // First check if we need UI context for this action type
      final needsUIContext = _actionRequiresUIContext(actionType);

      // If UI context is needed, verify it's available and mounted NOW
      if (needsUIContext && (context == null || !context.mounted)) {
        if (kDebugMode) {
          print('⚠️ UI context required but not available for: $actionType');
        }
        return;
      }

      // Track the interaction first (no context needed)
      await _trackNotificationInteraction(notificationId, actionType);

      // Handle actions that don't need UI context first (no async gaps)
      if (!needsUIContext) {
        switch (actionType) {
          case 'view_momentum':
          case 'open_momentum_meter':
            await _handleMomentumNavigationNoContext(actionData, ref);
            // Handle celebration separately if needed
            if (actionData['celebration'] == true &&
                context != null &&
                context.mounted) {
              _showCelebrationSnackBar(context);
            }
            break;
          case 'open_app':
            await _handleOpenAppNavigationNoContext(actionData, ref);
            break;
          default:
            await _handleMomentumNavigationNoContext(actionData, ref);
            // Handle celebration separately if needed
            if (actionData['celebration'] == true &&
                context != null &&
                context.mounted) {
              _showCelebrationSnackBar(context);
            }
        }
        return;
      }

      // For UI-requiring actions, check mounted again after async tracking
      if (context == null || !context.mounted) {
        if (kDebugMode) {
          print('⚠️ Context unmounted after tracking for: $actionType');
        }
        return;
      }

      // Now handle UI actions safely
      switch (actionType) {
        case 'schedule_call':
          await _handleScheduleCallNavigationSafe(actionData, context);
          break;
        case 'complete_lesson':
          await _handleCompleteLessonNavigationSafe(actionData, context);
          break;
        default:
          if (kDebugMode) {
            print('⚠️ Unknown UI action type: $actionType');
          }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error processing deep link: $e');
      }
    }
  }

  /// Check if action type requires UI context
  static bool _actionRequiresUIContext(String actionType) {
    return actionType == 'schedule_call' || actionType == 'complete_lesson';
  }

  /// Handle momentum meter navigation without context (data operations only)
  static Future<void> _handleMomentumNavigationNoContext(
    Map<String, dynamic> actionData,
    WidgetRef? ref,
  ) async {
    if (kDebugMode) {
      print('📊 Navigating to momentum meter (data only)');
    }

    // Refresh momentum data (pure navigation action, no context needed)
    if (ref != null) {
      final momentumController = ref.read(momentumControllerProvider);
      await momentumController.refresh();
    }
  }

  /// Handle open app navigation without context (data operations only)
  static Future<void> _handleOpenAppNavigationNoContext(
    Map<String, dynamic> actionData,
    WidgetRef? ref,
  ) async {
    if (kDebugMode) {
      print('📱 Navigating within app (data only)');
    }

    final focus = actionData['focus'] as String?;

    if (focus == 'momentum_meter' && ref != null) {
      // Navigate to momentum focus and refresh data (no context needed)
      final momentumController = ref.read(momentumControllerProvider);
      await momentumController.refresh();
    }

    // App is already open, navigation complete
  }

  /// Handle schedule call navigation with pre-verified context
  static Future<void> _handleScheduleCallNavigationSafe(
    Map<String, dynamic> actionData,
    BuildContext context, // Pre-verified as mounted
  ) async {
    if (kDebugMode) {
      print('📞 Navigating to schedule call flow');
    }

    final priority = actionData['priority'] as String?;
    final interventionType = actionData['intervention_type'] as String?;

    // Context is pre-verified as mounted, safe to use directly
    await _showScheduleCallDialog(
      context,
      priority: priority,
      interventionType: interventionType,
    );
  }

  /// Handle complete lesson navigation with pre-verified context
  static Future<void> _handleCompleteLessonNavigationSafe(
    Map<String, dynamic> actionData,
    BuildContext context, // Pre-verified as mounted
  ) async {
    if (kDebugMode) {
      print('📚 Navigating to lesson completion flow');
    }

    final suggestedLesson = actionData['suggested_lesson'] as String?;

    // Context is pre-verified as mounted, safe to use directly
    await _showCompleteLessonDialog(context, suggestedLesson: suggestedLesson);
  }

  /// Show celebration snackbar for navigation feedback
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

  /// Show schedule call navigation dialog
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
                _navigateToScheduleCall();
              },
              icon: const Icon(Icons.calendar_today),
              label: const Text('Schedule Call'),
            ),
          ],
        );
      },
    );
  }

  /// Show complete lesson navigation dialog
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
                _navigateToLessonFlow(suggestedLesson);
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

  /// Navigate to schedule call (pure navigation logic)
  static void _navigateToScheduleCall() {
    if (kDebugMode) {
      print('🚀 Navigating to schedule call flow');
    }

    // Trigger navigation to coach intervention scheduling
    // Business logic is handled by CoachInterventionService
    _triggerCoachInterventionFlow();
  }

  /// Navigate to lesson flow (pure navigation logic)
  static void _navigateToLessonFlow(String? suggestedLesson) {
    if (kDebugMode) {
      print('🚀 Navigating to lesson flow: ${suggestedLesson ?? 'general'}');
    }
    // TODO: Implement actual lesson navigation routing
    // This would route to appropriate lesson screens
  }

  /// Trigger coach intervention flow (navigation to business logic)
  static Future<void> _triggerCoachInterventionFlow() async {
    try {
      if (kDebugMode) {
        print('🚀 Navigating to coach intervention scheduling');
      }

      // Pure navigation trigger - the business logic will be handled
      // by the CoachInterventionService when properly implemented
      // For now, this is just navigation coordination

      if (kDebugMode) {
        print('✅ Coach intervention navigation triggered');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error triggering coach intervention navigation: $e');
      }
    }
  }

  /// Track notification interaction (delegate to analytics service)
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

      // Pure navigation tracking - detailed analytics handled by domain service
      // For now, this is just navigation coordination
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
          await NotificationCoreService.instance.getPendingActions();

      if (pendingActions.isEmpty) return;

      if (kDebugMode) {
        print(
          '🔄 Processing ${pendingActions.length} pending notification actions',
        );
      }

      // Check if context is still mounted after async operation
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

      // Check context is still mounted before showing snackbar
      if (pendingActions.length > 1 && context.mounted) {
        _showMultiplePendingActionsSnackBar(context, pendingActions.length);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error processing pending actions: $e');
      }
    }
  }

  /// Show snackbar for multiple pending actions navigation feedback
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

  /// Apply cached momentum updates (pure navigation coordination)
  static Future<void> applyCachedMomentumUpdates(WidgetRef ref) async {
    try {
      final cachedUpdate =
          await NotificationCoreService.instance.getCachedMomentumUpdate();

      if (cachedUpdate != null) {
        if (kDebugMode) {
          print('📊 Applying cached momentum update via navigation');
        }

        // Navigation coordination to refresh UI data
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
