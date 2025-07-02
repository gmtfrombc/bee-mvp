# Operational Runbook - Engagement Events

**Module:** Core Engagement  
**Milestone:** 1 · Data Backbone  
**Purpose:** Operations guide for monitoring, alerting, and maintenance

---

## Overview

This runbook provides comprehensive operational procedures for the BEE engagement events logging system. It covers monitoring setup, alert configurations, troubleshooting guides, and routine maintenance tasks.

## Monitoring Setup

### Key Performance Indicators (KPIs)

#### 1. System Health Metrics
```yaml
# Core system metrics to monitor
system_health:
  database:
    - table_size_growth_rate
    - query_response_time_p95
    - connection_pool_utilization
    - index_hit_ratio
    - replication_lag
  
  api:
    - request_rate_per_second
    - error_rate_percentage
    - response_time_p95
    - authentication_success_rate
  
  realtime:
    - notification_latency_p95
    - subscription_count
    - message_delivery_rate
    - websocket_connection_stability
```

#### 2. Business Metrics
```yaml
# Business-critical metrics
business_metrics:
  engagement:
    - daily_active_users
    - events_per_user_per_day
    - event_type_distribution
    - user_retention_rate
  
  data_quality:
    - event_validation_failure_rate
    - duplicate_event_percentage
    - missing_required_fields_rate
    - data_completeness_score
```

### Monitoring Infrastructure

#### 1. Database Monitoring Views
```sql
-- Create monitoring views for operational insights
CREATE VIEW engagement_events_health AS
SELECT 
    -- Table statistics
    schemaname,
    tablename,
    n_tup_ins as total_inserts,
    n_tup_upd as total_updates,
    n_tup_del as total_deletes,
    n_live_tup as live_rows,
    n_dead_tup as dead_rows,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze
FROM pg_stat_user_tables 
WHERE tablename = 'engagement_events';

-- Query performance monitoring
CREATE VIEW engagement_events_query_stats AS
SELECT 
    query,
    calls,
    total_time,
    mean_time,
    min_time,
    max_time,
    stddev_time,
    rows
FROM pg_stat_statements 
WHERE query LIKE '%engagement_events%'
ORDER BY mean_time DESC;

-- Index usage monitoring
CREATE VIEW engagement_events_index_health AS
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch,
    CASE 
        WHEN idx_scan = 0 THEN 'UNUSED'
        WHEN idx_scan < 100 THEN 'LOW_USAGE'
        ELSE 'ACTIVE'
    END as usage_status
FROM pg_stat_user_indexes 
WHERE tablename = 'engagement_events';
```

#### 2. Application Metrics Collection
```dart
// Flutter app metrics collection
class MetricsCollector {
  static final Map<String, int> _eventCounts = {};
  static final Map<String, List<double>> _responseTimes = {};
  
  // Track API response times
  static void recordApiResponseTime(String endpoint, double responseTime) {
    _responseTimes.putIfAbsent(endpoint, () => []);
    _responseTimes[endpoint]!.add(responseTime);
    
    // Keep only last 100 measurements
    if (_responseTimes[endpoint]!.length > 100) {
      _responseTimes[endpoint]!.removeAt(0);
    }
  }
  
  // Track event creation counts
  static void recordEventCreated(String eventType) {
    _eventCounts[eventType] = (_eventCounts[eventType] ?? 0) + 1;
  }
  
  // Get metrics summary
  static Map<String, dynamic> getMetricsSummary() {
    final summary = <String, dynamic>{};
    
    // Calculate average response times
    _responseTimes.forEach((endpoint, times) {
      if (times.isNotEmpty) {
        final avg = times.reduce((a, b) => a + b) / times.length;
        summary['${endpoint}_avg_response_time'] = avg;
      }
    });
    
    // Add event counts
    summary['event_counts'] = Map.from(_eventCounts);
    
    return summary;
  }
  
  // Send metrics to monitoring system
  static Future<void> sendMetrics() async {
    final metrics = getMetricsSummary();
    
    try {
      await supabase.from('app_metrics').insert({
        'timestamp': DateTime.now().toIso8601String(),
        'metrics': metrics,
        'app_version': '1.0.0',
        'platform': Platform.operatingSystem,
      });
    } catch (e) {
      print('Failed to send metrics: $e');
    }
  }
}
```

#### 3. Monitoring Dashboard Configuration
```json
{
  "dashboard": "BEE Engagement Events Operations",
  "refresh_interval": "30s",
  "panels": [
    {
      "title": "Event Insert Rate",
      "type": "graph",
      "targets": [
        {
          "query": "rate(engagement_events_inserts_total[5m])",
          "legend": "Inserts/sec"
        }
      ],
      "thresholds": [
        {"value": 100, "color": "green"},
        {"value": 500, "color": "yellow"},
        {"value": 1000, "color": "red"}
      ]
    },
    {
      "title": "Query Response Time",
      "type": "graph",
      "targets": [
        {
          "query": "histogram_quantile(0.95, engagement_events_query_duration_seconds)",
          "legend": "95th percentile"
        },
        {
          "query": "histogram_quantile(0.50, engagement_events_query_duration_seconds)",
          "legend": "50th percentile"
        }
      ],
      "thresholds": [
        {"value": 0.1, "color": "green"},
        {"value": 0.5, "color": "yellow"},
        {"value": 1.0, "color": "red"}
      ]
    },
    {
      "title": "RLS Policy Violations",
      "type": "stat",
      "targets": [
        {
          "query": "sum(increase(rls_violations_total[1h]))",
          "legend": "Violations/hour"
        }
      ],
      "thresholds": [
        {"value": 0, "color": "green"},
        {"value": 1, "color": "red"}
      ]
    },
    {
      "title": "Table Size Growth",
      "type": "graph",
      "targets": [
        {
          "query": "engagement_events_table_size_bytes",
          "legend": "Table size"
        }
      ]
    }
  ]
}
```

## Alert Configurations

### Critical Alerts

#### 1. RLS Policy Violations
```yaml
# Alert for any RLS policy violations
alert_rls_violations:
  name: "RLS Policy Violation Detected"
  condition: "rls_violations_total > 0"
  severity: "critical"
  description: "Cross-user data access attempt detected"
  notification_channels:
    - "pagerduty"
    - "slack_security"
  runbook_url: "https://docs.company.com/runbooks/rls-violations"
  
  # SQL query to detect violations
  detection_query: |
    SELECT 
      user_id,
      attempted_access_user_id,
      timestamp,
      query_text
    FROM security_audit_log 
    WHERE event_type = 'rls_violation' 
    AND timestamp > NOW() - INTERVAL '5 minutes';
```

#### 2. Performance Degradation
```yaml
# Alert for query performance issues
alert_performance_degradation:
  name: "Query Performance Degradation"
  condition: "avg_query_time > 500ms for 5 minutes"
  severity: "high"
  description: "Database queries taking longer than acceptable threshold"
  notification_channels:
    - "slack_engineering"
    - "email_oncall"
  
  # Monitoring query
  detection_query: |
    SELECT 
      query,
      mean_time,
      calls,
      total_time
    FROM pg_stat_statements 
    WHERE query LIKE '%engagement_events%' 
    AND mean_time > 500
    ORDER BY mean_time DESC;
```

#### 3. High Error Rate
```yaml
# Alert for API error rate
alert_high_error_rate:
  name: "High API Error Rate"
  condition: "error_rate > 5% for 10 minutes"
  severity: "high"
  description: "API error rate exceeding acceptable threshold"
  notification_channels:
    - "slack_engineering"
  
  # Error tracking
  detection_query: |
    SELECT 
      endpoint,
      status_code,
      COUNT(*) as error_count,
      COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() as error_percentage
    FROM api_logs 
    WHERE timestamp > NOW() - INTERVAL '10 minutes'
    AND status_code >= 400
    GROUP BY endpoint, status_code
    HAVING COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() > 5;
```

### Warning Alerts

#### 1. Table Growth Rate
```yaml
alert_table_growth:
  name: "High Table Growth Rate"
  condition: "table_size_growth > 1GB/day"
  severity: "warning"
  description: "Engagement events table growing faster than expected"
  notification_channels:
    - "slack_engineering"
  
  detection_query: |
    SELECT 
      pg_size_pretty(pg_total_relation_size('engagement_events')) as current_size,
      pg_size_pretty(
        pg_total_relation_size('engagement_events') - 
        LAG(pg_total_relation_size('engagement_events')) OVER (ORDER BY timestamp)
      ) as growth_since_last_check
    FROM table_size_history 
    WHERE table_name = 'engagement_events'
    ORDER BY timestamp DESC 
    LIMIT 1;
```

#### 2. Index Usage
```yaml
alert_unused_indexes:
  name: "Unused Database Indexes"
  condition: "index_usage_ratio < 80%"
  severity: "info"
  description: "Database indexes not being used efficiently"
  notification_channels:
    - "slack_engineering"
  
  detection_query: |
    SELECT 
      indexname,
      idx_scan,
      CASE 
        WHEN idx_scan = 0 THEN 'NEVER_USED'
        WHEN idx_scan < 100 THEN 'RARELY_USED'
        ELSE 'WELL_USED'
      END as usage_category
    FROM pg_stat_user_indexes 
    WHERE tablename = 'engagement_events'
    AND idx_scan < 100;
```

### Alert Response Procedures

#### 1. RLS Violation Response
```bash
#!/bin/bash
# Immediate response to RLS violations

echo "=== RLS VIOLATION RESPONSE ==="

# 1. Identify the violation
psql -c "
SELECT 
  user_id,
  attempted_access_user_id,
  timestamp,
  query_text,
  source_ip
FROM security_audit_log 
WHERE event_type = 'rls_violation' 
AND timestamp > NOW() - INTERVAL '1 hour'
ORDER BY timestamp DESC;
"

# 2. Check for ongoing violations
ACTIVE_VIOLATIONS=$(psql -t -c "
SELECT COUNT(*) 
FROM security_audit_log 
WHERE event_type = 'rls_violation' 
AND timestamp > NOW() - INTERVAL '5 minutes';
")

if [ "$ACTIVE_VIOLATIONS" -gt 0 ]; then
    echo "CRITICAL: $ACTIVE_VIOLATIONS active violations detected"
    
    # 3. Temporarily block suspicious IPs if needed
    # (Implementation depends on your infrastructure)
    
    # 4. Notify security team
    curl -X POST "$SLACK_WEBHOOK_SECURITY" \
      -H 'Content-type: application/json' \
      --data '{"text":"🚨 CRITICAL: RLS violations detected in engagement_events table"}'
fi

# 5. Generate detailed report
psql -c "
SELECT 
  DATE_TRUNC('hour', timestamp) as hour,
  COUNT(*) as violation_count,
  COUNT(DISTINCT user_id) as affected_users,
  COUNT(DISTINCT source_ip) as source_ips
FROM security_audit_log 
WHERE event_type = 'rls_violation' 
AND timestamp > NOW() - INTERVAL '24 hours'
GROUP BY DATE_TRUNC('hour', timestamp)
ORDER BY hour DESC;
" > /tmp/rls_violation_report.txt

echo "Detailed report saved to /tmp/rls_violation_report.txt"
```

#### 2. Performance Issue Response
```bash
#!/bin/bash
# Response to performance degradation

echo "=== PERFORMANCE ISSUE RESPONSE ==="

# 1. Identify slow queries
psql -c "
SELECT 
  query,
  calls,
  mean_time,
  total_time,
  (mean_time * calls) as total_impact
FROM pg_stat_statements 
WHERE query LIKE '%engagement_events%' 
AND mean_time > 100
ORDER BY total_impact DESC
LIMIT 10;
"

# 2. Check current database load
psql -c "
SELECT 
  state,
  COUNT(*) as connection_count,
  AVG(EXTRACT(EPOCH FROM (NOW() - query_start))) as avg_duration
FROM pg_stat_activity 
WHERE state IS NOT NULL
GROUP BY state;
"

# 3. Check for blocking queries
psql -c "
SELECT 
  blocked_locks.pid AS blocked_pid,
  blocked_activity.usename AS blocked_user,
  blocking_locks.pid AS blocking_pid,
  blocking_activity.usename AS blocking_user,
  blocked_activity.query AS blocked_statement,
  blocking_activity.query AS blocking_statement
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype
JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;
"

# 4. Check table and index statistics
psql -c "
SELECT 
  schemaname,
  tablename,
  n_live_tup,
  n_dead_tup,
  last_vacuum,
  last_autovacuum,
  last_analyze
FROM pg_stat_user_tables 
WHERE tablename = 'engagement_events';
"

echo "Performance analysis complete. Check output for issues."
```

## Troubleshooting Procedures

### Common Issues and Solutions

#### 1. High Query Response Times

**Symptoms:**
- API requests timing out
- Dashboard loading slowly
- User complaints about app performance

**Diagnosis Steps:**
```bash
# Check current query performance
psql -c "
SELECT 
  query,
  mean_time,
  calls,
  total_time
FROM pg_stat_statements 
WHERE query LIKE '%engagement_events%' 
ORDER BY mean_time DESC 
LIMIT 5;
"

# Check for missing indexes
psql -c "
SELECT 
  schemaname,
  tablename,
  attname,
  n_distinct,
  correlation
FROM pg_stats 
WHERE tablename = 'engagement_events' 
AND n_distinct > 100;
"

# Check table bloat
psql -c "
SELECT 
  schemaname,
  tablename,
  n_live_tup,
  n_dead_tup,
  ROUND(n_dead_tup * 100.0 / NULLIF(n_live_tup + n_dead_tup, 0), 2) as dead_tuple_percent
FROM pg_stat_user_tables 
WHERE tablename = 'engagement_events';
"
```

**Solutions:**
```bash
# 1. Analyze table statistics
psql -c "ANALYZE engagement_events;"

# 2. Vacuum if high dead tuple percentage
psql -c "VACUUM ANALYZE engagement_events;"

# 3. Check if indexes are being used
psql -c "
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM engagement_events 
WHERE user_id = '11111111-1111-1111-1111-111111111111' 
ORDER BY timestamp DESC 
LIMIT 50;
"

# 4. Consider adding missing indexes if needed
# (Based on query patterns identified)
```

#### 2. RLS Policy Issues

**Symptoms:**
- Users seeing other users' data
- Authentication errors
- Unexpected empty result sets

**Diagnosis Steps:**
```bash
# Check RLS is enabled
psql -c "
SELECT 
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables 
WHERE tablename = 'engagement_events';
"

# List current policies
psql -c "
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'engagement_events';
"

# Test policy with specific user
psql -c "
SET LOCAL role = 'authenticated';
SET LOCAL request.jwt.claims = '{\"sub\": \"11111111-1111-1111-1111-111111111111\"}';
SELECT COUNT(*) FROM engagement_events;
"
```

**Solutions:**
```bash
# 1. Verify user context is set correctly
# Check application code for proper JWT handling

# 2. Test policies manually
psql -c "
-- Test as specific user
SELECT set_config('request.jwt.claims', '{\"sub\": \"test-user-id\"}', true);
SELECT COUNT(*) FROM engagement_events;
"

# 3. Recreate policies if needed
psql -c "
DROP POLICY IF EXISTS \"Users can view own events\" ON engagement_events;
CREATE POLICY \"Users can view own events\" ON engagement_events 
FOR SELECT USING (auth.uid() = user_id);
"
```

#### 3. Realtime Notification Issues

**Symptoms:**
- Events not appearing in real-time
- WebSocket connection failures
- High notification latency

**Diagnosis Steps:**
```bash
# Check Realtime configuration
curl -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
  "$SUPABASE_URL/rest/v1/config/realtime"

# Test WebSocket connection
# (Use WebSocket testing tool or browser dev tools)

# Check for Realtime errors in logs
# (Check Supabase dashboard or logs)
```

**Solutions:**
```dart
// 1. Verify subscription setup
void debugRealtimeSubscription() {
  final channel = supabase
      .channel('debug_engagement_events')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'engagement_events',
        callback: (payload) {
          print('Realtime event received: ${payload.newRecord}');
        },
      )
      .subscribe((status) {
        print('Subscription status: $status');
      });
}

// 2. Implement connection retry logic
class RealtimeManager {
  static void setupReconnection() {
    supabase.realtime.onOpen(() {
      print('Realtime connected');
    });
    
    supabase.realtime.onClose((event) {
      print('Realtime disconnected: $event');
      // Implement exponential backoff reconnection
    });
    
    supabase.realtime.onError((error) {
      print('Realtime error: $error');
    });
  }
}
```

### Emergency Procedures

#### 1. Database Emergency Response
```bash
#!/bin/bash
# Emergency database response script

echo "=== DATABASE EMERGENCY RESPONSE ==="

# Check database connectivity
if ! psql -c "SELECT 1;" > /dev/null 2>&1; then
    echo "CRITICAL: Database connection failed"
    # Notify on-call team
    curl -X POST "$PAGERDUTY_WEBHOOK" \
      -H 'Content-type: application/json' \
      --data '{"incident_key":"db_connection_failure","description":"Database connection failed"}'
    exit 1
fi

# Check table accessibility
if ! psql -c "SELECT COUNT(*) FROM engagement_events LIMIT 1;" > /dev/null 2>&1; then
    echo "CRITICAL: engagement_events table inaccessible"
    # Check for table corruption or missing table
    psql -c "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'engagement_events');"
fi

# Check for blocking queries
BLOCKING_QUERIES=$(psql -t -c "
SELECT COUNT(*) 
FROM pg_stat_activity 
WHERE state = 'active' 
AND query_start < NOW() - INTERVAL '5 minutes'
AND query NOT LIKE '%pg_stat_activity%';
")

if [ "$BLOCKING_QUERIES" -gt 0 ]; then
    echo "WARNING: $BLOCKING_QUERIES long-running queries detected"
    
    # List blocking queries
    psql -c "
    SELECT 
      pid,
      usename,
      state,
      query_start,
      query
    FROM pg_stat_activity 
    WHERE state = 'active' 
    AND query_start < NOW() - INTERVAL '5 minutes'
    AND query NOT LIKE '%pg_stat_activity%';
    "
    
    # Option to kill blocking queries (use with caution)
    read -p "Kill long-running queries? (y/N): " -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        psql -c "
        SELECT pg_terminate_backend(pid) 
        FROM pg_stat_activity 
        WHERE state = 'active' 
        AND query_start < NOW() - INTERVAL '10 minutes'
        AND query NOT LIKE '%pg_stat_activity%';
        "
    fi
fi

echo "Emergency response complete"
```

#### 2. API Emergency Response
```bash
#!/bin/bash
# API emergency response script

echo "=== API EMERGENCY RESPONSE ==="

# Test API endpoints
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $USER_JWT" \
  "$SUPABASE_URL/rest/v1/engagement_events?limit=1")

if [ "$API_STATUS" != "200" ]; then
    echo "CRITICAL: API returning status $API_STATUS"
    
    # Check authentication
    AUTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
      "$SUPABASE_URL/auth/v1/user" \
      -H "Authorization: Bearer $USER_JWT")
    
    if [ "$AUTH_STATUS" != "200" ]; then
        echo "CRITICAL: Authentication service failing"
    fi
    
    # Check database connectivity from API
    DB_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
      -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
      "$SUPABASE_URL/rest/v1/engagement_events?limit=1")
    
    if [ "$DB_STATUS" != "200" ]; then
        echo "CRITICAL: Database connectivity from API failing"
    fi
fi

# Test GraphQL endpoint
GRAPHQL_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $USER_JWT" \
  -H "Content-Type: application/json" \
  -d '{"query": "query { engagement_events(limit: 1) { id } }"}' \
  "$SUPABASE_URL/graphql/v1")

if [ "$GRAPHQL_STATUS" != "200" ]; then
    echo "WARNING: GraphQL API returning status $GRAPHQL_STATUS"
fi

echo "API emergency response complete"
```

## Routine Maintenance Tasks

### Daily Tasks

#### 1. Health Check Script
```bash
#!/bin/bash
# Daily health check script

echo "=== DAILY HEALTH CHECK $(date) ==="

# 1. Check table size and growth
echo "Table Size:"
psql -c "
SELECT 
  pg_size_pretty(pg_total_relation_size('engagement_events')) as table_size,
  pg_size_pretty(pg_relation_size('engagement_events')) as data_size,
  pg_size_pretty(pg_total_relation_size('engagement_events') - pg_relation_size('engagement_events')) as index_size;
"

# 2. Check event counts by type
echo "Event Counts (Last 24 hours):"
psql -c "
SELECT 
  event_type,
  COUNT(*) as count,
  COUNT(DISTINCT user_id) as unique_users
FROM engagement_events 
WHERE timestamp > NOW() - INTERVAL '24 hours'
GROUP BY event_type 
ORDER BY count DESC;
"

# 3. Check for errors
echo "Error Summary:"
psql -c "
SELECT 
  DATE_TRUNC('hour', timestamp) as hour,
  COUNT(*) as error_count
FROM error_logs 
WHERE timestamp > NOW() - INTERVAL '24 hours'
AND component = 'engagement_events'
GROUP BY DATE_TRUNC('hour', timestamp)
ORDER BY hour DESC;
"

# 4. Check performance metrics
echo "Performance Summary:"
psql -c "
SELECT 
  'avg_query_time' as metric,
  ROUND(AVG(mean_time), 2) as value
FROM pg_stat_statements 
WHERE query LIKE '%engagement_events%'
UNION ALL
SELECT 
  'total_queries' as metric,
  SUM(calls) as value
FROM pg_stat_statements 
WHERE query LIKE '%engagement_events%';
"

# 5. Save metrics to history
psql -c "
INSERT INTO daily_health_metrics (
  date,
  table_size_bytes,
  total_events_24h,
  unique_users_24h,
  avg_query_time_ms
) VALUES (
  CURRENT_DATE,
  pg_total_relation_size('engagement_events'),
  (SELECT COUNT(*) FROM engagement_events WHERE timestamp > NOW() - INTERVAL '24 hours'),
  (SELECT COUNT(DISTINCT user_id) FROM engagement_events WHERE timestamp > NOW() - INTERVAL '24 hours'),
  (SELECT AVG(mean_time) FROM pg_stat_statements WHERE query LIKE '%engagement_events%')
);
"

echo "Daily health check complete"
```

### Weekly Tasks

#### 1. Performance Analysis
```bash
#!/bin/bash
# Weekly performance analysis

echo "=== WEEKLY PERFORMANCE ANALYSIS $(date) ==="

# 1. Analyze query patterns
echo "Top Queries by Total Time:"
psql -c "
SELECT 
  LEFT(query, 100) as query_preview,
  calls,
  ROUND(total_time, 2) as total_time_ms,
  ROUND(mean_time, 2) as avg_time_ms
FROM pg_stat_statements 
WHERE query LIKE '%engagement_events%'
ORDER BY total_time DESC 
LIMIT 10;
"

# 2. Index usage analysis
echo "Index Usage Analysis:"
psql -c "
SELECT 
  indexname,
  idx_scan,
  idx_tup_read,
  idx_tup_fetch,
  CASE 
    WHEN idx_scan = 0 THEN 'UNUSED'
    WHEN idx_scan < 100 THEN 'LOW_USAGE'
    ELSE 'ACTIVE'
  END as status
FROM pg_stat_user_indexes 
WHERE tablename = 'engagement_events'
ORDER BY idx_scan DESC;
"

# 3. Table maintenance check
echo "Table Maintenance Status:"
psql -c "
SELECT 
  schemaname,
  tablename,
  n_live_tup,
  n_dead_tup,
  ROUND(n_dead_tup * 100.0 / NULLIF(n_live_tup + n_dead_tup, 0), 2) as dead_tuple_percent,
  last_vacuum,
  last_autovacuum,
  last_analyze,
  last_autoanalyze
FROM pg_stat_user_tables 
WHERE tablename = 'engagement_events';
"

# 4. Growth trend analysis
echo "Growth Trend (Last 7 days):"
psql -c "
SELECT 
  date,
  table_size_bytes,
  total_events_24h,
  unique_users_24h,
  LAG(table_size_bytes) OVER (ORDER BY date) as prev_size,
  table_size_bytes - LAG(table_size_bytes) OVER (ORDER BY date) as size_growth
FROM daily_health_metrics 
WHERE date >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY date;
"

echo "Weekly performance analysis complete"
```

### Monthly Tasks

#### 1. Capacity Planning
```bash
#!/bin/bash
# Monthly capacity planning analysis

echo "=== MONTHLY CAPACITY PLANNING $(date) ==="

# 1. Growth projections
echo "Growth Projections:"
psql -c "
WITH monthly_growth AS (
  SELECT 
    DATE_TRUNC('month', timestamp) as month,
    COUNT(*) as events_count,
    COUNT(DISTINCT user_id) as unique_users,
    pg_total_relation_size('engagement_events') as table_size
  FROM engagement_events 
  WHERE timestamp >= DATE_TRUNC('month', NOW() - INTERVAL '6 months')
  GROUP BY DATE_TRUNC('month', timestamp)
)
SELECT 
  month,
  events_count,
  unique_users,
  pg_size_pretty(table_size) as table_size,
  ROUND(
    (events_count - LAG(events_count) OVER (ORDER BY month)) * 100.0 / 
    NULLIF(LAG(events_count) OVER (ORDER BY month), 0), 2
  ) as growth_rate_percent
FROM monthly_growth 
ORDER BY month;
"

# 2. Resource utilization trends
echo "Resource Utilization Trends:"
psql -c "
SELECT 
  DATE_TRUNC('week', date) as week,
  AVG(table_size_bytes) as avg_table_size,
  AVG(total_events_24h) as avg_daily_events,
  AVG(unique_users_24h) as avg_daily_users,
  AVG(avg_query_time_ms) as avg_query_time
FROM daily_health_metrics 
WHERE date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE_TRUNC('week', date)
ORDER BY week;
"

# 3. Recommendations
echo "Generating capacity recommendations..."

CURRENT_SIZE=$(psql -t -c "SELECT pg_total_relation_size('engagement_events');")
MONTHLY_GROWTH=$(psql -t -c "
SELECT COALESCE(
  (SELECT COUNT(*) FROM engagement_events WHERE timestamp >= DATE_TRUNC('month', NOW())) -
  (SELECT COUNT(*) FROM engagement_events WHERE timestamp >= DATE_TRUNC('month', NOW() - INTERVAL '1 month') AND timestamp < DATE_TRUNC('month', NOW())),
  0
);
")

echo "Current table size: $(echo $CURRENT_SIZE | numfmt --to=iec)"
echo "Monthly event growth: $MONTHLY_GROWTH events"

# Calculate projected size in 6 months
PROJECTED_SIZE=$((CURRENT_SIZE + (MONTHLY_GROWTH * 6 * 100)))  # Rough estimate
echo "Projected size in 6 months: $(echo $PROJECTED_SIZE | numfmt --to=iec)"

echo "Monthly capacity planning complete"
```

## Incident Response Playbook

### Severity Levels

#### 1. Critical (P0)
- **Definition:** Complete system outage or data breach
- **Response Time:** Immediate (< 15 minutes)
- **Escalation:** Page on-call engineer immediately

#### 2. High (P1)
- **Definition:** Significant performance degradation or partial outage
- **Response Time:** < 1 hour
- **Escalation:** Notify on-call engineer via Slack

#### 3. Medium (P2)
- **Definition:** Minor performance issues or non-critical bugs
- **Response Time:** < 4 hours
- **Escalation:** Create ticket for next business day

#### 4. Low (P3)
- **Definition:** Enhancement requests or minor issues
- **Response Time:** < 24 hours
- **Escalation:** Add to backlog

### Incident Response Steps

#### 1. Initial Response
```bash
# Incident response checklist
echo "=== INCIDENT RESPONSE CHECKLIST ==="
echo "1. [ ] Assess severity level"
echo "2. [ ] Notify appropriate stakeholders"
echo "3. [ ] Begin investigation"
echo "4. [ ] Implement immediate mitigation"
echo "5. [ ] Monitor for resolution"
echo "6. [ ] Conduct post-incident review"

# Quick system status check
./scripts/emergency_health_check.sh

# Gather initial information
echo "Incident Details:"
echo "Time: $(date)"
echo "Reporter: $USER"
echo "Affected Systems: engagement_events"
```

#### 2. Communication Templates
```bash
# Slack notification template
INCIDENT_MESSAGE="🚨 INCIDENT ALERT
Severity: P1
System: Engagement Events
Issue: High query response times detected
Status: Investigating
ETA: 30 minutes
Incident Commander: @oncall-engineer"

curl -X POST "$SLACK_WEBHOOK" \
  -H 'Content-type: application/json' \
  --data "{\"text\":\"$INCIDENT_MESSAGE\"}"
```

---

**Implementation Status:** Ready for deployment  
**Review Required:** Operations and SRE team approval  
**Next Steps:** Set up monitoring infrastructure and train operations team 