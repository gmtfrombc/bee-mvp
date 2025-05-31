# Sprint 0: Notification System Refactoring - Analysis & Setup

## **Objective**
Analyze current notification system architecture and prepare for consolidation of 11 services (5,668 lines) into clean domain-driven architecture.

## **Context**
- **Flutter Version:** 3.32.0
- **Current State:** 11 notification services with overlapping responsibilities
- **Goal:** Reduce to 7 services (~2,250 lines) with clear boundaries
- **Reference:** Following proven OfflineCacheService refactor methodology

## **Current Service Inventory**
```
app/lib/core/services/
├── notification_test_validator.dart (590 lines)
├── notification_ab_testing_service.dart (516 lines) 
├── push_notification_trigger_service.dart (512 lines)
├── notification_test_generator.dart (505 lines)
├── notification_deep_link_service.dart (500 lines)
├── notification_service.dart (498 lines)
├── notification_content_service.dart (456 lines)
├── notification_action_dispatcher.dart (409 lines)
├── background_notification_handler.dart (400 lines)
├── notification_preferences_service.dart (320 lines)
└── notification_testing_service.dart (259 lines)
```

## **Target Architecture**
```
app/lib/core/notifications/
├── domain/
│   ├── models/
│   │   ├── notification_models.dart
│   │   └── notification_types.dart
│   └── services/
│       ├── notification_core_service.dart (~400 lines)
│       ├── notification_content_service.dart (~300 lines)
│       ├── notification_trigger_service.dart (~350 lines)
│       ├── notification_preferences_service.dart (~250 lines)
│       └── notification_analytics_service.dart (~300 lines)
├── infrastructure/
│   ├── notification_dispatcher.dart (~200 lines)
│   └── notification_deep_link_service.dart (~250 lines)
└── testing/
    ├── notification_test_framework.dart (~400 lines)
    └── notification_integration_tests.dart (~300 lines)
```

## **Sprint 0 Tasks**

### **Task 1: Dependency Analysis (45 minutes)**
1. **Map Service Dependencies**
   ```bash
   # Run this to understand current imports
   grep -r "import.*notification" app/lib --include="*.dart" > dependency_analysis.txt
   ```

2. **Document Public Interfaces**
   - Identify methods used by UI components
   - Map provider dependencies 
   - Note main.dart integration points

3. **Find Circular Dependencies**
   - Check service-to-service imports
   - Document problematic coupling
   - Note shared model definitions

### **Task 2: Test Baseline (30 minutes)**
1. **Run Current Tests**
   ```bash
   flutter test
   flutter analyze
   ```

2. **Document Test Files**
   - List all notification-related test files
   - Note test patterns and coverage
   - Identify integration test dependencies

### **Task 3: Create Architecture Structure (15 minutes)**
1. **Create New Directories**
   ```bash
   mkdir -p app/lib/core/notifications/domain/models
   mkdir -p app/lib/core/notifications/domain/services  
   mkdir -p app/lib/core/notifications/infrastructure
   mkdir -p app/lib/core/notifications/testing
   ```

2. **Create README Template**
   ```markdown
   # Notification System Architecture
   
   ## Migration Status
   - [ ] Domain Models
   - [ ] Testing Infrastructure  
   - [ ] Core Service
   - [ ] Content & Trigger Services
   - [ ] Analytics Service
   - [ ] Infrastructure Layer
   ```

### **Task 4: Git Safety Setup (15 minutes)**
1. **Create Branch**
   ```bash
   git checkout -b refactor/notification-system-sprint-0
   git add .
   git commit -m "Sprint 0: Initial notification system analysis"
   ```

2. **Backup Current Services**
   ```bash
   cp -r app/lib/core/services app/lib/core/services.backup
   ```

## **Deliverables**
- [ ] `dependency_analysis.txt` - Service dependency map
- [ ] `test_baseline_report.md` - Current test status
- [ ] New directory structure created
- [ ] Git branch with baseline commit
- [ ] Backup of current services

## **Success Criteria**
- All tests passing (baseline established)
- Clear understanding of service dependencies
- New architecture structure ready
- Safe rollback procedures in place

## **Time Estimate:** 1.5-2 hours

## **Next Sprint Preview**
Sprint 1 will create unified domain models by extracting and consolidating scattered model definitions across the 11 services.

---

## **Key Files for Assistant Reference**
- `app/lib/main.dart` - Notification service initialization
- `app/lib/core/services/notification_*.dart` - All current services  
- `app/lib/features/momentum/presentation/widgets/notification_*.dart` - UI integration
- `test/` directory - Current test coverage

## **Flutter 3.32.0 Considerations**
- Use latest Riverpod patterns for state management
- Follow current Firebase messaging best practices
- Ensure compatibility with latest permission_handler
- Use modern async/await patterns throughout 