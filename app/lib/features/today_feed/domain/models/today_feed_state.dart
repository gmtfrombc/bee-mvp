part of 'today_feed_content.dart';

/// State management class for Today Feed content loading states
class TodayFeedState {
  const TodayFeedState._();

  /// Factory constructor for loading state
  const factory TodayFeedState.loading() = TodayFeedStateLoading;

  /// Factory constructor for successfully loaded state
  const factory TodayFeedState.loaded(TodayFeedContent content) =
      TodayFeedStateLoaded;

  /// Factory constructor for error state
  const factory TodayFeedState.error(String message) = TodayFeedStateError;

  /// Factory constructor for offline state with cached content
  const factory TodayFeedState.offline(TodayFeedContent cachedContent) =
      TodayFeedStateOffline;

  /// Factory constructor for fallback state with metadata
  const factory TodayFeedState.fallback(
    TodayFeedFallbackResult fallbackResult,
  ) = TodayFeedStateFallback;

  /// Pattern matching methods
  T when<T>({
    required T Function() loading,
    required T Function(TodayFeedContent content) loaded,
    required T Function(String message) error,
    required T Function(TodayFeedContent cachedContent) offline,
    required T Function(TodayFeedFallbackResult fallbackResult) fallback,
  }) {
    if (this is TodayFeedStateLoading) {
      return loading();
    } else if (this is TodayFeedStateLoaded) {
      return loaded((this as TodayFeedStateLoaded).content);
    } else if (this is TodayFeedStateError) {
      return error((this as TodayFeedStateError).message);
    } else if (this is TodayFeedStateOffline) {
      return offline((this as TodayFeedStateOffline).cachedContent);
    } else if (this is TodayFeedStateFallback) {
      return fallback((this as TodayFeedStateFallback).fallbackResult);
    }
    throw StateError('Invalid TodayFeedState');
  }

  /// Convenience getters
  bool get isLoading => this is TodayFeedStateLoading;
  bool get isLoaded => this is TodayFeedStateLoaded;
  bool get isError => this is TodayFeedStateError;
  bool get isOffline => this is TodayFeedStateOffline;
  bool get isFallback => this is TodayFeedStateFallback;

  /// Get content if available
  TodayFeedContent? get content {
    if (this is TodayFeedStateLoaded) {
      return (this as TodayFeedStateLoaded).content;
    } else if (this is TodayFeedStateOffline) {
      return (this as TodayFeedStateOffline).cachedContent;
    } else if (this is TodayFeedStateFallback) {
      return (this as TodayFeedStateFallback).fallbackResult.content;
    }
    return null;
  }

  /// Get error message if in error state
  String? get errorMessage {
    return this is TodayFeedStateError
        ? (this as TodayFeedStateError).message
        : null;
  }
}

/// Loading state implementation
class TodayFeedStateLoading extends TodayFeedState {
  const TodayFeedStateLoading() : super._();

  @override
  String toString() => 'TodayFeedState.loading()';

  @override
  bool operator ==(Object other) => other is TodayFeedStateLoading;

  @override
  int get hashCode => 0;
}

/// Loaded state implementation
class TodayFeedStateLoaded extends TodayFeedState {
  @override
  final TodayFeedContent content;

  const TodayFeedStateLoaded(this.content) : super._();

  @override
  String toString() => 'TodayFeedState.loaded($content)';

  @override
  bool operator ==(Object other) {
    return other is TodayFeedStateLoaded && other.content == content;
  }

  @override
  int get hashCode => content.hashCode;
}

/// Error state implementation
class TodayFeedStateError extends TodayFeedState {
  final String message;

  const TodayFeedStateError(this.message) : super._();

  @override
  String toString() => 'TodayFeedState.error($message)';

  @override
  bool operator ==(Object other) {
    return other is TodayFeedStateError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

/// Offline state implementation
class TodayFeedStateOffline extends TodayFeedState {
  final TodayFeedContent cachedContent;

  const TodayFeedStateOffline(this.cachedContent) : super._();

  @override
  String toString() => 'TodayFeedState.offline($cachedContent)';

  @override
  bool operator ==(Object other) {
    return other is TodayFeedStateOffline &&
        other.cachedContent == cachedContent;
  }

  @override
  int get hashCode => cachedContent.hashCode;
}

/// Fallback state implementation
class TodayFeedStateFallback extends TodayFeedState {
  final TodayFeedFallbackResult fallbackResult;

  const TodayFeedStateFallback(this.fallbackResult) : super._();

  @override
  String toString() => 'TodayFeedState.fallback($fallbackResult)';

  @override
  bool operator ==(Object other) {
    return other is TodayFeedStateFallback &&
        other.fallbackResult == fallbackResult;
  }

  @override
  int get hashCode => fallbackResult.hashCode;
}

/// User interaction data model for tracking engagement
class TodayFeedInteraction {
  final String? id;
  final String userId;
  final int contentId;
  final TodayFeedInteractionType interactionType;
  final DateTime interactionTimestamp;
  final int? sessionDuration; // in seconds

  const TodayFeedInteraction({
    this.id,
    required this.userId,
    required this.contentId,
    required this.interactionType,
    required this.interactionTimestamp,
    this.sessionDuration,
  });

  /// Create from API JSON response
  factory TodayFeedInteraction.fromJson(Map<String, dynamic> json) {
    return TodayFeedInteraction(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      contentId: json['content_id'] as int,
      interactionType: TodayFeedInteractionType.fromString(
        json['interaction_type'] as String,
      ),
      interactionTimestamp: DateTime.parse(
        json['interaction_timestamp'] as String,
      ),
      sessionDuration: json['session_duration'] as int?,
    );
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'content_id': contentId,
      'interaction_type': interactionType.value,
      'interaction_timestamp': interactionTimestamp.toIso8601String(),
      if (sessionDuration != null) 'session_duration': sessionDuration,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TodayFeedInteraction &&
        other.userId == userId &&
        other.contentId == contentId &&
        other.interactionType == interactionType &&
        other.interactionTimestamp == interactionTimestamp;
  }

  @override
  int get hashCode {
    return Object.hash(
      userId,
      contentId,
      interactionType,
      interactionTimestamp,
    );
  }

  @override
  String toString() {
    return 'TodayFeedInteraction(userId: $userId, contentId: $contentId, type: ${interactionType.value})';
  }
}

/// Fallback content result with metadata for enhanced error handling
class TodayFeedFallbackResult {
  final TodayFeedContent? content;
  final TodayFeedFallbackType fallbackType;
  final Duration contentAge;
  final bool isStale;
  final String userMessage;
  final bool shouldShowAgeWarning;
  final DateTime? lastAttemptToRefresh;

  const TodayFeedFallbackResult({
    required this.content,
    required this.fallbackType,
    required this.contentAge,
    required this.isStale,
    required this.userMessage,
    required this.shouldShowAgeWarning,
    required this.lastAttemptToRefresh,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TodayFeedFallbackResult &&
        other.content == content &&
        other.fallbackType == fallbackType &&
        other.contentAge == contentAge &&
        other.isStale == isStale &&
        other.userMessage == userMessage &&
        other.shouldShowAgeWarning == shouldShowAgeWarning &&
        other.lastAttemptToRefresh == lastAttemptToRefresh;
  }

  @override
  int get hashCode {
    return Object.hash(
      content,
      fallbackType,
      contentAge,
      isStale,
      userMessage,
      shouldShowAgeWarning,
      lastAttemptToRefresh,
    );
  }
}

/// Types of fallback content sources
enum TodayFeedFallbackType {
  previousDay('previous_day'),
  contentHistory('content_history'),
  none('none'),
  error('error');

  const TodayFeedFallbackType(this.value);
  final String value;
}

/// Content age validation result
class ContentAgeValidation {
  final bool isValid;
  final bool shouldWarn;
  final ContentAgeSeverity severity;
  final String message;

  const ContentAgeValidation({
    required this.isValid,
    required this.shouldWarn,
    required this.severity,
    required this.message,
  });
}

/// Content age severity levels
enum ContentAgeSeverity {
  fresh('fresh'),
  somewhatStale('somewhat_stale'),
  stale('stale'),
  veryStale('very_stale');

  const ContentAgeSeverity(this.value);
  final String value;
}
