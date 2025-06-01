# Today Feed Data Services

## Overview

The Today Feed data services provide comprehensive functionality for content interaction tracking, engagement detection, momentum management, and streak tracking. The architecture emphasizes modularity, testability, and maintainability with specialized services for each responsibility.

## Service Architecture

### Core Services
- **TodayFeedDataService**: Main data provider for Today Feed content
- **UserContentInteractionService**: Tracks user interactions with content
- **DailyEngagementDetectionService**: Detects and validates daily engagement patterns
- **TodayFeedMomentumAwardService**: Manages momentum point awards and integration

### Streak Tracking System (Modular Architecture)
- **TodayFeedStreakTrackingService**: Main coordinator for streak functionality
- **StreakPersistenceService**: Data storage and cache management
- **StreakCalculationService**: Core streak calculation algorithms
- **StreakMilestoneService**: Milestone detection and celebrations
- **StreakAnalyticsService**: Analytics and insights generation

### Supporting Services
- **SessionDurationTrackingService**: Tracks user session durations
- **TodayFeedSharingService**: Handles content sharing functionality
- **TodayFeedInteractionAnalyticsService**: Provides interaction analytics
- **RealtimeMomentumUpdateService**: Real-time momentum synchronization

---

## Streak Tracking System

### Architecture Overview

The streak tracking system has been refactored from a monolithic service into a modular architecture with clear separation of concerns:

```
TodayFeedStreakTrackingService (460 lines) - Main Coordinator
├── StreakPersistenceService (386 lines) - Data Layer
├── StreakCalculationService (264 lines) - Business Logic
├── StreakMilestoneService (392 lines) - Feature Logic
└── StreakAnalyticsService (518 lines) - Reporting & Insights
```

### Key Features

- **Comprehensive Tracking**: Accurate streak calculation across timezones
- **Milestone System**: Dynamic achievement detection with celebrations
- **Visual Feedback**: Rich animations and progress indicators
- **Analytics & Insights**: Personalized performance analysis
- **Offline Support**: Queue-based sync with automatic retry
- **Momentum Integration**: Bonus points for milestone achievements

### Usage Example

```dart
// Initialize the streak tracking system
final streakService = TodayFeedStreakTrackingService();
await streakService.initialize();

// Get current streak
final streak = await streakService.getCurrentStreak(userId);
print('Current streak: ${streak.currentStreak} days');

// Update streak on engagement
final result = await streakService.updateStreakOnEngagement(
  userId: userId,
  content: content,
  sessionDuration: 300, // 5 minutes
);

if (result.isSuccess && result.newMilestones.isNotEmpty) {
  // Show celebration for milestone achievement
  showCelebration(result.celebration);
  print('Earned ${result.momentumPointsEarned} bonus points!');
}

// Get comprehensive analytics
final analytics = await streakService.getStreakAnalytics(userId);
print('Consistency rate: ${analytics.consistencyRate}%');
print('Insights: ${analytics.insights.join(", ")}');
```

### Service Integration

The modular streak services integrate seamlessly:

1. **Persistence Layer**: Handles all data storage and caching
2. **Calculation Engine**: Performs accurate streak calculations
3. **Milestone System**: Detects achievements and creates celebrations
4. **Analytics Engine**: Generates insights and recommendations
5. **Main Coordinator**: Orchestrates all services and provides public API

---

## UserContentInteractionService

The `UserContentInteractionService` is responsible for tracking user interactions with Today Feed content and integrating with the momentum system.

### Features

- **Interaction Tracking**: Records different types of user interactions (view, tap, external link clicks, share, bookmark)
- **Momentum Integration**: Awards momentum points for qualifying interactions (view interactions, once per day)
- **Offline Support**: Queues interactions when offline and syncs when connectivity is restored
- **Engagement Events**: Integrates with Epic 2.1 engagement events system
- **Duplicate Prevention**: Prevents duplicate momentum awards for the same content on the same day

### Usage

```dart
final service = UserContentInteractionService();

// Record a view interaction
final result = await service.recordInteraction(
  TodayFeedInteractionType.view,
  content,
  sessionDuration: 120, // seconds
  additionalData: {'source': 'feed_tile'},
);

// Check if momentum was awarded
if (result['momentum_awarded']) {
  print('User earned ${result['momentum_points']} momentum points!');
}

// Check daily engagement status
final hasEngaged = await service.hasUserEngagedToday(userId);

// Get interaction history
final history = await service.getUserInteractionHistory(
  userId,
  limit: 50,
  startDate: DateTime.now().subtract(Duration(days: 7)),
);
```

### Interaction Types

- **view**: Content was viewed (awards momentum once per day)
- **tap**: Content tile was tapped
- **external_link_click**: External link was clicked
- **share**: Content was shared
- **bookmark**: Content was bookmarked

---

## Development Guidelines

### Code Quality Standards

All services follow consistent quality standards:
- **Line Limit**: Maximum 500 lines per service
- **Single Responsibility**: Each service has one clear purpose
- **Comprehensive Testing**: Minimum 85% test coverage
- **Error Handling**: Graceful degradation and proper logging
- **Documentation**: Complete API documentation with examples

### Testing Strategy

#### Service-Specific Testing
- **Persistence Service**: Database operations, cache management, sync queue
- **Calculation Service**: Streak algorithms, edge cases, timezone handling
- **Milestone Service**: Threshold detection, celebration creation, bonus integration
- **Analytics Service**: Calculation accuracy, insights generation, recommendations
- **Main Service**: Service coordination, API behavior, error handling

#### Integration Testing
- End-to-end streak tracking flow
- Cross-service data consistency
- Error handling under service failures
- Performance under load

### Adding New Features

1. **Identify Service**: Determine which service the feature belongs to
2. **Single Responsibility**: Ensure the feature aligns with service purpose
3. **Add Implementation**: Implement with proper error handling
4. **Update Tests**: Add comprehensive unit and integration tests
5. **Update Documentation**: Document new functionality and usage

### Service Modification Rules

- Maintain single responsibility per service
- Keep services under 500-line limit
- Use dependency injection for cross-service communication
- Implement proper error handling and logging
- Add unit tests for all new functionality

---

## Configuration

### Service Constants

```dart
// Streak tracking configuration
static const Duration cacheExpiry = Duration(minutes: 30);
static const List<int> milestoneThresholds = [3, 7, 14, 30, 60, 100, 200, 365];
static const int defaultAnalysisPeriod = 90; // days

// Interaction tracking configuration
static const int maxPendingInteractions = 100;
static const Duration syncRetryDelay = Duration(minutes: 5);
static const Duration maxSessionDuration = Duration(hours: 1);
```

### Database Integration

Services integrate with multiple database tables:
- **user_content_interactions**: Detailed interaction data
- **engagement_events**: Epic 2.1 engagement tracking
- **streak_data**: Streak tracking and milestones
- **momentum_events**: Momentum point transactions

---

## Error Handling

All services implement consistent error handling:
- **Graceful Degradation**: Non-critical failures don't break functionality
- **Offline Support**: Operations queued for sync when connectivity restored
- **Comprehensive Logging**: All operations logged for debugging
- **Fallback Mechanisms**: Default/empty values returned on errors

---

## Performance Characteristics

### Optimization Features
- **Smart Caching**: 30-minute TTL with intelligent invalidation
- **Offline Queue**: Automatic sync when connectivity restored
- **Service Coordination**: Minimal overhead through direct method calls
- **Memory Management**: Proper lifecycle management and disposal

### Scalability
- Individual service scaling and optimization
- Easier performance profiling and bottleneck identification
- Modular caching strategies per service responsibility
- Efficient data structures and algorithms

---

*This modular architecture provides a solid foundation for maintaining and extending Today Feed functionality while ensuring code quality, performance, and developer experience.* 