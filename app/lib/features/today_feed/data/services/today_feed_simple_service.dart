// Slim Today Feed Data Service

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/today_feed_content.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/today_feed_local_store.dart';

/// A trimmed-down replacement for TodayFeedDataService.
/// Keeps only what is required: load cached content, decide if refresh is needed,
/// fetch fresh content from Supabase, and cache it locally.
class TodayFeedSimpleService {
  static bool _initialized = false;

  static Future<void> _init() async {
    if (_initialized) return;
    // Connectivity service is already used elsewhere – initialise once.
    await ConnectivityService.initialize();
    _initialized = true;
  }

  /// Returns cached content first if available, then (optionally) fetches fresh.
  static Future<TodayFeedContent?> getTodayContent({
    bool forceRefresh = false,
  }) async {
    await _init();

    final cached = await TodayFeedLocalStore.getCachedContent();

    final needsRefresh =
        forceRefresh || await TodayFeedLocalStore.needsRefresh();

    if (!needsRefresh) return cached; // still fresh enough

    if (!ConnectivityService.isOnline) {
      debugPrint('📡 [TodayFeed] Device offline – using cached content');
      return cached; // could be null; caller must handle fallback
    }

    debugPrint('🌐 [TodayFeed] Fetching fresh content from Supabase...');
    final fresh = await _fetchFromSupabase();

    if (fresh != null) {
      await TodayFeedLocalStore.saveContent(fresh);
      debugPrint('✅ [TodayFeed] Fresh content fetched & cached');
      return fresh;
    }

    debugPrint('⚠️ [TodayFeed] Failed to fetch fresh content – using cache');
    return cached;
  }

  static Future<TodayFeedContent?> refreshContent() async =>
      getTodayContent(forceRefresh: true);

  /// Placeholder – interactions can be sent directly, no offline queue.
  static Future<void> recordInteraction(
    TodayFeedInteractionType type,
    TodayFeedContent content,
  ) async {
    debugPrint('ℹ️  [TodayFeed] Interaction recorded locally: ${type.value}');
    // TODO: Implement API hit if needed.
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------
  static Future<TodayFeedContent?> _fetchFromSupabase() async {
    try {
      final supabase = Supabase.instance.client;
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final resp =
          await supabase
              .from('daily_feed_content')
              .select('*')
              .eq('content_date', todayStr)
              .maybeSingle();

      if (resp == null) {
        debugPrint(
          '📭 [TodayFeed] No row for today – edge-function will generate',
        );
        // Trigger generation fire-and-forget
        await _triggerGeneration(todayStr);
        return null;
      }

      final content = TodayFeedContent.fromJson({
        'id': resp['id'],
        'content_date': resp['content_date'],
        'title': resp['title'],
        'summary': resp['summary'],
        'content_url': resp['content_url'],
        'external_link': resp['external_link'],
        'topic_category': resp['topic_category'],
        'ai_confidence_score': resp['ai_confidence_score'] ?? 0.8,
        'created_at': resp['created_at'],
        'updated_at': resp['updated_at'],
        'estimated_reading_minutes': 2,
        'has_user_engaged': false,
        'is_cached': false,
      });

      return content;
    } catch (e) {
      debugPrint('❌ [TodayFeed] Supabase fetch error: $e');
      return null;
    }
  }

  static Future<void> _triggerGeneration(String date) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.functions.invoke(
        'daily-content-generator',
        body: {'target_date': date, 'force_regenerate': false},
      );
      debugPrint('🚀 [TodayFeed] Triggered content generation');
    } catch (e) {
      debugPrint('❌ [TodayFeed] Failed to trigger generation: $e');
    }
  }
}
