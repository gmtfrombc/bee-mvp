# Streak Tracking Services - Testing Guide

## Overview

This guide provides comprehensive testing strategies for the modular streak tracking services. Each service is designed to be independently testable while maintaining integration capabilities.

## Testing Architecture

### Service-Specific Testing

Each service has dedicated unit tests focusing on its specific responsibilities:

```
test/features/today_feed/data/services/streak_services/
├── streak_persistence_service_test.dart
├── streak_calculation_service_test.dart
├── streak_milestone_service_test.dart
├── streak_analytics_service_test.dart
└── integration/
    ├── streak_tracking_integration_test.dart
    └── streak_services_coordination_test.dart
```

### Testing Strategy by Service

#### 1. StreakPersistenceService Testing

**Focus:** Data storage, cache management, offline sync

**Key Test Categories:**
```dart
group('Database Operations', () {
  test('should store and retrieve streak data correctly');
  test('should handle database connection failures gracefully');
  test('should validate data integrity before storage');
});

group('Cache Management', () {
  test('should cache streak data with TTL expiration');
  test('should invalidate expired cache entries');
  test('should handle cache misses gracefully');
});

group('Offline Sync', () {
  test('should queue updates when offline');
  test('should sync pending updates when connectivity restored');
  test('should handle sync failures with retry logic');
});
```

**Test Data Setup:**
```dart
final testStreak = EngagementStreak(
  userId: 'test_user_123',
  currentStreak: 5,
  longestStreak: 10,
  lastEngagementDate: DateTime.now(),
  isActiveToday: true,
);
```

#### 2. StreakCalculationService Testing

**Focus:** Core streak algorithms, timezone handling, edge cases

**Key Test Categories:**
```dart
group('Streak Calculation', () {
  test('should calculate current streak from engagement events');
  test('should handle timezone changes correctly');
  test('should detect consecutive day patterns');
  test('should handle DST transitions');
});

group('Edge Cases', () {
  test('should handle empty engagement history');
  test('should handle single engagement event');
  test('should handle gaps in engagement history');
  test('should handle future dates correctly');
});

group('Performance', () {
  test('should calculate streaks efficiently for large datasets');
  test('should handle 1000+ engagement events within time limits');
});
```

**Test Scenarios:**
```dart
// Consecutive days test
final consecutiveEngagements = [
  EngagementEvent(userId: 'user1', date: DateTime(2024, 1, 1)),
  EngagementEvent(userId: 'user1', date: DateTime(2024, 1, 2)),
  EngagementEvent(userId: 'user1', date: DateTime(2024, 1, 3)),
];

// Gap in engagement test
final gappedEngagements = [
  EngagementEvent(userId: 'user1', date: DateTime(2024, 1, 1)),
  EngagementEvent(userId: 'user1', date: DateTime(2024, 1, 3)), // Gap
  EngagementEvent(userId: 'user1', date: DateTime(2024, 1, 4)),
];
```

#### 3. StreakMilestoneService Testing

**Focus:** Milestone detection, celebration creation, bonus integration

**Key Test Categories:**
```dart
group('Milestone Detection', () {
  test('should detect new milestones at correct thresholds');
  test('should not detect duplicate milestones');
  test('should handle multiple milestone achievements');
});

group('Celebration Creation', () {
  test('should create appropriate celebrations for each milestone');
  test('should include correct emoji and messaging');
  test('should calculate momentum bonus points correctly');
});

group('Momentum Integration', () {
  test('should award bonus points through momentum service');
  test('should handle momentum service failures gracefully');
  test('should log bonus awards correctly');
});
```

**Milestone Test Data:**
```dart
final milestoneThresholds = [3, 7, 14, 30, 60, 100];

// Test milestone detection
for (final threshold in milestoneThresholds) {
  test('should detect milestone at $threshold days', () async {
    final oldStreak = EngagementStreak(currentStreak: threshold - 1);
    final newStreak = EngagementStreak(currentStreak: threshold);
    
    final milestones = service.detectNewMilestones(oldStreak, newStreak);
    expect(milestones, hasLength(1));
    expect(milestones.first.streakLength, equals(threshold));
  });
}
```

#### 4. StreakAnalyticsService Testing

**Focus:** Analytics calculation, insights generation, recommendations

**Key Test Categories:**
```dart
group('Analytics Calculation', () {
  test('should calculate consistency rate correctly');
  test('should generate streak trends accurately');
  test('should handle various analysis periods');
});

group('Insights Generation', () {
  test('should provide personalized insights');
  test('should detect improvement patterns');
  test('should identify performance drops');
});

group('Recommendations', () {
  test('should suggest consistency improvements');
  test('should recommend streak building strategies');
  test('should provide milestone-focused guidance');
});
```

**Analytics Test Scenarios:**
```dart
// Perfect consistency (100%)
final perfectEngagements = List.generate(30, (i) => 
  EngagementEvent(date: DateTime.now().subtract(Duration(days: i)))
);

// Partial consistency (60%)
final partialEngagements = List.generate(18, (i) => 
  EngagementEvent(date: DateTime.now().subtract(Duration(days: i * 2)))
);
```

### Integration Testing

#### Service Coordination Testing

**Focus:** Cross-service communication, data consistency, error handling

```dart
group('Service Coordination', () {
  test('should coordinate streak update across all services');
  test('should maintain data consistency between services');
  test('should handle service failures gracefully');
  test('should preserve public API behavior');
});

group('End-to-End Flows', () {
  test('should handle complete engagement flow');
  test('should process milestone achievements end-to-end');
  test('should generate analytics after streak updates');
});
```

#### Performance Integration Testing

```dart
group('Performance Integration', () {
  test('should handle concurrent service operations');
  test('should maintain performance under load');
  test('should manage memory efficiently across services');
});
```

## Test Data Management

### Mock Data Generation

```dart
class StreakTestDataGenerator {
  static EngagementStreak generateStreak({
    String userId = 'test_user',
    int currentStreak = 5,
    int longestStreak = 10,
    bool isActiveToday = true,
  }) {
    return EngagementStreak(
      userId: userId,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastEngagementDate: DateTime.now(),
      isActiveToday: isActiveToday,
    );
  }

  static List<EngagementEvent> generateEngagementHistory({
    String userId = 'test_user',
    int consecutiveDays = 7,
    DateTime? startDate,
  }) {
    startDate ??= DateTime.now().subtract(Duration(days: consecutiveDays));
    
    return List.generate(consecutiveDays, (i) => EngagementEvent(
      userId: userId,
      date: startDate!.add(Duration(days: i)),
      contentId: 'content_$i',
      sessionDuration: 120 + (i * 10), // Varying durations
    ));
  }
}
```

### Test Environment Setup

```dart
void main() {
  late StreakPersistenceService persistenceService;
  late StreakCalculationService calculationService;
  late StreakMilestoneService milestoneService;
  late StreakAnalyticsService analyticsService;

  setUp(() async {
    // Initialize services with test configuration
    persistenceService = StreakPersistenceService();
    calculationService = StreakCalculationService();
    milestoneService = StreakMilestoneService();
    analyticsService = StreakAnalyticsService();

    await persistenceService.initialize();
    await calculationService.initialize();
    await milestoneService.initialize();
    await analyticsService.initialize();
  });

  tearDown(() async {
    // Clean up test data and dispose services
    await persistenceService.clearTestData();
    persistenceService.dispose();
    calculationService.dispose();
    milestoneService.dispose();
    analyticsService.dispose();
  });
}
```

## Testing Best Practices

### 1. Service Isolation

```dart
// ✅ Good: Test each service independently
test('calculation service should calculate streak correctly', () async {
  // Mock persistence service responses
  when(mockPersistenceService.getEngagementEvents(any))
      .thenAnswer((_) async => testEngagements);
  
  final result = await calculationService.calculateCurrentStreak('user1');
  expect(result.currentStreak, equals(5));
});

// ❌ Avoid: Testing multiple services simultaneously in unit tests
test('should update streak and detect milestones', () async {
  // This should be an integration test, not a unit test
});
```

### 2. Comprehensive Edge Cases

```dart
group('Edge Cases', () {
  test('should handle empty user ID');
  test('should handle null engagement events');
  test('should handle future engagement dates');
  test('should handle timezone edge cases');
  test('should handle concurrent access scenarios');
});
```

### 3. Performance Testing

```dart
test('should calculate streaks within performance limits', () async {
  final largeDataset = StreakTestDataGenerator.generateEngagementHistory(
    consecutiveDays: 1000,
  );
  
  final stopwatch = Stopwatch()..start();
  final result = await calculationService.calculateCurrentStreak('user1');
  stopwatch.stop();
  
  expect(stopwatch.elapsedMilliseconds, lessThan(100)); // < 100ms
  expect(result.currentStreak, equals(1000));
});
```

### 4. Error Handling Validation

```dart
test('should handle service failures gracefully', () async {
  // Simulate service failure
  when(mockPersistenceService.getStoredStreakData(any))
      .thenThrow(Exception('Database connection failed'));
  
  final result = await calculationService.calculateCurrentStreak('user1');
  
  // Should return empty streak, not throw
  expect(result, equals(EngagementStreak.empty()));
});
```

## Continuous Integration

### Test Execution Commands

```bash
# Run all streak service tests
flutter test test/features/today_feed/data/services/streak_services/

# Run specific service tests
flutter test test/features/today_feed/data/services/streak_services/streak_calculation_service_test.dart

# Run integration tests
flutter test test/features/today_feed/data/services/streak_services/integration/

# Run with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Coverage Requirements

- **Minimum Coverage:** 85% for each service
- **Critical Paths:** 100% coverage for streak calculation algorithms
- **Error Handling:** 100% coverage for error scenarios
- **Integration:** 90% coverage for service coordination

### Performance Benchmarks

| Service | Operation | Max Time | Memory |
|---------|-----------|----------|---------|
| **Calculation** | Calculate streak (100 days) | 50ms | 2MB |
| **Persistence** | Store/retrieve streak | 20ms | 1MB |
| **Milestone** | Detect milestones | 10ms | 500KB |
| **Analytics** | Generate insights | 100ms | 3MB |

## Troubleshooting

### Common Test Issues

#### 1. Timezone-Related Failures
```dart
// Fix: Use UTC dates in tests
final testDate = DateTime.utc(2024, 1, 1);
```

#### 2. Async Test Timeouts
```dart
// Fix: Add proper timeouts
test('should handle large datasets', () async {
  // Test implementation
}, timeout: Timeout(Duration(seconds: 30)));
```

#### 3. Service Initialization Order
```dart
// Fix: Ensure proper initialization sequence
setUp(() async {
  await persistenceService.initialize(); // First
  await calculationService.initialize(); // Depends on persistence
  await milestoneService.initialize();   // Depends on calculation
});
```

### Debug Techniques

#### 1. Service State Inspection
```dart
test('debug service state', () async {
  debugPrint('Persistence service state: ${persistenceService.debugState}');
  debugPrint('Calculation service cache: ${calculationService.debugCache}');
});
```

#### 2. Mock Verification
```dart
test('verify service interactions', () async {
  await coordinatorService.updateStreak('user1');
  
  verify(mockPersistenceService.storeStreakData(any, any)).called(1);
  verify(mockCalculationService.calculateUpdatedStreak(any, any, any)).called(1);
});
```

---

*This testing guide ensures comprehensive validation of the modular streak tracking system while maintaining service independence and integration reliability.* 