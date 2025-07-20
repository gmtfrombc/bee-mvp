import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/models/today_feed_content.dart';
import '../models/today_feed_sharing_models.dart';
import '../../../../core/services/connectivity_service.dart';
import 'user_content_interaction_service.dart';
import 'today_feed_momentum_award_service.dart';
import 'today_feed_analytics_service.dart';

/// Service for handling Today Feed content sharing and bookmarking
/// with momentum bonus rewards
///
/// This service handles:
/// - Content sharing with native platform integration
/// - Bookmark management with local and remote storage
/// - Momentum bonus awards for sharing and bookmarking actions
/// - Offline support with sync capabilities
/// - Analytics tracking for social engagement metrics
class TodayFeedSharingService {
  static final TodayFeedSharingService _instance =
      TodayFeedSharingService._internal();
  factory TodayFeedSharingService() => _instance;
  TodayFeedSharingService._internal();

  // Dependencies
  late final SupabaseClient _supabase;
  late final UserContentInteractionService _interactionService;
  late final TodayFeedAnalyticsService _analyticsService;
  late final TodayFeedMomentumAwardService _momentumService;
  bool _isInitialized = false;
  final List<Map<String, dynamic>> _pendingActions = [];
  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;

  // Configuration constants for momentum bonuses
  static const int shareMomentumBonus = 2; // +2 points for sharing
  static const int bookmarkMomentumBonus = 1; // +1 point for bookmarking
  static const int maxDailyShareBonuses = 3; // Max 3 share bonuses per day
  static const int maxDailyBookmarkBonuses =
      5; // Max 5 bookmark bonuses per day
  static const Duration cooldownPeriod = Duration(minutes: 5); // Prevent spam

  // Moved cooldown & daily tracking to TodayFeedAnalyticsService

  /// Initialize the sharing service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _supabase = Supabase.instance.client;
      _interactionService = UserContentInteractionService();
      _momentumService = TodayFeedMomentumAwardService();
      _analyticsService = TodayFeedAnalyticsService();

      // Initialize dependencies
      await _interactionService.initialize();
      await _momentumService.initialize();
      await _analyticsService.initialize();

      // Set up connectivity monitoring for offline support
      await ConnectivityService.initialize();
      _connectivitySubscription = ConnectivityService.statusStream.listen(
        _onConnectivityChanged,
        onError: (error) {
          debugPrint('❌ TodayFeedSharingService connectivity error: $error');
        },
      );

      _isInitialized = true;
      debugPrint('✅ TodayFeedSharingService initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize TodayFeedSharingService: $e');
      rethrow;
    }
  }

  /// Share Today Feed content with momentum bonus
  ///
  /// Shares content using native platform sharing capabilities
  /// Awards momentum bonus if daily limit not exceeded
  ///
  /// Returns: SharingResult with details about the share action and bonus
  Future<SharingResult> shareContent({
    required TodayFeedContent content,
    String? customMessage,
    List<String>? files,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    await initialize();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Check daily limit and cooldown
      final limitResult = await _analyticsService.checkActionLimits(
        userId: userId,
        actionType: 'share',
        maxDaily: maxDailyShareBonuses,
        cooldownPeriod: cooldownPeriod,
      );
      if (!limitResult.canProceed) {
        return SharingResult.limitExceeded(
          message: limitResult.reason,
          dailyCount: limitResult.currentCount,
          maxDailyCount: maxDailyShareBonuses,
        );
      }

      // Create share content text
      final shareText = _buildShareText(content, customMessage);

      // Perform native sharing
      final shareResult = await Share.shareWithResult(
        shareText,
        subject: 'Health Insight: ${content.title}',
      );

      // Record interaction regardless of share result
      await _analyticsService.recordShareInteraction(
        userId: userId,
        content: content,
        shareResult: shareResult,
        additionalMetadata: additionalMetadata,
      );

      // Award momentum bonus if sharing was successful
      MomentumBonusResult? bonusResult;
      if (shareResult.status == ShareResultStatus.success) {
        bonusResult = await _awardSharingMomentumBonus(
          userId: userId,
          content: content,
          additionalMetadata: additionalMetadata,
        );
      }

      debugPrint(
        '✅ Content shared successfully with status: ${shareResult.status}',
      );

      return SharingResult.success(
        shareStatus: shareResult.status,
        momentumBonus: bonusResult,
        shareText: shareText,
      );
    } catch (e) {
      debugPrint('❌ Failed to share content: $e');

      // Queue action for offline sync if needed
      if (ConnectivityService.currentStatus == ConnectivityStatus.offline) {
        await _queuePendingAction('share', content, additionalMetadata);
        return SharingResult.queued(
          message: 'Share queued for when back online',
        );
      }

      return SharingResult.failed(
        message: 'Failed to share content',
        error: e.toString(),
      );
    }
  }

  /// Bookmark Today Feed content with momentum bonus
  ///
  /// Saves content to user's bookmark collection
  /// Awards momentum bonus if daily limit not exceeded
  ///
  /// Returns: BookmarkResult with details about the bookmark action and bonus
  Future<BookmarkResult> bookmarkContent({
    required TodayFeedContent content,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    await initialize();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Check if already bookmarked
      final isAlreadyBookmarked = await _isContentBookmarked(userId, content);
      if (isAlreadyBookmarked) {
        return BookmarkResult.alreadyBookmarked(
          message: 'Content already bookmarked',
        );
      }

      // Check daily limit and cooldown
      final limitResult = await _analyticsService.checkActionLimits(
        userId: userId,
        actionType: 'bookmark',
        maxDaily: maxDailyBookmarkBonuses,
        cooldownPeriod: cooldownPeriod,
      );
      if (!limitResult.canProceed) {
        return BookmarkResult.limitExceeded(
          message: limitResult.reason,
          dailyCount: limitResult.currentCount,
          maxDailyCount: maxDailyBookmarkBonuses,
        );
      }

      // Save bookmark to database
      await _saveBookmark(userId, content, additionalMetadata);

      // Record interaction
      await _analyticsService.recordBookmarkInteraction(
        userId: userId,
        content: content,
        additionalMetadata: additionalMetadata,
      );

      // Award momentum bonus
      final bonusResult = await _awardBookmarkMomentumBonus(
        userId: userId,
        content: content,
        additionalMetadata: additionalMetadata,
      );

      debugPrint('✅ Content bookmarked successfully');

      return BookmarkResult.success(
        momentumBonus: bonusResult,
        bookmarkId: content.id?.toString() ?? '',
      );
    } catch (e) {
      debugPrint('❌ Failed to bookmark content: $e');

      // Queue action for offline sync if needed
      if (ConnectivityService.currentStatus == ConnectivityStatus.offline) {
        await _queuePendingAction('bookmark', content, additionalMetadata);
        return BookmarkResult.queued(
          message: 'Bookmark queued for when back online',
        );
      }

      return BookmarkResult.failed(
        message: 'Failed to bookmark content',
        error: e.toString(),
      );
    }
  }

  /// Remove bookmark from content
  ///
  /// Removes content from user's bookmark collection
  /// No momentum bonus for removal actions
  ///
  /// Returns: BookmarkResult with removal details
  Future<BookmarkResult> removeBookmark({
    required TodayFeedContent content,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    await initialize();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Check if bookmarked
      final isBookmarked = await _isContentBookmarked(userId, content);
      if (!isBookmarked) {
        return BookmarkResult.notBookmarked(message: 'Content not bookmarked');
      }

      // Remove bookmark from database
      await _removeBookmark(userId, content);

      debugPrint('✅ Bookmark removed successfully');

      return BookmarkResult.removed(message: 'Bookmark removed successfully');
    } catch (e) {
      debugPrint('❌ Failed to remove bookmark: $e');
      return BookmarkResult.failed(
        message: 'Failed to remove bookmark',
        error: e.toString(),
      );
    }
  }

  /// Check if content is bookmarked by user
  Future<bool> isContentBookmarked(TodayFeedContent content) async {
    await initialize();

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    return await _isContentBookmarked(userId, content);
  }

  /// Get user's bookmarked content
  Future<List<TodayFeedContent>> getUserBookmarks({
    int limit = 50,
    DateTime? since,
  }) async {
    await initialize();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      dynamic query = _supabase
          .from('user_today_feed_bookmarks')
          .select('''
            content_id,
            bookmarked_at,
            daily_feed_content:content_id (
              id,
              content_date,
              title,
              summary,
              content_url,
              external_link,
              topic_category,
              ai_confidence_score,
              created_at,
              updated_at
            )
          ''')
          .eq('user_id', userId);

      // Apply date filter before ordering and limiting
      if (since != null) {
        query = query.gte('bookmarked_at', since.toIso8601String());
      }

      // Apply ordering and limiting after filtering
      query = query.order('bookmarked_at', ascending: false).limit(limit);

      final response = await query;

      final bookmarks =
          (response as List).map((item) {
            final contentData =
                item['daily_feed_content'] as Map<String, dynamic>;
            return TodayFeedContent.fromJson(contentData);
          }).toList();

      debugPrint('✅ Retrieved ${bookmarks.length} user bookmarks');
      return bookmarks;
    } catch (e) {
      debugPrint('❌ Failed to get user bookmarks: $e');
      return [];
    }
  }

  /// Get sharing and bookmarking statistics
  Future<SocialEngagementStats> getSocialEngagementStats(String userId) async {
    await initialize();

    try {
      // Get sharing stats
      final sharingStats = await _supabase
          .from('user_content_interactions')
          .select('interaction_timestamp')
          .eq('user_id', userId)
          .eq('interaction_type', 'share')
          .gte(
            'interaction_timestamp',
            DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          );

      // Get bookmark stats
      final bookmarkStats = await _supabase
          .from('user_today_feed_bookmarks')
          .select('bookmarked_at')
          .eq('user_id', userId)
          .gte(
            'bookmarked_at',
            DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          );

      // Calculate today's counts
      final todayStart = DateTime.now().copyWith(hour: 0, minute: 0, second: 0);
      final todayShares =
          (sharingStats as List)
              .where(
                (item) => DateTime.parse(
                  item['interaction_timestamp'],
                ).isAfter(todayStart),
              )
              .length;
      final todayBookmarks =
          (bookmarkStats as List)
              .where(
                (item) =>
                    DateTime.parse(item['bookmarked_at']).isAfter(todayStart),
              )
              .length;

      return SocialEngagementStats(
        totalShares: (sharingStats as List).length,
        totalBookmarks: (bookmarkStats as List).length,
        todayShares: todayShares,
        todayBookmarks: todayBookmarks,
        sharesRemaining: maxDailyShareBonuses - todayShares,
        bookmarksRemaining: maxDailyBookmarkBonuses - todayBookmarks,
        monthlyShares: (sharingStats as List).length,
        monthlyBookmarks: (bookmarkStats as List).length,
      );
    } catch (e) {
      debugPrint('❌ Failed to get social engagement stats: $e');
      return const SocialEngagementStats.empty();
    }
  }

  // Private helper methods

  /// Build share text for content
  String _buildShareText(TodayFeedContent content, String? customMessage) {
    final baseText =
        customMessage ??
        'Check out this health insight: "${content.title}"\n\n${content.summary}';

    final linkText =
        content.externalLink != null
            ? '\n\nRead more: ${content.externalLink}'
            : '';

    return '$baseText$linkText\n\nShared from the BEE Health App 🐝';
  }

  /// Award momentum bonus for sharing
  Future<MomentumBonusResult> _awardSharingMomentumBonus({
    required String userId,
    required TodayFeedContent content,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    try {
      // Award bonus points through momentum service
      final awardResult = await _momentumService.awardMomentumPoints(
        userId: userId,
        content: content,
        interactionMetadata: {
          'interaction_type': 'share',
          'bonus_points': shareMomentumBonus,
          'bonus_reason': 'content_sharing',
          ...?additionalMetadata,
        },
      );

      if (awardResult.success) {
        // Record bonus analytics
        await _analyticsService.recordBonusAnalytics(
          userId: userId,
          content: content,
          bonusType: 'share',
          pointsAwarded: shareMomentumBonus,
        );

        return MomentumBonusResult.success(
          bonusPoints: shareMomentumBonus,
          message: 'Great job sharing! +$shareMomentumBonus momentum points',
          awardTime: awardResult.awardTime ?? DateTime.now(),
        );
      } else {
        return MomentumBonusResult.failed(
          message: awardResult.message,
          error: awardResult.error,
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to award sharing momentum bonus: $e');
      return MomentumBonusResult.failed(
        message: 'Failed to award sharing bonus',
        error: e.toString(),
      );
    }
  }

  /// Award momentum bonus for bookmarking
  Future<MomentumBonusResult> _awardBookmarkMomentumBonus({
    required String userId,
    required TodayFeedContent content,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    try {
      // Award bonus points through momentum service
      final awardResult = await _momentumService.awardMomentumPoints(
        userId: userId,
        content: content,
        interactionMetadata: {
          'interaction_type': 'bookmark',
          'bonus_points': bookmarkMomentumBonus,
          'bonus_reason': 'content_bookmarking',
          ...?additionalMetadata,
        },
      );

      if (awardResult.success) {
        // Record bonus analytics
        await _analyticsService.recordBonusAnalytics(
          userId: userId,
          content: content,
          bonusType: 'bookmark',
          pointsAwarded: bookmarkMomentumBonus,
        );

        return MomentumBonusResult.success(
          bonusPoints: bookmarkMomentumBonus,
          message: 'Nice save! +$bookmarkMomentumBonus momentum point',
          awardTime: awardResult.awardTime ?? DateTime.now(),
        );
      } else {
        return MomentumBonusResult.failed(
          message: awardResult.message,
          error: awardResult.error,
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to award bookmark momentum bonus: $e');
      return MomentumBonusResult.failed(
        message: 'Failed to award bookmark bonus',
        error: e.toString(),
      );
    }
  }

  /// Check if content is bookmarked by user
  Future<bool> _isContentBookmarked(
    String userId,
    TodayFeedContent content,
  ) async {
    try {
      final result = await _supabase
          .from('user_today_feed_bookmarks')
          .select('id')
          .eq('user_id', userId)
          .eq('content_id', content.id ?? 0)
          .limit(1);

      return (result as List).isNotEmpty;
    } catch (e) {
      debugPrint('❌ Failed to check bookmark status: $e');
      return false;
    }
  }

  /// Save bookmark to database
  Future<void> _saveBookmark(
    String userId,
    TodayFeedContent content,
    Map<String, dynamic>? additionalMetadata,
  ) async {
    try {
      await _supabase.from('user_today_feed_bookmarks').insert({
        'user_id': userId,
        'content_id': content.id ?? 0,
        'content_title': content.title,
        'content_date': content.contentDate.toIso8601String().split('T')[0],
        'topic_category': content.topicCategory.value,
        'bookmarked_at': DateTime.now().toIso8601String(),
        'metadata': {
          'ai_confidence_score': content.aiConfidenceScore,
          'estimated_reading_minutes': content.estimatedReadingMinutes,
          'source': 'today_feed_sharing_service',
          ...?additionalMetadata,
        },
      });

      debugPrint('✅ Bookmark saved to database');
    } catch (e) {
      debugPrint('❌ Failed to save bookmark: $e');
      rethrow;
    }
  }

  /// Remove bookmark from database
  Future<void> _removeBookmark(String userId, TodayFeedContent content) async {
    try {
      await _supabase
          .from('user_today_feed_bookmarks')
          .delete()
          .eq('user_id', userId)
          .eq('content_id', content.id ?? 0);

      debugPrint('✅ Bookmark removed from database');
    } catch (e) {
      debugPrint('❌ Failed to remove bookmark: $e');
      rethrow;
    }
  }

  // (removed unused legacy wrapper methods – now handled directly via
  // _analyticsService)

  /// Queue pending action for offline sync
  Future<void> _queuePendingAction(
    String actionType,
    TodayFeedContent content,
    Map<String, dynamic>? additionalMetadata,
  ) async {
    try {
      if (_pendingActions.length >= 50) {
        // Remove oldest pending action
        _pendingActions.removeAt(0);
      }

      _pendingActions.add({
        'action_type': actionType,
        'content_id': content.id,
        'content_data': content.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
        'metadata': additionalMetadata ?? {},
      });

      debugPrint('📋 Queued $actionType action for offline sync');
    } catch (e) {
      debugPrint('❌ Failed to queue pending action: $e');
    }
  }

  /// Handle connectivity changes for offline sync
  void _onConnectivityChanged(ConnectivityStatus status) {
    if (status == ConnectivityStatus.online && _pendingActions.isNotEmpty) {
      _syncPendingActions();
    }
  }

  /// Sync pending actions when back online
  Future<void> _syncPendingActions() async {
    if (_pendingActions.isEmpty) return;

    debugPrint('🔄 Syncing ${_pendingActions.length} pending actions');

    final actionsToSync = List<Map<String, dynamic>>.from(_pendingActions);
    _pendingActions.clear();

    for (final action in actionsToSync) {
      try {
        final content = TodayFeedContent.fromJson(
          action['content_data'] as Map<String, dynamic>,
        );
        final actionType = action['action_type'] as String;
        final metadata = action['metadata'] as Map<String, dynamic>?;

        if (actionType == 'share') {
          await shareContent(content: content, additionalMetadata: metadata);
        } else if (actionType == 'bookmark') {
          await bookmarkContent(content: content, additionalMetadata: metadata);
        }
      } catch (e) {
        debugPrint('❌ Failed to sync pending action: $e');
        // Re-queue failed action
        _pendingActions.add(action);
      }
    }

    debugPrint('✅ Pending actions sync completed');
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _pendingActions.clear();
    // cooldown cache lives in analytics service now
    _isInitialized = false;
    debugPrint('✅ TodayFeedSharingService disposed');
  }
}
