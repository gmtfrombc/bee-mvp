# Directory Structure - Notification System Refactor

## **Current Structure (Before Refactor)**
```
BEE-MVP/
├── app/
│   ├── lib/
│   │   ├── main.dart ← Notification service initialization
│   │   ├── core/
│   │   │   └── services/
│   │   │       ├── notification_test_validator.dart (590 lines)
│   │   │       ├── notification_ab_testing_service.dart (516 lines)
│   │   │       ├── push_notification_trigger_service.dart (512 lines)
│   │   │       ├── notification_test_generator.dart (505 lines)
│   │   │       ├── notification_deep_link_service.dart (500 lines)
│   │   │       ├── notification_service.dart (498 lines)
│   │   │       ├── notification_content_service.dart (456 lines)
│   │   │       ├── notification_action_dispatcher.dart (409 lines)
│   │   │       ├── background_notification_handler.dart (400 lines)
│   │   │       ├── notification_preferences_service.dart (320 lines)
│   │   │       └── notification_testing_service.dart (259 lines)
│   │   └── features/
│   │       └── momentum/
│   │           └── presentation/
│   │               └── widgets/
│   │                   ├── notification_settings_form.dart
│   │                   └── notification_option_widgets.dart
│   └── docs/
│       └── refactor/
│           └── notification_system_refactor/
│               ├── README.md ← Navigation hub
│               ├── sprint_0_setup.md ← Current sprint
│               └── directory_structure.md ← This file
└── test/
    └── [notification test files]
```

## **Target Structure (After Refactor)**
```
BEE-MVP/
├── app/
│   ├── lib/
│   │   ├── main.dart ← Updated initialization
│   │   ├── core/
│   │   │   ├── services/
│   │   │   │   └── [other non-notification services]
│   │   │   └── notifications/ ← NEW CONSOLIDATED STRUCTURE
│   │   │       ├── domain/
│   │   │       │   ├── models/
│   │   │       │   │   ├── notification_models.dart (~200 lines)
│   │   │       │   │   └── notification_types.dart (~100 lines)
│   │   │       │   └── services/
│   │   │       │       ├── notification_core_service.dart (~400 lines)
│   │   │       │       ├── notification_content_service.dart (~300 lines)
│   │   │       │       ├── notification_trigger_service.dart (~350 lines)
│   │   │       │       ├── notification_preferences_service.dart (~250 lines)
│   │   │       │       └── notification_analytics_service.dart (~300 lines)
│   │   │       ├── infrastructure/
│   │   │       │   ├── notification_dispatcher.dart (~200 lines)
│   │   │       │   └── notification_deep_link_service.dart (~250 lines)
│   │   │       └── testing/
│   │   │           ├── notification_test_framework.dart (~400 lines)
│   │   │           └── notification_integration_tests.dart (~300 lines)
│   │   └── features/
│   │       └── momentum/
│   │           └── presentation/
│   │               └── widgets/
│   │                   ├── notification_settings_form.dart ← Updated imports
│   │                   └── notification_option_widgets.dart ← Updated imports
│   └── docs/
│       └── refactor/
│           └── notification_system_refactor/
│               ├── README.md
│               ├── sprint_0_setup.md
│               ├── directory_structure.md
│               ├── dependency_analysis.txt ← Generated in Sprint 0
│               └── test_baseline_report.md ← Generated in Sprint 0
└── test/
    └── [updated notification test files]
```

## **Directory Creation Commands (Sprint 0)**
```bash
# Run these commands in BEE-MVP/ root directory
mkdir -p app/lib/core/notifications/domain/models
mkdir -p app/lib/core/notifications/domain/services
mkdir -p app/lib/core/notifications/infrastructure
mkdir -p app/lib/core/notifications/testing
mkdir -p app/docs/refactor/notification_system_refactor
```

## **Key Directory Purposes**

### **Domain Layer** (`app/lib/core/notifications/domain/`)
- **models/**: Pure data models and types (no business logic)
- **services/**: Core business logic services with clear responsibilities

### **Infrastructure Layer** (`app/lib/core/notifications/infrastructure/`)
- Action dispatching and UI integration
- Deep linking and navigation
- External system integration

### **Testing Layer** (`app/lib/core/notifications/testing/`)
- Centralized testing framework
- Integration test scenarios
- Testing utilities and helpers

## **File Naming Conventions**
- Use `snake_case` for all Dart files
- Prefix with `notification_` for clarity
- Descriptive names indicating single responsibility
- Follow Flutter/Dart style guide

## **Import Path Examples (After Refactor)**
```dart
// Domain models
import 'package:app/core/notifications/domain/models/notification_models.dart';
import 'package:app/core/notifications/domain/models/notification_types.dart';

// Domain services
import 'package:app/core/notifications/domain/services/notification_core_service.dart';
import 'package:app/core/notifications/domain/services/notification_content_service.dart';

// Infrastructure
import 'package:app/core/notifications/infrastructure/notification_dispatcher.dart';

// Testing
import 'package:app/core/notifications/testing/notification_test_framework.dart';
```

## **Migration Safety**
- Original files will be backed up to `app/lib/core/services.backup/`
- Git branches for each sprint allow easy rollback
- Incremental migration ensures no functionality loss 