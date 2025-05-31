# Sprint 0: OfflineCacheService Pre-Refactoring Analysis

## **Current Architecture Analysis**

### **File Statistics**
- **Main Service:** `app/lib/core/services/offline_cache_service.dart`
- **Total Lines:** 730 lines
- **Test File:** `app/test/core/services/offline_cache_service_test.dart` (342 lines)
- **Test Coverage:** 20 test cases passing ✅

### **Public Method Inventory (37 methods)**

#### **Core Content Methods (8 methods)**
1. `cacheMomentumData()` - Enhanced caching with priority flags
2. `getCachedMomentumData()` - Retrieval with staleness control
3. `getCachedWeeklyTrend()` - Component-specific retrieval 
4. `getCachedMomentumStats()` - Stats-specific retrieval
5. `_cacheWeeklyTrend()` - Private component caching
6. `_cacheMomentumStats()` - Private stats caching
7. `warmCache()` - Cache warming functionality
8. `isCachedDataValid()` - Enhanced validity checking

#### **Pending Action Methods (6 methods)**
9. `queuePendingAction()` - Priority-based action queuing
10. `processPendingActions()` - Retry logic processing
11. `getPendingActions()` - Action retrieval
12. `removePendingAction()` - Single action removal
13. `clearPendingActions()` - Bulk action clearing
14. `_cleanupExpiredDataSafe()` - Safe cleanup during init

#### **Error Management Methods (3 methods)**
15. `queueError()` - Error queuing with size limits
16. `getQueuedErrors()` - Error retrieval
17. `clearQueuedErrors()` - Error queue clearing

#### **Cache Management Methods (6 methods)**
18. `invalidateCache()` - Smart component-based invalidation
19. `clearAllCache()` - Complete cache reset
20. `performCacheCleanup()` - Maintenance operations
21. `checkCacheHealth()` - Health monitoring
22. `_validateCacheVersion()` - Version management
23. `initialize()` - Service initialization

#### **Statistics & Health Methods (5 methods)**
24. `getEnhancedCacheStats()` - Comprehensive statistics
25. `getCacheStats()` - Legacy compatibility method
26. `getCachedDataAge()` - Age calculation
27. Health score calculation (embedded in getEnhancedCacheStats)
28. Cache health scoring logic

#### **Background Sync Methods (2 methods)**
29. `enableBackgroundSync()` - Sync control
30. `isBackgroundSyncEnabled()` - Sync status

#### **Testing Methods (7 methods)**
31. `resetForTesting()` - Test state reset
32. `setCachedDataForTesting()` - Test data injection
33. `clearCacheForTesting()` - Test cache clearing
34. `getCachedMomentumDataForTesting()` - Test data retrieval
35. `isCachedDataValidForTesting()` - Test validity check
36. Static test data fields: `_testCachedData`, `_testCacheIsValid`

### **SharedPreferences Keys (9 keys)**
```dart
static const String _momentumDataKey = 'cached_momentum_data';
static const String _lastUpdateKey = 'momentum_last_update';
static const String _pendingActionsKey = 'pending_actions';
static const String _errorQueueKey = 'error_queue';
static const String _cacheVersionKey = 'cache_version';
static const String _backgroundSyncKey = 'background_sync_enabled';
static const String _lastSyncAttemptKey = 'last_sync_attempt';
static const String _weeklyTrendKey = 'cached_weekly_trend';
static const String _momentumStatsKey = 'cached_momentum_stats';
```

### **Cache Validity Configuration**
```dart
static const int _defaultCacheValidityHours = 24;
static const int _criticalCacheValidityHours = 1;
static const int _weeklyTrendValidityHours = 12;
static const int _statsValidityHours = 6;
static const int _currentCacheVersion = 2;
```

## **Dependency Analysis**

### **Direct Dependencies (6 files)**
1. **`app/lib/main.dart`** - Service initialization
2. **`app/lib/features/momentum/data/services/momentum_api_service.dart`** - Primary client (15+ method calls)
3. **`app/lib/features/momentum/presentation/providers/momentum_api_provider.dart`** - Provider integration (10+ method calls)
4. **`app/lib/features/momentum/presentation/widgets/error_widgets.dart`** - Statistics display
5. **`app/lib/core/services/health_check_service.dart`** - Health monitoring
6. **`app/integration_test/user_acceptance_test_framework.dart`** - Integration testing

### **Test Dependencies (2 files)**
1. **`app/test/core/services/offline_cache_service_test.dart`** - Main test suite (20 tests)
2. **`app/test/features/momentum/data/services/momentum_api_service_test.dart`** - Integration tests

### **Usage Pattern Analysis**

#### **High-Frequency Methods** (Called >5 times across codebase)
- `getCachedMomentumData()` - 8 usages
- `getEnhancedCacheStats()` - 6 usages  
- `cacheMomentumData()` - 5 usages

#### **Medium-Frequency Methods** (Called 2-4 times)
- `queueError()` - 3 usages
- `initialize()` - 3 usages
- `clearAllCache()` - 2 usages

#### **Testing-Specific Methods** (Test files only)
- All testing helper methods are only used in test files
- No production code depends on testing methods ✅

## **Risk Assessment**

### **🟢 LOW RISK Areas**
- **Statistics Service (Sprint 1):** Clean separation, minimal dependencies
- **Error Service (Sprint 2):** Self-contained functionality
- **Sync Service (Sprint 4):** Simple state management

### **🟡 MEDIUM RISK Areas** 
- **Action Service (Sprint 3):** Complex retry logic and priority handling
- **Validation Service (Sprint 5):** Cache validity logic with multiple configurations
- **Maintenance Service (Sprint 6):** Smart invalidation and cleanup operations

### **🟡 MEDIUM-HIGH RISK Areas**
- **Content Service (Sprint 7):** Core caching functionality, most dependencies
- **Final Integration (Sprint 8):** Service coordination and backward compatibility

## **Test Baseline Documentation**

### **Current Test Status**
```
✅ All 20 tests passing
✅ Test execution time: ~1 second
✅ No flaky tests identified
✅ Comprehensive coverage of all major functionality
```

### **Test Categories**
1. **Enhanced Caching (3 tests)** - Core functionality
2. **Cache Validity (3 tests)** - Validation logic
3. **Cache Management (2 tests)** - Statistics and version handling
4. **Smart Cache Invalidation (1 test)** - Component invalidation
5. **Enhanced Pending Actions (3 tests)** - Action management
6. **Background Sync Management (1 test)** - Sync control
7. **Cache Warming (1 test)** - Cache warming
8. **Error Handling (2 tests)** - Error queuing
9. **Cache Health Scoring (2 tests)** - Health monitoring
10. **Legacy Compatibility (1 test)** - Backward compatibility

### **Critical Test Dependencies**
- `shared_preferences` mocking working correctly
- `TestHelpers.createSampleMomentumData()` provides valid test data
- All async operations properly awaited
- Proper cleanup between tests with `clearAllCache()`

## **Proposed Service Extraction Plan**

### **Target Service Architecture**
```
OfflineCacheService (Main Coordinator ~200 lines)
├── OfflineCacheStatsService (Statistics ~150 lines)
├── OfflineCacheErrorService (Error handling ~120 lines)  
├── OfflineCacheActionService (Pending actions ~180 lines)
├── OfflineCacheSyncService (Background sync ~100 lines)
├── OfflineCacheValidationService (Data validation ~150 lines)
├── OfflineCacheMaintenanceService (Cleanup ~180 lines)
└── OfflineCacheContentService (Core content ~200 lines)
```

### **Service Extraction Mapping**

#### **Sprint 1: OfflineCacheStatsService**
```dart
// Methods to extract:
- getEnhancedCacheStats()
- getCachedDataAge() 
- getCacheStats() [legacy]
- checkCacheHealth()
- Health score calculation logic
```

#### **Sprint 2: OfflineCacheErrorService**
```dart
// Methods to extract:
- queueError()
- getQueuedErrors()
- clearQueuedErrors()
// Keys: _errorQueueKey
```

#### **Sprint 3: OfflineCacheActionService** 
```dart
// Methods to extract:
- queuePendingAction()
- processPendingActions()
- getPendingActions()
- removePendingAction()
- clearPendingActions()
- _cleanupExpiredDataSafe()
// Keys: _pendingActionsKey
```

#### **Sprint 4: OfflineCacheSyncService**
```dart
// Methods to extract:
- enableBackgroundSync()
- isBackgroundSyncEnabled()
- warmCache()
// Keys: _backgroundSyncKey, _lastSyncAttemptKey
```

#### **Sprint 5: OfflineCacheValidationService**
```dart
// Methods to extract:
- isCachedDataValid()
- _validateCacheVersion()
// Keys: _cacheVersionKey
// Constants: All validity hours
```

#### **Sprint 6: OfflineCacheMaintenanceService**
```dart
// Methods to extract:
- invalidateCache()
- clearAllCache()
- performCacheCleanup()
```

#### **Sprint 7: OfflineCacheContentService**
```dart
// Methods to extract:
- cacheMomentumData()
- getCachedMomentumData()
- getCachedWeeklyTrend()
- getCachedMomentumStats()
- _cacheWeeklyTrend()
- _cacheMomentumStats()
// Keys: _momentumDataKey, _lastUpdateKey, _weeklyTrendKey, _momentumStatsKey
```

## **Safety Measures Established**

### **Git Strategy**
- ✅ Branch created: `refactor/offline-cache-service`
- ✅ Clean working directory
- ✅ All current changes committed

### **Backup Strategy**
- ✅ Original file preserved in git history
- ✅ Directory structure created: `app/lib/core/services/cache/offline/`
- ✅ Rollback procedures documented

### **Testing Strategy**
- ✅ Baseline test run completed (all passing)
- ✅ Test execution command documented: `flutter test test/core/services/offline_cache_service_test.dart`
- ✅ Integration test awareness documented

### **Commit Strategy**
- Each sprint will create independent commits
- Can rollback to any previous sprint state
- Service extraction is incremental and reversible

## **Next Steps for Sprint 1**

### **Ready to Proceed With:**
1. **OfflineCacheStatsService extraction** (lowest risk)
2. **Target methods identified:** `getEnhancedCacheStats()`, `getCachedDataAge()`, `getCacheStats()`, health scoring
3. **Expected line reduction:** ~150 lines from main service
4. **Risk level:** 🟢 LOW

### **Success Criteria for Sprint 1:**
- [ ] All 20 tests still passing
- [ ] Statistics service created (~150 lines)
- [ ] Main service reduced to ~580 lines
- [ ] All statistics APIs work identically
- [ ] No performance degradation

---

**Sprint 0 Status: ✅ COMPLETE**

**Recommendations:**
- Proceed immediately with Sprint 1 (Statistics Service extraction)
- Follow exact same methodology as TodayFeedCacheService refactor
- Commit after each successful service extraction
- Test continuously throughout the process 