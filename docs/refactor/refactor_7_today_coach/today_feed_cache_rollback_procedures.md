# Today Feed Cache Service - Rollback Procedures

**Document Version**: 1.0  
**Last Updated**: January 2025  
**Migration Phase**: Sprint 5.4 - Migration & Rollout Plan  

## 🚨 Emergency Contacts

- **Primary Engineer**: [Engineering Lead]
- **DevOps Team**: [DevOps Lead] 
- **Product Manager**: [Product Manager]
- **24/7 Support**: [Support Contact]

---

## 🎯 **Rollback Overview**

This document provides comprehensive procedures for rolling back the Today Feed Cache Service refactoring in case of issues during migration. The rollback procedures are designed to be fast, safe, and minimize user impact.

### **Rollback Triggers**

Immediate rollback should be triggered if any of the following conditions are met:

1. **Performance Degradation** > 50% from baseline
2. **Error Rate** > 5% over 1-hour period
3. **Critical Functionality Failure** (content not loading, app crashes)
4. **User Complaints** > 10 reports/hour
5. **Memory Usage** > 200% of baseline
6. **Database Issues** (connection failures, data corruption)

---

## 🚀 **Rollback Procedures**

### **Level 1: Feature Flag Rollback (Immediate - 30 seconds)**

**Use Case**: Quick rollback for performance issues or high error rates

```bash
# Emergency Feature Flag Rollback
# This disables the new architecture immediately for all users

# Option 1: Using Migration Manager API
await TodayFeedCacheMigrationManager.forceCompatibilityMode(
  reason: 'Emergency rollback - [specific reason]'
);

# Option 2: Using Direct Configuration
await TodayFeedCacheMigrationManager.setMigrationPhase(
  MigrationPhase.compatibilityOnly
);

# Option 3: Emergency Rollback with Monitoring
await TodayFeedCacheMigrationManager.triggerRollback(
  reason: 'Performance degradation detected',
  metadata: {
    'error_rate': '8%',
    'response_time_ms': 1200,
    'triggered_by': 'automated_monitoring'
  }
);
```

**Validation Steps:**
1. ✅ Verify feature flag is disabled: `getCurrentMigrationPhase() == compatibilityOnly`
2. ✅ Check user reports return to normal within 5 minutes
3. ✅ Monitor error rates decrease to <2%
4. ✅ Verify performance metrics return to baseline

**Expected Recovery Time**: 30 seconds to 2 minutes

---

### **Level 2: Application Restart Rollback (5-10 minutes)**

**Use Case**: Feature flag rollback doesn't resolve issues or app-wide problems

```bash
# Step 1: Force compatibility mode
await TodayFeedCacheMigrationManager.forceCompatibilityMode(
  reason: 'Application restart rollback required'
);

# Step 2: Clear all cache data to reset state
await TodayFeedCacheService.invalidateCache(
  reason: 'rollback_cleanup'
);

# Step 3: Restart application services
# This varies by deployment environment:

# For Flutter app (requires app restart)
# Users will need to restart the app, but new users get compatibility mode

# For backend services
kubectl rollout restart deployment/today-feed-service
# OR
docker-compose restart today-feed-service

# Step 4: Verify rollback success
final status = await TodayFeedCacheMigrationManager.getMigrationStatus();
assert(status['forced_compatibility'] == true);
```

**Validation Steps:**
1. ✅ All new app instances use compatibility mode
2. ✅ Cache is cleared and rebuilt with legacy architecture
3. ✅ Error rates return to normal within 10 minutes
4. ✅ All core functionality restored

**Expected Recovery Time**: 5-10 minutes

---

### **Level 3: Database Rollback (30-60 minutes)**

**Use Case**: Data corruption or database schema issues

```sql
-- Emergency database rollback script
-- Execute in this order:

-- Step 1: Stop all writes to affected tables
UPDATE migration_config SET rollback_mode = 'true' WHERE service = 'today_feed_cache';

-- Step 2: Restore from last known good backup
-- This should be automated in your backup system
RESTORE DATABASE today_feed_cache FROM BACKUP 'latest_pre_migration';

-- Step 3: Update migration phase in SharedPreferences
-- This needs to be done via application code:
```

```dart
// Application code for database rollback
await TodayFeedCacheMigrationManager.forceCompatibilityMode(
  reason: 'Database rollback - data corruption detected'
);

// Clear all cached data to force refresh from restored database
await TodayFeedCacheService.invalidateCache(reason: 'database_rollback');

// Verify data integrity
final healthCheck = await TodayFeedCacheHealthService.getDiagnosticInfo();
assert(healthCheck['data_integrity'] == 'healthy');
```

**Validation Steps:**
1. ✅ Database restored to pre-migration state
2. ✅ Data integrity checks pass
3. ✅ All cache entries regenerated from restored data
4. ✅ User data is intact and accessible

**Expected Recovery Time**: 30-60 minutes

---

### **Level 4: Full System Rollback (2-4 hours)**

**Use Case**: Complete system failure or widespread issues

```bash
# Full system rollback procedure
# This is the nuclear option - complete revert to pre-refactoring state

# Step 1: Deployment rollback
git checkout [previous_stable_commit]
git tag rollback-$(date +%Y%m%d-%H%M%S)

# Step 2: Database schema rollback
# Run pre-prepared rollback migrations
flutter pub run migration_tool:rollback --target=pre_refactoring

# Step 3: Configuration rollback
# Restore all configuration to pre-refactoring state
cp config/pre_refactoring_backup/* config/

# Step 4: Clear all caches and state
rm -rf cache/*
redis-cli FLUSHDB  # If using Redis

# Step 5: Deploy rolled-back version
flutter build apk --release
# Deploy to app stores as emergency update

# Step 6: Monitor recovery
./scripts/monitor_rollback_recovery.sh
```

**Validation Steps:**
1. ✅ Complete system restored to pre-refactoring state
2. ✅ All user functionality works as before refactoring
3. ✅ Performance metrics match pre-refactoring baseline
4. ✅ No data loss confirmed

**Expected Recovery Time**: 2-4 hours

---

## 📊 **Rollback Monitoring**

### **Automated Rollback Triggers**

```dart
// Automated monitoring and rollback triggers
class AutomatedRollbackMonitor {
  static const Duration monitoringInterval = Duration(minutes: 5);
  static const double errorRateThreshold = 0.05; // 5%
  static const Duration responseTimeThreshold = Duration(milliseconds: 1000);
  
  static Future<void> checkAndTriggerRollback() async {
    final metrics = await TodayFeedCacheMigrationManager.getMigrationMetrics();
    final successValidation = await TodayFeedCacheMigrationManager.validateSuccessCriteria();
    
    // Check error rate
    if (metrics['success_rate'] < 95) {
      await TodayFeedCacheMigrationManager.triggerRollback(
        reason: 'Automated rollback - high error rate: ${metrics["success_rate"]}%',
        metadata: metrics,
      );
      return;
    }
    
    // Check success criteria
    if (!successValidation['overall_success']) {
      await TodayFeedCacheMigrationManager.triggerRollback(
        reason: 'Automated rollback - success criteria failed',
        metadata: successValidation,
      );
      return;
    }
  }
}
```

### **Manual Monitoring Checklist**

**Every 15 minutes during rollout:**
- [ ] Error rate < 2%
- [ ] Response time < 500ms average
- [ ] Memory usage < 150% of baseline
- [ ] User complaints < 2/hour
- [ ] Cache hit rate > 90%

**Immediate Rollback If:**
- [ ] Error rate > 5% for 15+ minutes
- [ ] Response time > 1000ms for 10+ minutes
- [ ] App crashes reported by >5 users
- [ ] Critical functionality fails
- [ ] Data corruption detected

---

## 🔄 **Recovery Validation**

### **Post-Rollback Checklist**

**Immediate (within 5 minutes):**
- [ ] Verify rollback phase is active
- [ ] Check error rates return to normal
- [ ] Confirm critical functionality works
- [ ] Monitor user complaint channels

**Short-term (within 30 minutes):**
- [ ] Validate all performance metrics return to baseline
- [ ] Confirm data integrity
- [ ] Check cache rebuild completion
- [ ] Review system logs for any residual issues

**Long-term (within 2 hours):**
- [ ] Comprehensive functionality testing
- [ ] User acceptance validation
- [ ] Performance benchmark comparison
- [ ] Prepare post-mortem analysis

### **Success Criteria for Recovery**

```dart
// Automated recovery validation
final recoveryValidation = {
  'error_rate': '< 2%',
  'response_time': '< 300ms average',
  'memory_usage': '< 120% of baseline',
  'cache_hit_rate': '> 95%',
  'user_complaints': '< 1/hour',
  'critical_functions': 'all_working',
  'data_integrity': 'validated',
};
```

---

## 📞 **Communication Procedures**

### **Internal Communication**

**Immediate (within 5 minutes of rollback):**
- Notify engineering team via Slack/Teams
- Update incident tracking system
- Inform product and QA teams

**Short-term (within 30 minutes):**
- Send status update to stakeholders
- Create incident report ticket
- Schedule post-mortem meeting

### **User Communication Templates**

**Service Status Page Update:**
```
🔧 MAINTENANCE NOTICE
We're temporarily using our legacy Today Feed system while we address a minor issue with our new architecture. Your Today Feed content remains available and unaffected. We expect to resume the migration shortly.
```

**In-App Notification (if needed):**
```
📱 SYSTEM UPDATE
We've temporarily switched to our proven Today Feed system to ensure optimal performance. Your content and data are safe. Thank you for your patience.
```

**Support Team Script:**
```
"We're aware of the recent Today Feed changes and have temporarily reverted to our previous system to ensure the best user experience. Your data is safe and the service is functioning normally. We'll provide updates as we continue improving the system."
```

---

## 🛠️ **Prevention Measures**

### **Pre-Rollout Preparation**

1. **Backup Strategy**
   - Database backups every 6 hours during migration
   - Configuration snapshots before each phase
   - Code repository tags for quick reversion

2. **Monitoring Setup**
   - Automated rollback triggers
   - Real-time performance dashboards
   - User feedback monitoring

3. **Team Preparation**
   - Rollback procedure training
   - Emergency contact list verification
   - Communication template preparation

### **Gradual Rollout Strategy**

```dart
// Recommended rollout phases to minimize risk
final rolloutPlan = {
  'Phase 1': {
    'percentage': 1,
    'duration': '24 hours',
    'criteria': 'Internal users + 1% of active users'
  },
  'Phase 2': {
    'percentage': 5,
    'duration': '48 hours', 
    'criteria': 'Extended to 5% after successful Phase 1'
  },
  'Phase 3': {
    'percentage': 25,
    'duration': '72 hours',
    'criteria': 'Quarter rollout with comprehensive monitoring'
  },
  'Phase 4': {
    'percentage': 100,
    'duration': 'Ongoing',
    'criteria': 'Full deployment after validation'
  }
};
```

---

## 📝 **Post-Rollback Analysis**

### **Immediate Actions (within 24 hours)**

1. **Root Cause Analysis**
   - Identify primary failure point
   - Review logs and metrics leading to rollback
   - Document timeline of events

2. **Impact Assessment**
   - User impact duration and scope
   - Performance degradation extent
   - Data integrity verification

3. **Process Review**
   - Rollback procedure effectiveness
   - Communication timeline and clarity
   - Monitoring adequacy

### **Improvement Planning (within 1 week)**

1. **Technical Improvements**
   - Address root cause of rollback
   - Enhance monitoring capabilities
   - Improve rollback automation

2. **Process Improvements**
   - Update rollback procedures based on learnings
   - Enhance communication templates
   - Adjust rollout strategy

3. **Documentation Updates**
   - Update this rollback guide
   - Document lessons learned
   - Share with broader engineering team

---

## 🎯 **Quick Reference Commands**

### **Emergency Rollback (30 seconds)**
```dart
await TodayFeedCacheMigrationManager.forceCompatibilityMode(
  reason: 'EMERGENCY_ROLLBACK'
);
```

### **Check Rollback Status**
```dart
final status = await TodayFeedCacheMigrationManager.getMigrationStatus();
print('Rollback Active: ${status["forced_compatibility"]}');
```

### **Clear Rollback and Resume**
```dart
await TodayFeedCacheMigrationManager.clearForcedCompatibilityMode();
await TodayFeedCacheMigrationManager.clearRollback();
```

### **Emergency Contact Commands**
```bash
# Slack notifications
slack-notify --channel=#emergency --message="Today Feed Cache rollback triggered"

# PagerDuty alert
pd-trigger --service=today-feed --severity=high --message="Cache service rollback"

# Status page update
status-update --component=today-feed --status=maintenance
```

---

**Remember**: When in doubt, choose the faster, safer rollback option. User experience preservation is the top priority during any rollback procedure.

---

*This document should be reviewed and updated after each migration phase and any rollback events.* 