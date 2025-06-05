# Test Pruning Plan: 1,203 → 200-300 Tests

## Current State Analysis
- **60 test files**
- **25,104 lines of test code**
- **1,203 individual tests** (837 `test()` + 366 `testWidgets()`)

## Pruning Strategy: Keep Critical, Delete Redundant

### ❌ DELETE: Over-Engineered Tests (70% reduction)

#### 1. Configuration Constant Tests
```dart
// DELETE: Testing static constants
test('should have correct duration constants', () {
  expect(SessionTrackingConfig.minValidSession, equals(const Duration(seconds: 3)));
  expect(SessionTrackingConfig.maxValidSession, equals(const Duration(hours: 2)));
  // ... 15 more constant assertions
});
```
**Why Delete**: Constants don't need testing; compiler catches changes.

#### 2. Exhaustive JSON Serialization Tests  
```dart
// DELETE: Multiple JSON round-trip tests for simple models
test('should serialize to and from JSON correctly', () {
  final json = originalSession.toJson();
  final deserializedSession = ReadingSession.fromJson(json);
  expect(deserializedSession.sessionId, equals(originalSession.sessionId));
  // ... 10 more property checks
});
```
**Why Delete**: Keep 1 JSON test per model, not exhaustive property checking.

#### 3. Excessive Edge Case Testing
```dart
// DELETE: Testing every possible error combination
test('should handle zero estimated reading time', () { ... });
test('should handle negative reading time', () { ... });
test('should handle null reading time', () { ... });
test('should handle empty reading time', () { ... });
```
**Why Delete**: Test representative error cases, not every permutation.

#### 4. Redundant Equality/HashCode Tests
```dart
// DELETE: Extensive equality testing
test('should handle equality and hashCode correctly', () {
  // 50 lines of equality edge cases
});
```
**Why Delete**: Simple equality usually doesn't need extensive testing.

#### 5. Over-Mocked Integration Tests
```dart
// SIMPLIFY: Tests with 20+ mock setups
test('complex integration scenario', () {
  // 100 lines of mock setup for simple functionality
});
```

---

### ✅ KEEP: Critical Business Logic Tests

#### 1. Momentum Calculation (Core Business Logic)
```dart
// KEEP: Essential business rules
test('momentum calculation for rising state', () { ... });
test('momentum state transitions', () { ... });
test('coach intervention triggers', () { ... });
```

#### 2. Security & HIPAA Compliance  
```dart
// KEEP: Critical for healthcare app
test('user data encryption', () { ... });
test('data retention policies', () { ... });
test('unauthorized access prevention', () { ... });
```

#### 3. API Integration Points
```dart
// KEEP: External dependencies
test('supabase authentication', () { ... });
test('firebase messaging', () { ... });
test('api error handling', () { ... });
```

#### 4. Critical User Flows
```dart
// KEEP: Core user journeys  
test('user onboarding flow', () { ... });
test('momentum state updates', () { ... });
test('notification delivery', () { ... });
```

---

## File-by-File Pruning Plan

### High-Impact Deletions (Safe, Big Wins)

| File | Current Lines | Target Lines | Reduction |
|------|---------------|-------------|-----------|
| `session_duration_tracking_service_test.dart` | 864 | 80 | 90% |
| `momentum_api_service_test.dart` | 759 | 100 | 87% |
| `coach_intervention_test.dart` | 694 | 80 | 88% |
| `today_feed_content_test.dart` | 594 | 60 | 90% |
| `coach_dashboard_filters_test.dart` | 552 | 50 | 91% |

### Medium-Impact Pruning

| Category | Files | Current Tests | Target Tests |
|----------|-------|---------------|-------------|
| Widget Tests | 20 files | 366 tests | 80 tests |
| Service Tests | 25 files | 600 tests | 120 tests |
| Model Tests | 15 files | 237 tests | 50 tests |

---

## Sprint 1 Test Pruning Checklist

### Week 1: Analysis & Safe Deletions
- [ ] Identify all constant validation tests → DELETE
- [ ] Identify redundant JSON tests → DELETE  
- [ ] Map critical vs non-critical tests
- [ ] Create test preservation list

### Week 2: Aggressive Pruning
- [ ] Delete excessive edge case tests
- [ ] Consolidate similar test scenarios
- [ ] Simplify over-mocked integration tests
- [ ] Validate core functionality still covered

## Expected Results

**Before Pruning:**
- 60 test files
- 1,203 tests
- 25,104 lines
- ~4-5 minute test run

**After Pruning:**
- 25-30 test files  
- 200-300 tests
- 5,000-7,000 lines
- ~1-2 minute test run

**Quality Maintained:**
- ✅ All critical business logic covered
- ✅ Security tests preserved
- ✅ Integration points tested
- ✅ Core user flows validated

## Risk Assessment: Very Low
- Tests can always be added back
- Business logic tests preserved
- No code changes during pruning
- Incremental validation possible 