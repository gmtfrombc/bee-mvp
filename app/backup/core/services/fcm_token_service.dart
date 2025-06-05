import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_service.dart';
import '../notifications/domain/services/notification_core_service.dart';
import 'notification_service.dart';

/// Service responsible for FCM token lifecycle management and storage
/// Delegates core functionality to NotificationCoreService
class FCMTokenService {
  static FCMTokenService? _instance;
  static FCMTokenService get instance => _instance ??= FCMTokenService._();

  FCMTokenService._();

  // Delegate to core service
  NotificationCoreService get _coreService => NotificationCoreService.instance;

  /// Check if Firebase is available for FCM operations
  bool get isAvailable => _coreService.isAvailable;

  /// Store FCM token locally and in Supabase user profile
  Future<void> storeToken(String token) async {
    // The core service handles token storage automatically,
    // but we can explicitly store if needed
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      await prefs.setInt(
        'fcm_token_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );

      if (kDebugMode) {
        debugPrint(
          '📱 FCM Token stored via FCMTokenService: ${token.substring(0, 20)}...',
        );
      }

      // Store in Supabase user profile if available
      await _storeTokenInSupabase(token);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to store FCM token: $e');
      }
    }
  }

  /// Get the currently stored FCM token
  Future<String?> getStoredToken() async {
    return await _coreService.getToken();
  }

  /// Check if the stored token is still valid (not older than 1 week)
  Future<bool> isTokenValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('fcm_token_timestamp');

      if (timestamp == null) return false;

      final tokenDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));

      return tokenDate.isAfter(weekAgo);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to check token validity: $e');
      }
      return false;
    }
  }

  /// Get fresh token from Firebase and store it
  Future<String?> refreshToken() async {
    return await _coreService.getToken();
  }

  /// Get current valid token (refresh if needed)
  Future<String?> getCurrentToken() async {
    return await _coreService.getToken();
  }

  /// Remove stored token locally and from Supabase
  Future<void> removeToken() async {
    await _coreService.deleteToken();
  }

  /// Store token in Supabase user profile
  Future<void> _storeTokenInSupabase(String token) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null) {
        await supabase.from('user_profiles').upsert({
          'user_id': user.id,
          'fcm_token': token,
          'token_updated_at': DateTime.now().toIso8601String(),
          'platform': Platform.operatingSystem,
        });

        if (kDebugMode) {
          debugPrint('☁️ FCM Token stored in Supabase user profile');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to store FCM token in Supabase: $e');
      }
    }
  }

  /// Get all FCM tokens for a user (useful for multi-device support)
  Future<List<Map<String, dynamic>>> getUserTokens(String userId) async {
    try {
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from('user_fcm_tokens')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to get user FCM tokens: $e');
      }
      return [];
    }
  }

  /// Clean up expired tokens from Supabase (useful for maintenance)
  Future<void> cleanupExpiredTokens() async {
    try {
      final supabase = Supabase.instance.client;
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      await supabase
          .from('user_fcm_tokens')
          .delete()
          .lt('updated_at', thirtyDaysAgo.toIso8601String());

      if (kDebugMode) {
        debugPrint('🧹 Expired FCM tokens cleaned up');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to cleanup expired FCM tokens: $e');
      }
    }
  }

  /// Subscribe to user-specific topic for targeted notifications
  Future<void> subscribeToUserTopic(String userId) async {
    if (!isAvailable) {
      FirebaseService.logServiceAttempt('FCM', 'subscribeToUserTopic');
      return;
    }

    try {
      final topic = 'user_$userId';
      await NotificationService.instance.subscribeToTopic(topic);

      if (kDebugMode) {
        debugPrint('✅ Subscribed to user topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to subscribe to user topic: $e');
      }
    }
  }

  /// Unsubscribe from user-specific topic
  Future<void> unsubscribeFromUserTopic(String userId) async {
    if (!isAvailable) {
      FirebaseService.logServiceAttempt('FCM', 'unsubscribeFromUserTopic');
      return;
    }

    try {
      final topic = 'user_$userId';
      await NotificationService.instance.unsubscribeFromTopic(topic);

      if (kDebugMode) {
        debugPrint('✅ Unsubscribed from user topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to unsubscribe from user topic: $e');
      }
    }
  }
}
