import 'package:app/core/services/vitals_notifier_service.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/core/providers/vitals_notifier_provider.dart';
import 'package:app/core/providers/supabase_provider.dart';

class AdaptivePollingToggle extends ConsumerStatefulWidget {
  const AdaptivePollingToggle({super.key});

  @override
  ConsumerState<AdaptivePollingToggle> createState() =>
      _AdaptivePollingToggleState();
}

class _AdaptivePollingToggleState extends ConsumerState<AdaptivePollingToggle> {
  bool _isPollingEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isPollingEnabled =
          prefs.getBool(VitalsNotifierService.adaptivePollingPrefKey) ?? false;
      _isLoading = false;
    });
  }

  Future<void> _updatePreference(bool value) async {
    setState(() {
      _isPollingEnabled = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(VitalsNotifierService.adaptivePollingPrefKey, value);

    // Restart VitalsNotifierService with new mode so change takes effect immediately.
    final service = ref.read(vitalsNotifierServiceProvider);
    await service.stopSubscription();

    final supabase = ref.read(supabaseClientProvider);
    final userId = supabase.auth.currentUser?.id;
    if (userId != null) {
      // Ignore failure here; UI will show disconnected state if it fails.
      // ignore: unawaited_futures
      service.startSubscription(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SwitchListTile(
      title: Text(
        'Adaptive Polling',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: AppTheme.getTextPrimary(context),
        ),
      ),
      subtitle: Text(
        'Reduces resource usage on older devices by polling for data instead of using a live connection.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppTheme.getTextSecondary(context),
        ),
      ),
      value: _isPollingEnabled,
      onChanged: _updatePreference,
      activeColor: AppTheme.momentumRising,
      contentPadding: EdgeInsets.zero,
    );
  }
}
