# OfflineCacheService Refactoring Plan

## **Overview**

**Project:** OfflineCacheService Refactoring (Following TodayFeedCacheService Success)  
**Target File:** `app/lib/core/services/offline_cache_service.dart` (730 lines)  
**Current Status:** All functionality working (tests passing)  
**Objective:** Refactor monolithic service into modular architecture while maintaining 100% backward compatibility

## **Problem Statement**

The `OfflineCacheService` has grown to 730 lines and exhibits the same "god object" anti-pattern as the previous TodayFeedCacheService with multiple responsibilities:
- Core momentum data caching and retrieval
- Cache validation and version management  
- Pending action queue management with priority and retry logic
- Error handling and reporting queue
- Background synchronization control
- Cache health monitoring and statistics
- Cache maintenance and cleanup operations
- Testing helper methods

## **Refactoring Strategy**

**Approach:** Safe, incremental extraction with continuous testing (proven successful)  
**Risk Management:** Medium-High - Core infrastructure used by momentum features  
**Testing Protocol:** Run full test suite after every extraction step  
**Reference:** Follow exact methodology from TodayFeedCacheService refactor

## **Target Architecture**

```
OfflineCacheService (Main Coordinator ~200 lines)
├── OfflineCacheContentService (Core data caching/retrieval ~200 lines)
├── OfflineCacheValidationService (Data integrity & validation ~150 lines)  
├── OfflineCacheMaintenanceService (Cleanup & version management ~180 lines)
├── OfflineCacheErrorService (Error handling & queuing ~120 lines)
├── OfflineCacheSyncService (Background synchronization ~100 lines)
└── OfflineCacheStatsService (Health monitoring & statistics ~150 lines)
```

---

## **Sprint Breakdown**

### **Sprint 0: Pre-Refactoring Analysis & Setup**
**Time Estimate:** 1-2 hours  
**Risk Level:** 🟢 MINIMAL

#### **Objectives:**
- Document current architecture and dependencies
- Establish baseline test coverage
- Create refactoring workspace following proven approach

#### **Tasks:**
1. **Test Baseline Documentation**
   - Run full test suite and document baseline
   - Identify all test files that depend on OfflineCacheService
   - Note any flaky tests that need attention
   - Document current test pattern: `test/core/services/offline_cache_service_test.dart`

2. **Architecture Analysis**
   - Create dependency map of all public methods (37+ methods identified)
   - Document all static methods and their usage patterns
   - Map SharedPreferences key usage (9 keys identified)
   - Identify method call relationships and dependencies
   - Document current usage in `MomentumApiService` and providers

3. **Workspace Setup**
   - Create new directory structure: `app/lib/core/services/cache/offline/`
   - Create git branch for refactoring work: `refactor/offline-cache-service`
   - Document current file structure and dependencies

4. **Safety Measures**
   - Create backup of original file
   - Establish rollback procedures identical to TodayFeedCache refactor
   - Document commit strategy (commit after each service extraction)

#### **Success Criteria:**
- [ ] All tests passing (baseline established)
- [ ] Complete method dependency map created
- [ ] New directory structure ready
- [ ] Git branch created and baseline committed
- [ ] Rollback procedures documented

#### **Deliverables:**
- Dependency map document
- Test baseline report
- Git branch with initial commit

---

### **Sprint 1: Extract Statistics & Health Service**
**Time Estimate:** 2-3 hours  
**Risk Level:** 🟢 LOW

#### **Focus:** Extract health monitoring and statistics functionality
**Target:** ~150 lines → `OfflineCacheStatsService`

#### **Methods to Extract:**
- `getEnhancedCacheStats()`
- `getCachedDataAge()`
- `getCacheStats()` (legacy compatibility)
- `checkCacheHealth()`
- `performCacheCleanup()` (health score logic only)

#### **Helper Methods:**
- Health score calculation logic
- Cache age calculation
- Statistics aggregation methods

#### **Tasks:**
1. **Create Service Structure**
   ```dart
   class OfflineCacheStatsService {
     static SharedPreferences? _prefs;
     
     static Future<void> initialize(SharedPreferences prefs) async {
       _prefs = prefs;
     }
     
     static Future<Map<String, dynamic>> getEnhancedCacheStats() async { ... }
   }
   ```

2. **Extract Methods by Group**
   - Move basic statistics methods first
   - Move health scoring logic
   - Move cache age calculations
   - Test after each group

3. **Update Main Service**
   - Add statistics service dependency
   - Replace method calls with service delegation
   - Maintain identical public interfaces

#### **Success Criteria:**
- [ ] All tests still passing
- [ ] Statistics service created (~150 lines)
- [ ] Main service reduced by ~150 lines
- [ ] All statistics APIs work identically
- [ ] No performance degradation

#### **Files Created:**
- `app/lib/core/services/cache/offline/offline_cache_stats_service.dart`

---

### **Sprint 2: Extract Error Management Service**
**Time Estimate:** 1-2 hours  
**Risk Level:** 🟢 LOW

#### **Focus:** Extract error handling and queuing functionality
**Target:** ~120 lines → `OfflineCacheErrorService`

#### **Methods to Extract:**
- `queueError()`
- `getQueuedErrors()`
- `clearQueuedErrors()`
- Error queue size management logic

#### **Tasks:**
1. **Create Error Service Structure**
   ```dart
   class OfflineCacheErrorService {
     static const String _errorQueueKey = 'error_queue';
     static SharedPreferences? _prefs;
   }
   ```

2. **Extract Error Methods**
   - Move error queuing logic
   - Move error retrieval methods
   - Move error cleanup logic

3. **Integration Testing**
   - Verify error queuing works identically
   - Test error queue size limits
   - Check error retrieval functionality

#### **Success Criteria:**
- [ ] All tests still passing
- [ ] Error service created (~120 lines)
- [ ] Main service reduced by ~120 lines
- [ ] Error handling APIs work identically

#### **Files Created:**
- `app/lib/core/services/cache/offline/offline_cache_error_service.dart`

---

### **Sprint 3: Extract Pending Actions Service**  
**Time Estimate:** 2-3 hours  
**Risk Level:** 🟡 MEDIUM

#### **Focus:** Extract pending action queue management
**Target:** ~180 lines → `OfflineCacheActionService`

#### **Methods to Extract:**
- `queuePendingAction()`
- `processPendingActions()`
- `getPendingActions()`
- `removePendingAction()`
- `clearPendingActions()`
- `_cleanupExpiredDataSafe()`

#### **Complex Logic:**
- Priority-based action queuing
- Retry logic implementation
- Duplicate action detection
- Action sorting and processing

#### **Tasks:**
1. **Create Action Service Structure**
   ```dart
   class OfflineCacheActionService {
     static const String _pendingActionsKey = 'pending_actions';
     static SharedPreferences? _prefs;
   }
   ```

2. **Extract Action Methods**
   - Move action queuing with priority logic
   - Move action processing with retry logic
   - Move action cleanup methods
   - **Critical:** Maintain exact retry and priority behavior

3. **Comprehensive Testing**
   - Test priority-based queuing
   - Test retry logic
   - Test duplicate detection
   - Test action cleanup

#### **Success Criteria:**
- [ ] All tests still passing
- [ ] Action service created (~180 lines)
- [ ] Priority and retry logic preserved
- [ ] Main service reduced by ~180 lines

#### **Files Created:**
- `app/lib/core/services/cache/offline/offline_cache_action_service.dart`

---

### **Sprint 4: Extract Background Sync Service**
**Time Estimate:** 1-2 hours  
**Risk Level:** 🟢 LOW

#### **Focus:** Extract background synchronization control
**Target:** ~100 lines → `OfflineCacheSyncService`

#### **Methods to Extract:**
- `enableBackgroundSync()`
- `isBackgroundSyncEnabled()`
- `warmCache()`
- Background sync settings management

#### **Tasks:**
1. **Create Sync Service Structure**
   ```dart
   class OfflineCacheSyncService {
     static const String _backgroundSyncKey = 'background_sync_enabled';
     static const String _lastSyncAttemptKey = 'last_sync_attempt';
   }
   ```

2. **Extract Sync Methods**
   - Move background sync enable/disable
   - Move cache warming functionality
   - Move sync attempt tracking

#### **Success Criteria:**
- [ ] All tests still passing
- [ ] Sync service created (~100 lines)
- [ ] Background sync functionality preserved
- [ ] Main service reduced by ~100 lines

#### **Files Created:**
- `app/lib/core/services/cache/offline/offline_cache_sync_service.dart`

---

### **Sprint 5: Extract Cache Validation Service**
**Time Estimate:** 2-3 hours  
**Risk Level:** 🟡 MEDIUM

#### **Focus:** Extract data validation and cache integrity
**Target:** ~150 lines → `OfflineCacheValidationService`

#### **Methods to Extract:**
- `isCachedDataValid()`
- `_validateCacheVersion()`
- Cache validity checking logic
- Version management functionality

#### **Complex Logic:**
- Custom validity period handling
- High priority update validation
- Cache version compatibility checks

#### **Tasks:**
1. **Create Validation Service Structure**
   ```dart
   class OfflineCacheValidationService {
     static const String _cacheVersionKey = 'cache_version';
     static const int _currentCacheVersion = 2;
   }
   ```

2. **Extract Validation Methods**
   - Move cache validity checking
   - Move version validation logic
   - Move compatibility checks
   - **Critical:** Preserve all validity logic exactly

#### **Success Criteria:**
- [ ] All tests still passing
- [ ] Validation service created (~150 lines)
- [ ] Cache validity logic preserved
- [ ] Version management functionality intact

#### **Files Created:**
- `app/lib/core/services/cache/offline/offline_cache_validation_service.dart`

---

### **Sprint 6: Extract Cache Maintenance Service**
**Time Estimate:** 2-3 hours  
**Risk Level:** 🟡 MEDIUM

#### **Focus:** Extract cache maintenance and cleanup operations
**Target:** ~180 lines → `OfflineCacheMaintenanceService`

#### **Methods to Extract:**
- `invalidateCache()`
- `clearAllCache()`
- `performCacheCleanup()` (cleanup operations only)
- Cache cleanup and maintenance logic

#### **Complex Logic:**
- Smart cache invalidation
- Selective cache clearing
- Cache cleanup operations
- Storage management

#### **Tasks:**
1. **Create Maintenance Service Structure**
   ```dart
   class OfflineCacheMaintenanceService {
     static SharedPreferences? _prefs;
   }
   ```

2. **Extract Maintenance Methods**
   - Move cache invalidation logic
   - Move cache clearing methods
   - Move cleanup operations
   - **Critical:** Preserve all invalidation logic

#### **Success Criteria:**
- [ ] All tests still passing
- [ ] Maintenance service created (~180 lines)
- [ ] Cache invalidation logic preserved
- [ ] Cleanup operations work identically

#### **Files Created:**
- `app/lib/core/services/cache/offline/offline_cache_maintenance_service.dart`

---

### **Sprint 7: Extract Content Service & Core Integration**
**Time Estimate:** 3-4 hours  
**Risk Level:** 🟡 MEDIUM-HIGH

#### **Focus:** Extract core content caching functionality
**Target:** ~200 lines → `OfflineCacheContentService`

#### **Methods to Extract:**
- `cacheMomentumData()`
- `getCachedMomentumData()`
- `getCachedWeeklyTrend()`
- `getCachedMomentumStats()`
- `_cacheWeeklyTrend()`
- `_cacheMomentumStats()`

#### **Complex Logic:**
- Granular caching with skip logic
- Component-based caching
- Stale data handling
- Content-specific validity

#### **Tasks:**
1. **Create Content Service Structure**
   ```dart
   class OfflineCacheContentService {
     static const String _momentumDataKey = 'cached_momentum_data';
     static const String _weeklyTrendKey = 'cached_weekly_trend';
     static const String _momentumStatsKey = 'cached_momentum_stats';
   }
   ```

2. **Extract Content Methods**
   - Move core caching functionality
   - Move data retrieval methods
   - Move component-specific caching
   - **Critical:** Preserve all caching behavior exactly

3. **Integration with Other Services**
   - Ensure validation service integration
   - Maintain statistics service integration
   - Test cross-service dependencies

#### **Success Criteria:**
- [ ] All tests still passing
- [ ] Content service created (~200 lines)
- [ ] Core caching functionality preserved
- [ ] Service integrations working
- [ ] Main service significantly reduced

#### **Files Created:**
- `app/lib/core/services/cache/offline/offline_cache_content_service.dart`

---

### **Sprint 8: Final Integration & Testing Cleanup**
**Time Estimate:** 2-3 hours  
**Risk Level:** 🟡 MEDIUM

#### **Focus:** Final integration and testing infrastructure
**Target:** Main service ~200 lines (final target achieved)

#### **Remaining Methods in Main Service:**
- `initialize()` (coordinator only)
- Service initialization and coordination
- Testing helper methods (if keeping them in main service)
- Backward compatibility methods

#### **Tasks:**
1. **Clean Up Main Service**
   - Remove extracted method bodies
   - Add service delegation calls
   - Maintain backward compatibility
   - Clean up imports and dependencies

2. **Update Testing Infrastructure**
   - Ensure all tests pass
   - Update test imports if needed
   - Test service initialization order
   - Test backward compatibility

3. **Create Service README**
   - Document new architecture
   - Provide migration guide
   - Update code examples
   - Document service dependencies

4. **Integration Testing**
   - Test full momentum flow end-to-end
   - Test offline/online scenarios
   - Test error handling across services
   - Performance testing

#### **Success Criteria:**
- [ ] All tests still passing
- [ ] Main service ~200 lines
- [ ] Backward compatibility maintained
- [ ] Performance unchanged
- [ ] Documentation complete

#### **Files Created/Updated:**
- `app/lib/core/services/cache/offline/README.md`
- Updated main service with delegation
- Integration tests

---

## **Testing Strategy**

### **Continuous Testing Protocol**
- Run full test suite after each sprint
- Specific focus on `test/core/services/offline_cache_service_test.dart`
- Test momentum provider functionality
- Test API service integration

### **Integration Points to Test**
1. **MomentumApiService Integration**
   - `getCurrentMomentum()` caching behavior
   - Offline mode functionality
   - Cache warming and background refresh

2. **Provider Integration**
   - `momentum_api_provider.dart` functionality
   - Cache statistics providers
   - Connectivity-aware providers

3. **Cross-Service Dependencies**
   - Service initialization order
   - Inter-service communication
   - Error propagation between services

### **Backward Compatibility Testing**
- All existing public methods must work identically
- Performance must not degrade
- Memory usage should remain consistent
- Error behavior must be preserved

---

## **Risk Mitigation**

### **High-Risk Areas**
1. **Pending Action Processing** (Sprint 3)
   - Complex retry logic
   - Priority-based queuing
   - Action cleanup mechanisms

2. **Cache Content Operations** (Sprint 7)
   - Core caching functionality
   - Multiple data type handling
   - Stale data logic

3. **Service Initialization** (Sprint 8)
   - Service dependency order
   - Initialization state management
   - Cross-service communication

### **Mitigation Strategies**
- Test after each method extraction
- Maintain commit history for rollback
- Use exact same patterns from TodayFeedCache refactor
- Keep detailed logs of changes made

---

## **Success Metrics**

### **Code Quality Metrics**
- **Line Reduction:** 730 → ~1,100 lines (6 services + main coordinator)
- **Main Service:** 730 → ~200 lines (72% reduction)
- **Service Cohesion:** Each service has single clear responsibility
- **Maintainability:** Enhanced modularity for future development

### **Functional Metrics**
- **Test Coverage:** 100% tests passing before and after
- **Performance:** No degradation in cache operations
- **Memory Usage:** Consistent or improved memory footprint
- **API Compatibility:** 100% backward compatibility maintained

### **Architecture Metrics**
- **Service Separation:** Clear boundaries between services
- **Dependency Management:** Clean service initialization
- **Error Handling:** Distributed error handling across services
- **Documentation:** Complete service documentation

---

## **Future Benefits**

### **Development Velocity**
- Easier to modify specific cache aspects
- Cleaner testing of individual components
- Faster debugging with isolated services
- Reduced cognitive load for developers

### **Feature Development**
- Easy to add new cache types or strategies
- Simple to enhance error handling
- Straightforward to add new statistics
- Clear extension points for new functionality

### **Maintenance**
- Isolated bug fixes
- Targeted performance improvements
- Component-specific optimizations
- Clear service responsibilities

---

## **Implementation Timeline**

| Sprint | Focus | Duration | Risk | Dependencies |
|---------|-------|----------|------|--------------|
| 0 | Setup & Analysis | 1-2h | 🟢 | None |
| 1 | Statistics Service | 2-3h | 🟢 | Sprint 0 |
| 2 | Error Service | 1-2h | 🟢 | Sprint 1 |
| 3 | Action Service | 2-3h | 🟡 | Sprint 2 |
| 4 | Sync Service | 1-2h | 🟢 | Sprint 3 |
| 5 | Validation Service | 2-3h | 🟡 | Sprint 4 |
| 6 | Maintenance Service | 2-3h | 🟡 | Sprint 5 |
| 7 | Content Service | 3-4h | 🟡 | Sprint 6 |
| 8 | Final Integration | 2-3h | 🟡 | Sprint 7 |

**Total Estimated Time:** 16-25 hours  
**Recommended Approach:** Complete 1-2 sprints per session to maintain context

---

## **Rollback Strategy**

### **Per-Sprint Rollback**
- Each sprint creates independent git commit
- Can rollback to any previous sprint state
- Service extraction is incremental and reversible

### **Full Rollback**
- Keep original file as backup
- Git branch allows complete revert
- Tests provide confidence in rollback state

### **Partial Rollback**
- Can keep successfully extracted services
- Rollback only problematic extractions
- Maintain working state throughout process

---

*This plan follows the proven methodology from the successful TodayFeedCacheService refactor, adapted specifically for OfflineCacheService's unique responsibilities and complexity.* 