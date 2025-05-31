# Sprint 1 Assistant Prompt: Extract Statistics & Health Service

## **Context & Previous Work**

You are continuing the OfflineCacheService refactoring after **Sprint 0 (COMPLETE)**. The previous assistant has:

✅ **Completed Sprint 0 Analysis:**
- Analyzed 730-line monolithic `OfflineCacheService` with 37 methods
- Established baseline: All 20 tests passing
- Created git branch: `refactor/offline-cache-service`
- Set up directory structure: `app/lib/core/services/cache/offline/`
- Documented all dependencies and risk levels
- Committed comprehensive analysis to git

✅ **Sprint 0 Deliverables:**
- `docs/refactor/sprint_0_analysis.md` - Complete architecture analysis
- `docs/refactor/offline_cache_service_refactor_plan.md` - Master refactoring plan
- Directory structure ready for modular services
- All safety measures established

## **Sprint 1 Objective: Extract Statistics & Health Service**

**Target:** Extract ~150 lines → `OfflineCacheStatsService` 
**Risk Level:** 🟢 LOW (Safest extraction to start with)
**Current State:** All tests passing, clean git branch

### **Methods to Extract (5 methods + logic):**
1. **`getEnhancedCacheStats()`** - 6 usages across codebase (high-frequency)
2. **`getCachedDataAge()`** - Age calculation utility
3. **`getCacheStats()`** - Legacy compatibility method (delegates to getEnhancedCacheStats)
4. **`checkCacheHealth()`** - Health monitoring functionality
5. **Health score calculation logic** - Currently embedded in getEnhancedCacheStats

### **Files to Create:**
- `app/lib/core/services/cache/offline/offline_cache_stats_service.dart`

### **Current File Locations:**
- **Main Service:** `app/lib/core/services/offline_cache_service.dart` (730 lines)
- **Test File:** `app/test/core/services/offline_cache_service_test.dart` (342 lines, 20 tests)
- **Sprint 0 Analysis:** `docs/refactor/sprint_0_analysis.md`

## **Step-by-Step Instructions**

### **Step 1: Create the Statistics Service Structure**

Create `app/lib/core/services/cache/offline/offline_cache_stats_service.dart` with this basic structure:

```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Statistics and health monitoring service for offline cache
class OfflineCacheStatsService {
  static SharedPreferences? _prefs;
  
  /// Initialize the stats service with SharedPreferences
  static Future<void> initialize(SharedPreferences prefs) async {
    _prefs = prefs;
  }
  
  // TODO: Extract methods here
}
```

### **Step 2: Extract Methods One by One**

**CRITICAL:** Extract methods in this exact order to minimize risk:

#### **2a. Extract `getCachedDataAge()` first (lowest risk)**
- Copy method from main service lines ~496-507
- Update to use `_prefs` instead of accessing directly
- Test immediately after extraction

#### **2b. Extract health score calculation logic**
- This is embedded in `getEnhancedCacheStats()` around lines ~464-471
- Create separate private method `_calculateHealthScore()`
- Keep exact same logic

#### **2c. Extract `getEnhancedCacheStats()` method**
- Copy method from main service lines ~450-485
- Import any needed dependencies
- Update to call extracted health score method
- This is the most complex method - test thoroughly

#### **2d. Extract `checkCacheHealth()` method**
- Copy method from main service lines ~721-730
- Update to use local stats service methods

#### **2e. Create `getCacheStats()` legacy wrapper**
- Simple delegation to `getEnhancedCacheStats()`
- Maintains backward compatibility

### **Step 3: Update Main Service with Delegation**

In `app/lib/core/services/offline_cache_service.dart`:

1. **Add import:** `import 'cache/offline/offline_cache_stats_service.dart';`

2. **Update `initialize()` method** to initialize stats service:
```dart
await OfflineCacheStatsService.initialize(_prefs!);
```

3. **Replace extracted methods** with delegation calls:
```dart
static Future<Map<String, dynamic>> getEnhancedCacheStats() async {
  await initialize();
  return await OfflineCacheStatsService.getEnhancedCacheStats();
}
```

4. **Remove original method implementations** (but keep method signatures for backward compatibility)

### **Step 4: Testing Protocol**

**CRITICAL:** Test after each method extraction:

```bash
cd app
flutter test test/core/services/offline_cache_service_test.dart
```

**Expected Test Results:**
- ✅ All 20 tests must still pass
- ✅ No new test failures
- ✅ Performance should be identical

**Specific tests to watch:**
- "Cache Management should provide comprehensive cache statistics"
- "Cache Health Scoring should calculate cache health score correctly" 
- "Cache Health Scoring should reduce health score with problems"
- "Legacy Compatibility should maintain backward compatibility with getCacheStats"

### **Step 5: Verification Checklist**

Before proceeding, verify:

- [ ] **All tests passing:** 20/20 tests green
- [ ] **Line count reduction:** Main service reduced by ~150 lines
- [ ] **New service created:** ~150 lines in OfflineCacheStatsService
- [ ] **No breaking changes:** All public APIs work identically
- [ ] **Import dependencies:** New service has all needed imports

### **Step 6: Commit Sprint 1 Completion**

```bash
git add .
git commit -m "Sprint 1: Extract OfflineCacheStatsService (150 lines)

- Created OfflineCacheStatsService with statistics and health monitoring
- Extracted 5 methods: getEnhancedCacheStats, getCachedDataAge, getCacheStats, checkCacheHealth, health scoring
- Maintained backward compatibility with delegation pattern
- All 20 tests still passing
- Main service reduced from 730 to ~580 lines
- Ready for Sprint 2: Error Service extraction"
```

## **Dependencies & Integration Points**

### **Methods Calling Statistics Functions:**
- `momentum_api_provider.dart` - calls `getEnhancedCacheStats()` (2 usages)
- `error_widgets.dart` - calls `getCacheStats()` (2 usages) 
- `health_check_service.dart` - calls `getEnhancedCacheStats()` (1 usage)

### **SharedPreferences Keys Used by Stats Service:**
```dart
// These keys are read by the stats service:
_momentumDataKey = 'cached_momentum_data'
_lastUpdateKey = 'momentum_last_update'  
_pendingActionsKey = 'pending_actions'
_errorQueueKey = 'error_queue'
_weeklyTrendKey = 'cached_weekly_trend'
_momentumStatsKey = 'cached_momentum_stats'
_backgroundSyncKey = 'background_sync_enabled'
_lastSyncAttemptKey = 'last_sync_attempt'
_cacheVersionKey = 'cache_version'
```

## **Risk Mitigation**

### **If Tests Fail:**
1. **Immediate rollback:** `git checkout -- app/lib/core/services/offline_cache_service.dart`
2. **Remove new service:** `rm app/lib/core/services/cache/offline/offline_cache_stats_service.dart`
3. **Re-run tests** to confirm rollback success
4. **Analyze failure** and try smaller extractions

### **Common Issues to Watch For:**
- **Missing imports** in new service
- **SharedPreferences initialization** timing
- **Method signature changes** (must maintain exact compatibility)
- **Async/await patterns** - keep identical behavior

## **Success Criteria**

### **Functional Success:**
- [ ] All 20 existing tests pass
- [ ] Statistics functionality works identically
- [ ] Health monitoring preserved exactly
- [ ] Legacy `getCacheStats()` still works

### **Code Quality Success:**
- [ ] Main service reduced by ~150 lines
- [ ] New service is ~150 lines
- [ ] Clean separation of concerns
- [ ] No code duplication between services

### **Architecture Success:**
- [ ] Service initialization pattern established
- [ ] Delegation pattern working correctly
- [ ] Backward compatibility maintained 100%
- [ ] Ready for Sprint 2 (Error Service extraction)

## **Next Steps After Sprint 1**

If Sprint 1 succeeds, the next assistant should proceed with:

**Sprint 2: Extract Error Management Service** (🟢 LOW RISK)
- Target: `queueError()`, `getQueuedErrors()`, `clearQueuedErrors()`
- Expected reduction: ~120 lines
- Similar delegation pattern

## **Files Modified in Sprint 1**

### **Created:**
- `app/lib/core/services/cache/offline/offline_cache_stats_service.dart`

### **Modified:**
- `app/lib/core/services/offline_cache_service.dart` (delegation added, methods removed)

### **Unchanged (should not be touched):**
- All test files (methods delegated transparently)
- All dependent services (APIs unchanged)

## **Emergency Contacts & Rollback**

### **If Sprint 1 Gets Stuck:**
1. **Stop immediately** if more than 2 test failures occur
2. **Document the issue** in git commit
3. **Rollback to Sprint 0 state:** `git reset --hard HEAD~1`
4. **Consider smaller extraction chunks** or different method order

### **Validation Commands:**
```bash
# Run tests
cd app && flutter test test/core/services/offline_cache_service_test.dart

# Check line count
wc -l app/lib/core/services/offline_cache_service.dart

# Verify git status
git status
git log --oneline -n 5
```

---

**Sprint 1 Status: 🎯 READY TO EXECUTE**

**Previous Assistant Notes:** "Sprint 0 completed successfully. All baseline requirements met. Statistics service extraction is lowest risk and ready for immediate execution. Follow the exact methodology that worked for TodayFeedCacheService refactor." 