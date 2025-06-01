# Today Feed Streak Tracking Service Refactoring Plan

## **Overview**

**Project:** Today Feed Streak Tracking Service Architecture Refactoring  
**Target:** 1 monolithic service (1,010 lines) → 5 modular services  
**Current Status:** T1.3.4.10 ✅ COMPLETE - All functionality working (tests passing)  
**Objective:** Refactor oversized service into clean, maintainable architecture with clear boundaries

---

## **Problem Statement**

The `TodayFeedStreakTrackingService` has grown to **1,010 lines**, violating our 500-line service limit and exhibiting classic "god object" anti-patterns.

### **Current Service Analysis**
| Responsibility | Lines | Complexity | Status |
|----------------|-------|------------|--------|
| **Streak Calculation Logic** | ~200 | High | 🔄 Needs Extraction |
| **Milestone Detection & Management** | ~150 | Medium | 🔄 Needs Extraction |
| **Celebration Creation & Management** | ~100 | Medium | 🔄 Needs Extraction |
| **Analytics Calculation** | ~100 | Medium | 🔄 Needs Extraction |
| **Database Operations** | ~100 | Low | 🔄 Needs Extraction |
| **Cache Management** | ~80 | Low | 🔄 Needs Extraction |
| **Offline Sync Management** | ~80 | Low | 🔄 Needs Extraction |
| **Service Coordination** | ~200 | High | 🔄 Needs Refactoring |

### **Refactoring Goals**
- [ ] **Lines Reduced:** 1,010 → ~1,350 total lines across 5 services (managed growth)
- [ ] **Service Compliance:** Each service ≤500 lines
- [ ] **Clear Boundaries:** Single responsibility per service
- [ ] **Zero Breaking Changes:** Maintain public API exactly
- [ ] **Improved Testability:** Isolated, focused unit tests

---

## **Target Architecture**

```
app/lib/features/today_feed/data/services/
├── today_feed_streak_tracking_service.dart (320 lines) ✅ Coordinator
└── streak_services/
    ├── streak_persistence_service.dart (280 lines) ✅ Data layer
    ├── streak_calculation_service.dart (290 lines) ✅ Business logic
    ├── streak_milestone_service.dart (240 lines) ✅ Feature logic
    └── streak_analytics_service.dart (220 lines) ✅ Reporting
```

### **Architecture Benefits**
- [ ] Clear service boundaries and single responsibilities
- [ ] Enhanced testability with focused unit tests
- [ ] Easier maintenance and feature additions
- [ ] Compliance with coding guidelines

---

## **Sprint Breakdown**

### **Sprint 0: Pre-Refactoring Analysis & Setup** 
**Time Estimate:** 1-2 hours  
**Risk Level:** 🟢 MINIMAL  
**Status:** ⚪ Not Started

#### **Objectives:**
- [ ] Document current service structure and dependencies
- [ ] Create service extraction plan and testing baseline
- [ ] Set up new directory structure and safety measures

#### **Tasks:**

##### **1. Service Analysis**
- [ ] Map all public/private methods and their responsibilities
- [ ] Document dependencies with other Today Feed services (`DailyEngagementDetectionService`, `TodayFeedMomentumAwardService`)
- [ ] Identify all integration points with UI components
- [ ] Document current test coverage and patterns

##### **2. Create Safety Measures**
- [ ] Create git branch: `refactor/streak-tracking-service-modularization`
- [ ] Backup original service file to safe location
- [ ] Run baseline test suite: `flutter test`
- [ ] Document current test results and expected behavior
- [ ] Document rollback procedures

##### **3. Prepare New Structure**
- [ ] Create directory: `app/lib/features/today_feed/data/services/streak_services/`
- [ ] Create placeholder files for new services
- [ ] Update service exports if needed

##### **4. Test Baseline**
- [ ] Run full test suite and document results
- [ ] Identify streak-specific tests that must continue passing
- [ ] Document current performance benchmarks

#### **Success Criteria:**
- [ ] All tests passing (baseline established)
- [ ] Complete method responsibility map created
- [ ] New directory structure ready
- [ ] Git branch created with baseline
- [ ] Rollback procedures documented

#### **Deliverables:**
- [ ] Service responsibility breakdown document
- [ ] Test baseline report
- [ ] New directory structure
- [ ] Git branch with initial commit

**Sprint 0 Status:** ⚪ **READY TO START**

---

### **Sprint 1: Extract Persistence Service**
**Time Estimate:** 2-3 hours  
**Risk Level:** 🟢 LOW  
**Status:** ⚪ Not Started

#### **Focus:** Extract all data persistence operations into dedicated service
**Target:** Create `StreakPersistenceService` (~280 lines)

#### **Tasks:**

##### **1. Create StreakPersistenceService Structure**
- [ ] Create file: `streak_services/streak_persistence_service.dart`
- [ ] Set up class structure with proper imports
- [ ] Implement singleton pattern following existing service patterns
- [ ] Add initialization method with proper dependencies

##### **2. Extract Database Operations**
- [ ] Move `_getStoredStreakData()` → `getStoredStreakData()`
- [ ] Move `_storeStreakData()` → `storeStreakData()`
- [ ] Move `_getAchievedMilestones()` → `getAchievedMilestones()`
- [ ] Move `_getPendingCelebration()` → `getPendingCelebration()`
- [ ] Ensure proper error handling for all database operations

##### **3. Extract Cache Management**
- [ ] Move `_getCachedStreak()` → `getCachedStreak()`
- [ ] Move `_cacheStreak()` → `cacheStreak()`
- [ ] Move cache cleanup logic → `clearCache()`
- [ ] Move cache expiry logic and validation

##### **4. Extract Offline Sync Operations**
- [ ] Move `_queueStreakUpdate()` → `queueStreakUpdate()`
- [ ] Move `_syncPendingUpdates()` → `syncPendingUpdates()`
- [ ] Move pending updates management → `getPendingUpdates()`
- [ ] Ensure connectivity monitoring integration

##### **5. Update Main Service**
- [ ] Add `StreakPersistenceService` dependency injection
- [ ] Replace all direct persistence calls with service calls
- [ ] Update initialization to include persistence service
- [ ] Maintain exact same public API behavior

##### **6. Create Unit Tests**
- [ ] Test database operations independently
- [ ] Test cache management functionality
- [ ] Test offline sync queuing and processing
- [ ] Test error handling scenarios

#### **Success Criteria:**
- [ ] StreakPersistenceService created (~280 lines)
- [ ] All persistence operations extracted successfully
- [ ] Main service updated with proper dependency injection
- [ ] All existing tests still passing
- [ ] New unit tests for persistence service created

#### **Deliverables:**
- [ ] `streak_persistence_service.dart` (280 lines)
- [ ] Updated main service with injection
- [ ] Unit tests for persistence operations

**Sprint 1 Status:** ⚪ **PENDING SPRINT 0**

---

### **Sprint 2: Extract Calculation Service**
**Time Estimate:** 2-3 hours  
**Risk Level:** 🟡 MEDIUM  
**Status:** ⚪ Not Started

#### **Focus:** Extract core streak calculation logic into dedicated service
**Target:** Create `StreakCalculationService` (~290 lines)

#### **Tasks:**

##### **1. Create StreakCalculationService Structure**
- [ ] Create file: `streak_services/streak_calculation_service.dart`
- [ ] Set up class with proper dependency injection for persistence service
- [ ] Implement singleton pattern and initialization
- [ ] Add proper imports and configuration constants

##### **2. Extract Core Calculation Methods**
- [ ] Move `_calculateCurrentStreak()` → `calculateCurrentStreak()`
- [ ] Move `_calculateUpdatedStreak()` → `calculateUpdatedStreak()`
- [ ] Move `_calculateStreakMetrics()` → `calculateStreakMetrics()`
- [ ] Ensure proper integration with persistence service

##### **3. Extract Calculation Helper Methods**
- [ ] Move `_isConsecutiveDay()` → helper method
- [ ] Move `_calculateStreakLength()` → helper method  
- [ ] Move `_calculateConsistencyRate()` → helper method
- [ ] Move all streak computation algorithms

##### **4. Update Main Service Integration**
- [ ] Add `StreakCalculationService` dependency injection
- [ ] Replace all calculation calls with service calls
- [ ] Maintain exact same public API behavior
- [ ] Update `getCurrentStreak()` method to use service
- [ ] Update `updateStreakOnEngagement()` method to use service

##### **5. Create Comprehensive Unit Tests**
- [ ] Test streak calculation with various engagement patterns
- [ ] Test consecutive day detection logic
- [ ] Test streak break handling
- [ ] Test consistency rate calculations
- [ ] Test edge cases (timezone changes, DST)

##### **6. Integration Testing**
- [ ] Test calculation service with persistence service
- [ ] Verify no performance degradation
- [ ] Test error handling and fallback behavior

#### **Success Criteria:**
- [ ] StreakCalculationService created (~290 lines)
- [ ] All calculation logic extracted and working correctly
- [ ] Main service updated with proper injection
- [ ] All existing tests still passing
- [ ] Comprehensive unit tests for calculations created

#### **Deliverables:**
- [ ] `streak_calculation_service.dart` (290 lines)
- [ ] Updated main service with calculation injection
- [ ] Unit tests covering calculation scenarios

**Sprint 2 Status:** ⚪ **PENDING SPRINT 1**

---

### **Sprint 3: Extract Milestone & Analytics Services**
**Time Estimate:** 3-4 hours  
**Risk Level:** 🟡 MEDIUM  
**Status:** ⚪ Not Started

#### **Focus:** Extract milestone detection and analytics into separate services
**Target:** Create `StreakMilestoneService` (~240 lines) and `StreakAnalyticsService` (~220 lines)

#### **Tasks:**

##### **1. Create StreakMilestoneService**
- [ ] Create file: `streak_services/streak_milestone_service.dart`
- [ ] Set up dependencies: persistence service, momentum award service
- [ ] Implement singleton pattern and initialization
- [ ] Add milestone configuration constants

##### **2. Extract Milestone Detection Logic**
- [ ] Move `_detectNewMilestones()` → `detectNewMilestones()`
- [ ] Move `_createMilestone()` → `createMilestone()`
- [ ] Move `_getMilestoneData()` → helper method
- [ ] Ensure proper milestone threshold validation

##### **3. Extract Celebration Management**
- [ ] Move `_createCelebration()` → `createCelebration()`
- [ ] Move celebration helper methods (emoji, title, message generation)
- [ ] Move celebration storage and retrieval logic
- [ ] Integrate with celebration display system

##### **4. Extract Momentum Bonus Logic**
- [ ] Move `_awardMilestoneBonus()` → `awardMilestoneBonus()`
- [ ] Ensure proper integration with `TodayFeedMomentumAwardService`
- [ ] Maintain bonus point calculations and thresholds
- [ ] Add proper error handling for bonus awards

##### **5. Create StreakAnalyticsService**
- [ ] Create file: `streak_services/streak_analytics_service.dart`
- [ ] Set up dependencies: persistence service
- [ ] Implement singleton pattern and initialization

##### **6. Extract Analytics Calculation Logic**
- [ ] Move `getStreakAnalytics()` → `calculateStreakAnalytics()`
- [ ] Move `_calculateStreakAnalytics()` → `_calculateAnalyticsFromEvents()`
- [ ] Move analytics helper methods (trends, insights, recommendations)
- [ ] Move performance metrics and reporting logic

##### **7. Update Main Service Integration**
- [ ] Add both services to dependency injection
- [ ] Update `updateStreakOnEngagement()` to use milestone service
- [ ] Update `getStreakAnalytics()` to use analytics service
- [ ] Coordinate between services in main service

##### **8. Create Unit Tests**
- [ ] Test milestone detection with various streak scenarios
- [ ] Test celebration creation and management
- [ ] Test momentum bonus integration
- [ ] Test analytics calculation accuracy
- [ ] Test insights and recommendations generation

#### **Success Criteria:**
- [ ] StreakMilestoneService created (~240 lines)
- [ ] StreakAnalyticsService created (~220 lines)  
- [ ] All milestone and analytics logic extracted successfully
- [ ] Main service properly coordinates between services
- [ ] All existing tests still passing
- [ ] Unit tests for both new services created

#### **Deliverables:**
- [ ] `streak_milestone_service.dart` (240 lines)
- [ ] `streak_analytics_service.dart` (220 lines)
- [ ] Updated main service coordination
- [ ] Unit tests for both services

**Sprint 3 Status:** ⚪ **PENDING SPRINT 2**

---

### **Sprint 4: Finalize Main Service & Integration Testing**
**Time Estimate:** 2-3 hours  
**Risk Level:** 🟡 MEDIUM  
**Status:** ⚪ Not Started

#### **Focus:** Complete main service refactoring and comprehensive testing
**Target:** Finalize `TodayFeedStreakTrackingService` (~320 lines)

#### **Tasks:**

##### **1. Finalize Main Service Structure**
- [ ] Remove all extracted methods from main service
- [ ] Implement clean dependency injection for all 4 services
- [ ] Add proper error handling for service failures
- [ ] Maintain connectivity monitoring coordination

##### **2. Validate Public API Preservation**
- [ ] Ensure `getCurrentStreak()` works exactly as before
- [ ] Ensure `updateStreakOnEngagement()` works exactly as before
- [ ] Ensure `getStreakAnalytics()` works exactly as before
- [ ] Ensure `markCelebrationAsShown()` works exactly as before
- [ ] Ensure `handleStreakBreak()` works exactly as before

##### **3. Test Service Coordination**
- [ ] Test coordination between persistence and calculation services
- [ ] Test coordination between calculation and milestone services
- [ ] Test coordination between milestone and analytics services
- [ ] Test error handling when individual services fail

##### **4. Validate Edge Cases**
- [ ] Test offline functionality still works correctly
- [ ] Test momentum integration still works correctly
- [ ] Test cache coordination across services
- [ ] Test error handling and recovery scenarios

##### **5. Integration Testing**
- [ ] Test complete user engagement flow end-to-end
- [ ] Test streak calculation with milestone detection
- [ ] Test analytics generation with various data scenarios
- [ ] Test celebration flow from creation to display

##### **6. Performance Testing**
- [ ] Verify service coordination doesn't add significant overhead
- [ ] Test memory usage with multiple service instances
- [ ] Validate cache performance across services
- [ ] Benchmark against original single-service performance

##### **7. Regression Testing**
- [ ] Run full existing test suite
- [ ] Test all UI components that integrate with streak tracking
- [ ] Test momentum integration with Epic 1.1
- [ ] Test engagement detection integration with Epic 2.1

#### **Success Criteria:**
- [ ] Main service finalized (~320 lines, down from 1,010)
- [ ] All public API methods working identically to before
- [ ] Clean service coordination implemented
- [ ] All existing integration tests passing
- [ ] Performance validated (no degradation)
- [ ] Full end-to-end testing complete

#### **Deliverables:**
- [ ] Finalized `today_feed_streak_tracking_service.dart` (320 lines)
- [ ] Complete integration test suite results
- [ ] Performance validation report

**Sprint 4 Status:** ⚪ **PENDING SPRINT 3**

---

### **Sprint 5: Documentation & Cleanup**
**Time Estimate:** 1-2 hours  
**Risk Level:** 🟢 LOW  
**Status:** ⚪ Not Started

#### **Focus:** Complete documentation and final cleanup
**Target:** Professional documentation and code cleanup

#### **Tasks:**

##### **1. Create Service Architecture Documentation**
- [ ] Document service responsibilities and boundaries
- [ ] Create service interaction diagrams
- [ ] Document dependency injection patterns
- [ ] Add service usage examples

##### **2. Update Code Documentation**
- [ ] Add comprehensive service documentation to each file
- [ ] Document public API methods with examples
- [ ] Add integration patterns documentation
- [ ] Document configuration options and constants

##### **3. Code Quality & Cleanup**
- [ ] Remove any commented-out code
- [ ] Ensure consistent formatting across all services
- [ ] Verify all imports are necessary and organized
- [ ] Run `dart format` and `flutter analyze` on all files

##### **4. Update Integration Documentation**
- [ ] Update Today Feed service README
- [ ] Document service architecture changes
- [ ] Add testing guidelines for new architecture
- [ ] Update developer setup guides

##### **5. Create Testing Documentation**
- [ ] Document how to test each service independently
- [ ] Create integration testing guide
- [ ] Document test coverage expectations
- [ ] Add troubleshooting guide

##### **6. Final Validation**
- [ ] Run complete test suite one final time
- [ ] Validate all services are under 500-line limit
- [ ] Confirm all functionality works end-to-end
- [ ] Verify documentation is complete and accurate

#### **Success Criteria:**
- [ ] All tests passing (final validation)
- [ ] Comprehensive documentation created
- [ ] Code properly formatted and analyzed
- [ ] Integration guides updated
- [ ] All services under 500-line limit confirmed

#### **Deliverables:**
- [ ] Service architecture documentation
- [ ] Updated README files and developer guides
- [ ] Clean, well-documented code
- [ ] Testing and integration guides

**Sprint 5 Status:** ⚪ **PENDING SPRINT 4**

---

## **Testing Strategy**

### **Continuous Testing Protocol**
- [ ] Run after each sprint: `flutter test`
- [ ] Run after each sprint: `flutter analyze` 
- [ ] Run after each sprint: `dart format --set-exit-if-changed .`

### **Service-Specific Testing Checklist**

#### **Persistence Service Tests**
- [ ] Database operations (store/retrieve streak data)
- [ ] Cache management (store/retrieve/clear cached streaks)
- [ ] Offline sync functionality (queue/sync pending updates)
- [ ] Error handling for database failures

#### **Calculation Service Tests**
- [ ] Streak calculation accuracy with various engagement patterns
- [ ] Edge cases (timezone changes, DST transitions, gaps)
- [ ] Performance with large datasets
- [ ] Consecutive day detection logic

#### **Milestone Service Tests**
- [ ] Milestone detection logic for all thresholds
- [ ] Celebration creation and management
- [ ] Momentum bonus integration and point awards
- [ ] Error handling for bonus award failures

#### **Analytics Service Tests**
- [ ] Analytics calculation accuracy
- [ ] Trend analysis and insights generation
- [ ] Performance insights and recommendations
- [ ] Edge cases with sparse or invalid data

#### **Integration Tests**
- [ ] End-to-end streak tracking flow (view → engagement → update → milestone)
- [ ] Service coordination under normal conditions
- [ ] Service coordination under error conditions
- [ ] Cross-service data consistency

### **Regression Testing Checklist**
- [ ] Complete streak tracking user journey
- [ ] Offline functionality (cache, sync, queue)
- [ ] Momentum integration with Epic 1.1
- [ ] Engagement detection integration with Epic 2.1
- [ ] UI component integration (widgets, forms, displays)

---

## **Success Metrics**

### **Quantitative Goals**
- [ ] **Service Compliance:** 5 services all ≤500 lines
  - [ ] Main service: ~320 lines (68% reduction from 1,010)
  - [ ] Persistence service: ~280 lines
  - [ ] Calculation service: ~290 lines
  - [ ] Milestone service: ~240 lines
  - [ ] Analytics service: ~220 lines
  - [ ] Total: ~1,350 lines (managed 34% growth for modularity)

- [ ] **Code Quality Metrics:**
  - [ ] Test coverage maintained >85%
  - [ ] Service cohesion improved (single responsibility)
  - [ ] Dependency coupling reduced
  - [ ] Performance maintained (no degradation)

- [ ] **Development Velocity Metrics:**
  - [ ] Easier service testing (isolated unit tests)
  - [ ] Clear service boundaries (no overlapping responsibilities)
  - [ ] Enhanced debugging capabilities (service-specific logs)

### **Qualitative Goals**
- [ ] **Developer Experience Improvements:**
  - [ ] Clear service responsibilities
  - [ ] Easy testing of streak features
  - [ ] Simple service integration patterns

- [ ] **Maintainability Improvements:**
  - [ ] Safe service modification
  - [ ] Simple feature addition process
  - [ ] Clean code organization

---

## **Risk Assessment & Mitigation**

### **High Priority Risks**

#### **Risk 1: Breaking Public API**
- **Probability:** Medium
- **Impact:** High
- **Mitigation Checklist:**
  - [ ] Preserve exact method signatures during extraction
  - [ ] Maintain identical return types and error handling
  - [ ] Run comprehensive integration tests after each sprint
  - [ ] Test all UI components that depend on the service

#### **Risk 2: Performance Degradation from Service Calls**
- **Probability:** Low
- **Impact:** Medium
- **Mitigation Checklist:**
  - [ ] Minimize service indirection overhead
  - [ ] Use direct method calls instead of event-based communication
  - [ ] Benchmark performance before and after refactoring
  - [ ] Monitor memory usage across service instances

### **Medium Priority Risks**

#### **Risk 3: Complex Dependency Chain Issues**
- **Probability:** Medium
- **Impact:** Medium
- **Mitigation Checklist:**
  - [ ] Use simple dependency injection pattern
  - [ ] Avoid circular dependencies between services
  - [ ] Create clear interface contracts
  - [ ] Test service initialization order

#### **Risk 4: Test Coverage Loss During Migration**
- **Probability:** Medium
- **Impact:** Medium
- **Mitigation Checklist:**
  - [ ] Take baseline test coverage measurements
  - [ ] Test each extracted service individually
  - [ ] Maintain integration tests throughout process
  - [ ] Add new unit tests for each service

---

## **Implementation Timeline**

| Sprint | Focus | Duration | Risk | Dependencies | Status |
|---------|-------|----------|------|--------------|--------|
| 0 | Analysis & Setup | 1-2h | 🟢 | None | ⚪ **READY** |
| 1 | Extract Persistence | 2-3h | 🟢 | Sprint 0 | ⚪ Planned |
| 2 | Extract Calculation | 2-3h | 🟡 | Sprint 1 | ⚪ Planned |
| 3 | Extract Milestone & Analytics | 3-4h | 🟡 | Sprint 2 | ⚪ Planned |
| 4 | Main Service & Integration | 2-3h | 🟡 | Sprint 3 | ⚪ Planned |
| 5 | Documentation & Cleanup | 1-2h | 🟢 | Sprint 4 | ⚪ Planned |

### **Timeline Summary**
- **Total Estimated Time:** 11-17 hours (2-3 days for 1 developer)
- **Target Success Rate:** 5/5 sprints completed successfully
- **Critical Path:** Sequential sprint dependencies

---

## **Project Status Tracking**

### **Overall Progress**
- [ ] **Sprint 0:** Analysis & Setup (1-2h)
- [ ] **Sprint 1:** Extract Persistence Service (2-3h)  
- [ ] **Sprint 2:** Extract Calculation Service (2-3h)
- [ ] **Sprint 3:** Extract Milestone & Analytics Services (3-4h)
- [ ] **Sprint 4:** Finalize Main Service & Integration Testing (2-3h)
- [ ] **Sprint 5:** Documentation & Cleanup (1-2h)

### **Quality Gates**
- [ ] All existing tests passing after each sprint
- [ ] Code analysis clean after each sprint
- [ ] Performance benchmarks maintained
- [ ] Documentation complete and accurate

### **Final Deliverables**
- [ ] 5 modular services (all ≤500 lines)
- [ ] Comprehensive test suite with maintained coverage
- [ ] Complete architecture documentation
- [ ] Migration guide and integration examples

---

**🎯 PROJECT STATUS: READY TO START**

**Current State:** All functionality working, refactoring needed for compliance  
**Next Action:** Begin Sprint 0 - Analysis & Setup  
**Success Definition:** 1,010-line service → 5 compliant services with zero breaking changes

*This refactoring plan transforms the monolithic streak tracking service into a clean, modular architecture while preserving all existing functionality and improving code quality, testability, and maintainability.* 