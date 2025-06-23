// Slim Today Feed Data Service

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/today_feed_content.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/today_feed_local_store.dart';
import 'dart:async';

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
    var fresh = await _fetchFromSupabase();

    if (fresh != null) {
      // Preserve local engagement flag if same article id/date
      if (cached != null && cached.id == fresh.id) {
        fresh = fresh.copyWith(hasUserEngaged: cached.hasUserEngaged);
      }

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

      // -------------------------------------------------------------
      // New approach (2025-06-22): backend always marks the most-recent
      // row as `is_active = true` and exposes a view that returns *only*
      // that winner.  No date filtering required here – we simply grab
      // the single row from the view.
      // -------------------------------------------------------------

      final resp =
          await supabase
              .from('daily_feed_content_current')
              .select('*')
              .maybeSingle();

      if (resp == null) {
        debugPrint('📭 [TodayFeed] No active daily content row yet');

        // Kick off generation for today in the background so the user
        // will see content after a short delay without blocking the UI.
        final today = DateTime.now();
        final todayStr =
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        unawaited(_triggerGeneration(todayStr));
        return null;
      }

      // If rich payload missing, request regeneration (edge-case safety)
      if (resp['full_content'] == null) {
        final today = DateTime.now();
        final todayStr =
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        unawaited(_triggerGeneration(todayStr, forceRegenerate: true));
      }

      final content = TodayFeedContent.fromJson({
        'id': resp['id'],
        'content_date': resp['content_date'],
        'title': resp['title'],
        'summary': resp['summary'],
        'content_url': resp['content_url'],
        'external_link': resp['external_link'],
        'topic_category': resp['topic_category'],
        if (resp['full_content'] != null) 'full_content': resp['full_content'],
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

  static Future<void> _triggerGeneration(
    String date, {
    bool forceRegenerate = false,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.functions.invoke(
        'daily-content-generator',
        body: {'target_date': date, 'force_regenerate': forceRegenerate},
      );
      debugPrint('🚀 [TodayFeed] Triggered content generation');
    } catch (e) {
      debugPrint('❌ [TodayFeed] Failed to trigger generation: $e');
    }
  }
}
