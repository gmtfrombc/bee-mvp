# Sprint 2 Execution Guide: Service Consolidation (AI Assistant)

## Objective: Consolidate 50+ services → 15-20 services (60% reduction)

### Pre-Execution Setup

**1. Create consolidation branch:**
```bash
git checkout main
git pull origin main
git checkout -b sprint-2-service-consolidation
git push -u origin sprint-2-service-consolidation
```

**2. Baseline measurements:**
```bash
echo "=== BASELINE SERVICE METRICS ===" > sprint2_metrics.txt
echo "Service files: $(find lib -name "*service*.dart" | wc -l)" >> sprint2_metrics.txt
echo "Total services: $(grep -r "class.*Service" lib --include="*.dart" | wc -l)" >> sprint2_metrics.txt
echo "Core services: $(find lib/core/services -name "*.dart" | wc -l)" >> sprint2_metrics.txt
echo "Notification services: $(find lib -name "*notification*service*.dart" | wc -l)" >> sprint2_metrics.txt
echo "Cache services: $(find lib -name "*cache*service*.dart" | wc -l)" >> sprint2_metrics.txt

# Document current service dependencies
find lib -name "*service*.dart" -exec basename {} \; | sort > current_services.txt
```

**3. Backup critical files:**
```bash
mkdir -p backup/core/services
mkdir -p backup/core/notifications
mkdir -p backup/features/today_feed/data/services

# Backup notification services
cp -r lib/core/services/*notification* backup/core/services/ 2>/dev/null || true
cp -r lib/core/notifications/ backup/core/notifications/ 2>/dev/null || true

# Backup cache services  
cp -r lib/core/services/cache/ backup/core/services/ 2>/dev/null || true

# Backup today feed services
cp -r lib/features/today_feed/data/services/ backup/features/today_feed/data/ 2>/dev/null || true
```

---

## Phase 1: Notification Domain Consolidation (Day 1-3)

### Current Notification Services (12 → 3):

**Files to Consolidate:**
```bash
lib/core/services/notification_service.dart
lib/core/services/notification_content_service.dart
lib/core/services/notification_testing_service.dart
lib/core/services/notification_ab_testing_service.dart
lib/core/services/notification_deep_link_service.dart
lib/core/services/push_notification_trigger_service.dart
lib/core/services/background_notification_handler.dart
lib/core/services/fcm_token_service.dart
lib/core/notifications/domain/services/notification_core_service.dart
lib/core/notifications/domain/services/notification_content_service.dart (duplicate)
lib/core/notifications/domain/services/notification_analytics_service.dart
lib/core/notifications/domain/services/notification_trigger_service.dart
lib/core/notifications/domain/services/notification_preferences_service.dart
```

### Step 1A: Create NotificationManager (Day 1)

**1. Create new directory structure:**
```bash
mkdir -p lib/core/notifications/services
```

**2. Create `lib/core/notifications/services/notification_manager.dart`:**

**AI Instructions:** Merge these services into `NotificationManager`:
- `notification_service.dart` (main coordinator logic)
- `notification_core_service.dart` (core functionality)
- `push_notification_trigger_service.dart` (trigger logic)
- `fcm_token_service.dart` (token management)
- `background_notification_handler.dart` (background handling)

**Template Structure:**
```dart
/// Central notification coordinator service
/// 
/// Consolidates: NotificationService, NotificationCoreService, 
/// PushNotificationTriggerService, FCMTokenService, BackgroundNotificationHandler
class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  // === FCM TOKEN MANAGEMENT (from fcm_token_service.dart) ===
  
  // === CORE NOTIFICATION LOGIC (from notification_core_service.dart) ===
  
  // === TRIGGER MANAGEMENT (from push_notification_trigger_service.dart) ===
  
  // === BACKGROUND HANDLING (from background_notification_handler.dart) ===
  
  // === MAIN COORDINATION (from notification_service.dart) ===
}
```

**3. Merge Implementation Steps:**

```bash
# Step 1: Copy core class structure from notification_core_service.dart
# Step 2: Add FCM token methods from fcm_token_service.dart  
# Step 3: Add trigger logic from push_notification_trigger_service.dart
# Step 4: Add background handling from background_notification_handler.dart
# Step 5: Add main coordination from notification_service.dart
# Step 6: Resolve any duplicate methods (keep most recent implementation)
```

**4. Update imports in NotificationManager:**
```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Add any other imports from the consolidated services
```

### Step 1B: Create NotificationPreferences (Day 2)

**1. Create `lib/core/notifications/services/notification_preferences.dart`:**

**AI Instructions:** Merge these services:
- `notification_preferences_service.dart` (user settings)
- `notification_deep_link_service.dart` (deep linking)
- `notification_ab_testing_service.dart` (A/B testing config)

**Template Structure:**
```dart
/// User notification preferences and configuration service
/// 
/// Consolidates: NotificationPreferencesService, NotificationDeepLinkService,
/// NotificationABTestingService
class NotificationPreferences {
  static final NotificationPreferences _instance = NotificationPreferences._internal();
  factory NotificationPreferences() => _instance;
  NotificationPreferences._internal();

  // === USER PREFERENCES (from notification_preferences_service.dart) ===
  
  // === DEEP LINK HANDLING (from notification_deep_link_service.dart) ===
  
  // === A/B TESTING CONFIG (from notification_ab_testing_service.dart) ===
}
```

### Step 1C: Create NotificationAnalytics (Day 3)

**1. Create `lib/core/notifications/services/notification_analytics.dart`:**

**AI Instructions:** Merge these services:
- `notification_analytics_service.dart` (tracking & analytics)
- `notification_testing_service.dart` (testing utilities)
- `notification_content_service.dart` (content generation - merge analytics parts only)

**Template Structure:**
```dart
/// Notification analytics and testing service
/// 
/// Consolidates: NotificationAnalyticsService, NotificationTestingService,
/// content analytics from NotificationContentService
class NotificationAnalytics {
  static final NotificationAnalytics _instance = NotificationAnalytics._internal();
  factory NotificationAnalytics() => _instance;
  NotificationAnalytics._internal();

  // === ANALYTICS TRACKING (from notification_analytics_service.dart) ===
  
  // === TESTING UTILITIES (from notification_testing_service.dart) ===
  
  // === CONTENT ANALYTICS (from notification_content_service.dart) ===
}
```

### Step 1D: Update All Import References

**AI Instructions:** Use global find/replace to update imports:

```bash
# Find all files that import old notification services:
grep -r "import.*notification.*service" lib --include="*.dart" > notification_imports.txt

# For each file found, replace imports:
# OLD: import '../../services/notification_service.dart';
# NEW: import '../../notifications/services/notification_manager.dart';

# OLD: import '../../services/fcm_token_service.dart';  
# NEW: import '../../notifications/services/notification_manager.dart';

# OLD: import '../domain/services/notification_preferences_service.dart';
# NEW: import '../services/notification_preferences.dart';

# etc.
```

**Validation After Phase 1:**
```bash
# Check compilation
flutter analyze

# Test notification functionality  
flutter test test/core/notifications/ --reporter=compact
flutter test test/core/services/*notification* --reporter=compact

# Update metrics
echo "=== AFTER NOTIFICATION CONSOLIDATION ===" >> sprint2_metrics.txt
echo "Notification services: $(find lib -name "*notification*service*.dart" | wc -l)" >> sprint2_metrics.txt
echo "Expected: 3 files" >> sprint2_metrics.txt
```

---

## Phase 2: Cache Domain Consolidation (Day 4-6)

### Current Cache Services (15 → 3):

**Files to Consolidate:**
```bash
lib/core/services/offline_cache_service.dart
lib/core/services/today_feed_cache_service.dart
lib/core/services/cache/today_feed_cache_warming_service.dart
lib/core/services/cache/today_feed_cache_performance_service.dart
lib/core/services/cache/today_feed_cache_maintenance_service.dart
lib/core/services/cache/today_feed_cache_health_service.dart
lib/core/services/cache/today_feed_cache_sync_service.dart
lib/core/services/cache/today_feed_cache_statistics_service.dart
lib/core/services/cache/offline/offline_cache_maintenance_service.dart
lib/core/services/cache/offline/offline_cache_error_service.dart
lib/core/services/cache/offline/offline_cache_validation_service.dart
lib/core/services/cache/offline/offline_cache_stats_service.dart
lib/core/services/cache/offline/offline_cache_content_service.dart
lib/core/services/cache/offline/offline_cache_sync_service.dart
lib/core/services/cache/offline/offline_cache_action_service.dart
```

### Step 2A: Create CacheManager (Day 4)

**1. Create new directory:**
```bash
mkdir -p lib/core/cache/services
```

**2. Create `lib/core/cache/services/cache_manager.dart`:**

**AI Instructions:** Merge these services:
- `today_feed_cache_service.dart` (main caching logic)
- `today_feed_cache_warming_service.dart` (warming)
- `today_feed_cache_sync_service.dart` (sync)
- `today_feed_cache_maintenance_service.dart` (maintenance)

**Template Structure:**
```dart
/// Unified cache management service for all content types
/// 
/// Consolidates: TodayFeedCacheService, TodayFeedCacheWarmingService,
/// TodayFeedCacheSyncService, TodayFeedCacheMaintenanceService
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  // === CORE CACHING (from today_feed_cache_service.dart) ===
  
  // === CACHE WARMING (from today_feed_cache_warming_service.dart) ===
  
  // === SYNC OPERATIONS (from today_feed_cache_sync_service.dart) ===
  
  // === MAINTENANCE (from today_feed_cache_maintenance_service.dart) ===
}
```

### Step 2B: Create OfflineManager (Day 5)

**1. Create `lib/core/cache/services/offline_manager.dart`:**

**AI Instructions:** Merge these services:
- `offline_cache_service.dart` (main offline logic)
- `offline_cache_content_service.dart` (content management)
- `offline_cache_sync_service.dart` (sync)
- `offline_cache_validation_service.dart` (validation)
- `offline_cache_action_service.dart` (actions)
- `offline_cache_error_service.dart` (error handling)

### Step 2C: Create CacheAnalytics (Day 6)

**1. Create `lib/core/cache/services/cache_analytics.dart`:**

**AI Instructions:** Merge these services:
- `today_feed_cache_performance_service.dart` (performance)
- `today_feed_cache_statistics_service.dart` (statistics)
- `today_feed_cache_health_service.dart` (health monitoring)
- `offline_cache_stats_service.dart` (offline stats)

### Step 2D: Update Cache Import References

**AI Instructions:** Update all cache service imports:

```bash
# Find all cache service imports
grep -r "import.*cache.*service" lib --include="*.dart" > cache_imports.txt

# Replace with new imports:
# OLD: import '../services/today_feed_cache_service.dart';
# NEW: import '../cache/services/cache_manager.dart';

# OLD: import '../services/offline_cache_service.dart';
# NEW: import '../cache/services/offline_manager.dart';
```

**Validation After Phase 2:**
```bash
flutter analyze
flutter test test/core/services/cache/ --reporter=compact

echo "=== AFTER CACHE CONSOLIDATION ===" >> sprint2_metrics.txt
echo "Cache services: $(find lib -name "*cache*service*.dart" | wc -l)" >> sprint2_metrics.txt
echo "Expected: 3 files" >> sprint2_metrics.txt
```

---

## Phase 3: Today Feed Domain Consolidation (Day 7-8)

### Current Today Feed Services (12 → 2):

**Files to Consolidate:**
```bash
lib/features/today_feed/data/services/session_duration_tracking_service.dart
lib/features/today_feed/data/services/today_feed_streak_tracking_service.dart
lib/features/today_feed/data/services/today_feed_data_service.dart
lib/features/today_feed/data/services/today_feed_momentum_award_service.dart
lib/features/today_feed/data/services/user_content_interaction_service.dart
lib/features/today_feed/data/services/today_feed_content_quality_service.dart
lib/features/today_feed/data/services/today_feed_sharing_service.dart
lib/features/today_feed/data/services/today_feed_interaction_analytics_service.dart
lib/features/today_feed/data/services/realtime_momentum_update_service.dart
lib/features/today_feed/data/services/daily_engagement_detection_service.dart
lib/features/today_feed/data/services/user_feedback_collection_service.dart
lib/features/today_feed/data/services/today_feed_analytics_dashboard_service.dart
```

### Step 3A: Create TodayFeedManager (Day 7)

**1. Create new directory:**
```bash
mkdir -p lib/features/today_feed/services
```

**2. Create `lib/features/today_feed/services/today_feed_manager.dart`:**

**AI Instructions:** Merge these services:
- `today_feed_data_service.dart` (core data)
- `today_feed_streak_tracking_service.dart` (streaks)
- `today_feed_momentum_award_service.dart` (awards)
- `today_feed_content_quality_service.dart` (quality)
- `today_feed_sharing_service.dart` (sharing)
- `realtime_momentum_update_service.dart` (realtime)

### Step 3B: Create TodayFeedAnalytics (Day 8)

**1. Create `lib/features/today_feed/services/today_feed_analytics.dart`:**

**AI Instructions:** Merge these services:
- `session_duration_tracking_service.dart` (session tracking)
- `user_content_interaction_service.dart` (interactions)
- `today_feed_interaction_analytics_service.dart` (analytics)
- `daily_engagement_detection_service.dart` (engagement)
- `user_feedback_collection_service.dart` (feedback)
- `today_feed_analytics_dashboard_service.dart` (dashboard)

### Step 3C: Update Today Feed Import References

**Validation After Phase 3:**
```bash
flutter analyze
flutter test test/features/today_feed/ --reporter=compact

echo "=== AFTER TODAY FEED CONSOLIDATION ===" >> sprint2_metrics.txt
echo "Today Feed services: $(find lib/features/today_feed -name "*service*.dart" | wc -l)" >> sprint2_metrics.txt
echo "Expected: 2 files" >> sprint2_metrics.txt
```

---

## Phase 4: Delete Original Service Files (Day 9)

### Safe Deletion Process

**AI Instructions:** Only delete after confirming:
1. All imports updated successfully
2. All tests passing
3. No compilation errors

**1. Delete notification service files:**
```bash
# Verify no references remain:
grep -r "notification_service.dart" lib --include="*.dart"
grep -r "fcm_token_service.dart" lib --include="*.dart"
grep -r "notification_core_service.dart" lib --include="*.dart"

# If no references found, delete:
rm lib/core/services/notification_service.dart
rm lib/core/services/notification_content_service.dart
rm lib/core/services/notification_testing_service.dart
rm lib/core/services/notification_ab_testing_service.dart
rm lib/core/services/notification_deep_link_service.dart
rm lib/core/services/push_notification_trigger_service.dart
rm lib/core/services/background_notification_handler.dart
rm lib/core/services/fcm_token_service.dart
rm -rf lib/core/notifications/domain/services/
```

**2. Delete cache service files:**
```bash
# Verify and delete cache services
rm -rf lib/core/services/cache/
rm lib/core/services/offline_cache_service.dart
rm lib/core/services/today_feed_cache_service.dart
```

**3. Delete today feed service files:**
```bash
# Verify and delete today feed services
rm -rf lib/features/today_feed/data/services/
```

---

## Final Validation & Testing (Day 10)

### Comprehensive Validation:

**1. Compilation check:**
```bash
flutter clean
flutter pub get
flutter analyze
```

**2. Test execution:**
```bash
# Run all tests
flutter test --reporter=expanded

# Specific service tests
flutter test test/core/notifications/ --reporter=compact
flutter test test/core/services/ --reporter=compact  
flutter test test/features/today_feed/ --reporter=compact
```

**3. Manual functionality test:**
```bash
# Start app and verify:
flutter run

# Test checklist:
# [ ] App starts without errors
# [ ] Notifications work
# [ ] Caching works
# [ ] Today feed displays
# [ ] No console errors
```

### Final Metrics:

```bash
echo "=== FINAL SPRINT 2 METRICS ===" >> sprint2_metrics.txt
echo "Total service files: $(find lib -name "*service*.dart" | wc -l)" >> sprint2_metrics.txt
echo "Total service classes: $(grep -r "class.*Service" lib --include="*.dart" | wc -l)" >> sprint2_metrics.txt
echo "Notification services: $(find lib -name "*notification*service*.dart" | wc -l)" >> sprint2_metrics.txt
echo "Cache services: $(find lib -name "*cache*service*.dart" | wc -l)" >> sprint2_metrics.txt
echo "Today Feed services: $(find lib/features/today_feed -name "*service*.dart" | wc -l)" >> sprint2_metrics.txt

# Calculate reduction
ORIGINAL_SERVICES=$(wc -l < current_services.txt)
FINAL_SERVICES=$(find lib -name "*service*.dart" | wc -l)
REDUCTION=$(( ORIGINAL_SERVICES - FINAL_SERVICES ))
PERCENT_REDUCTION=$(( REDUCTION * 100 / ORIGINAL_SERVICES ))

echo "Service reduction: $ORIGINAL_SERVICES → $FINAL_SERVICES ($PERCENT_REDUCTION% reduction)" >> sprint2_metrics.txt
```

### Success Criteria Check:

```bash
FINAL_SERVICES=$(find lib -name "*service*.dart" | wc -l)
if [ $FINAL_SERVICES -le 25 ]; then
  echo "✅ SUCCESS: Services reduced to $FINAL_SERVICES" >> sprint2_metrics.txt
else
  echo "⚠️ REVIEW: Service count is $FINAL_SERVICES (target: <25)" >> sprint2_metrics.txt
fi

# Check for God files
LARGE_FILES=$(find lib -name "*service*.dart" -exec wc -l {} + | awk '$1 > 600 {print $2}')
if [ -z "$LARGE_FILES" ]; then
  echo "✅ SUCCESS: No God files (>600 lines)" >> sprint2_metrics.txt
else
  echo "⚠️ REVIEW: Large files found: $LARGE_FILES" >> sprint2_metrics.txt
fi
```

### Commit Changes:

```bash
git add .
git commit -m "Sprint 2: Service consolidation - reduced from $ORIGINAL_SERVICES to $FINAL_SERVICES services

Notification Domain (12 → 3):
- NotificationManager (core coordination)
- NotificationPreferences (user settings)  
- NotificationAnalytics (tracking)

Cache Domain (15 → 3):
- CacheManager (core caching)
- OfflineManager (offline functionality)
- CacheAnalytics (performance monitoring)

Today Feed Domain (12 → 2):  
- TodayFeedManager (content & data)
- TodayFeedAnalytics (analytics & tracking)

All functionality preserved, interfaces maintained."

git push origin sprint-2-service-consolidation
```

---

## Rollback Plan

```bash
# If consolidation causes issues:
git checkout main
git checkout -b sprint-2-service-consolidation-fix

# Restore from backups:
cp -r backup/* lib/

# Review sprint2_metrics.txt to identify issues
# Implement gradual consolidation instead
```

---

## Critical Service Boundaries (DO NOT MERGE)

### Keep Separate (Core App Functions):
- AuthService (authentication logic)
- ResponsiveService (UI calculations)
- ErrorHandlingService (error management)
- ConnectivityService (network status)
- FirebaseService (Firebase initialization)

### Keep Separate (Version/Configuration):
- VersionService (app versioning)
- HealthCheckService (system health)
- MonitoringService (performance monitoring)

These services have distinct, non-overlapping responsibilities and should remain separate to maintain clear architectural boundaries. 