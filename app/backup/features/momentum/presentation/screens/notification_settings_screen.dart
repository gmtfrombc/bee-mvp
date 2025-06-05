import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/notification_settings_form.dart';

/// Screen for managing notification preferences
/// Refactored to use extracted components for better maintainability
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceSecondary,
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: AppTheme.surfaceSecondary,
        elevation: 0,
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: NotificationSettingsForm(),
        ),
      ),
    );
  }
}
