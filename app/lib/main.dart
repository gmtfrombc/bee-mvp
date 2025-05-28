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
import 'core/providers/supabase_provider.dart';
import 'features/momentum/presentation/screens/momentum_screen.dart';
import 'core/services/notification_preferences_service.dart';

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

  // Initialize Firebase
  try {
    await FirebaseService.initialize();
    debugPrint('✅ Firebase initialized');
  } catch (e) {
    debugPrint('❌ Failed to initialize Firebase: $e');
    // Continue without Firebase for development
  }

  // Initialize notification preferences
  try {
    await NotificationPreferencesService.instance.initialize();
    debugPrint('✅ Notification preferences service initialized');
  } catch (e) {
    debugPrint('❌ Failed to initialize notification preferences: $e');
  }

  // Initialize notification service with enhanced handlers
  try {
    await NotificationService.instance.initialize(
      onMessageReceived: _handleForegroundMessage,
      onMessageOpenedApp: _handleNotificationTap,
      onTokenRefresh: _handleTokenRefresh,
    );
    debugPrint('✅ Notification service initialized');

    // Get and store initial FCM token
    await _initializeFCMToken();
  } catch (e) {
    debugPrint('❌ Failed to initialize notification service: $e');
    // Continue without notifications for development
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

  runApp(const ProviderScope(child: BEEApp()));
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
    final currentToken = await FCMTokenService.instance.getCurrentToken();
    if (currentToken != null) {
      debugPrint(
        '📱 FCM Token initialized: ${currentToken.substring(0, 20)}...',
      );
    } else {
      debugPrint('⚠️ Failed to get FCM token');
    }
  } catch (e) {
    debugPrint('❌ Failed to initialize FCM token: $e');
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
