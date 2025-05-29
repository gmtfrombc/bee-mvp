import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'notification_service.dart';
import 'firebase_service.dart';

/// Service responsible for FCM token lifecycle management and storage
/// Gracefully handles Firebase unavailability in development environments
class FCMTokenService {
  static FCMTokenService? _instance;
  static FCMTokenService get instance => _instance ??= FCMTokenService._();

  FCMTokenService._();

  static const String _tokenKey = 'fcm_token';
  static const String _tokenTimestampKey = 'fcm_token_timestamp';

  /// Check if FCM functionality is available
  bool get isAvailable => NotificationService.instance.isAvailable;

  /// Store FCM token locally and in Supabase user profile
  Future<void> storeToken(String token) async {
    try {
      // Store locally regardless of Firebase availability
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setInt(
        _tokenTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );

      if (kDebugMode) {
        print('📱 FCM Token stored locally: ${token.substring(0, 20)}...');
      }

      // Store in Supabase user profile if available
      await _storeTokenInSupabase(token);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to store FCM token: $e');
      }
    }
  }

  /// Get the currently stored FCM token
  Future<String?> getStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get stored FCM token: $e');
      }
      return null;
    }
  }

  /// Check if the stored token is still valid (not older than 1 week)
  Future<bool> isTokenValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_tokenTimestampKey);

      if (timestamp == null) return false;

      final tokenDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));

      return tokenDate.isAfter(weekAgo);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to check token validity: $e');
      }
      return false;
    }
  }

  /// Get fresh token from Firebase and store it
  Future<String?> refreshToken() async {
    if (!isAvailable) {
      FirebaseService.logServiceAttempt('FCM', 'refreshToken');
      return null;
    }

    try {
      final newToken = await NotificationService.instance.getToken();

      if (newToken != null) {
        await storeToken(newToken);
        if (kDebugMode) {
          print('🔄 FCM Token refreshed successfully');
        }
        return newToken;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to refresh FCM token: $e');
      }
      return null;
    }
  }

  /// Get current valid token (refresh if needed)
  Future<String?> getCurrentToken() async {
    if (!isAvailable) {
      FirebaseService.logServiceAttempt('FCM', 'getCurrentToken');
      // Return locally stored token as fallback
      return await getStoredToken();
    }

    try {
      // Check if we have a valid stored token
      if (await isTokenValid()) {
        final storedToken = await getStoredToken();
        if (storedToken != null) {
          if (kDebugMode) {
            print('✅ Using valid stored FCM token');
          }
          return storedToken;
        }
      }

      // Token is invalid or doesn't exist, get a fresh one
      if (kDebugMode) {
        print('🔄 Refreshing FCM token...');
      }
      return await refreshToken();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get current FCM token: $e');
      }
      return null;
    }
  }

  /// Remove stored token locally and from Supabase
  Future<void> removeToken() async {
    try {
      // Remove locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_tokenTimestampKey);

      // Remove from Supabase
      await _removeTokenFromSupabase();

      // Delete from Firebase if available
      if (isAvailable) {
        await NotificationService.instance.deleteToken();
      } else {
        FirebaseService.logServiceAttempt('FCM', 'deleteToken');
      }

      if (kDebugMode) {
        print('🗑️ FCM Token removed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to remove FCM token: $e');
      }
    }
  }

  /// Store token in Supabase user profile
  Future<void> _storeTokenInSupabase(String token) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        if (kDebugMode) {
          print('⚠️ No authenticated user, cannot store FCM token in Supabase');
        }
        return;
      }

      // Update user metadata with FCM token
      await supabase.auth.updateUser(
        UserAttributes(
          data: {
            'fcm_token': token,
            'fcm_token_updated_at': DateTime.now().toIso8601String(),
            'device_platform': defaultTargetPlatform.name,
          },
        ),
      );

      // Also store in a dedicated table for better querying
      await supabase.from('user_fcm_tokens').upsert({
        'user_id': user.id,
        'fcm_token': token,
        'device_platform': defaultTargetPlatform.name,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        print('✅ FCM Token stored in Supabase');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to store FCM token in Supabase: $e');
      }
      // Don't throw - this is non-critical for local functionality
    }
  }

  /// Remove token from Supabase user profile
  Future<void> _removeTokenFromSupabase() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) return;

      // Remove from user metadata
      await supabase.auth.updateUser(
        UserAttributes(data: {'fcm_token': null, 'fcm_token_updated_at': null}),
      );

      // Remove from dedicated table
      await supabase.from('user_fcm_tokens').delete().eq('user_id', user.id);

      if (kDebugMode) {
        print('✅ FCM Token removed from Supabase');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to remove FCM token from Supabase: $e');
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
        print('❌ Failed to get user FCM tokens: $e');
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
        print('🧹 Expired FCM tokens cleaned up');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to cleanup expired FCM tokens: $e');
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
        print('✅ Subscribed to user topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to subscribe to user topic: $e');
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
        print('✅ Unsubscribed from user topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to unsubscribe from user topic: $e');
      }
    }
  }
}
