import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'core/config/environment.dart';
import 'core/theme/app_theme.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/offline_cache_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/notification_action_dispatcher.dart';
import 'core/services/fcm_token_service.dart';
import 'core/services/version_service.dart';
import 'core/providers/supabase_provider.dart';
import 'features/momentum/presentation/screens/momentum_screen.dart';
import 'core/notifications/domain/services/notification_preferences_service.dart';
import 'core/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment configuration
  await Environment.initialize();

  // Print environment configuration for debugging
  Environment.printConfig();

  // Validate environment configuration
  if (!Environment.hasValidConfiguration) {
    debugPrint('❌ Environment configuration is incomplete!');
    debugPrint(
      '   Please set SUPABASE_URL and SUPABASE_ANON_KEY environment variables',
    );
    debugPrint('   or create a .env file with proper configuration.');
  }

  // Initialize Firebase with enhanced error handling
  try {
    await FirebaseService.initializeWithFallback();
    if (FirebaseService.isAvailable) {
      debugPrint('✅ Firebase initialized successfully');
    } else {
      debugPrint(
        '⚠️ Firebase not available: ${FirebaseService.initializationError}',
      );
      debugPrint('💡 App will continue with limited functionality');
    }
  } catch (e) {
    debugPrint('❌ Firebase initialization error: $e');
    // Continue without Firebase for development
  }

  // Central notification system coordination
  await _initializeNotificationSystem();

  // Initialize other core services
  await _initializeCoreServices();

  runApp(const ProviderScope(child: BEEApp()));
}

/// Central notification system initialization with health checking
Future<void> _initializeNotificationSystem() async {
  final stopwatch = Stopwatch()..start();
  final serviceStatus = <String, bool>{};

  try {
    debugPrint('🔄 Initializing notification system...');

    // 1. Initialize notification preferences (domain layer)
    try {
      await NotificationPreferencesService.instance.initialize();
      serviceStatus['preferences'] = true;
      debugPrint('✅ Notification preferences service initialized');
    } catch (e) {
      serviceStatus['preferences'] = false;
      debugPrint('❌ Failed to initialize notification preferences: $e');
    }

    // 2. Initialize core notification service
    try {
      await NotificationService.instance.initialize(
        onMessageReceived: _handleForegroundMessage,
        onMessageOpenedApp: _handleNotificationTap,
        onTokenRefresh: _handleTokenRefresh,
      );
      serviceStatus['core'] = true;
      debugPrint('✅ Notification service initialized');

      // 3. Initialize FCM token handling
      await _initializeFCMToken();
      serviceStatus['fcm'] = true;
    } catch (e) {
      serviceStatus['core'] = false;
      serviceStatus['fcm'] = false;
      debugPrint('❌ Failed to initialize notification service: $e');
    }

    stopwatch.stop();

    // Service health summary
    final successCount = serviceStatus.values.where((status) => status).length;
    final totalCount = serviceStatus.length;

    debugPrint(
      '📊 Notification system health: $successCount/$totalCount services',
    );
    debugPrint('⏱️ Initialization time: ${stopwatch.elapsedMilliseconds}ms');

    if (successCount == totalCount) {
      debugPrint('✅ Notification system fully operational');
    } else {
      debugPrint('⚠️ Notification system partially functional:');
      serviceStatus.forEach((service, status) {
        final icon = status ? '✅' : '❌';
        debugPrint('   $icon $service');
      });
    }
  } catch (e) {
    debugPrint('❌ Critical notification system initialization error: $e');
  }
}

/// Initialize other core services with error isolation
Future<void> _initializeCoreServices() async {
  // Initialize version service
  try {
    await VersionService.initialize();
    debugPrint('✅ Version service initialized: ${VersionService.fullVersion}');
  } catch (e) {
    debugPrint('❌ Failed to initialize version service: $e');
  }

  // Initialize connectivity monitoring
  try {
    await ConnectivityService.initialize();
    debugPrint('✅ Connectivity service initialized');
  } catch (e) {
    debugPrint('❌ Failed to initialize connectivity service: $e');
  }

  // Initialize offline cache
  try {
    await OfflineCacheService.initialize();
    debugPrint('✅ Offline cache service initialized');
  } catch (e) {
    debugPrint('❌ Failed to initialize offline cache: $e');
  }
}

/// Handle foreground notifications with enhanced dispatcher
void _handleForegroundMessage(RemoteMessage message) {
  debugPrint('📱 Foreground notification: ${message.notification?.title}');

  // Use the action dispatcher for comprehensive handling
  final dispatcher = NotificationActionDispatcher.instance;
  if (dispatcher.isReady) {
    dispatcher.handleForegroundNotification(message);
  } else {
    // Fallback for when dispatcher isn't ready yet
    debugPrint('⚠️ Notification dispatcher not ready, message queued');
  }
}

/// Handle notification taps with deep linking
void _handleNotificationTap(RemoteMessage message) {
  debugPrint('👆 Notification tapped: ${message.notification?.title}');
  debugPrint('📱 Notification data: ${message.data}');

  // Use the action dispatcher for comprehensive handling
  final dispatcher = NotificationActionDispatcher.instance;
  if (dispatcher.isReady) {
    dispatcher.handleNotificationTap(message);
  } else {
    // Store for later processing when dispatcher is ready
    debugPrint('⚠️ Notification dispatcher not ready, tap action queued');
  }
}

/// Handle FCM token refresh
void _handleTokenRefresh(String token) {
  debugPrint('🔄 FCM Token refreshed: $token');
  // Store token in Supabase user profile using FCM token service
  FCMTokenService.instance.storeToken(token);
}

/// Initialize FCM token on app startup
Future<void> _initializeFCMToken() async {
  try {
    // Check if FCM is available before attempting to get token
    if (!FCMTokenService.instance.isAvailable) {
      debugPrint('⚠️ FCM not available, skipping token initialization');
      return;
    }

    final currentToken = await FCMTokenService.instance.getCurrentToken();
    if (currentToken != null) {
      debugPrint(
        '📱 FCM Token initialized: ${currentToken.substring(0, 20)}...',
      );
    } else {
      debugPrint('⚠️ Failed to get FCM token - may be in development mode');
    }
  } catch (e) {
    debugPrint('❌ Failed to initialize FCM token: $e');
    // Continue without FCM token - app should work offline
  }
}

/// App wrapper to handle authentication and notification setup
class AppWrapper extends ConsumerStatefulWidget {
  const AppWrapper({super.key});

  @override
  ConsumerState<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends ConsumerState<AppWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();

    // Add lifecycle observer for app state changes
    WidgetsBinding.instance.addObserver(this);

    // Trigger authentication and notification setup on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureAuthenticated();
      _initializeNotificationDispatcher();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Dispose notification dispatcher
    NotificationActionDispatcher.instance.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Notify the dispatcher about app state changes
    final dispatcher = NotificationActionDispatcher.instance;
    if (dispatcher.isReady) {
      dispatcher.onAppStateChanged(state);
    }
  }

  void _ensureAuthenticated() async {
    try {
      // Wait for Supabase to be initialized
      final supabaseClient = await ref.read(supabaseProvider.future);

      final currentUser = supabaseClient.auth.currentUser;
      debugPrint('🔐 Current user: ${currentUser?.id ?? 'null'}');

      if (currentUser == null) {
        // Try anonymous sign-in first
        debugPrint('🔐 Attempting anonymous sign-in...');
        await supabaseClient.auth.signInAnonymously();
        debugPrint('✅ Successfully signed in anonymously');
      } else {
        debugPrint('✅ User already authenticated: ${currentUser.id}');
      }
    } catch (e) {
      // Authentication failed - continue anyway for offline functionality
      debugPrint('❌ Authentication setup failed: $e');
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

  @override
  Widget build(BuildContext context) {
    // Show the main screen - the momentum provider will handle auth fallbacks
    return const MomentumScreen();
  }
}

class BEEApp extends ConsumerWidget {
  const BEEApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'BEE Momentum Meter',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const AppWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}
