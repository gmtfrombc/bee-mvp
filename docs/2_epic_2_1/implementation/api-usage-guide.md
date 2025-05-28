# API Usage Guide - Engagement Events

**Module:** Core Engagement  
**Milestone:** 1 · Data Backbone  
**Purpose:** Developer guide for integrating with engagement events APIs

---

## Overview

This guide provides comprehensive documentation for integrating with the BEE engagement events logging system. It covers REST API, GraphQL API, and Realtime subscriptions with practical Flutter examples.

## Authentication

All API requests require authentication using Supabase JWT tokens:

```dart
// Initialize Supabase client
final supabase = Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_ANON_KEY',
);

// User authentication
await supabase.auth.signInWithPassword(
  email: 'user@example.com',
  password: 'password',
);
```

## REST API Integration

### Basic CRUD Operations

#### 1. Create Event (POST)
```dart
// Create a new engagement event
Future<Map<String, dynamic>?> createEvent({
  required String eventType,
  required Map<String, dynamic> value,
}) async {
  try {
    final response = await supabase
        .from('engagement_events')
        .insert({
          'event_type': eventType,
          'value': value,
        })
        .select()
        .single();
    
    return response;
  } catch (error) {
    print('Error creating event: $error');
    return null;
  }
}

// Usage example
final event = await createEvent(
  eventType: 'app_open',
  value: {
    'session_duration': 300,
    'screen': 'dashboard',
    'app_version': '1.0.0',
  },
);
```

#### 2. Read Events (GET)
```dart
// Get user's recent events
Future<List<Map<String, dynamic>>> getRecentEvents({
  int limit = 50,
  String? eventType,
}) async {
  try {
    var query = supabase
        .from('engagement_events')
        .select()
        .order('timestamp', ascending: false)
        .limit(limit);
    
    if (eventType != null) {
      query = query.eq('event_type', eventType);
    }
    
    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  } catch (error) {
    print('Error fetching events: $error');
    return [];
  }
}

// Usage examples
final allEvents = await getRecentEvents();
final appOpenEvents = await getRecentEvents(eventType: 'app_open');
```

#### 3. Query with Filters
```dart
// Get events within date range
Future<List<Map<String, dynamic>>> getEventsByDateRange({
  required DateTime startDate,
  required DateTime endDate,
  String? eventType,
}) async {
  try {
    var query = supabase
        .from('engagement_events')
        .select()
        .gte('timestamp', startDate.toIso8601String())
        .lte('timestamp', endDate.toIso8601String())
        .order('timestamp', ascending: false);
    
    if (eventType != null) {
      query = query.eq('event_type', eventType);
    }
    
    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  } catch (error) {
    print('Error fetching events by date: $error');
    return [];
  }
}

// Get events with JSONB filtering
Future<List<Map<String, dynamic>>> getEventsByValue({
  required Map<String, dynamic> valueFilter,
}) async {
  try {
    final response = await supabase
        .from('engagement_events')
        .select()
        .contains('value', valueFilter)
        .order('timestamp', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  } catch (error) {
    print('Error fetching events by value: $error');
    return [];
  }
}

// Usage example
final goalEvents = await getEventsByValue({
  'goal_type': 'steps',
});
```

#### 4. Update Event (PATCH)
```dart
// Soft delete an event
Future<bool> softDeleteEvent(String eventId) async {
  try {
    await supabase
        .from('engagement_events')
        .update({'is_deleted': true})
        .eq('id', eventId);
    
    return true;
  } catch (error) {
    print('Error deleting event: $error');
    return false;
  }
}

// Update event value
Future<bool> updateEventValue(
  String eventId,
  Map<String, dynamic> newValue,
) async {
  try {
    await supabase
        .from('engagement_events')
        .update({'value': newValue})
        .eq('id', eventId);
    
    return true;
  } catch (error) {
    print('Error updating event: $error');
    return false;
  }
}
```

### Batch Operations

#### Bulk Insert Events
```dart
// Insert multiple events at once
Future<List<Map<String, dynamic>>?> createBatchEvents(
  List<Map<String, dynamic>> events,
) async {
  try {
    final response = await supabase
        .from('engagement_events')
        .insert(events)
        .select();
    
    return List<Map<String, dynamic>>.from(response);
  } catch (error) {
    print('Error creating batch events: $error');
    return null;
  }
}

// Usage example
final batchEvents = [
  {
    'event_type': 'steps_import',
    'value': {'steps': 8500, 'source': 'fitbit'},
  },
  {
    'event_type': 'mood_log',
    'value': {'mood_score': 8, 'energy_level': 7},
  },
];

await createBatchEvents(batchEvents);
```

## GraphQL API Integration

### Basic Queries

#### 1. Query Events
```dart
// GraphQL query for events
Future<List<Map<String, dynamic>>> queryEventsGraphQL({
  int limit = 50,
  String? eventType,
}) async {
  const query = '''
    query GetEngagementEvents(\$limit: Int!, \$eventType: String) {
      engagement_events(
        limit: \$limit
        where: { event_type: { _eq: \$eventType } }
        order_by: { timestamp: desc }
      ) {
        id
        timestamp
        event_type
        value
      }
    }
  ''';
  
  try {
    final response = await supabase.functions.invoke(
      'graphql',
      body: {
        'query': query,
        'variables': {
          'limit': limit,
          if (eventType != null) 'eventType': eventType,
        },
      },
    );
    
    return List<Map<String, dynamic>>.from(
      response.data['data']['engagement_events'],
    );
  } catch (error) {
    print('Error querying events via GraphQL: $error');
    return [];
  }
}
```

#### 2. Aggregation Queries
```dart
// Get event counts by type
Future<Map<String, int>> getEventCountsByType() async {
  const query = '''
    query GetEventCounts {
      engagement_events_aggregate {
        nodes {
          event_type
        }
      }
    }
  ''';
  
  try {
    final response = await supabase.functions.invoke(
      'graphql',
      body: {'query': query},
    );
    
    final events = response.data['data']['engagement_events_aggregate']['nodes'];
    final counts = <String, int>{};
    
    for (final event in events) {
      final type = event['event_type'] as String;
      counts[type] = (counts[type] ?? 0) + 1;
    }
    
    return counts;
  } catch (error) {
    print('Error getting event counts: $error');
    return {};
  }
}
```

### GraphQL Mutations

#### 1. Create Event
```dart
// GraphQL mutation for creating events
Future<Map<String, dynamic>?> createEventGraphQL({
  required String eventType,
  required Map<String, dynamic> value,
}) async {
  const mutation = '''
    mutation CreateEngagementEvent(\$eventType: String!, \$value: jsonb!) {
      insert_engagement_events_one(object: {
        event_type: \$eventType
        value: \$value
      }) {
        id
        timestamp
        event_type
        value
      }
    }
  ''';
  
  try {
    final response = await supabase.functions.invoke(
      'graphql',
      body: {
        'query': mutation,
        'variables': {
          'eventType': eventType,
          'value': value,
        },
      },
    );
    
    return response.data['data']['insert_engagement_events_one'];
  } catch (error) {
    print('Error creating event via GraphQL: $error');
    return null;
  }
}
```

## Realtime Subscriptions

### Basic Event Subscription

```dart
class EngagementEventsService {
  late RealtimeChannel _channel;
  final StreamController<Map<String, dynamic>> _eventController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;
  
  // Subscribe to user's engagement events
  void subscribeToEvents() {
    _channel = supabase
        .channel('engagement_events')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'engagement_events',
          callback: (payload) {
            final newEvent = payload.newRecord;
            _eventController.add(newEvent);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'engagement_events',
          callback: (payload) {
            final updatedEvent = payload.newRecord;
            _eventController.add(updatedEvent);
          },
        )
        .subscribe();
  }
  
  // Unsubscribe from events
  void unsubscribe() {
    _channel.unsubscribe();
    _eventController.close();
  }
}

// Usage in Flutter widget
class EventsWidget extends StatefulWidget {
  @override
  _EventsWidgetState createState() => _EventsWidgetState();
}

class _EventsWidgetState extends State<EventsWidget> {
  final EngagementEventsService _eventsService = EngagementEventsService();
  final List<Map<String, dynamic>> _events = [];
  
  @override
  void initState() {
    super.initState();
    _eventsService.subscribeToEvents();
    _eventsService.eventStream.listen((event) {
      setState(() {
        _events.insert(0, event);
      });
    });
  }
  
  @override
  void dispose() {
    _eventsService.unsubscribe();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _events.length,
      itemBuilder: (context, index) {
        final event = _events[index];
        return ListTile(
          title: Text(event['event_type']),
          subtitle: Text(event['timestamp']),
          trailing: Text(event['value'].toString()),
        );
      },
    );
  }
}
```

### Filtered Subscriptions

```dart
// Subscribe to specific event types
void subscribeToEventType(String eventType) {
  _channel = supabase
      .channel('engagement_events_$eventType')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'engagement_events',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'event_type',
          value: eventType,
        ),
        callback: (payload) {
          final newEvent = payload.newRecord;
          _eventController.add(newEvent);
        },
      )
      .subscribe();
}

// Subscribe with multiple filters
void subscribeToGoalEvents() {
  _channel = supabase
      .channel('goal_events')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'engagement_events',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'event_type',
          value: 'goal_complete',
        ),
        callback: (payload) {
          final goalEvent = payload.newRecord;
          _handleGoalCompletion(goalEvent);
        },
      )
      .subscribe();
}
```

## Event Type Conventions

### Standard Event Types

#### 1. App Lifecycle Events
```dart
// App opened
await createEvent(
  eventType: 'app_open',
  value: {
    'session_id': 'session_123',
    'screen': 'dashboard',
    'app_version': '1.0.0',
    'platform': 'ios',
  },
);

// App closed
await createEvent(
  eventType: 'app_close',
  value: {
    'session_id': 'session_123',
    'session_duration': 300, // seconds
    'screens_visited': ['dashboard', 'goals', 'profile'],
  },
);

// Screen view
await createEvent(
  eventType: 'screen_view',
  value: {
    'screen_name': 'goal_details',
    'previous_screen': 'dashboard',
    'view_duration': 45,
  },
);
```

#### 2. Goal and Achievement Events
```dart
// Goal completed
await createEvent(
  eventType: 'goal_complete',
  value: {
    'goal_id': 'goal_123',
    'goal_type': 'steps',
    'target': 10000,
    'achieved': 12500,
    'streak': 5,
    'completion_time': DateTime.now().toIso8601String(),
  },
);

// Goal created
await createEvent(
  eventType: 'goal_created',
  value: {
    'goal_id': 'goal_124',
    'goal_type': 'exercise',
    'target': 30, // minutes
    'frequency': 'daily',
    'category': 'fitness',
  },
);

// Goal updated
await createEvent(
  eventType: 'goal_updated',
  value: {
    'goal_id': 'goal_123',
    'changes': {
      'target': {'old': 8000, 'new': 10000},
      'frequency': {'old': 'daily', 'new': 'weekly'},
    },
  },
);
```

#### 3. Health Data Events
```dart
// Steps import from wearable
await createEvent(
  eventType: 'steps_import',
  value: {
    'source': 'fitbit',
    'steps': 8500,
    'calories': 2100,
    'distance': 6.8, // km
    'active_minutes': 85,
    'sync_timestamp': DateTime.now().toIso8601String(),
  },
);

// Manual health data entry
await createEvent(
  eventType: 'health_data_manual',
  value: {
    'data_type': 'weight',
    'value': 70.5,
    'unit': 'kg',
    'notes': 'Morning weight after workout',
  },
);

// Sleep data
await createEvent(
  eventType: 'sleep_log',
  value: {
    'hours_slept': 7.5,
    'sleep_quality': 8, // 1-10 scale
    'bedtime': '22:30',
    'wake_time': '06:00',
    'interruptions': 1,
    'source': 'apple_watch',
  },
);
```

#### 4. Engagement and Interaction Events
```dart
// Coach message sent
await createEvent(
  eventType: 'coach_message_sent',
  value: {
    'message_id': 'msg_123',
    'type': 'encouragement',
    'trigger': 'goal_achievement',
    'content_length': 120,
    'personalization_score': 0.85,
  },
);

// User interaction with coach
await createEvent(
  eventType: 'coach_interaction',
  value: {
    'message_id': 'msg_123',
    'action': 'liked',
    'response_time': 30, // seconds
  },
);

// Mood log
await createEvent(
  eventType: 'mood_log',
  value: {
    'mood_score': 8, // 1-10 scale
    'energy_level': 7,
    'stress_level': 3,
    'notes': 'Feeling great after morning run',
    'tags': ['exercise', 'morning', 'positive'],
  },
);
```

### Custom Event Types

#### Naming Conventions
- Use snake_case for event types
- Start with category: `app_`, `goal_`, `health_`, `coach_`, `user_`
- Be descriptive but concise
- Use consistent verb tenses (past tense for completed actions)

#### Examples
```dart
// Feature usage tracking
await createEvent(
  eventType: 'feature_used',
  value: {
    'feature_name': 'goal_sharing',
    'usage_context': 'achievement_celebration',
    'user_segment': 'premium',
  },
);

// Error tracking
await createEvent(
  eventType: 'error_occurred',
  value: {
    'error_type': 'api_timeout',
    'error_code': 'TIMEOUT_001',
    'endpoint': '/api/goals',
    'retry_count': 2,
  },
);

// A/B test events
await createEvent(
  eventType: 'ab_test_exposure',
  value: {
    'test_name': 'onboarding_flow_v2',
    'variant': 'control',
    'user_cohort': 'new_users',
  },
);
```

## JSONB Payload Schemas

### Common Payload Patterns

#### 1. Metadata Pattern
```dart
// Standard metadata fields for all events
final basePayload = {
  'timestamp': DateTime.now().toIso8601String(),
  'app_version': '1.0.0',
  'platform': 'ios',
  'user_agent': 'BEE/1.0.0 (iOS 15.0)',
  'session_id': 'session_123',
};

// Merge with specific event data
final eventPayload = {
  ...basePayload,
  'goal_id': 'goal_123',
  'achievement_type': 'streak',
};
```

#### 2. Measurement Pattern
```dart
// For events with measurable values
final measurementPayload = {
  'value': 10000,
  'unit': 'steps',
  'target': 8000,
  'percentage': 125.0,
  'previous_value': 9500,
  'trend': 'increasing',
};
```

#### 3. User Action Pattern
```dart
// For user interaction events
final actionPayload = {
  'action': 'button_click',
  'element_id': 'complete_goal_btn',
  'screen': 'goal_details',
  'coordinates': {'x': 150, 'y': 300},
  'duration': 250, // ms
};
```

#### 4. Context Pattern
```dart
// For events that need contextual information
final contextPayload = {
  'context': {
    'location': 'home',
    'time_of_day': 'morning',
    'weather': 'sunny',
    'day_of_week': 'monday',
  },
  'user_state': {
    'energy_level': 'high',
    'mood': 'positive',
    'stress_level': 'low',
  },
};
```

### Validation Helpers

```dart
// Validate event payload structure
class EventValidator {
  static bool validateAppOpenPayload(Map<String, dynamic> payload) {
    final requiredFields = ['session_id', 'screen', 'app_version'];
    return requiredFields.every((field) => payload.containsKey(field));
  }
  
  static bool validateGoalCompletePayload(Map<String, dynamic> payload) {
    final requiredFields = ['goal_id', 'goal_type', 'target', 'achieved'];
    return requiredFields.every((field) => payload.containsKey(field)) &&
           payload['achieved'] is num &&
           payload['target'] is num;
  }
  
  static bool validateStepsImportPayload(Map<String, dynamic> payload) {
    final requiredFields = ['source', 'steps'];
    return requiredFields.every((field) => payload.containsKey(field)) &&
           payload['steps'] is int &&
           payload['steps'] >= 0;
  }
}

// Usage
final payload = {'goal_id': 'goal_123', 'target': 10000, 'achieved': 12000};
if (EventValidator.validateGoalCompletePayload(payload)) {
  await createEvent(eventType: 'goal_complete', value: payload);
}
```

## Error Handling

### Common Error Patterns

```dart
// Comprehensive error handling
Future<Map<String, dynamic>?> createEventWithRetry({
  required String eventType,
  required Map<String, dynamic> value,
  int maxRetries = 3,
}) async {
  for (int attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      final response = await supabase
          .from('engagement_events')
          .insert({
            'event_type': eventType,
            'value': value,
          })
          .select()
          .single();
      
      return response;
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // Unique constraint violation
        print('Duplicate event detected: ${e.message}');
        return null;
      } else if (e.code == '23503') {
        // Foreign key constraint violation
        print('Invalid user_id: ${e.message}');
        return null;
      } else if (attempt == maxRetries) {
        print('Failed to create event after $maxRetries attempts: ${e.message}');
        rethrow;
      }
    } catch (e) {
      if (attempt == maxRetries) {
        print('Unexpected error creating event: $e');
        rethrow;
      }
      
      // Wait before retry
      await Future.delayed(Duration(seconds: attempt));
    }
  }
  
  return null;
}
```

### Offline Support

```dart
// Queue events for offline scenarios
class OfflineEventQueue {
  static const String _queueKey = 'offline_events_queue';
  
  // Add event to offline queue
  static Future<void> queueEvent({
    required String eventType,
    required Map<String, dynamic> value,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = prefs.getString(_queueKey) ?? '[]';
    final queue = List<Map<String, dynamic>>.from(jsonDecode(queueJson));
    
    queue.add({
      'event_type': eventType,
      'value': value,
      'queued_at': DateTime.now().toIso8601String(),
    });
    
    await prefs.setString(_queueKey, jsonEncode(queue));
  }
  
  // Sync queued events when online
  static Future<void> syncQueuedEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = prefs.getString(_queueKey) ?? '[]';
    final queue = List<Map<String, dynamic>>.from(jsonDecode(queueJson));
    
    if (queue.isEmpty) return;
    
    final successfulEvents = <int>[];
    
    for (int i = 0; i < queue.length; i++) {
      final event = queue[i];
      try {
        await createEvent(
          eventType: event['event_type'],
          value: event['value'],
        );
        successfulEvents.add(i);
      } catch (e) {
        print('Failed to sync event: $e');
      }
    }
    
    // Remove successfully synced events
    for (int i = successfulEvents.length - 1; i >= 0; i--) {
      queue.removeAt(successfulEvents[i]);
    }
    
    await prefs.setString(_queueKey, jsonEncode(queue));
  }
}
```

## Performance Best Practices

### Batching Events

```dart
// Batch events for better performance
class EventBatcher {
  static const int _batchSize = 10;
  static const Duration _batchTimeout = Duration(seconds: 30);
  
  final List<Map<String, dynamic>> _eventBatch = [];
  Timer? _batchTimer;
  
  void addEvent({
    required String eventType,
    required Map<String, dynamic> value,
  }) {
    _eventBatch.add({
      'event_type': eventType,
      'value': value,
    });
    
    if (_eventBatch.length >= _batchSize) {
      _flushBatch();
    } else {
      _startBatchTimer();
    }
  }
  
  void _startBatchTimer() {
    _batchTimer?.cancel();
    _batchTimer = Timer(_batchTimeout, _flushBatch);
  }
  
  Future<void> _flushBatch() async {
    if (_eventBatch.isEmpty) return;
    
    final eventsToSend = List<Map<String, dynamic>>.from(_eventBatch);
    _eventBatch.clear();
    _batchTimer?.cancel();
    
    try {
      await createBatchEvents(eventsToSend);
    } catch (e) {
      print('Failed to send batch events: $e');
      // Could implement retry logic here
    }
  }
}
```

### Caching Strategies

```dart
// Cache frequently accessed events
class EventCache {
  static final Map<String, List<Map<String, dynamic>>> _cache = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);
  static final Map<String, DateTime> _cacheTimestamps = {};
  
  static Future<List<Map<String, dynamic>>> getCachedEvents(
    String cacheKey,
    Future<List<Map<String, dynamic>>> Function() fetchFunction,
  ) async {
    final now = DateTime.now();
    final cachedTime = _cacheTimestamps[cacheKey];
    
    if (cachedTime != null && 
        now.difference(cachedTime) < _cacheExpiry &&
        _cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }
    
    final events = await fetchFunction();
    _cache[cacheKey] = events;
    _cacheTimestamps[cacheKey] = now;
    
    return events;
  }
  
  static void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }
}

// Usage
final recentEvents = await EventCache.getCachedEvents(
  'recent_events',
  () => getRecentEvents(limit: 20),
);
```

---

**Implementation Status:** Ready for use  
**Review Required:** Mobile development team approval  
**Next Steps:** Integrate examples into Flutter app and test thoroughly 