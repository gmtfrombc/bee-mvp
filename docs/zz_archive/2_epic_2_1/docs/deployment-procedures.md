# Deployment Procedures - Engagement Events

**Module:** Core Engagement  
**Milestone:** 1 · Data Backbone  
**Purpose:** Define deployment, rollback, and operational procedures

---

## Migration Deployment Checklist

### Pre-Deployment Verification

#### 1. Environment Readiness
- [ ] **Database Connection**: Verify Supabase connection and credentials
- [ ] **Backup Status**: Confirm recent backup exists (within 24 hours)
- [ ] **Resource Monitoring**: Check database CPU/memory usage <70%
- [ ] **Active Sessions**: Verify no long-running transactions in progress
- [ ] **Disk Space**: Ensure >20% free space available

```bash
# Pre-deployment checks script
#!/bin/bash
echo "=== Pre-Deployment Verification ==="

# Check database connectivity
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT NOW();" || exit 1

# Check disk space
df -h | grep -E "(80%|9[0-9]%)" && echo "WARNING: Low disk space detected"

# Check active connections
psql -c "SELECT count(*) as active_connections FROM pg_stat_activity WHERE state = 'active';"

# Verify backup recency
psql -c "SELECT pg_size_pretty(pg_database_size('$DB_NAME')) as db_size;"
```

#### 2. Migration File Validation
- [ ] **Syntax Check**: SQL syntax validation completed
- [ ] **Dependency Check**: Required tables/extensions exist
- [ ] **Test Environment**: Migration tested on staging environment
- [ ] **Rollback Plan**: Rollback script prepared and tested

```bash
# Migration validation script
#!/bin/bash
MIGRATION_FILE="supabase/migrations/20241201000000_engagement_events.sql"

echo "=== Migration File Validation ==="

# Check file exists
[ -f "$MIGRATION_FILE" ] || { echo "Migration file not found"; exit 1; }

# Syntax check (dry run)
psql --set ON_ERROR_STOP=on --single-transaction --dry-run -f "$MIGRATION_FILE"

# Check for dangerous operations
grep -i "DROP\|TRUNCATE\|DELETE" "$MIGRATION_FILE" && echo "WARNING: Destructive operations detected"

echo "Migration file validation completed"
```

#### 3. Application Readiness
- [ ] **API Compatibility**: Verify API endpoints handle new schema
- [ ] **Client Updates**: Flutter app updated to use new event types
- [ ] **Feature Flags**: New features disabled until migration complete
- [ ] **Monitoring**: Enhanced monitoring enabled for deployment

### Deployment Execution Steps

#### Step 1: Maintenance Mode (Optional)
```bash
# Enable maintenance mode if needed
curl -X POST "$SUPABASE_URL/rest/v1/system_status" \
  -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"maintenance_mode": true, "message": "Database migration in progress"}'
```

#### Step 2: Create Deployment Snapshot
```bash
# Create pre-migration snapshot
SNAPSHOT_NAME="pre_engagement_events_$(date +%Y%m%d_%H%M%S)"
pg_dump -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME > "backups/$SNAPSHOT_NAME.sql"
echo "Snapshot created: $SNAPSHOT_NAME"
```

#### Step 3: Execute Migration
```bash
#!/bin/bash
echo "=== Executing Migration ==="

# Set error handling
set -e

# Execute migration with transaction
psql --set ON_ERROR_STOP=on --single-transaction -f "supabase/migrations/20241201000000_engagement_events.sql"

# Verify migration success
psql -c "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'engagement_events');" | grep -q "t" || exit 1

echo "Migration executed successfully"
```

#### Step 4: Post-Migration Validation
```bash
#!/bin/bash
echo "=== Post-Migration Validation ==="

# Verify table structure
psql -c "\d+ engagement_events"

# Check RLS is enabled
psql -c "SELECT relrowsecurity FROM pg_class WHERE relname = 'engagement_events';" | grep -q "t" || exit 1

# Verify indexes exist
psql -c "SELECT indexname FROM pg_indexes WHERE tablename = 'engagement_events';"

# Test basic operations
psql -c "INSERT INTO engagement_events (user_id, event_type, value) VALUES ('11111111-1111-1111-1111-111111111111', 'deployment_test', '{}');"
psql -c "SELECT COUNT(*) FROM engagement_events WHERE event_type = 'deployment_test';"

echo "Post-migration validation completed"
```

#### Step 5: Load Test Data (Development Only)
```bash
# Load seed data in development environment
if [ "$ENVIRONMENT" = "development" ]; then
    psql -f "supabase/migrations/seed_engagement_events.sql"
    echo "Test data loaded"
fi
```

#### Step 6: Disable Maintenance Mode
```bash
# Disable maintenance mode
curl -X POST "$SUPABASE_URL/rest/v1/system_status" \
  -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"maintenance_mode": false}'
```

### Post-Deployment Verification

#### 1. Functional Testing
- [ ] **API Endpoints**: Test all CRUD operations
- [ ] **RLS Policies**: Verify user isolation works
- [ ] **Realtime**: Test event subscriptions
- [ ] **Performance**: Check query response times

```bash
# Automated functional tests
python tests/run_all_tests.py --skip-performance
```

#### 2. Performance Monitoring
- [ ] **Query Performance**: Monitor slow query log
- [ ] **Connection Pool**: Check connection usage
- [ ] **Index Usage**: Verify indexes are being used
- [ ] **Realtime Latency**: Monitor notification delays

#### 3. Error Monitoring
- [ ] **Application Logs**: Check for new error patterns
- [ ] **Database Logs**: Monitor for constraint violations
- [ ] **API Errors**: Watch for 500/400 error rates
- [ ] **User Reports**: Monitor support channels

## Rollback Procedures

### Automatic Rollback Triggers
- Migration execution fails
- Post-deployment validation fails
- Critical performance degradation (>50% slower)
- RLS policy violations detected

### Rollback Execution

#### Step 1: Immediate Response
```bash
#!/bin/bash
echo "=== INITIATING ROLLBACK ==="

# Enable maintenance mode immediately
curl -X POST "$SUPABASE_URL/rest/v1/system_status" \
  -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"maintenance_mode": true, "message": "Emergency rollback in progress"}'

# Stop all background jobs
psql -c "SELECT pg_cancel_backend(pid) FROM pg_stat_activity WHERE application_name LIKE '%cron%';"
```

#### Step 2: Schema Rollback
```sql
-- Rollback script: rollback_engagement_events.sql
BEGIN;

-- Drop new table and related objects
DROP TABLE IF EXISTS engagement_events CASCADE;
DROP TABLE IF EXISTS engagement_events_archive CASCADE;
DROP FUNCTION IF EXISTS archive_old_deleted_events() CASCADE;
DROP FUNCTION IF EXISTS delete_user_data(UUID) CASCADE;

-- Remove any new indexes
DROP INDEX IF EXISTS idx_engagement_events_user_timestamp;
DROP INDEX IF EXISTS idx_engagement_events_value;
DROP INDEX IF EXISTS idx_engagement_events_type;

-- Remove RLS policies
-- (Policies are automatically dropped with table)

-- Log rollback action
INSERT INTO deployment_log (action, details, timestamp)
VALUES ('rollback', 'engagement_events migration rolled back', NOW());

COMMIT;
```

#### Step 3: Data Recovery
```bash
# Restore from pre-migration snapshot if needed
SNAPSHOT_FILE="backups/pre_engagement_events_$(date +%Y%m%d)*.sql"
if [ -f $SNAPSHOT_FILE ]; then
    echo "Restoring from snapshot: $SNAPSHOT_FILE"
    psql -f "$SNAPSHOT_FILE"
fi
```

#### Step 4: Verification
```bash
# Verify rollback completed successfully
psql -c "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'engagement_events');" | grep -q "f" || echo "ERROR: Table still exists"

# Test basic application functionality
curl -f "$SUPABASE_URL/rest/v1/health" || echo "ERROR: API not responding"
```

### Rollback Decision Matrix

| Issue Type | Severity | Action | Timeline |
|------------|----------|---------|----------|
| **Migration Failure** | Critical | Automatic rollback | Immediate |
| **Performance Degradation** | High | Manual rollback | <30 minutes |
| **RLS Violations** | Critical | Automatic rollback | Immediate |
| **API Errors** | Medium | Investigate first | <1 hour |
| **User Reports** | Low | Monitor and fix | <24 hours |

## Monitoring and Alerts

### Database Health Monitoring

#### 1. Performance Metrics
```sql
-- Query performance monitoring
CREATE VIEW engagement_events_performance AS
SELECT 
    schemaname,
    tablename,
    seq_scan,
    seq_tup_read,
    idx_scan,
    idx_tup_fetch,
    n_tup_ins,
    n_tup_upd,
    n_tup_del
FROM pg_stat_user_tables 
WHERE tablename = 'engagement_events';

-- Index usage monitoring
CREATE VIEW engagement_events_index_usage AS
SELECT 
    indexrelname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes 
WHERE relname = 'engagement_events';
```

#### 2. Alert Configurations
```yaml
# Monitoring alerts configuration
alerts:
  - name: "High Table Growth Rate"
    condition: "table_size_growth > 1GB/day"
    severity: "warning"
    notification: "slack"
    
  - name: "RLS Policy Violation"
    condition: "cross_user_access_attempts > 0"
    severity: "critical"
    notification: "pagerduty"
    
  - name: "Query Performance Degradation"
    condition: "avg_query_time > 500ms"
    severity: "warning"
    notification: "email"
    
  - name: "Index Not Used"
    condition: "index_usage_ratio < 80%"
    severity: "info"
    notification: "slack"
```

#### 3. Monitoring Scripts
```bash
#!/bin/bash
# Database monitoring script (run every 5 minutes)

# Check table size
TABLE_SIZE=$(psql -t -c "SELECT pg_size_pretty(pg_total_relation_size('engagement_events'));")
echo "engagement_events size: $TABLE_SIZE"

# Check query performance
SLOW_QUERIES=$(psql -t -c "SELECT count(*) FROM pg_stat_statements WHERE query LIKE '%engagement_events%' AND mean_time > 500;")
if [ "$SLOW_QUERIES" -gt 0 ]; then
    echo "WARNING: $SLOW_QUERIES slow queries detected"
fi

# Check RLS violations (custom log table)
RLS_VIOLATIONS=$(psql -t -c "SELECT count(*) FROM security_audit_log WHERE event_type = 'rls_violation' AND timestamp > NOW() - INTERVAL '5 minutes';")
if [ "$RLS_VIOLATIONS" -gt 0 ]; then
    echo "CRITICAL: $RLS_VIOLATIONS RLS violations detected"
fi
```

### Application Monitoring

#### 1. API Health Checks
```bash
#!/bin/bash
# API health monitoring

# Test REST API
curl -f -H "Authorization: Bearer $USER_JWT" \
  "$SUPABASE_URL/rest/v1/engagement_events?limit=1" || echo "REST API ERROR"

# Test GraphQL API
curl -f -H "Authorization: Bearer $USER_JWT" \
  -H "Content-Type: application/json" \
  -d '{"query": "query { engagement_events(limit: 1) { id } }"}' \
  "$SUPABASE_URL/graphql/v1" || echo "GraphQL API ERROR"

# Test Realtime connection
# (This would require a WebSocket client test)
```

#### 2. Performance Dashboards
```json
{
  "dashboard": "Engagement Events Monitoring",
  "panels": [
    {
      "title": "Event Insert Rate",
      "query": "rate(engagement_events_inserts_total[5m])",
      "type": "graph"
    },
    {
      "title": "Query Response Time",
      "query": "histogram_quantile(0.95, engagement_events_query_duration_seconds)",
      "type": "graph"
    },
    {
      "title": "RLS Policy Checks",
      "query": "engagement_events_rls_checks_total",
      "type": "counter"
    },
    {
      "title": "Table Size Growth",
      "query": "engagement_events_table_size_bytes",
      "type": "graph"
    }
  ]
}
```

## Backup and Recovery Procedures

### Automated Backup Strategy

#### 1. Daily Backups
```bash
#!/bin/bash
# Daily backup script

BACKUP_DIR="/backups/daily"
DATE=$(date +%Y%m%d)
BACKUP_FILE="$BACKUP_DIR/engagement_events_$DATE.sql"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Dump engagement events table
pg_dump -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME \
  --table=engagement_events \
  --table=engagement_events_archive \
  --inserts \
  --column-inserts > "$BACKUP_FILE"

# Compress backup
gzip "$BACKUP_FILE"

# Verify backup integrity
gunzip -t "$BACKUP_FILE.gz" || echo "ERROR: Backup corruption detected"

# Clean up old backups (keep 30 days)
find "$BACKUP_DIR" -name "*.gz" -mtime +30 -delete

echo "Daily backup completed: $BACKUP_FILE.gz"
```

#### 2. Point-in-Time Recovery Setup
```sql
-- Enable point-in-time recovery
ALTER SYSTEM SET wal_level = 'replica';
ALTER SYSTEM SET archive_mode = 'on';
ALTER SYSTEM SET archive_command = 'cp %p /backups/wal/%f';

-- Restart required for changes to take effect
SELECT pg_reload_conf();
```

### Recovery Procedures

#### 1. Table Recovery
```bash
#!/bin/bash
# Recover engagement_events table from backup

BACKUP_FILE="$1"
if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: $0 <backup_file>"
    exit 1
fi

echo "=== Starting Table Recovery ==="

# Create recovery timestamp
RECOVERY_ID="recovery_$(date +%Y%m%d_%H%M%S)"

# Backup current state before recovery
pg_dump -t engagement_events > "backups/pre_recovery_$RECOVERY_ID.sql"

# Drop existing table (if needed)
read -p "Drop existing engagement_events table? (y/N): " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    psql -c "DROP TABLE IF EXISTS engagement_events CASCADE;"
fi

# Restore from backup
psql -f "$BACKUP_FILE"

# Verify recovery
psql -c "SELECT COUNT(*) as recovered_events FROM engagement_events;"

echo "Recovery completed with ID: $RECOVERY_ID"
```

#### 2. Point-in-Time Recovery
```bash
#!/bin/bash
# Point-in-time recovery to specific timestamp

TARGET_TIME="$1"
if [ -z "$TARGET_TIME" ]; then
    echo "Usage: $0 'YYYY-MM-DD HH:MM:SS'"
    exit 1
fi

echo "=== Point-in-Time Recovery to $TARGET_TIME ==="

# Stop database
pg_ctl stop -D $PGDATA

# Restore base backup
tar -xzf /backups/base/latest_base_backup.tar.gz -C $PGDATA

# Create recovery configuration
cat > $PGDATA/recovery.conf << EOF
restore_command = 'cp /backups/wal/%f %p'
recovery_target_time = '$TARGET_TIME'
recovery_target_action = 'promote'
EOF

# Start database in recovery mode
pg_ctl start -D $PGDATA

echo "Point-in-time recovery initiated"
```

### Disaster Recovery Plan

#### 1. Recovery Time Objectives (RTO)
- **Critical Data Loss**: 4 hours maximum downtime
- **Partial Data Loss**: 1 hour maximum downtime
- **Performance Issues**: 30 minutes maximum impact

#### 2. Recovery Point Objectives (RPO)
- **Maximum Data Loss**: 15 minutes
- **Backup Frequency**: Every 6 hours
- **WAL Archiving**: Continuous

#### 3. Emergency Contacts
```yaml
emergency_contacts:
  primary_dba:
    name: "Database Administrator"
    phone: "+1-XXX-XXX-XXXX"
    email: "dba@company.com"
  
  backup_dba:
    name: "Backup DBA"
    phone: "+1-XXX-XXX-XXXX"
    email: "backup-dba@company.com"
  
  infrastructure_team:
    slack: "#infrastructure-alerts"
    email: "infra-team@company.com"
```

---

**Implementation Status:** Ready for deployment  
**Review Required:** DevOps and DBA team approval  
**Next Steps:** Set up monitoring dashboards and alert systems 