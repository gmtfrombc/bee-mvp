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
  /// Uses the generated firebase_options.dart configuration
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize Firebase with generated configuration
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
      _available = true;

      if (kDebugMode) {
        print('✅ Firebase initialized successfully for project: $projectId');
      }
    } catch (e) {
      _initialized = true;
      _available = false;
      _initializationError = e.toString();

      if (kDebugMode) {
        print('❌ Firebase initialization failed: $e');
        print('💡 App will continue with limited functionality');
        print('💡 Notifications and analytics will be disabled');
      }

      // Don't rethrow in development - allow app to continue
      if (!Environment.isDevelopment) {
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
        print('🔧 Firebase unavailable in development mode: $e');
        print('🔧 App functionality will work without Firebase services');
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
        print('⚠️ Failed to get Firebase app: $e');
      }
      return null;
    }
  }

  /// Check if a specific Firebase service is available
  static bool isServiceAvailable(String serviceName) {
    if (!_available) {
      if (kDebugMode) {
        print(
          '⚠️ Firebase service $serviceName not available: Firebase not initialized',
        );
      }
      return false;
    }
    return true;
  }

  /// Log Firebase service usage attempt
  static void logServiceAttempt(String serviceName, String operation) {
    if (kDebugMode) {
      if (_available) {
        print('🔥 Firebase $serviceName: $operation');
      } else {
        print(
          '⚠️ Attempted to use Firebase $serviceName ($operation) but Firebase is not available',
        );
        print('💡 Reason: ${_initializationError ?? 'Unknown'}');
      }
    }
  }
}
