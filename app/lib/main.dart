import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/services/notification_action_dispatcher.dart';
import 'core/config/environment.dart';
import 'core/theme/app_theme.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/offline_cache_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/version_service.dart';
import 'core/providers/supabase_provider.dart';
import 'features/momentum/presentation/screens/momentum_screen.dart';
import 'features/ai_coach/ui/coach_chat_screen.dart';
import 'core/utils/deep_link_service.dart';
import 'features/momentum/presentation/screens/profile_settings_screen.dart';
import 'features/gamification/ui/rewards_navigator.dart';
import 'core/notifications/domain/services/notification_preferences_service.dart';
import 'core/providers/theme_provider.dart';
import 'features/wearable/ui/wearable_dashboard_screen.dart';
import 'package:app/features/achievements/progress_celebration_widget.dart';
import 'package:app/features/wearable/ui/health_permissions_state.dart';
import 'core/providers/vitals_notifier_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/services/auth_session_service.dart';
import 'package:app/core/navigation/routes.dart';
import 'features/action_steps/providers/momentum_listener_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/navigation/filtering_route_information_provider.dart';
import 'package:go_router/go_router.dart' as gor;

// Global instance to share across app
final AuthSessionService authSessionService = AuthSessionService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize environment configuration
    await Environment.initialize();
    debugPrint('✅ Environment initialized');

    // Debug: print masked environment config in development builds
    if (kDebugMode) {
      Environment.printConfig();
    }

    // Initialize Supabase early so that session restoration can occur before runApp
    await Supabase.initialize(
      url: Environment.supabaseUrl,
      anonKey: Environment.supabaseAnonKey,
    );
    await authSessionService.restore();
    debugPrint('🔑 Session restoration attempt complete');

    // Initialize core services
    await _initializeCoreServices();

    runApp(const ProviderScope(child: BEEApp()));
  } catch (e, stackTrace) {
    debugPrint('❌ App initialization failed: $e');
    debugPrint('Stack trace: $stackTrace');
    // Run app anyway with minimal functionality
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Failed to initialize app',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Error: $e'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Initialize core services required for app functionality
Future<void> _initializeCoreServices() async {
  try {
    // Initialize Firebase services
    await FirebaseService.initializeWithFallback();
    debugPrint('✅ Firebase initialized');

    // Initialize offline cache service
    await OfflineCacheService.initialize();
    debugPrint('✅ Offline cache initialized');

    // Initialize connectivity monitoring
    await ConnectivityService.initialize();
    debugPrint('✅ Connectivity service initialized');

    // Initialize version checking
    await VersionService.initialize();
    debugPrint('✅ Version service initialized');

    // Initialize notification preferences
    await NotificationPreferencesService.instance.initialize();
    debugPrint('✅ Notification preferences initialized');

    debugPrint('🚀 Core services initialization complete');
  } catch (e, stackTrace) {
    debugPrint('❌ Core services initialization failed: $e');
    debugPrint('Stack trace: $stackTrace');
    rethrow;
  }
}

/// Main app wrapper that handles initialization and global providers
class AppWrapper extends ConsumerStatefulWidget {
  const AppWrapper({super.key});

  @override
  ConsumerState<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends ConsumerState<AppWrapper>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const MomentumScreen(),
    const CoachChatScreen(),
    const WearableDashboardScreen(),
    const RewardsNavigator(),
    const ProfileSettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();

    // Listen for deep-links
    _setupDeepLinkHandling();
  }

  @override
  void dispose() {
    // Cancel deep-link stream subscription automatically by not storing; uni_links handles.
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh health permissions when returning to foreground.
      ref.read(healthPermissionsProvider.notifier).refreshPermissions();

      // Trigger a lightweight vitals refresh so sleep/weight stay current.
      ref.read(vitalsNotifierServiceProvider).refreshVitals();
    }
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize notification dispatcher
      _initializeNotificationDispatcher();

      // Initialize Supabase connection
      await _initializeSupabase();

      debugPrint('🎉 App initialization complete');
    } catch (e, stackTrace) {
      debugPrint('❌ App wrapper initialization failed: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> _initializeSupabase() async {
    try {
      // Initialize Supabase provider
      await ref.read(supabaseProvider.future);
      // Start listening for momentum updates as soon as Supabase is ready.
      ref.read(momentumListenerProvider);
      debugPrint('✅ Supabase connection established');

      // Start listening for token refreshes/sign-out to keep secure storage in sync
      authSessionService.listen();
    } catch (e) {
      debugPrint('❌ Supabase initialization failed: $e');
      // App can still function with offline features
    }
  }

  void _initializeNotificationDispatcher() {
    try {
      // Initialize the notification action dispatcher with context and ref
      final dispatcher = NotificationActionDispatcher.instance;
      dispatcher.initialize(context: context, ref: ref);
      debugPrint('✅ Notification action dispatcher initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize notification dispatcher: $e');
    }
  }

  /// Handles incoming deep links to open relevant in-app screens.
  void _setupDeepLinkHandling() {
    // Cold-start link
    DeepLinkService.initialUri().then((uri) {
      if (uri != null) _handleUri(uri);
    });

    // Hot links
    DeepLinkService.stream.listen(
      _handleUri,
      onError: (err) {
        debugPrint('❌ Deep-link error: $err');
      },
    );
  }

  void _handleUri(Uri uri) {
    if (DeepLinkService.isPasswordReset(uri)) {
      final token = DeepLinkService.extractAccessToken(uri);
      if (token != null) {
        context.push(kPasswordResetRoute, extra: token);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProgressCelebrationListener(
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.getSurfacePrimary(context),
          selectedItemColor: AppTheme.getMomentumColor(MomentumState.rising),
          unselectedItemColor: AppTheme.getTextTertiary(context),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.psychology_outlined),
              activeIcon: Icon(Icons.psychology),
              label: 'Coach',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.monitor_heart_outlined),
              activeIcon: Icon(Icons.monitor_heart),
              label: 'Stats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events),
              label: 'Rewards',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class BEEApp extends ConsumerWidget {
  const BEEApp({super.key});

  // Static instances to prevent recreation on every build
  static bool _debugSetup = false;
  static final routeInfoProvider = FilteringRouteInformationProvider(
    PlatformRouteInformationProvider(
      initialRouteInformation: RouteInformation(
        uri: Uri.parse('/'),
        state: {
          'location': '/',
          'state': {'codec': 'json', 'encoded': 'null'},
        },
      ),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    // Setup router debugging in debug mode (only once)
    if (kDebugMode && !_debugSetup) {
      setupRouterDebugging();
      _debugSetup = true;
    }

    return MaterialApp.router(
      title: 'BEE Momentum Meter',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routeInformationProvider: routeInfoProvider,
      routeInformationParser: appRouter.routeInformationParser,
      routerDelegate: appRouter.routerDelegate,
      backButtonDispatcher: appRouter.backButtonDispatcher,
      debugShowCheckedModeBanner: false,
    );
  }
}
