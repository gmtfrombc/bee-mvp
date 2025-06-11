/// Lightweight local storage helper for Today Feed
/// Stores a single JSON blob for today's content and the last refresh date.
/// Keeps implementation minimal and avoids dependency on the heavy cache stack.
library;
// ignore_for_file: unused_import

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/today_feed/domain/models/today_feed_content.dart';
import 'package:flutter/foundation.dart';

class TodayFeedLocalStore {
  static const _contentKey = 'today_feed_content';
  static const _lastRefreshKey = 'today_feed_last_refresh';

  static SharedPreferences? _prefs;

  static Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Save content and mark refresh time
  static Future<void> saveContent(TodayFeedContent content) async {
    await _ensurePrefs();
    final jsonStr = jsonEncode(content.toJson());
    await _prefs!.setString(_contentKey, jsonStr);
    await _prefs!.setString(_lastRefreshKey, DateTime.now().toIso8601String());
    debugPrint('✅ [LocalStore] Today content saved');
  }

  /// Return cached content if any (regardless of freshness)
  static Future<TodayFeedContent?> getCachedContent() async {
    await _ensurePrefs();
    final jsonStr = _prefs!.getString(_contentKey);
    if (jsonStr == null) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return TodayFeedContent.fromJson(map);
    } catch (e) {
      debugPrint('❌ [LocalStore] Failed to decode cached content: $e');
      return null;
    }
  }

  /// Date of last successful refresh (null if never)
  static Future<DateTime?> lastRefresh() async {
    await _ensurePrefs();
    final str = _prefs!.getString(_lastRefreshKey);
    if (str == null) return null;
    return DateTime.tryParse(str);
  }

  /// Determine if refresh is needed (new calendar day or force)
  static Future<bool> needsRefresh() async {
    final last = await lastRefresh();
    if (last == null) return true;
    final now = DateTime.now();
    return !(last.year == now.year &&
        last.month == now.month &&
        last.day == now.day);
  }

  /// Clear store (debug / troubleshooting)
  static Future<void> clear() async {
    await _ensurePrefs();
    await _prefs!.remove(_contentKey);
    await _prefs!.remove(_lastRefreshKey);
  }
}
