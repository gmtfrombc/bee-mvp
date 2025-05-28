import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'features/momentum/presentation/screens/momentum_screen.dart';
import 'core/config/supabase_config.dart';
import 'core/config/environment.dart';
import 'core/providers/auth_provider.dart';
import 'core/services/supabase_test_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/offline_cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Print environment configuration for debugging
  Environment.printConfig();

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    print('✅ Supabase initialized successfully');

    // Run connection test
    await SupabaseTestService.testConnection();
  } catch (e) {
    print('❌ Failed to initialize Supabase: $e');
  }

  // Initialize connectivity monitoring
  try {
    await ConnectivityService.initialize();
    print('✅ Connectivity service initialized');
  } catch (e) {
    print('❌ Failed to initialize connectivity service: $e');
  }

  // Initialize offline cache
  try {
    await OfflineCacheService.initialize();
    print('✅ Offline cache service initialized');
  } catch (e) {
    print('❌ Failed to initialize offline cache: $e');
  }

  runApp(const ProviderScope(child: BEEApp()));
}

/// App wrapper to handle authentication
class AppWrapper extends ConsumerStatefulWidget {
  const AppWrapper({super.key});

  @override
  ConsumerState<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends ConsumerState<AppWrapper> {
  @override
  void initState() {
    super.initState();
    // Trigger authentication on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureAuthenticated();
    });
  }

  void _ensureAuthenticated() async {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final currentUser = ref.read(authNotifierProvider).value;

    print('🔐 Current user: ${currentUser?.id ?? 'null'}');

    if (currentUser == null) {
      try {
        print('🔐 Attempting anonymous sign-in...');
        await authNotifier.signInAnonymously();
        print('✅ Successfully signed in anonymously');
      } catch (e) {
        print('❌ Failed to sign in anonymously: $e');
      }
    } else {
      print('✅ User already authenticated: ${currentUser.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return authState.when(
      data: (user) {
        // Show the main screen regardless of auth status
        // The momentum provider will handle fallbacks
        return const MomentumScreen();
      },
      loading:
          () => const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          ),
      error: (error, stack) {
        // Even on auth error, show the main screen with fallback data
        print('Auth error: $error');
        return const MomentumScreen();
      },
    );
  }
}

class BEEApp extends StatelessWidget {
  const BEEApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BEE Momentum Meter',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const AppWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}
