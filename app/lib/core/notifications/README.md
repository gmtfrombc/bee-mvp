# Notification System Architecture

## Migration Status
- [x] Domain Models ✅ **COMPLETE** - Sprint 1 (Unified models created)
- [ ] Testing Infrastructure  
- [ ] Core Service
- [ ] Content & Trigger Services
- [ ] Analytics Service
- [ ] Infrastructure Layer

## Current Architecture (Sprint 1 - Domain Models Complete)

### ✅ Completed in Sprint 1
- **Domain Models Created:** Unified notification data models at `app/lib/core/notifications/domain/models/`
  - `notification_models.dart` (420 lines) - All data classes consolidated
  - `notification_types.dart` (150 lines) - All enums and constants unified
- **Core Services Updated:** 4 core services successfully migrated to use unified models
  - `notification_content_service.dart` ✅ - Updated & tested
  - `background_notification_handler.dart` ✅ - Import fixed
  - `notification_preferences_service.dart` ✅ - Using unified types
  - `notification_action_dispatcher.dart` ✅ - Import updated
- **UI Components Updated:** Notification UI widgets now use unified enums
  - `notification_option_widgets.dart` ✅ - Uses unified `NotificationFrequency`
  - `notification_settings_form.dart` ✅ - Form uses unified types
  - `push_notification_trigger_service.dart` ✅ - Uses `NotificationType`
- **All Tests Passing:** ✅ 405 tests with 0 failures
- **Static Analysis Clean:** ✅ No issues found

### Services Being Consolidated (Remaining)
- `notification_test_validator.dart` (590 lines) - Testing logic mixed with business logic
- `notification_ab_testing_service.dart` (516 lines) - Overlaps with analytics
- `push_notification_trigger_service.dart` (512 lines) - ✅ **Updated to use unified models**
- `notification_test_generator.dart` (505 lines) - Massive testing service  
- `notification_deep_link_service.dart` (500 lines) - Navigation logic scattered
- `notification_service.dart` (498 lines) - Core FCM + permissions mixed
- `notification_content_service.dart` (456 lines) - ✅ **Updated & tested**
- `notification_action_dispatcher.dart` (409 lines) - ✅ **Updated to use unified models**
- `background_notification_handler.dart` (400 lines) - ✅ **Updated to use unified models**
- `notification_preferences_service.dart` (320 lines) - ✅ **Using unified types**
- `notification_testing_service.dart` (259 lines) - Coordinator for test services

**Remaining: 7 services to consolidate in future sprints**

### Target Architecture
```
app/lib/core/notifications/
├── domain/
│   ├── models/
│   │   ├── notification_models.dart (Unified data models)
│   │   └── notification_types.dart (Enums and constants)
│   └── services/
│       ├── notification_core_service.dart (FCM & permissions ~400 lines)
│       ├── notification_content_service.dart (Content generation ~300 lines)
│       ├── notification_trigger_service.dart (Timing & triggers ~350 lines)
│       ├── notification_preferences_service.dart (User settings ~250 lines)
│       └── notification_analytics_service.dart (Metrics & A/B testing ~300 lines)
├── infrastructure/
│   ├── notification_dispatcher.dart (Action handling ~200 lines)
│   └── notification_deep_link_service.dart (Navigation ~250 lines)
└── testing/
    ├── notification_test_framework.dart (Testing infrastructure ~400 lines)
    └── notification_integration_tests.dart (E2E test scenarios ~300 lines)
```

**Target: 7 services, ~2,250 lines (60% reduction)**

## Integration Points Identified

### Main.dart Dependencies
- `NotificationService.instance.initialize()`
- `NotificationActionDispatcher.instance`
- `NotificationPreferencesService.instance.initialize()`
- FCM token management via `FCMTokenService.instance`

### UI Integration Points
- `notification_settings_screen.dart`
- `notification_settings_form.dart`
- `notification_option_widgets.dart`

### Service Dependencies
- Core services depend on `NotificationPreferencesService`
- Test services have circular dependencies
- Background handler integrates with deep link service
- Action dispatcher coordinates with multiple services

## Test Coverage
- **Current Test Files:**
  - `background_notification_handler_test.dart` (369 lines)
  - `notification_content_service_test.dart` (360 lines)
  - `push_notification_trigger_service_test.dart` (372 lines)
- **All Tests Passing:** ✅ 405 tests
- **No Analysis Issues:** ✅ Flutter analyze clean

## Sprint Progress
- [x] Sprint 0: Analysis & Setup Complete
- [x] Sprint 1: Unified Domain Models ✅ **COMPLETE** (420+150 lines created, 4 services migrated, 405 tests passing)
- [ ] Sprint 2: Testing Infrastructure (Target: Consolidate test services into unified framework)
- [ ] Sprint 3: Core FCM Service (Target: Clean core notification service)
- [ ] Sprint 4: Content & Trigger Services (Target: Merge content generation logic)
- [ ] Sprint 5: Analytics & A/B Testing (Target: Unified analytics service)
- [ ] Sprint 6: Infrastructure Layer (Target: Dispatcher and deep link services)
- [ ] Sprint 7: Final Integration (Target: Remove old services, update main.dart)
- [ ] Sprint 8: Cleanup & Documentation (Target: Final tests, docs, performance validation) 