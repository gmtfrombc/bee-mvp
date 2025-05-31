# Today Feed Data Services

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

### Configuration

- **Max Pending Interactions**: 100 interactions queued offline
- **Sync Retry Delay**: 5 minutes between sync attempts
- **Max Session Duration**: 1 hour (sessions longer than this are clamped)

### Database Integration

The service integrates with two database tables:

1. **user_content_interactions**: Stores detailed interaction data
2. **engagement_events**: Stores events for Epic 2.1 engagement tracking

### Error Handling

The service gracefully handles:
- Network connectivity issues (offline queuing)
- Authentication errors
- Database connection failures
- Engagement event logging failures (non-blocking)

### Testing

Comprehensive unit tests are available in `user_content_interaction_service_test.dart` covering:
- Service initialization
- Interaction type validation
- Content model integration
- Configuration validation
- Error handling scenarios 