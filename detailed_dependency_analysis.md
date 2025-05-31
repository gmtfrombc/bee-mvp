# Detailed Dependency Analysis - Sprint 0

## Service-to-Service Dependencies

### Direct Import Dependencies
Based on `dependency_analysis.txt` findings:

```
push_notification_trigger_service.dart → notification_preferences_service.dart
notification_test_generator.dart → notification_service.dart
notification_test_generator.dart → notification_preferences_service.dart  
notification_test_generator.dart → notification_ab_testing_service.dart
notification_deep_link_service.dart → background_notification_handler.dart
notification_action_dispatcher.dart → background_notification_handler.dart
notification_action_dispatcher.dart → notification_deep_link_service.dart
notification_test_validator.dart → notification_test_generator.dart
coach_intervention_service.dart → notification_preferences_service.dart
fcm_token_service.dart → notification_service.dart
notification_testing_service.dart → notification_test_generator.dart
notification_testing_service.dart → notification_test_validator.dart
```

### Circular Dependencies Identified ⚠️

1. **Testing Services Triangle:**
   - `notification_testing_service.dart` → `notification_test_generator.dart`
   - `notification_test_generator.dart` → `notification_service.dart`
   - `notification_test_validator.dart` → `notification_test_generator.dart`

2. **Action/Deep Link Circle:**
   - `notification_action_dispatcher.dart` → `notification_deep_link_service.dart`
   - `notification_deep_link_service.dart` → `background_notification_handler.dart`
   - `notification_action_dispatcher.dart` → `background_notification_handler.dart`

### Service Dependency Hub: `notification_preferences_service.dart`
**Dependent Services:**
- `push_notification_trigger_service.dart`
- `notification_test_generator.dart`
- `coach_intervention_service.dart`
- UI widgets (`notification_settings_form.dart`, `notification_option_widgets.dart`)

This service acts as a central configuration hub - good candidate for early consolidation.

## UI Integration Points

### Direct UI Dependencies
```
features/momentum/presentation/screens/momentum_screen.dart 
  → notification_settings_screen.dart

features/momentum/presentation/screens/notification_settings_screen.dart
  → widgets/notification_settings_form.dart

features/momentum/presentation/widgets/notification_settings_form.dart
  → ../../../../core/services/notification_preferences_service.dart
  → notification_option_widgets.dart

features/momentum/presentation/widgets/notification_option_widgets.dart
  → ../../../../core/services/notification_preferences_service.dart
```

### Main.dart Integration Pattern
```dart
// Current initialization order in main.dart:
1. NotificationPreferencesService.instance.initialize()
2. NotificationService.instance.initialize()
3. NotificationActionDispatcher.instance initialization
4. FCMTokenService.instance token management
```

**Critical Integration Points:**
- Foreground message handling via `_handleForegroundMessage()`
- Notification tap handling via `_handleNotificationTap()`
- Token refresh handling via `_handleTokenRefresh()`
- App lifecycle management in `AppWrapper`

## Service Complexity Analysis

### High Complexity Services (>500 lines)
1. **`notification_test_validator.dart`** (590 lines)
   - Complex testing logic mixed with business validation
   - Multiple overlapping responsibilities
   - **Refactor Priority:** HIGH

2. **`notification_ab_testing_service.dart`** (516 lines)
   - A/B testing logic
   - Analytics collection
   - Variant management
   - **Refactor Priority:** MEDIUM

3. **`push_notification_trigger_service.dart`** (512 lines)
   - Trigger logic
   - Content generation overlap
   - Scheduling functionality
   - **Refactor Priority:** HIGH

### Medium Complexity Services (400-500 lines)
4. **`notification_test_generator.dart`** (505 lines)
5. **`notification_deep_link_service.dart`** (500 lines)
6. **`notification_service.dart`** (498 lines)
7. **`notification_content_service.dart`** (456 lines)
8. **`notification_action_dispatcher.dart`** (409 lines)
9. **`background_notification_handler.dart`** (400 lines)

### Lower Complexity Services (<400 lines)
10. **`notification_preferences_service.dart`** (320 lines)
11. **`notification_testing_service.dart`** (259 lines)

## Overlapping Responsibilities Identified

### Content Generation Overlap
- `notification_content_service.dart`: Pure content generation
- `push_notification_trigger_service.dart`: Contains content logic
- **Resolution:** Extract content logic from trigger service

### Testing Logic Scattered
- `notification_test_validator.dart`: Validation logic
- `notification_test_generator.dart`: Generation logic  
- `notification_testing_service.dart`: Coordination logic
- **Resolution:** Consolidate into unified testing framework

### Analytics/A/B Testing Overlap
- `notification_ab_testing_service.dart`: A/B testing
- Multiple services: Analytics collection scattered
- **Resolution:** Unified analytics service

### Action Handling Fragmentation
- `notification_action_dispatcher.dart`: Action routing
- `notification_deep_link_service.dart`: Navigation handling
- `background_notification_handler.dart`: Background actions
- **Resolution:** Clear action/navigation/background boundaries

## Public Interface Analysis

### Most Used Public Methods
Based on UI integration and service dependencies:

1. **NotificationPreferencesService:**
   - `initialize()`
   - Preference getters/setters
   - Used by 3+ services + UI

2. **NotificationService:**
   - `initialize(onMessageReceived, onMessageOpenedApp, onTokenRefresh)`
   - `isAvailable` getter
   - Token management methods

3. **NotificationActionDispatcher:**
   - `initialize(context, ref)`
   - `handleForegroundNotification()`
   - `handleNotificationTap()`
   - App lifecycle methods

### Breaking Change Risk Assessment
- **LOW RISK:** Testing services (isolated usage)
- **MEDIUM RISK:** Content/trigger services (some UI integration)
- **HIGH RISK:** Core service, preferences, action dispatcher (main.dart + UI)

## Consolidation Strategy Recommendations

### Phase 1: Low Risk (Testing Infrastructure)
- Consolidate testing services first
- Minimal breaking changes
- Establishes pattern

### Phase 2: Medium Risk (Content/Analytics)
- Merge content and trigger logic
- Unify A/B testing and analytics
- Some service interface changes

### Phase 3: High Risk (Core Infrastructure)
- Consolidate core FCM service
- Merge action handling services
- Update main.dart integration

### Phase 4: Integration & Cleanup
- Update all import references
- Remove legacy files
- Final testing and documentation

## Migration Path Identified
1. **Models First:** Create unified domain models (safe)
2. **Testing Framework:** Extract testing logic (isolated)
3. **Service by Service:** Consolidate one service at a time
4. **Interface Preservation:** Maintain public APIs during migration
5. **Import Updates:** Bulk update imports at the end
6. **Legacy Cleanup:** Remove old files only after verification 