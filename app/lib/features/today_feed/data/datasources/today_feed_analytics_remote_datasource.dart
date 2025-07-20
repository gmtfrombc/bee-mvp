import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data-source for interaction analytics & reading sessions.
/// Encapsulates all Supabase writes so services remain storage-agnostic.
class TodayFeedAnalyticsRemoteDataSource {
  TodayFeedAnalyticsRemoteDataSource() : _supabase = Supabase.instance.client;

  final SupabaseClient _supabase;

  /// Inserts a user interaction analytics event.
  Future<void> insertInteractionEvent(Map<String, dynamic> data) async {
    await _supabase.from('today_feed_analytics_events').insert(data);
  }

  /// Inserts a reading-session row.
  Future<void> insertReadingSession(Map<String, dynamic> data) async {
    await _supabase.from('today_feed_reading_sessions').insert(data);
  }
}
