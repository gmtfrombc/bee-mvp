import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Service responsible for Firebase Core initialization and configuration
class FirebaseService {
  static bool _initialized = false;

  /// Firebase project ID for BEE Momentum Meter
  static const String projectId = 'bee-mvp-3ab43';

  /// Initialize Firebase Core with default configuration
  /// Uses GoogleService-Info.plist (iOS) and google-services.json (Android)
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Use default Firebase configuration from config files
      await Firebase.initializeApp();
      _initialized = true;

      if (kDebugMode) {
        print('Firebase initialized successfully for project: $projectId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Firebase initialization failed: $e');
      }
      rethrow;
    }
  }

  /// Check if Firebase has been initialized
  static bool get isInitialized => _initialized;

  /// Get the current Firebase project ID
  static String get currentProjectId => projectId;
}
