import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/notification_preferences_service.dart';
import '../../../../core/services/accessibility_service.dart';

/// Screen for managing notification preferences
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
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
    return Scaffold(
      backgroundColor: AppTheme.surfaceSecondary,
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: AppTheme.surfaceSecondary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildSectionHeader(
                'Manage Your Notifications',
                'Customize when and how you receive momentum updates',
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
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
        ),
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

            _buildNotificationTypeToggle(
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

            _buildNotificationTypeToggle(
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

            _buildNotificationTypeToggle(
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

  Widget _buildNotificationTypeToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: value ? AppTheme.momentumRising : AppTheme.textSecondary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        Semantics(
          label: title,
          hint: value ? 'Currently enabled' : 'Currently disabled',
          child: Switch(value: value, onChanged: onChanged),
        ),
      ],
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
            Row(
              children: [
                const Icon(Icons.schedule, color: AppTheme.momentumRising),
                const SizedBox(width: 12),
                Text(
                  'Notification Frequency',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ...NotificationFrequency.values.map((frequency) {
              return Semantics(
                label: frequency.displayName,
                hint: frequency.description,
                child: RadioListTile<NotificationFrequency>(
                  title: Text(frequency.displayName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(frequency.description),
                      const SizedBox(height: 4),
                      Text(
                        'Up to ${frequency.maxDailyNotifications} per day, '
                        '${frequency.minIntervalMinutes ~/ 60}h minimum between notifications',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  value: frequency,
                  groupValue: _frequency,
                  onChanged: (value) async {
                    if (value != null) {
                      setState(() {
                        _frequency = value;
                      });
                      await _prefsService.setNotificationFrequency(value);

                      if (mounted) {
                        context.announceToScreenReader(
                          'Notification frequency set to ${value.displayName}',
                        );
                      }
                    }
                  },
                ),
              );
            }),
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
                    child: _buildTimeSelector('Start Time', _quietHoursStart, (
                      hour,
                    ) async {
                      setState(() {
                        _quietHoursStart = hour;
                      });
                      await _prefsService.setQuietHoursStart(hour);
                    }),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimeSelector('End Time', _quietHoursEnd, (
                      hour,
                    ) async {
                      setState(() {
                        _quietHoursEnd = hour;
                      });
                      await _prefsService.setQuietHoursEnd(hour);
                    }),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector(
    String label,
    int currentHour,
    ValueChanged<int> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Semantics(
          label: '$label: ${_formatHour(currentHour)}',
          hint: 'Tap to change time',
          button: true,
          child: InkWell(
            onTap: () => _showTimePicker(currentHour, onChanged),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatHour(currentHour),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const Icon(Icons.access_time, size: 20),
                ],
              ),
            ),
          ),
        ),
      ],
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

            _buildStatusRow(
              'Notifications',
              _notificationsEnabled ? 'Enabled' : 'Disabled',
              _notificationsEnabled,
            ),

            if (_notificationsEnabled) ...[
              _buildStatusRow(
                'Quiet Hours',
                isInQuietHours ? 'Active' : 'Inactive',
                !isInQuietHours,
              ),

              _buildStatusRow(
                'Can Send Notifications',
                canSendNotification ? 'Yes' : 'No',
                canSendNotification,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, bool isPositive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isPositive ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatHour(int hour) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:00 $period';
  }

  Future<void> _showTimePicker(
    int currentHour,
    ValueChanged<int> onChanged,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: 0),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onChanged(picked.hour);
    }
  }
}
