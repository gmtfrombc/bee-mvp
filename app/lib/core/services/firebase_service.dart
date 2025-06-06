import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../config/environment.dart';
import '../../firebase_options.dart';

/// Service responsible for Firebase Core initialization and configuration
/// Handles graceful degradation when Firebase is not available
class FirebaseService {
  static bool _initialized = false;
  static bool _available = false;
  static String? _initializationError;

  /// Firebase project ID for BEE Momentum Meter
  static const String projectId = 'bee-mvp-3ab43';

  /// Initialize Firebase Core with enhanced error handling
  /// Uses the generated firebase_options.dart configuration if available
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Check if Firebase app already exists (handle duplicate app error)
      if (Firebase.apps.isNotEmpty) {
        // Firebase is already initialized
        _initialized = true;
        _available = true;

        if (kDebugMode) {
          debugPrint('✅ Firebase already initialized for project: $projectId');
        }
        return;
      }

      // Initialize Firebase with generated configuration
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
      _available = true;

      if (kDebugMode) {
        debugPrint(
          '✅ Firebase initialized successfully for project: $projectId',
        );
      }
    } on FirebaseException catch (e) {
      if (e.code == 'duplicate-app') {
        // Handle duplicate app specifically
        _initialized = true;
        _available = true;

        if (kDebugMode) {
          debugPrint('✅ Firebase app already exists - using existing instance');
        }
        return;
      }

      // Other Firebase errors
      _initialized = true;
      _available = false;
      _initializationError = e.toString();

      if (kDebugMode) {
        debugPrint('❌ Firebase initialization failed: $e');
        debugPrint('💡 App will continue with limited functionality');
        debugPrint('💡 Notifications and analytics will be disabled');
      }

      // Don't rethrow in development/test environments - allow app to continue
      if (!Environment.isDevelopment && !kDebugMode) {
        rethrow;
      }
    } catch (e) {
      _initialized = true;
      _available = false;
      _initializationError = e.toString();

      if (kDebugMode) {
        debugPrint('❌ Firebase initialization failed: $e');
        debugPrint('💡 App will continue with limited functionality');
        debugPrint('💡 Notifications and analytics will be disabled');
      }

      // Don't rethrow in development/test environments - allow app to continue
      if (!Environment.isDevelopment && !kDebugMode) {
        rethrow;
      }
    }
  }

  /// Initialize Firebase with fallback for missing configuration
  /// This method attempts initialization but doesn't fail the app if Firebase is unavailable
  static Future<void> initializeWithFallback() async {
    try {
      await initialize();
    } catch (e) {
      // In development, log the error but continue
      if (kDebugMode) {
        debugPrint('🔧 Firebase unavailable in development mode: $e');
        debugPrint('🔧 App functionality will work without Firebase services');
      }

      _initialized = true;
      _available = false;
      _initializationError = e.toString();
    }
  }

  /// Check if Firebase has been initialized
  static bool get isInitialized => _initialized;

  /// Check if Firebase is available for use
  static bool get isAvailable => _available;

  /// Get the initialization error if any
  static String? get initializationError => _initializationError;

  /// Get the current Firebase project ID
  static String get currentProjectId => projectId;

  /// Get a safe Firebase app instance
  /// Returns null if Firebase is not available
  static FirebaseApp? get safeApp {
    if (!_available) return null;

    try {
      return Firebase.app();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to get Firebase app: $e');
      }
      return null;
    }
  }

  /// Check if a specific Firebase service is available
  static bool isServiceAvailable(String serviceName) {
    if (!_available) {
      if (kDebugMode) {
        debugPrint(
          '⚠️ Firebase service $serviceName not available: Firebase not initialized',
        );
      }
      return false;
    }
    return true;
  }

  /// Log Firebase service usage attempt
  static void logServiceAttempt(String serviceName, String operation) {
    // Suppress logging during tests to reduce noise
    if (kDebugMode && !_isInTestEnvironment) {
      if (_available) {
        debugPrint('🔥 Firebase $serviceName: $operation');
      } else {
        debugPrint(
          '⚠️ Attempted to use Firebase $serviceName ($operation) but Firebase is not available',
        );
        debugPrint('💡 Reason: ${_initializationError ?? 'Unknown'}');
      }
    }
  }

  /// Check if we're running in a test environment
  static bool get _isInTestEnvironment {
    // Flutter test framework sets this environment variable
    return const bool.fromEnvironment('flutter.flutter_test') ||
        // Alternative check for test environment
        StackTrace.current.toString().contains('flutter_test');
  }
}
