# Notification System Refactoring - Documentation Hub

## **Quick Start for New Assistant**
👉 **Start with:** `sprint_0_setup.md` for immediate tasks

## **Project Context**
- **App:** BEE MVP - Medical/HIPAA app for behavioral engagement
- **Flutter Version:** 3.32.0  
- **Current Issue:** 11 notification services (5,668 lines) with unclear boundaries
- **Goal:** Consolidate to 7 services (~2,250 lines) with domain-driven architecture

## **Reference Documents**

### **Architecture References**
- `../../../0_Core_docs/bee_mvp_architecture.md` - Overall app architecture
- `../../../architecture/architectural_recommendations.md` - Why this refactor is needed
- `../offline_cache_service_refactor_plan.md` - Proven refactor methodology
- `../component_size_audit_refactor_plan.md` - Recent successful refactor

### **Current State Analysis**
```
Current Services (app/lib/core/services/):
├── notification_test_validator.dart (590 lines) ← Testing logic in business service
├── notification_ab_testing_service.dart (516 lines) ← A/B testing separate
├── push_notification_trigger_service.dart (512 lines) ← Trigger logic mixed
├── notification_test_generator.dart (505 lines) ← More testing logic
├── notification_deep_link_service.dart (500 lines) ← Navigation scattered  
├── notification_service.dart (498 lines) ← Core FCM + permissions
├── notification_content_service.dart (456 lines) ← Content generation
├── notification_action_dispatcher.dart (409 lines) ← Action handling
├── background_notification_handler.dart (400 lines) ← Background processing
├── notification_preferences_service.dart (320 lines) ← User settings
└── notification_testing_service.dart (259 lines) ← Test coordinator
```

## **Sprint Progress Tracking**

### **Sprint 0: Analysis & Setup** ⏳
- [ ] Dependency analysis completed
- [ ] Test baseline documented  
- [ ] Architecture structure created
- [ ] Git branch and backups ready

### **Future Sprints**
- **Sprint 1:** Unified Domain Models
- **Sprint 2:** Testing Infrastructure 
- **Sprint 3:** Core FCM Service
- **Sprint 4:** Content & Trigger Services
- **Sprint 5:** Analytics & A/B Testing
- **Sprint 6:** Infrastructure Layer
- **Sprint 7:** Final Integration
- **Sprint 8:** Cleanup & Documentation

## **Key Integration Points**
```dart
// main.dart - Service initialization
await NotificationService.instance.initialize();
await NotificationPreferencesService.instance.initialize();

// UI Components using services
app/lib/features/momentum/presentation/widgets/notification_*

// Providers depending on services  
app/lib/features/momentum/presentation/providers/
```

## **Flutter 3.32.0 Best Practices**
- Use `flutter_riverpod` for state management
- Follow current `firebase_messaging` patterns
- Implement proper `permission_handler` usage
- Use modern async/await throughout
- Follow domain-driven architecture principles

## **Testing Requirements**
- Maintain >85% test coverage
- Run full test suite after each sprint
- Integration tests for notification flows
- Device compatibility testing (iOS/Android)

## **Safety Measures**
- Git branch for each sprint
- Backup before major changes
- Incremental refactoring approach
- Comprehensive testing after each change
- Clear rollback procedures

---

**For questions or issues:** Reference the architectural recommendations document and previous successful refactor patterns. 