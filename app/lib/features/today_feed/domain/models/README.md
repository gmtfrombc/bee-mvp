# Today Feed Domain Models

This module contains the data models for the Today Feed feature (Epic 1.3), implementing the data layer for AI-generated daily health content.

## 📁 Files

### `today_feed_content.dart`
Main data model file containing all core classes for Today Feed functionality.

## 🏗️ Core Classes

### `TodayFeedContent`
Primary data model representing daily AI-generated health content.

**Key Features:**
- JSON serialization compatible with backend API
- Validation methods for content quality and freshness
- Helper methods for UI display formatting
- Immutable design with copyWith functionality
- Comprehensive equals/hashCode implementation

**Usage:**
```dart
// Create from API response
final content = TodayFeedContent.fromJson(apiResponse);

// Create sample data for testing
final sample = TodayFeedContent.sample();

// Update engagement status
final engaged = content.copyWith(hasUserEngaged: true);

// Check content validity
if (content.isValid && content.isFresh) {
  // Display content
}
```

### `TodayFeedState`
Union type for managing content loading states with pattern matching.

**States:**
- `loading()` - Content is being fetched
- `loaded(content)` - Content successfully loaded  
- `error(message)` - Failed to load content
- `offline(cachedContent)` - Offline mode with cached content

**Usage:**
```dart
state.when(
  loading: () => LoadingWidget(),
  loaded: (content) => ContentWidget(content),
  error: (message) => ErrorWidget(message),
  offline: (cached) => OfflineWidget(cached),
);
```

### `TodayFeedInteraction`
Model for tracking user interactions with content for analytics and momentum awards.

**Interaction Types:**
- `view` - User viewed the content
- `tap` - User tapped on content
- `externalLinkClick` - User clicked external link
- `share` - User shared content
- `bookmark` - User bookmarked content

### `HealthTopic`
Enum defining content topic categories with backend-compatible string values.

**Topics:**
- `nutrition` - Nutrition and diet content
- `exercise` - Physical activity and fitness
- `sleep` - Sleep health and optimization
- `stress` - Stress management techniques
- `prevention` - Preventive health measures
- `lifestyle` - General lifestyle improvements

## 🔧 API Compatibility

The models use sample data for MVP development phase.

**Backend JSON Structure:**
```json
{
  "id": 1,
  "content_date": "2024-12-28",
  "title": "Health Content Title",
  "summary": "Content summary...",
  "topic_category": "nutrition",
  "ai_confidence_score": 0.85,
  "created_at": "2024-12-28T06:00:00Z",
  "updated_at": "2024-12-28T06:00:00Z"
}
```

## ✅ Validation Rules

### Content Validation
- Title: Maximum 60 characters, not empty
- Summary: Maximum 200 characters, not empty  
- AI Confidence Score: Between 0.0 and 1.0
- Topic Category: Must be valid HealthTopic enum value

### Quality Checks
- `isHighQuality`: AI confidence score ≥ 0.7
- `isFresh`: Content date matches current date
- `isStale`: Content older than 7 days
- `hasExternalLink`: External link is present and not empty

## 🎨 UI Helper Methods

### Date Formatting
- `formattedDate`: "Dec 28, 2024" format
- `shortDate`: "Dec 28" format for badges
- `ageInDays`: Number of days since content date

### Display Names
- `topicDisplayName`: Human-readable topic names
- `confidenceLevel`: "High", "Medium", or "Low" based on AI score
- `readingTimeText`: "3 min read" format

## 🧪 Testing

Comprehensive unit tests are available in:
```
test/features/today_feed/domain/models/today_feed_content_test.dart
```

**Test Coverage:**
- JSON serialization/deserialization
- Validation methods
- Helper methods
- State management
- Equality and hash code
- Edge cases and error handling

## 🔄 State Management Integration

These models are designed to work with Riverpod providers for reactive state management:

```dart
// Example provider usage (to be implemented in next tasks)
final todayFeedProvider = StateNotifierProvider<TodayFeedNotifier, TodayFeedState>(
  (ref) => TodayFeedNotifier(ref.read(todayFeedServiceProvider)),
);
```

## 📋 Next Steps

**T1.3.2.3**: Implement TodayFeedTile StatefulWidget with Material Design 3
- Use these models in the UI component
- Implement proper error and loading states
- Add Material Design 3 styling
- Integrate with Riverpod state management

---

**Implementation Status**: ✅ Complete  
**Task**: T1.3.2.2 - Create TodayFeedContent data model with JSON serialization  
**Epic**: 1.3 Today Feed (AI Daily Brief)  
**Estimated Time**: 4 hours  
**Actual Time**: 4 hours 