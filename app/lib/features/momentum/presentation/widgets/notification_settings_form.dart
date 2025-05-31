import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/notification_preferences_service.dart';
import '../../../../core/services/accessibility_service.dart';
import 'notification_option_widgets.dart';
import '../../../../core/notifications/domain/models/notification_types.dart';

/// Form component for notification settings
/// Contains all the form logic and card builders
class NotificationSettingsForm extends StatefulWidget {
  const NotificationSettingsForm({super.key});

  @override
  State<NotificationSettingsForm> createState() =>
      _NotificationSettingsFormState();
}

class _NotificationSettingsFormState extends State<NotificationSettingsForm> {
  final _prefsService = NotificationPreferencesService.instance;

  // Local state for immediate UI updates
  late bool _notificationsEnabled;
  late bool _momentumNotifications;
  late bool _celebrationNotifications;
  late bool _interventionNotifications;
  late bool _quietHoursEnabled;
  late int _quietHoursStart;
  late int _quietHoursEnd;
  late NotificationFrequency _frequency;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    _notificationsEnabled = _prefsService.notificationsEnabled;
    _momentumNotifications = _prefsService.momentumNotificationsEnabled;
    _celebrationNotifications = _prefsService.celebrationNotificationsEnabled;
    _interventionNotifications = _prefsService.interventionNotificationsEnabled;
    _quietHoursEnabled = _prefsService.quietHoursEnabled;
    _quietHoursStart = _prefsService.quietHoursStart;
    _quietHoursEnd = _prefsService.quietHoursEnd;
    _frequency = _prefsService.notificationFrequency;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        NotificationOptionWidgets.buildSectionHeader(
          context: context,
          title: 'Manage Your Notifications',
          subtitle: 'Customize when and how you receive momentum updates',
        ),

        const SizedBox(height: 24),

        // Global notifications toggle
        _buildGlobalNotificationsCard(),

        const SizedBox(height: 16),

        // Notification types
        if (_notificationsEnabled) ...[
          _buildNotificationTypesCard(),

          const SizedBox(height: 16),

          // Frequency settings
          _buildFrequencyCard(),

          const SizedBox(height: 16),

          // Quiet hours
          _buildQuietHoursCard(),

          const SizedBox(height: 24),

          // Current status
          _buildCurrentStatusCard(),
        ],
      ],
    );
  }

  Widget _buildGlobalNotificationsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _notificationsEnabled
                      ? Icons.notifications
                      : Icons.notifications_off,
                  color:
                      _notificationsEnabled
                          ? AppTheme.momentumRising
                          : AppTheme.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enable Notifications',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Receive momentum updates and encouragement',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Semantics(
                  label: 'Enable notifications',
                  hint:
                      _notificationsEnabled
                          ? 'Notifications are currently enabled'
                          : 'Notifications are currently disabled',
                  child: Switch(
                    value: _notificationsEnabled,
                    onChanged: (value) async {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                      await _prefsService.setNotificationsEnabled(value);

                      if (mounted) {
                        context.announceToScreenReader(
                          'Notifications ${value ? 'enabled' : 'disabled'}',
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTypesCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Types',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            NotificationOptionWidgets.buildNotificationTypeToggle(
              context: context,
              icon: Icons.trending_up,
              title: 'Momentum Updates',
              subtitle: 'Get notified about your momentum changes',
              value: _momentumNotifications,
              onChanged: (value) async {
                setState(() {
                  _momentumNotifications = value;
                });
                await _prefsService.setMomentumNotificationsEnabled(value);
              },
            ),

            const Divider(height: 24),

            NotificationOptionWidgets.buildNotificationTypeToggle(
              context: context,
              icon: Icons.celebration,
              title: 'Celebrations',
              subtitle: 'Celebrate your achievements and milestones',
              value: _celebrationNotifications,
              onChanged: (value) async {
                setState(() {
                  _celebrationNotifications = value;
                });
                await _prefsService.setCelebrationNotificationsEnabled(value);
              },
            ),

            const Divider(height: 24),

            NotificationOptionWidgets.buildNotificationTypeToggle(
              context: context,
              icon: Icons.support_agent,
              title: 'Support & Interventions',
              subtitle: 'Receive help when you need it most',
              value: _interventionNotifications,
              onChanged: (value) async {
                setState(() {
                  _interventionNotifications = value;
                });
                await _prefsService.setInterventionNotificationsEnabled(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NotificationOptionWidgets.buildCardHeader(
              context: context,
              icon: Icons.schedule,
              title: 'Notification Frequency',
              subtitle: null,
            ),
            const SizedBox(height: 16),

            NotificationOptionWidgets.buildFrequencySelector(
              context: context,
              currentFrequency: _frequency,
              onChanged: (value) async {
                setState(() {
                  _frequency = value;
                });
                await _prefsService.setNotificationFrequency(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuietHoursCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _quietHoursEnabled ? Icons.bedtime : Icons.bedtime_off,
                  color:
                      _quietHoursEnabled
                          ? AppTheme.momentumRising
                          : AppTheme.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quiet Hours',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'No notifications during your rest time',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Semantics(
                  label: 'Enable quiet hours',
                  hint:
                      _quietHoursEnabled
                          ? 'Quiet hours are currently enabled'
                          : 'Quiet hours are currently disabled',
                  child: Switch(
                    value: _quietHoursEnabled,
                    onChanged: (value) async {
                      setState(() {
                        _quietHoursEnabled = value;
                      });
                      await _prefsService.setQuietHoursEnabled(value);
                    },
                  ),
                ),
              ],
            ),

            if (_quietHoursEnabled) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: NotificationOptionWidgets.buildTimeSelector(
                      context: context,
                      label: 'Start Time',
                      currentHour: _quietHoursStart,
                      onChanged: (hour) async {
                        setState(() {
                          _quietHoursStart = hour;
                        });
                        await _prefsService.setQuietHoursStart(hour);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: NotificationOptionWidgets.buildTimeSelector(
                      context: context,
                      label: 'End Time',
                      currentHour: _quietHoursEnd,
                      onChanged: (hour) async {
                        setState(() {
                          _quietHoursEnd = hour;
                        });
                        await _prefsService.setQuietHoursEnd(hour);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStatusCard() {
    final isInQuietHours = _prefsService.isInQuietHours;
    final canSendNotification = _prefsService.canSendNotification;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  canSendNotification ? Icons.check_circle : Icons.pause_circle,
                  color: canSendNotification ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 12),
                Text(
                  'Current Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            NotificationOptionWidgets.buildStatusRow(
              context: context,
              label: 'Notifications',
              value: _notificationsEnabled ? 'Enabled' : 'Disabled',
              isPositive: _notificationsEnabled,
            ),

            if (_notificationsEnabled) ...[
              NotificationOptionWidgets.buildStatusRow(
                context: context,
                label: 'Quiet Hours',
                value: isInQuietHours ? 'Active' : 'Inactive',
                isPositive: !isInQuietHours,
              ),

              NotificationOptionWidgets.buildStatusRow(
                context: context,
                label: 'Can Send Notifications',
                value: canSendNotification ? 'Yes' : 'No',
                isPositive: canSendNotification,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
