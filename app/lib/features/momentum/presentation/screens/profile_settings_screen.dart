import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ignore_for_file: unused_element

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/theme_provider.dart';
import '../widgets/health_permission_toggle.dart';
import '../../../../core/mixins/permission_auto_refresh_mixin.dart';
import 'package:app/features/settings/ui/mfa_toggle_tile.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/navigation/routes.dart';
import '../../../../core/providers/auth_provider.dart';
import 'package:app/features/health_signals/pes/pes_providers.dart';

/// Screen for managing user profile and app settings
class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen>
    with PermissionAutoRefreshMixin<ProfileSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: AppTheme.getSurfaceSecondary(context),
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        backgroundColor: AppTheme.getSurfacePrimary(context),
        foregroundColor: AppTheme.getTextPrimary(context),
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
                context,
                'Personalize Your Experience',
                'Customize your app preferences and settings',
              ),

              const SizedBox(height: 24),

              // Profile section
              _buildProfileCard(context),

              const SizedBox(height: 16),

              // Theme settings
              _buildThemeCard(context, ref, themeMode),

              const SizedBox(height: 16),

              // App preferences
              _buildAppPreferencesCard(context, ref),

              const SizedBox(height: 24),

              // About section
              _buildAboutCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.getTextPrimary(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.getTextSecondary(context),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Card(
      color: AppTheme.getSurfacePrimary(context),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.momentumRising.withValues(
                    alpha: 0.1,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 32,
                    color: AppTheme.momentumRising,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sarah Johnson',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.getTextPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Member since January 2024',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.getTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.edit, color: AppTheme.getTextTertiary(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard(
    BuildContext context,
    WidgetRef ref,
    ThemeMode currentMode,
  ) {
    return Card(
      color: AppTheme.getSurfacePrimary(context),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getThemeIcon(currentMode),
                  color: AppTheme.momentumRising,
                ),
                const SizedBox(width: 12),
                Text(
                  'Appearance',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Theme mode options
            ...ThemeMode.values.map((mode) {
              return Semantics(
                label: _getThemeLabel(mode),
                hint: _getThemeHint(mode),
                selected: currentMode == mode,
                child: RadioListTile<ThemeMode>(
                  title: Text(
                    _getThemeLabel(mode),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.getTextPrimary(context),
                    ),
                  ),
                  subtitle: Text(
                    _getThemeDescription(mode),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.getTextSecondary(context),
                    ),
                  ),
                  value: mode,
                  groupValue: currentMode,
                  activeColor: AppTheme.momentumRising,
                  onChanged: (ThemeMode? value) {
                    if (value != null) {
                      ref.read(themeModeProvider.notifier).setThemeMode(value);
                    }
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              );
            }),

            const SizedBox(height: 12),

            // Quick toggle button
            Semantics(
              label: 'Quick theme toggle',
              hint: 'Toggle between light and dark themes',
              button: true,
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(themeModeProvider.notifier).toggleTheme();
                },
                icon: Icon(
                  Icons.brightness_6,
                  color: AppTheme.getTextPrimary(context),
                ),
                label: Text(
                  'Quick Toggle',
                  style: TextStyle(color: AppTheme.getTextPrimary(context)),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.getTextTertiary(context)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppPreferencesCard(BuildContext context, WidgetRef ref) {
    return Card(
      color: AppTheme.getSurfacePrimary(context),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, color: AppTheme.momentumRising),
                const SizedBox(width: 12),
                Text(
                  'App Preferences',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            const HealthPermissionToggle(),
            const Divider(),
            const _DailyPromptTimeTile(),
            const Divider(),
            const MfaToggleTile(),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    return Card(
      color: AppTheme.getSurfacePrimary(context),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info, color: AppTheme.momentumRising),
                const SizedBox(width: 12),
                Text(
                  'About',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Version 1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.getTextSecondary(context),
              ),
            ),

            const Divider(height: 24),

            // Log-out button
            Consumer(
              builder:
                  (context, ref, _) => ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Log Out'),
                    onTap: () async {
                      await ref.read(authNotifierProvider.notifier).signOut();
                      if (context.mounted) {
                        context.go(kLaunchRoute);
                      }
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Semantics(
      label: title,
      hint: subtitle,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.getTextSecondary(context), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.getTextPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.getTextSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppTheme.getTextTertiary(context),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  String _getThemeDescription(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Always use light theme';
      case ThemeMode.dark:
        return 'Always use dark theme';
      case ThemeMode.system:
        return 'Follow system setting';
    }
  }

  String _getThemeHint(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Set app to always use light theme';
      case ThemeMode.dark:
        return 'Set app to always use dark theme';
      case ThemeMode.system:
        return 'App will follow your device theme setting';
    }
  }
}

/// Tile that shows and lets user update PES daily prompt time.
class _DailyPromptTimeTile extends ConsumerWidget {
  const _DailyPromptTimeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTime = ref.watch(dailyPromptControllerProvider);

    return asyncTime.when(
      data:
          (time) => ListTile(
            leading: Icon(
              Icons.schedule,
              color: AppTheme.getTextSecondary(context),
            ),
            title: const Text('Daily PES Prompt Time'),
            subtitle: Text(time.format(context)),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: time,
              );
              if (picked != null && picked != time) {
                await ref
                    .read(dailyPromptControllerProvider.notifier)
                    .updateTime(picked);
              }
            },
          ),
      loading:
          () => const ListTile(
            leading: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            title: Text('Loading prompt time...'),
          ),
      error:
          (e, st) => ListTile(
            leading: const Icon(Icons.error),
            title: const Text('Failed to load prompt time'),
            subtitle: Text(e.toString()),
          ),
    );
  }
}
