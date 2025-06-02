# TodayFeedCacheService Refactoring Plan

## **Overview**

**Project:** Epic 1.3 Today Feed - Code Refactoring  
**Target File:** `app/lib/core/services/today_feed_cache_service.dart` (4,078 lines)  
**Current Status:** All functionality working (82/82 tests passing)  
**Objective:** Refactor monolithic service into modular architecture while maintaining 100% backward compatibility

## **Problem Statement**

The `TodayFeedCacheService` has grown to over 4,000 lines and exhibits "god object" anti-pattern with multiple responsibilities:
- Content storage and retrieval
- Background synchronization 
- Timezone management and DST handling
- Cache cleanup and maintenance
- Health monitoring and diagnostics
- Statistics and performance metrics
- Error handling and retry logic

## **Refactoring Strategy**

**Approach:** Safe, incremental extraction with continuous testing  
**Risk Management:** High - This is core infrastructure used throughout the app  
**Testing Protocol:** Run full test suite after every extraction step  

## **Target Architecture**

```
TodayFeedCacheService (Main Coordinator ~500 lines)
├── TodayFeedContentService (Content storage/retrieval)
├── TodayFeedSyncService (Background sync/connectivity)  
├── TodayFeedTimezoneService (Timezone/DST handling)
├── TodayFeedCacheMaintenanceService (Cleanup/invalidation)
├── TodayFeedCacheHealthService (Health monitoring/diagnostics)
├── TodayFeedCacheStatisticsService (Statistics/metrics)
└── TodayFeedCachePerformanceService (Performance analysis)
```

---

## **Overall Progress**

**Completed Sprints:** 7/8 ✅  
**Current Status:** Sprint 7 Complete - Content Management Service Extracted  
**Next Sprint:** Sprint 8 - Final Integration & Cleanup  
**Estimated Completion:** 87.5% complete

### **Sprint Status Summary:**
- ✅ **Sprint 1:** Statistics Service (Complete)
- ✅ **Sprint 2:** Health Monitoring Service (Complete)  
- ✅ **Sprint 3:** Performance Analysis Service (Complete)
- ✅ **Sprint 4:** Timezone Management Service (Complete)
- ✅ **Sprint 5:** Background Sync Service (Complete)
- ✅ **Sprint 6:** Cache Maintenance Service (Complete)
- ✅ **Sprint 7:** Content Management Service (Complete)
- 📋 **Sprint 8:** Final Integration & Cleanup (Next)

### **Current Architecture Status:**
```
TodayFeedCacheService (Main Coordinator ~606 lines)
├── ✅ TodayFeedCacheStatisticsService (Statistics/metrics)
├── ✅ TodayFeedCacheHealthService (Health monitoring/diagnostics)
├── ✅ TodayFeedCachePerformanceService (Performance analysis)
├── ✅ TodayFeedTimezoneService (Timezone/DST handling)
├── ✅ TodayFeedCacheSyncService (Background sync/connectivity)
├── ✅ TodayFeedCacheMaintenanceService (Cleanup/invalidation - 392 lines)
├── ✅ TodayFeedContentService (Content storage/retrieval - 448 lines)
└── 📋 Final cleanup and optimization
```

---

## **Sprint Breakdown**

### **Sprint 0: Pre-Refactoring Analysis & Setup**
**Time Estimate:** 1-2 hours  
**Risk Level:** 🟢 MINIMAL

#### **Objectives:**
- Document current architecture and dependencies
- Establish baseline test coverage
- Create refactoring workspace

#### **Tasks:**
1. **Test Baseline Documentation**
   - Run full test suite and document baseline (82/82 tests)
   - Screenshot or document current test output
   - Note any flaky tests that need attention

2. **Architecture Analysis**
   - Create dependency map of all public methods
   - Document all static methods and their usage patterns
   - Identify method call relationships and dependencies
   - Map out SharedPreferences key usage

3. **Workspace Setup**
   - Set up new directory structure: `app/lib/core/services/cache/`
   - Create git branch for refactoring work: `refactor/today-feed-cache-service`
   - Document current file structure

4. **Safety Measures**
   - Create backup of original file
   - Establish rollback procedures
   - Document commit strategy

#### **Success Criteria:**
- [ ] All tests passing (82/82)
- [ ] Complete method dependency map created
- [ ] New directory structure ready
- [ ] Git branch created and baseline committed
- [ ] Rollback procedures documented

#### **Deliverables:**
- Dependency map document
- Test baseline report
- Git branch with initial commit

---

### **Sprint 1: Extract Statistics Service**
**Time Estimate:** 2-3 hours  
**Risk Level:** 🟢 LOW

#### **Focus:** Extract all statistics and metrics functionality
**Target:** ~600-800 lines → `TodayFeedCacheStatisticsService`

#### **Methods to Extract:**
- `getCacheStatistics()`
- `_getDetailedPerformanceStatistics()`
- `_getCacheUsageStatistics()`
- `_getCacheTrendAnalysis()`
- `_getCacheEfficiencyMetrics()`
- `_getOperationalStatistics()`
- `exportMetricsForMonitoring()`
- `_generateStatisticalSummary()`

#### **Helper Methods:**
- `_calculateAverage()`
- `_calculateMedian()`
- `_calculateStandardDeviation()`
- `_getPerformanceRating()`
- `_calculateOverallPerformanceRating()`
- `_generatePerformanceInsights()`
- `_calculateAvailabilityScore()`
- `_getUtilizationStatus()`
- `_calculateFreshnessScore()`

#### **Tasks:**
1. **Create Service Structure**
   ```dart
   class TodayFeedCacheStatisticsService {
     static SharedPreferences? _prefs;
     
     static Future<void> initialize(SharedPreferences prefs) async {
       _prefs = prefs;
     }
   }
   ```

2. **Extract Methods by Group**
   - Move basic statistics methods first
   - Move helper calculation methods
   - Move complex analysis methods last
   - Test after each group

3. **Update Main Service**
   - Add statistics service dependency
   - Replace method calls with service delegation
   - Maintain identical public interfaces

4. **Integration Testing**
   - Verify all statistics APIs work identically
   - Test statistics service initialization
   - Check memory usage patterns

#### **Success Criteria:**
- [ ] All 82 tests still passing
- [ ] Statistics service created (~600-800 lines)
- [ ] Main service reduced by ~800 lines
- [ ] All statistics APIs work identically
- [ ] No performance degradation

#### **Files Created:**
- `app/lib/core/services/cache/today_feed_cache_statistics_service.dart`

---

### **Sprint 2: Extract Health Monitoring Service**
**Time Estimate:** 1-2 hours  
**Risk Level:** 🟢 LOW

#### **Focus:** Extract health monitoring and diagnostics
**Target:** ~400-600 lines → `TodayFeedCacheHealthService`

#### **Methods to Extract:**
- `getCacheHealthStatus()`
- `performCacheIntegrityCheck()`
- `getDiagnosticInfo()`
- `_calculateOverallHealthScore()`
- `_calculateHitRateMetrics()`
- `_validateCacheIntegrity()`
- `_validateMetadataConsistency()`
- `_isValidContent()`

#### **Helper Methods:**
- `_calculateIntegrityScore()`
- `_generateIntegrityRecommendations()`
- `_calculateErrorRate()`
- `_generateHealthRecommendations()`

#### **Tasks:**
1. **Create Health Service**
   - Set up service with SharedPreferences dependency
   - Ensure access to cache keys and validation logic

2. **Extract Health Methods**
   - Move health status calculation
   - Move integrity checking logic
   - Move diagnostic information gathering

3. **Maintain Dependencies**
   - Ensure proper access to other service metrics
   - Keep diagnostic data collection intact

#### **Success Criteria:**
- [ ] All 82 tests still passing
- [ ] Health service created (~400-600 lines)
- [ ] Main service further reduced
- [ ] Health monitoring works identically
- [ ] Diagnostic info remains comprehensive

#### **Files Created:**
- `app/lib/core/services/cache/today_feed_cache_health_service.dart`

---

### **Sprint 3: Extract Performance Analysis Service**
**Time Estimate:** 1-2 hours  
**Risk Level:** 🟢 LOW

#### **Focus:** Extract performance testing and analysis
**Target:** ~300-500 lines → `TodayFeedCachePerformanceService`

#### **Methods to Extract:**
- `_calculatePerformanceMetrics()`
- Performance benchmarking methods
- Performance rating and insight methods
- Efficiency calculation methods from statistics

#### **Helper Methods:**
- `_calculatePerformanceRating()`
- `_generatePerformanceRecommendations()`
- `_calculateStorageEfficiency()`
- `_calculatePerformanceEfficiency()`

#### **Tasks:**
1. **Create Performance Service**
   - Set up performance testing infrastructure
   - Maintain benchmark accuracy

2. **Extract Performance Logic**
   - Move performance measurement methods
   - Keep timing precision intact

3. **Coordinate with Statistics**
   - Ensure proper integration with statistics service
   - Avoid duplication of metrics calculation

#### **Success Criteria:**
- [ ] All 82 tests still passing
- [ ] Performance service created (~300-500 lines)
- [ ] Performance metrics identical to original
- [ ] Benchmark timing accuracy maintained

#### **Files Created:**
- `app/lib/core/services/cache/today_feed_cache_performance_service.dart`

---

### **Sprint 4: Extract Timezone Management Service**
**Time Estimate:** 2-3 hours  
**Risk Level:** 🟡 MEDIUM

#### **Focus:** Extract timezone and DST handling logic
**Target:** ~500-700 lines → `TodayFeedTimezoneService`

#### **Methods to Extract:**
- `_detectAndHandleTimezoneChanges()`
- `_getCurrentTimezoneInfo()`
- `_saveTimezoneInfo()` / `_getSavedTimezoneInfo()`
- `_hasTimezoneChanged()` / `_hasDstChanged()`
- `_shouldRefreshDueToTimezoneChange()`
- `_scheduleTimezoneChecks()`
- `_isPastRefreshTimeEnhanced()`
- `_adjustForDstTransition()`

#### **Helper Methods:**
- `_calculateNextRefreshTime()`
- `_checkTimezoneRefreshRequirement()`
- `_scheduleSpecificRefresh()`
- `_isSameLocalDay()`

#### **Tasks:**
1. **Create Timezone Service**
   - Set up timer management within service
   - Maintain timezone detection accuracy

2. **Extract Timezone Logic**
   - Move timezone change detection
   - Move DST transition handling
   - Keep refresh scheduling logic

3. **Timer Management**
   - Ensure timezone check timer continues working
   - Maintain refresh scheduling integration

4. **Testing Focus**
   - Test timezone change scenarios
   - Verify DST transition handling
   - Check refresh scheduling accuracy

#### **Success Criteria:**
- [ ] All 82 tests still passing
- [ ] Timezone service created (~500-700 lines)
- [ ] Timezone change detection functional
- [ ] Refresh scheduling maintains timezone awareness
- [ ] DST transitions handled correctly

#### **Files Created:**
- `app/lib/core/services/cache/today_feed_timezone_service.dart`

---

### **Sprint 5: Extract Background Sync Service**
**Time Estimate:** 2-3 hours  
**Risk Level:** 🟡 MEDIUM

#### **Focus:** Extract sync and connectivity management
**Target:** ~600-800 lines → `TodayFeedSyncService`

#### **Methods to Extract:**
- `syncWhenOnline()`
- `_initializeConnectivityListener()`
- `_onConnectivityChanged()`
- `_handleConnectivityRestored()` / `_handleConnectivityLost()`
- `_processPendingInteractionsWithRetry()`
- `_processIndividualInteraction()`
- `_scheduleRetrySync()`
- `queueInteraction()`
- `_validateCacheIntegrity()` (sync-related parts)

#### **Helper Methods:**
- `_logInteractionProcessingResults()`
- `_syncContentHistory()`
- `_updateSyncMetadata()`
- `getSyncStatus()`

#### **Tasks:**
1. **Create Sync Service**
   - Set up connectivity listener management
   - Maintain interaction queue processing

2. **Extract Sync Logic**
   - Move connectivity handling
   - Move retry mechanisms
   - Keep interaction queuing intact

3. **Maintain Integration**
   - Ensure proper coordination with main service
   - Keep sync status reporting functional

4. **Testing Focus**
   - Test offline/online transitions
   - Verify retry mechanisms
   - Check interaction queuing

#### **Success Criteria:**
- [ ] All 82 tests still passing
- [ ] Sync service created (~600-800 lines)
- [ ] Background sync works identically
- [ ] Connectivity handling unchanged
- [ ] Retry mechanisms functional

#### **Files Created:**
- `app/lib/core/services/cache/today_feed_sync_service.dart`

---

### **Sprint 6: Extract Cache Maintenance Service** ✅ **COMPLETED**
**Time Estimate:** 2-3 hours  
**Risk Level:** 🟡 MEDIUM  
**Actual Time:** ~2 hours

#### **Focus:** Extract cleanup, invalidation, and maintenance
**Target:** ~500-700 lines → `TodayFeedCacheMaintenanceService`

#### **Methods to Extract:**
- `_cleanupExpiredContent()`
- `_performCacheCleanup()`
- `_validateContentFreshness()`
- `_scheduleAutomaticCleanup()`
- `_performAutomaticCleanup()`
- `invalidateContent()`
- `selectiveCleanup()`
- `_enforceEntryLimits()`
- `_calculateCacheSize()`

#### **Helper Methods:**
- `_checkContentExpiration()`
- `_removeExpiredContent()`
- `_removeStaleContentOlderThan()`
- `getCacheInvalidationStats()`

#### **Tasks:**
1. **Create Maintenance Service** ✅
   - Set up automatic cleanup scheduling
   - Maintain cache size management

2. **Extract Maintenance Logic** ✅
   - Move cleanup and invalidation methods
   - Keep automatic scheduling functional

3. **Timer Management** ✅
   - Ensure cleanup timer continues working
   - Maintain cleanup intervals

4. **Testing Focus** ✅
   - Test automatic cleanup scheduling
   - Verify manual invalidation
   - Check cache size management

#### **Success Criteria:**
- [x] All 30 tests still passing
- [x] Maintenance service created (~393 lines)
- [x] Cache cleanup works identically
- [x] Automatic scheduling unchanged
- [x] Invalidation methods functional

#### **Files Created:**
- `app/lib/core/services/cache/today_feed_cache_maintenance_service.dart`

#### **Sprint 6 Summary:**
Successfully extracted cache maintenance functionality into a dedicated service. The maintenance service handles:
- **Cache Size Management**: Calculates cache size and enforces limits
- **Content Cleanup**: Removes expired and stale content automatically
- **Cache Invalidation**: Provides manual and automatic invalidation options
- **Content Validation**: Checks content freshness and expiration
- **Automatic Scheduling**: Manages periodic cleanup operations

The main service now delegates all maintenance operations to the specialized service while maintaining full backward compatibility.

---

### **Sprint 7: Extract Content Management Service** ✅ **COMPLETED**
**Time Estimate:** 3-4 hours  
**Risk Level:** 🔴 HIGH  
**Actual Time:** ~2.5 hours

#### **Focus:** Extract core content storage and retrieval
**Target:** ~800-1000 lines → `TodayFeedContentService`

#### **Methods Successfully Extracted:**
- `cacheTodayContent()` - Core content caching with metadata and size management
- `getTodayContent()` - Content retrieval with validation
- `getPreviousDayContent()` - Previous day content as fallback
- `getFallbackContentWithMetadata()` - Enhanced fallback with metadata
- `archiveTodayContent()` - Archive current content to previous day storage
- `clearTodayContent()` - Clear current content only
- Content history management (`_addToContentHistory`, `_getLatestFromHistory`)
- Content validation and timezone awareness helpers

#### **Tasks Completed:**
1. **Create Content Service** ✅
   - Set up service with SharedPreferences dependency
   - Maintain content storage and retrieval accuracy

2. **Extract Content Logic** ✅
   - Move core content management methods
   - Keep cache size enforcement intact
   - Maintain content history functionality

3. **Maintain Dependencies** ✅
   - Ensure proper access to maintenance service for size checks
   - Keep timezone service integration for content validation

4. **Testing Focus** ✅
   - Test content caching and retrieval
   - Verify fallback content mechanisms
   - Check content history management

#### **Success Criteria:**
- [x] All 397 tests still passing
- [x] Content service created (~448 lines)
- [x] Main service reduced from ~837 to ~606 lines (~231 line reduction)
- [x] Content management works identically
- [x] Fallback content mechanisms unchanged
- [x] Cache size management functional

#### **Files Created:**
- `app/lib/core/services/cache/today_feed_content_service.dart`

#### **Sprint 7 Summary:**
Successfully extracted core content management functionality into a dedicated service. The content service handles:
- **Content Storage**: Primary caching with metadata and size validation
- **Content Retrieval**: Timezone-aware content fetching with validation
- **Fallback Management**: Previous day content and history-based fallbacks
- **Content History**: Maintains 7-day content history for reliability
- **Content Lifecycle**: Archive, clear, and invalidation operations
- **Metadata Management**: Content timestamps, cache flags, and AI confidence scores

The main service now delegates all content operations to the specialized service while maintaining full backward compatibility. This was the highest risk extraction due to core content handling, but completed successfully with zero test failures.

---