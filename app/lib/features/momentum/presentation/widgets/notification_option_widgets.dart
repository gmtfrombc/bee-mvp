import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/notification_preferences_service.dart';
import '../../../../core/services/accessibility_service.dart';

/// Reusable widgets for notification settings options
/// Contains toggles, selectors, and status displays
class NotificationOptionWidgets {
  /// Builds a notification type toggle with icon, title, and subtitle
  static Widget buildNotificationTypeToggle({
    required BuildContext context,
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

  /// Builds a time selector widget for quiet hours
  static Widget buildTimeSelector({
    required BuildContext context,
    required String label,
    required int currentHour,
    required ValueChanged<int> onChanged,
  }) {
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
            onTap: () => _showTimePicker(context, currentHour, onChanged),
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

  /// Builds a status row showing current setting state
  static Widget buildStatusRow({
    required BuildContext context,
    required String label,
    required String value,
    required bool isPositive,
  }) {
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

  /// Builds a frequency selector for notification frequency
  static Widget buildFrequencySelector({
    required BuildContext context,
    required NotificationFrequency currentFrequency,
    required ValueChanged<NotificationFrequency> onChanged,
  }) {
    return Column(
      children:
          NotificationFrequency.values.map((frequency) {
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
                groupValue: currentFrequency,
                onChanged: (value) {
                  if (value != null) {
                    onChanged(value);
                    context.announceToScreenReader(
                      'Notification frequency set to ${value.displayName}',
                    );
                  }
                },
              ),
            );
          }).toList(),
    );
  }

  /// Builds a section header with title and subtitle
  static Widget buildSectionHeader({
    required BuildContext context,
    required String title,
    required String subtitle,
  }) {
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

  /// Builds a card with icon and title for settings sections
  static Widget buildCardHeader({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String? subtitle,
    Color? iconColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor ?? AppTheme.momentumRising),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Private helper methods
  static String _formatHour(int hour) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:00 $period';
  }

  static Future<void> _showTimePicker(
    BuildContext context,
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
