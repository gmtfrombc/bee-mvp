# Component Size Audit Report
**Date:** $(date)  
**Total Files Analyzed:** 59  
**Total Lines of Code:** 26,948  

## Size Guidelines
- **Services:** ≤500 lines
- **UI Components:** ≤300 lines  
- **Screen Components:** ≤400 lines (special consideration)
- **Modal Components:** ≤250 lines
- **Models:** Flexible (complex data structures acceptable)

## Critical Violations Summary

### 🚨 **CRITICAL VIOLATIONS** (>100% over limit)
| Component | Lines | Type | Violation % | Priority |
|-----------|-------|------|-------------|----------|
| `TodayFeedTile` | 1,261 | Widget | 421% | CRITICAL |
| `CoachDashboardScreen` | 946 | Screen | 315% | CRITICAL |
| `TodayFeedCacheStatisticsService` | 981 | Service | 196% | HIGH |
| `NotificationTestingService` | 685 | Service | 137% | HIGH |

### ⚠️ **HIGH VIOLATIONS** (50-100% over limit)
| Component | Lines | Type | Violation % | Priority |
|-----------|-------|------|-------------|----------|
| `SkeletonWidgets` | 770 | Widget | 257% | HIGH |
| `TodayFeedCacheService` | 693 | Service | 139% | HIGH |
| `RichContentRenderer` | 686 | Widget | 229% | HIGH |
| `TodayFeedCacheSyncService` | 677 | Service | 135% | HIGH |
| `MomentumDetailModal` | 650 | Modal | 260% | HIGH |
| `TodayFeedCacheHealthService` | 609 | Service | 122% | HIGH |
| `NotificationSettingsScreen` | 604 | Screen | 151% | HIGH |
| `MomentumApiService` | 575 | Service | 115% | HIGH |
| `CoachInterventionService` | 570 | Service | 114% | HIGH |
| `MomentumGauge` | 530 | Widget | 177% | HIGH |
| `NotificationAbTestingService` | 516 | Service | 103% | HIGH |
| `PushNotificationTriggerService` | 512 | Service | 102% | HIGH |

### 📋 **MODERATE VIOLATIONS** (0-50% over limit)
| Component | Lines | Type | Violation % | Priority |
|-----------|-------|------|-------------|----------|
| `NotificationDeepLinkService` | 500 | Service | 100% | MEDIUM |
| `NotificationService` | 498 | Service | 100% | MEDIUM |
| `ProfileSettingsScreen` | 467 | Screen | 117% | MEDIUM |
| `WeeklyTrendChart` | 458 | Widget | 153% | MEDIUM |
| `NotificationContentService` | 456 | Service | 91% | MEDIUM |
| `TodayFeedTimezoneService` | 453 | Service | 91% | MEDIUM |
| `LoadingIndicator` | 448 | Widget | 149% | MEDIUM |
| `TodayFeedContentService` | 448 | Service | 90% | MEDIUM |
| `OfflineCacheService` | 443 | Service | 89% | MEDIUM |
| `TodayFeedCachePerformanceService` | 413 | Service | 83% | MEDIUM |
| `ErrorWidgets` | 412 | Widget | 137% | MEDIUM |
| `NotificationActionDispatcher` | 409 | Service | 82% | MEDIUM |
| `QuickStatsCards` | 367 | Widget | 122% | MEDIUM |
| `MomentumCard` | 353 | Widget | 118% | MEDIUM |
| `AppTheme` | 348 | Config | N/A | LOW |
| `MomentumScreen` | 339 | Screen | 85% | LOW |
| `RiverpodQuickStatsCards` | 334 | Widget | 111% | MEDIUM |
| `TodayFeedDataService` | 332 | Service | 66% | LOW |
| `NotificationPreferencesService` | 320 | Service | 64% | LOW |

## Component Type Analysis

### Services (Target: ≤500 lines)
**Total Services:** 29  
**Violations:** 16 (55% violation rate)  
**Average Size:** 456 lines  

#### Major Service Violations:
- `TodayFeedCacheStatisticsService`: 981 lines (needs major refactoring)
- `NotificationTestingService`: 685 lines (testing framework extraction)
- `TodayFeedCacheService`: 693 lines (already identified for refactoring)

### UI Widgets (Target: ≤300 lines)
**Total Widgets:** 15  
**Violations:** 12 (80% violation rate)  
**Average Size:** 476 lines  

#### Major Widget Violations:
- `TodayFeedTile`: 1,261 lines (animation/interaction extraction needed)
- `SkeletonWidgets`: 770 lines (split into individual skeleton components)
- `RichContentRenderer`: 686 lines (content type handlers)

### Screen Components (Target: ≤400 lines)
**Total Screens:** 4  
**Violations:** 3 (75% violation rate)  
**Average Size:** 589 lines  

#### Screen Violations:
- `CoachDashboardScreen`: 946 lines (tab extraction needed)
- `NotificationSettingsScreen`: 604 lines (settings form extraction)
- `ProfileSettingsScreen`: 467 lines (minor violation)

### Modal Components (Target: ≤250 lines)
**Total Modals:** 1  
**Violations:** 1 (100% violation rate)  

#### Modal Violations:
- `MomentumDetailModal`: 650 lines (content/actions extraction)

### Models (No strict limit)
**Total Models:** 2  
**Violations:** 0 (flexible guidelines)  

#### Large Models (acceptable):
- `TodayFeedContent`: 814 lines (complex data structure)
- `MomentumData`: 188 lines (within reasonable bounds)

## Refactoring Priority Matrix

### **Sprint 1 Targets** (Immediate - Critical Impact)
1. **TodayFeedTile** (1,261 lines → ~300 lines)
   - Extract animations (~200 lines)
   - Extract interactions (~150 lines)
   - Extract state management (~100 lines)

2. **CoachDashboardScreen** (946 lines → ~400 lines)
   - Extract tab components (~600 lines)
   - Extract filter widgets (~150 lines)

### **Sprint 2 Targets** (High Impact)
3. **TodayFeedCacheStatisticsService** (981 lines → ~500 lines)
   - Extract metrics collection (~200 lines)
   - Extract health analysis (~150 lines)
   - Extract reporting (~130 lines)

4. **NotificationTestingService** (685 lines → ~400 lines)
   - Extract test framework (~200 lines)
   - Extract test scenarios (~150 lines)

### **Sprint 3-4 Targets** (Medium Impact)
5. **SkeletonWidgets** (770 lines → multiple files)
6. **RichContentRenderer** (686 lines → content handlers)
7. **Service size normalization** (bring all services under 500 lines)

## Implementation Recommendations

### **Immediate Actions**
1. Create refactor branch: `refactor/component-size-audit`
2. Establish automated size checking in CI/CD
3. Begin TodayFeedTile extraction (highest impact)

### **Architecture Patterns to Follow**
- Use proven incremental extraction from OfflineCacheService refactor
- Maintain 100% backward compatibility
- Comprehensive testing after each extraction
- Clear documentation for extracted components

### **Size Monitoring**
```bash
# Add to pre-commit hooks
find app/lib -name "*.dart" -exec wc -l {} + | awk '$1 > 500 && $2 ~ /service/ {print "ERROR: Service " $2 " exceeds 500 lines (" $1 " lines)"}'
find app/lib -name "*.dart" -exec wc -l {} + | awk '$1 > 300 && $2 ~ /widget|presentation/ && $2 !~ /screen/ {print "ERROR: Widget " $2 " exceeds 300 lines (" $1 " lines)"}'
```

## Success Metrics Target

### **End State Goals**
- **Services:** 0 files >500 lines (currently 16 violations)
- **Widgets:** 0 files >300 lines (currently 12 violations)  
- **Screens:** ≤1 file >400 lines (currently 3 violations)
- **Overall Compliance:** >90% (currently ~40%)

### **Quality Maintenance**
- All extractions maintain test coverage >85%
- No performance regressions
- Clear documentation for all extracted components
- Automated governance prevents regression

---
**Next Action:** Begin Sprint 0 workspace setup and testing baseline 