# Offline Cache Service Architecture

## Overview

The `OfflineCacheService` has been refactored from a monolithic 730-line service into a modular architecture consisting of 6 specialized services, each with a single responsibility. This refactoring maintains 100% backward compatibility while improving maintainability, testability, and extensibility.

## Architecture

```
OfflineCacheService (Main Coordinator ~284 lines)
├── OfflineCacheContentService (Core data caching/retrieval ~263 lines)
├── OfflineCacheValidationService (Data integrity & validation ~155 lines)  
├── OfflineCacheMaintenanceService (Cleanup & version management ~212 lines)
├── OfflineCacheErrorService (Error handling & queuing ~116 lines)
├── OfflineCacheSyncService (Background synchronization ~94 lines)
├── OfflineCacheActionService (Pending action queue management ~178 lines)
└── OfflineCacheStatsService (Health monitoring & statistics ~150 lines)
```

## Service Responsibilities

### 1. OfflineCacheService (Main Coordinator)
**File:** `app/lib/core/services/offline_cache_service.dart`  
**Responsibility:** Service coordination, initialization, and public API facade

**Key Functions:**
- Service initialization and dependency management
- Public API delegation to appropriate services
- Backward compatibility maintenance
- Testing helper methods

**Example Usage:**
```dart
// Initialize all services
await OfflineCacheService.initialize();

// Cache momentum data
await OfflineCacheService.cacheMomentumData(data, isHighPriority: true);

// Get cached data
final data = await OfflineCacheService.getCachedMomentumData();
```

### 2. OfflineCacheContentService
**File:** `offline_cache_content_service.dart`  
**Responsibility:** Core momentum data caching and retrieval operations

**Key Functions:**
- `cacheMomentumData()` - Cache momentum data with priority and skip logic
- `getCachedMomentumData()` - Retrieve cached momentum data with validation
- `getCachedWeeklyTrend()` - Get cached weekly trend data
- `getCachedMomentumStats()` - Get cached momentum statistics
- Component-specific caching (trend, stats, main data)

**SharedPreferences Keys:**
- `cached_momentum_data` - Main momentum data
- `cached_weekly_trend` - Weekly trend data  
- `cached_momentum_stats` - Momentum statistics
- `cached_data_timestamp` - Cache timestamp

### 3. OfflineCacheValidationService
**File:** `offline_cache_validation_service.dart`  
**Responsibility:** Cache validity checks and version management

**Key Functions:**
- `isCachedDataValid()` - Check if cached data is still valid
- `validateCacheVersion()` - Validate and upgrade cache versions
- Custom validity period handling
- High priority update validation

**SharedPreferences Keys:**
- `cache_version` - Current cache version
- `cached_data_timestamp` - For validation checks

### 4. OfflineCacheMaintenanceService
**File:** `offline_cache_maintenance_service.dart`  
**Responsibility:** Cache cleanup, invalidation, and maintenance operations

**Key Functions:**
- `invalidateCache()` - Smart cache invalidation by component
- `clearAllCache()` - Clear all cached data
- `performCacheCleanup()` - Clean up old/invalid cache entries
- `checkCacheHealth()` - Monitor cache health and trigger cleanup

**Features:**
- Selective cache invalidation (momentum data, weekly trend, stats)
- Health monitoring and automatic cleanup
- Storage space management

### 5. OfflineCacheErrorService
**File:** `offline_cache_error_service.dart`  
**Responsibility:** Error queuing and reporting management

**Key Functions:**
- `queueError()` - Queue errors for later reporting
- `getQueuedErrors()` - Retrieve queued errors
- `clearQueuedErrors()` - Clear error queue
- Error queue size management (max 50 errors)

**SharedPreferences Keys:**
- `error_queue` - JSON array of queued errors

### 6. OfflineCacheSyncService
**File:** `offline_cache_sync_service.dart`  
**Responsibility:** Background synchronization control and cache warming

**Key Functions:**
- `enableBackgroundSync()` - Enable/disable background sync
- `isBackgroundSyncEnabled()` - Check background sync status
- `warmCache()` - Warm cache when coming online
- Sync attempt tracking

**SharedPreferences Keys:**
- `background_sync_enabled` - Background sync setting
- `last_sync_attempt` - Last sync attempt timestamp

### 7. OfflineCacheActionService
**File:** `offline_cache_action_service.dart`  
**Responsibility:** Pending action queue with priority and retry logic

**Key Functions:**
- `queuePendingAction()` - Queue actions with priority (1-3) and retry count
- `processPendingActions()` - Process actions when back online
- `getPendingActions()` - Get all pending actions
- `removePendingAction()` - Remove completed actions
- `clearPendingActions()` - Clear all actions
- Duplicate action detection

**SharedPreferences Keys:**
- `pending_actions` - JSON array of pending actions

**Action Structure:**
```dart
{
  'id': 'unique_id',
  'type': 'action_type',
  'data': {...},
  'priority': 1-3,  // 1=low, 2=medium, 3=high
  'maxRetries': 3,
  'retryCount': 0,
  'timestamp': 'ISO_8601',
  'lastAttempt': 'ISO_8601'?
}
```

### 8. OfflineCacheStatsService
**File:** `offline_cache_stats_service.dart`  
**Responsibility:** Cache statistics, health monitoring, and metrics

**Key Functions:**
- `getEnhancedCacheStats()` - Comprehensive cache statistics
- `getCachedDataAge()` - Get age of cached data
- `getCacheStats()` - Legacy compatibility method
- Health score calculation
- Cache metrics aggregation

**Statistics Include:**
- Cache health score (0-100)
- Data age and validity status
- Component availability (trend, stats, main data)
- Queue sizes (errors, pending actions)
- Background sync status
- Cache version information

## Initialization Flow

```dart
// 1. Check if already initialized
if (_isInitialized) return;

// 2. Get SharedPreferences instance
_prefs ??= await SharedPreferences.getInstance();

// 3. Initialize validation service first (handles version upgrades)
await OfflineCacheValidationService.initialize(_prefs!);
await OfflineCacheValidationService.validateCacheVersion();

// 4. Initialize all other services
await OfflineCacheStatsService.initialize(_prefs!);
await OfflineCacheErrorService.initialize(_prefs!);
await OfflineCacheActionService.initialize(_prefs!);
await OfflineCacheSyncService.initialize(_prefs!);
await OfflineCacheMaintenanceService.initialize(_prefs!);
await OfflineCacheContentService.initialize(_prefs!);

// 5. Mark as initialized
_isInitialized = true;
```

## Migration Guide

### For Existing Code
**No changes required!** All existing code using `OfflineCacheService` will continue to work exactly as before. The main service delegates to the appropriate specialized services.

### For New Development
Consider using the specialized services directly for better performance and clearer intent:

```dart
// Instead of:
await OfflineCacheService.getEnhancedCacheStats();

// Consider:
await OfflineCacheStatsService.getEnhancedCacheStats();

// Instead of:
await OfflineCacheService.queueError(error);

// Consider:
await OfflineCacheErrorService.queueError(error);
```

## Testing

### Test Structure
- Main tests: `app/test/core/services/offline_cache_service_test.dart`
- All existing tests continue to pass
- Tests verify both direct service usage and delegation through main service

### Testing Guidelines
- Use `OfflineCacheService.resetForTesting()` to reset state between tests
- Services are automatically initialized during `OfflineCacheService.initialize()`
- Mock SharedPreferences using `SharedPreferences.setMockInitialValues({})`

## Performance Considerations

### Memory Usage
- Services are static with minimal memory footprint
- SharedPreferences instance is shared across all services
- Lazy initialization prevents unnecessary service setup

### Storage Efficiency
- Granular caching allows selective updates
- Component-specific invalidation reduces unnecessary cache clearing
- Automatic cleanup maintains storage efficiency

### Network Efficiency
- Background sync controls reduce unnecessary API calls
- Cache warming optimizes online-to-offline transitions
- Priority-based action processing handles critical operations first

## Extension Points

### Adding New Cache Types
1. Create new methods in `OfflineCacheContentService`
2. Add validation logic in `OfflineCacheValidationService`
3. Update statistics in `OfflineCacheStatsService`
4. Add cleanup logic in `OfflineCacheMaintenanceService`

### Adding New Statistics
1. Extend `OfflineCacheStatsService.getEnhancedCacheStats()`
2. Update health score calculation if needed
3. Add new metrics to the stats response

### Custom Validation Logic
1. Extend `OfflineCacheValidationService.isCachedDataValid()`
2. Add new validation parameters as needed
3. Implement custom validity periods

## Troubleshooting

### Common Issues
1. **Service not initialized:** Ensure `OfflineCacheService.initialize()` is called
2. **Tests failing:** Use `OfflineCacheService.resetForTesting()` in tearDown
3. **Cache not clearing:** Check if selective invalidation is being used
4. **Actions not processing:** Verify network connectivity and retry logic

### Debug Information
```dart
// Get comprehensive cache status
final stats = await OfflineCacheService.getEnhancedCacheStats();
print('Cache Health: ${stats['healthScore']}');
print('Has Data: ${stats['hasCachedData']}');
print('Is Valid: ${stats['isValid']}');
print('Pending Actions: ${stats['pendingActionsCount']}');
print('Queued Errors: ${stats['queuedErrorsCount']}');
```

## Version History

### Version 2.0 (Current)
- Modular architecture with 6 specialized services
- Enhanced error handling and queuing
- Priority-based action processing
- Improved health monitoring
- Better testing support

### Version 1.0 (Legacy)
- Monolithic service (730 lines)
- Basic caching functionality
- Limited error handling
- Simple action queuing

---

**Note:** This architecture maintains 100% backward compatibility. All existing code will continue to work without modification while benefiting from the improved internal structure. 