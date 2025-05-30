import 'package:intl/intl.dart';

/// Sentinel value for tracking unset parameters in copyWith methods
const Object _unset = Object();

/// Health topic categories for Today Feed content
enum HealthTopic {
  nutrition('nutrition'),
  exercise('exercise'),
  sleep('sleep'),
  stress('stress'),
  prevention('prevention'),
  lifestyle('lifestyle');

  const HealthTopic(this.value);
  final String value;

  static HealthTopic fromString(String value) {
    return HealthTopic.values.firstWhere(
      (topic) => topic.value == value,
      orElse: () => HealthTopic.lifestyle, // Default fallback
    );
  }
}

/// Content interaction types for tracking user engagement
enum TodayFeedInteractionType {
  view('view'),
  tap('tap'),
  externalLinkClick('external_link_click'),
  share('share'),
  bookmark('bookmark');

  const TodayFeedInteractionType(this.value);
  final String value;

  static TodayFeedInteractionType fromString(String value) {
    return TodayFeedInteractionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => TodayFeedInteractionType.view, // Default fallback
    );
  }
}

/// Rich content element types for structured health content
enum RichContentType {
  paragraph('paragraph'),
  bulletList('bullet_list'),
  numberedList('numbered_list'),
  heading('heading'),
  highlight('highlight'),
  externalLink('external_link'),
  tip('tip'),
  warning('warning');

  const RichContentType(this.value);
  final String value;

  static RichContentType fromString(String value) {
    return RichContentType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => RichContentType.paragraph,
    );
  }
}

/// Individual rich content element
class RichContentElement {
  final RichContentType type;
  final String text;
  final List<String>? listItems;
  final String? linkUrl;
  final String? linkText;
  final bool isBold;
  final bool isItalic;

  const RichContentElement({
    required this.type,
    required this.text,
    this.listItems,
    this.linkUrl,
    this.linkText,
    this.isBold = false,
    this.isItalic = false,
  });

  factory RichContentElement.fromJson(Map<String, dynamic> json) {
    return RichContentElement(
      type: RichContentType.fromString(json['type'] as String),
      text: json['text'] as String,
      listItems:
          json['list_items'] != null
              ? List<String>.from(json['list_items'] as List)
              : null,
      linkUrl: json['link_url'] as String?,
      linkText: json['link_text'] as String?,
      isBold: json['is_bold'] as bool? ?? false,
      isItalic: json['is_italic'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'text': text,
      if (listItems != null) 'list_items': listItems,
      if (linkUrl != null) 'link_url': linkUrl,
      if (linkText != null) 'link_text': linkText,
      'is_bold': isBold,
      'is_italic': isItalic,
    };
  }

  /// Create a copy of this element with updated properties
  RichContentElement copyWith({
    RichContentType? type,
    String? text,
    List<String>? listItems,
    String? linkUrl,
    String? linkText,
    bool? isBold,
    bool? isItalic,
  }) {
    return RichContentElement(
      type: type ?? this.type,
      text: text ?? this.text,
      listItems: listItems ?? this.listItems,
      linkUrl: linkUrl ?? this.linkUrl,
      linkText: linkText ?? this.linkText,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
    );
  }
}

/// Rich content structure for Today Feed
class TodayFeedRichContent {
  final List<RichContentElement> elements;
  final List<String> keyTakeaways;
  final String? actionableAdvice;
  final String? sourceReference;

  const TodayFeedRichContent({
    required this.elements,
    this.keyTakeaways = const [],
    this.actionableAdvice,
    this.sourceReference,
  });

  factory TodayFeedRichContent.fromJson(Map<String, dynamic> json) {
    return TodayFeedRichContent(
      elements:
          (json['elements'] as List<dynamic>)
              .map(
                (e) => RichContentElement.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
      keyTakeaways:
          json['key_takeaways'] != null
              ? List<String>.from(json['key_takeaways'] as List)
              : const [],
      actionableAdvice: json['actionable_advice'] as String?,
      sourceReference: json['source_reference'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'elements': elements.map((e) => e.toJson()).toList(),
      'key_takeaways': keyTakeaways,
      if (actionableAdvice != null) 'actionable_advice': actionableAdvice,
      if (sourceReference != null) 'source_reference': sourceReference,
    };
  }

  /// Create a copy of this rich content with updated properties
  TodayFeedRichContent copyWith({
    List<RichContentElement>? elements,
    List<String>? keyTakeaways,
    String? actionableAdvice,
    String? sourceReference,
  }) {
    return TodayFeedRichContent(
      elements: elements ?? this.elements,
      keyTakeaways: keyTakeaways ?? this.keyTakeaways,
      actionableAdvice: actionableAdvice ?? this.actionableAdvice,
      sourceReference: sourceReference ?? this.sourceReference,
    );
  }

  /// Create sample rich content for demo purposes
  factory TodayFeedRichContent.sample() {
    return TodayFeedRichContent(
      elements: [
        const RichContentElement(
          type: RichContentType.paragraph,
          text:
              "Sleep is more than just rest—it's when your immune system gets to work. During deep sleep phases, your body produces infection-fighting cells and antibodies that keep you healthy.",
        ),
        const RichContentElement(
          type: RichContentType.heading,
          text: "Why Sleep Matters for Immunity",
          isBold: true,
        ),
        const RichContentElement(
          type: RichContentType.bulletList,
          text: "Key immune benefits of quality sleep:",
          listItems: [
            "Produces T-cells that fight infection",
            "Releases cytokines that regulate inflammation",
            "Strengthens memory of previous infections",
            "Helps vaccines work more effectively",
          ],
        ),
        const RichContentElement(
          type: RichContentType.tip,
          text:
              "Aim for 7-9 hours of sleep nightly. Keep your bedroom cool (60-67°F) and dark for optimal immune recovery.",
        ),
        const RichContentElement(
          type: RichContentType.externalLink,
          text: "Learn more about sleep and immunity research",
          linkUrl: "https://example.com/sleep-research-study",
          linkText: "View Research Study →",
        ),
      ],
      keyTakeaways: [
        "Sleep directly impacts immune system strength",
        "Deep sleep phases are crucial for infection recovery",
        "7-9 hours nightly supports optimal immune function",
      ],
      actionableAdvice:
          "Start tonight: Put your phone in another room 30 minutes before bedtime to improve sleep quality and immune recovery.",
      sourceReference:
          "Based on research from the Sleep Foundation and Harvard Medical School",
    );
  }
}

/// Today Feed content data model representing daily AI-generated health content
class TodayFeedContent {
  final int? id;
  final DateTime contentDate;
  final String title;
  final String summary;
  final String? contentUrl;
  final String? externalLink;
  final HealthTopic topicCategory;
  final double aiConfidenceScore;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? imageUrl;
  final int estimatedReadingMinutes;
  final bool hasUserEngaged;
  final bool isCached;
  final TodayFeedRichContent? fullContent;

  const TodayFeedContent({
    this.id,
    required this.contentDate,
    required this.title,
    required this.summary,
    this.contentUrl,
    this.externalLink,
    required this.topicCategory,
    required this.aiConfidenceScore,
    this.createdAt,
    this.updatedAt,
    this.imageUrl,
    this.estimatedReadingMinutes = 2,
    this.hasUserEngaged = false,
    this.isCached = false,
    this.fullContent,
  });

  /// Factory constructor for sample/demo data
  factory TodayFeedContent.sample() {
    final now = DateTime.now();
    return TodayFeedContent(
      id: 1,
      contentDate: now,
      title: "The Hidden Connection Between Sleep and Immune Function",
      summary:
          "New research reveals that just one night of poor sleep can reduce your immune system's effectiveness by up to 70%. Here's what you need to know about optimizing your sleep for better health.",
      contentUrl: "https://content.bee-app.com/sleep-immune-connection",
      externalLink: "https://example.com/sleep-research-study",
      topicCategory: HealthTopic.sleep,
      aiConfidenceScore: 0.85,
      createdAt: now.subtract(const Duration(hours: 6)),
      updatedAt: now.subtract(const Duration(hours: 6)),
      estimatedReadingMinutes: 3,
      hasUserEngaged: false,
      isCached: false,
      fullContent: TodayFeedRichContent.sample(),
    );
  }

  /// Create from backend API JSON response
  factory TodayFeedContent.fromJson(Map<String, dynamic> json) {
    return TodayFeedContent(
      id: json['id'] as int?,
      contentDate: DateTime.parse(json['content_date'] as String),
      title: json['title'] as String,
      summary: json['summary'] as String,
      contentUrl: json['content_url'] as String?,
      externalLink: json['external_link'] as String?,
      topicCategory: HealthTopic.fromString(json['topic_category'] as String),
      aiConfidenceScore: (json['ai_confidence_score'] as num).toDouble(),
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
      imageUrl: json['image_url'] as String?,
      estimatedReadingMinutes: json['estimated_reading_minutes'] as int? ?? 2,
      hasUserEngaged: json['has_user_engaged'] as bool? ?? false,
      isCached: json['is_cached'] as bool? ?? false,
      fullContent:
          json['full_content'] != null
              ? TodayFeedRichContent.fromJson(
                json['full_content'] as Map<String, dynamic>,
              )
              : null,
    );
  }

  /// Convert to JSON for API requests and caching
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'content_date':
          contentDate.toIso8601String().split('T')[0], // YYYY-MM-DD format
      'title': title,
      'summary': summary,
      if (contentUrl != null) 'content_url': contentUrl,
      if (externalLink != null) 'external_link': externalLink,
      'topic_category': topicCategory.value,
      'ai_confidence_score': aiConfidenceScore,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (imageUrl != null) 'image_url': imageUrl,
      'estimated_reading_minutes': estimatedReadingMinutes,
      'has_user_engaged': hasUserEngaged,
      'is_cached': isCached,
      if (fullContent != null) 'full_content': fullContent!.toJson(),
    };
  }

  /// Copy with method for immutable updates
  TodayFeedContent copyWith({
    int? id,
    DateTime? contentDate,
    String? title,
    String? summary,
    Object? contentUrl = _unset,
    Object? externalLink = _unset,
    HealthTopic? topicCategory,
    double? aiConfidenceScore,
    Object? createdAt = _unset,
    Object? updatedAt = _unset,
    Object? imageUrl = _unset,
    int? estimatedReadingMinutes,
    bool? hasUserEngaged,
    bool? isCached,
    Object? fullContent = _unset,
  }) {
    return TodayFeedContent(
      id: id ?? this.id,
      contentDate: contentDate ?? this.contentDate,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      contentUrl:
          contentUrl == _unset ? this.contentUrl : contentUrl as String?,
      externalLink:
          externalLink == _unset ? this.externalLink : externalLink as String?,
      topicCategory: topicCategory ?? this.topicCategory,
      aiConfidenceScore: aiConfidenceScore ?? this.aiConfidenceScore,
      createdAt: createdAt == _unset ? this.createdAt : createdAt as DateTime?,
      updatedAt: updatedAt == _unset ? this.updatedAt : updatedAt as DateTime?,
      imageUrl: imageUrl == _unset ? this.imageUrl : imageUrl as String?,
      estimatedReadingMinutes:
          estimatedReadingMinutes ?? this.estimatedReadingMinutes,
      hasUserEngaged: hasUserEngaged ?? this.hasUserEngaged,
      isCached: isCached ?? this.isCached,
      fullContent:
          fullContent == _unset
              ? this.fullContent
              : fullContent as TodayFeedRichContent?,
    );
  }

  /// Validation methods

  /// Check if content is valid for display
  bool get isValid {
    return title.isNotEmpty &&
        title.length <= 60 &&
        summary.isNotEmpty &&
        summary.length <= 200 &&
        aiConfidenceScore >= 0.0 &&
        aiConfidenceScore <= 1.0;
  }

  /// Check if content is fresh (published today)
  bool get isFresh {
    final today = DateTime.now();
    return contentDate.year == today.year &&
        contentDate.month == today.month &&
        contentDate.day == today.day;
  }

  /// Check if content is high quality based on AI confidence score
  bool get isHighQuality {
    return aiConfidenceScore >= 0.7;
  }

  /// Check if content has external resources
  bool get hasExternalLink {
    return externalLink != null && externalLink!.isNotEmpty;
  }

  /// Helper methods for UI display

  /// Get formatted content date for display
  String get formattedDate {
    return DateFormat('MMM d, yyyy').format(contentDate);
  }

  /// Get short date for badges (e.g., "Dec 28")
  String get shortDate {
    return DateFormat('MMM d').format(contentDate);
  }

  /// Get topic display name with proper capitalization
  String get topicDisplayName {
    switch (topicCategory) {
      case HealthTopic.nutrition:
        return 'Nutrition';
      case HealthTopic.exercise:
        return 'Exercise';
      case HealthTopic.sleep:
        return 'Sleep';
      case HealthTopic.stress:
        return 'Stress Management';
      case HealthTopic.prevention:
        return 'Prevention';
      case HealthTopic.lifestyle:
        return 'Lifestyle';
    }
  }

  /// Get confidence level description for users
  String get confidenceLevel {
    if (aiConfidenceScore >= 0.8) return 'High';
    if (aiConfidenceScore >= 0.6) return 'Medium';
    return 'Low';
  }

  /// Get reading time text for display
  String get readingTimeText {
    return '$estimatedReadingMinutes min read';
  }

  /// Get age of content in days
  int get ageInDays {
    return DateTime.now().difference(contentDate).inDays;
  }

  /// Check if content is stale (older than 7 days)
  bool get isStale {
    return ageInDays > 7;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TodayFeedContent &&
        other.id == id &&
        other.contentDate == contentDate &&
        other.title == title &&
        other.summary == summary &&
        other.topicCategory == topicCategory;
  }

  @override
  int get hashCode {
    return Object.hash(id, contentDate, title, summary, topicCategory);
  }

  @override
  String toString() {
    return 'TodayFeedContent(id: $id, title: $title, topic: ${topicCategory.value}, date: ${contentDate.toIso8601String().split('T')[0]})';
  }
}

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
