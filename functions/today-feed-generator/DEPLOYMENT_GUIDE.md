# Deployment Guide: Content Versioning System

**Epic 1.3: Today Feed (AI Daily Brief)**  
**Task: T1.3.1.7 - Content Storage and Versioning System**

## Overview

This guide walks through deploying the content versioning system for the Today Feed service. The system adds version control, change tracking, and content delivery optimization to the existing Today Feed infrastructure.

## Prerequisites

### Required
- ✅ Existing Today Feed service deployed (T1.3.1.1-T1.3.1.6)
- ✅ Supabase project with service role key
- ✅ GCP Cloud Run environment
- ✅ Database migration access

### Environment Variables
Ensure these are set in your deployment environment:
```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-actual-service-role-key
GCP_PROJECT_ID=your-gcp-project
VERTEX_AI_LOCATION=us-central1
GOOGLE_APPLICATION_CREDENTIALS={"type":"service_account",...}
```

## Deployment Steps

### Step 1: Database Migration

#### 1.1 Backup Current Database
```sql
-- Create backup of current content (run in Supabase SQL editor)
CREATE TABLE daily_feed_content_backup AS SELECT * FROM daily_feed_content;
```

#### 1.2 Apply Versioning Migration
```bash
# Option A: Using Python script
cd /path/to/bee-mvp
source app/.env  # Or set environment variables manually
python scripts/run_migration.py supabase/migrations/20241229000000_content_versioning_system.sql

# Option B: Manual execution in Supabase SQL Editor
# Copy contents of 20241229000000_content_versioning_system.sql
# Paste and run in Supabase dashboard SQL editor
```

#### 1.3 Verify Migration
```sql
-- Check that tables were created
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('content_versions', 'content_change_log', 'content_delivery_optimization');

-- Check that triggers are active
SELECT trigger_name FROM information_schema.triggers 
WHERE event_object_table = 'daily_feed_content';

-- Verify view exists
SELECT * FROM content_with_versions LIMIT 1;
```

### Step 2: Deploy Updated Service

#### 2.1 Update Cloud Run Service
```bash
cd functions/today-feed-generator

# Build and deploy with new versioning endpoints
gcloud run deploy today-feed-generator \
  --source . \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --memory 512Mi \
  --cpu 1 \
  --timeout 300 \
  --set-env-vars SUPABASE_URL="$SUPABASE_URL" \
  --set-env-vars SUPABASE_SERVICE_ROLE_KEY="$SUPABASE_SERVICE_ROLE_KEY" \
  --set-env-vars GCP_PROJECT_ID="$GCP_PROJECT_ID" \
  --set-env-vars VERTEX_AI_LOCATION="$VERTEX_AI_LOCATION" \
  --set-env-vars GOOGLE_APPLICATION_CREDENTIALS="$GOOGLE_APPLICATION_CREDENTIALS"
```

#### 2.2 Verify Deployment
```bash
# Get service URL
SERVICE_URL=$(gcloud run services describe today-feed-generator --platform managed --region us-central1 --format 'value(status.url)')

# Test health endpoint
curl "$SERVICE_URL/health"

# Should return something like:
# {
#   "status": "healthy",
#   "service": "today-feed-generator",
#   "timestamp": "2024-12-29T12:00:00.000Z",
#   "version": "1.0.0"
# }
```

### Step 3: Test Versioning System

#### 3.1 Run Automated Tests
```bash
cd functions/today-feed-generator

# Set service URL for testing
export TODAY_FEED_SERVICE_URL="https://your-service-url"

# Run comprehensive test suite
deno run --allow-net --allow-env test-versioning.ts

# Expected output:
# 🧪 Testing Today Feed Versioning System
# ✅ PASS: Health Check
# ✅ PASS: Version History - Missing Content ID Validation
# ... (more tests)
# 📊 Test Results: X/Y tests passed (100%)
```

#### 3.2 Manual API Testing

**Test Version History:**
```bash
curl "$SERVICE_URL/versions/history?content_id=1"
```

**Test Cached Content:**
```bash
curl -H "If-None-Match: test-etag" "$SERVICE_URL/content/cached?date=2024-12-29"
```

**Test Delivery Stats:**
```bash
curl "$SERVICE_URL/delivery/stats?days=7"
```

### Step 4: Initialize Existing Content

Since existing content won't have versions, we need to create initial versions:

```sql
-- Run this in Supabase SQL editor to create initial versions for existing content
DO $$
DECLARE
    content_record RECORD;
BEGIN
    FOR content_record IN SELECT id FROM daily_feed_content LOOP
        PERFORM create_content_version(
            content_record.id, 
            'initial', 
            'Migrated from existing content', 
            'migration-system'
        );
    END LOOP;
END $$;
```

Verify initialization:
```sql
-- Check that all content has versions
SELECT 
    dfc.id,
    dfc.content_date,
    dfc.title,
    cv.version_number,
    cv.change_type
FROM daily_feed_content dfc
LEFT JOIN content_versions cv ON dfc.id = cv.content_id AND cv.is_active = true
ORDER BY dfc.content_date DESC;
```

### Step 5: Update Application Integration

#### 5.1 Flutter App Updates
Update your Flutter app to use the new cached content endpoint:

```dart
// Replace existing content fetch calls
final response = await http.get(
  Uri.parse('$serviceUrl/content/cached?date=$date'),
  headers: {
    'If-None-Match': cachedEtag, // If you have cached ETag
  },
);

if (response.statusCode == 304) {
  // Use cached content
  return cachedContent;
} else if (response.statusCode == 200) {
  // Update cache with new content
  final newEtag = response.headers['etag'];
  // ... save new content and ETag
}
```

#### 5.2 Admin Dashboard Integration
Add version management to your admin interface:

```typescript
// Get version history
const versionHistory = await fetch(`/versions/history?content_id=${contentId}`);

// Create new version
const newVersion = await fetch('/versions/create', {
  method: 'POST',
  body: JSON.stringify({
    content_id: contentId,
    change_type: 'update',
    change_reason: 'Fixed typo',
    changed_by: 'admin@example.com'
  })
});

// Rollback to previous version
const rollback = await fetch('/versions/rollback', {
  method: 'POST',
  body: JSON.stringify({
    content_id: contentId,
    target_version: 2,
    rollback_reason: 'Reverting problematic changes',
    changed_by: 'admin@example.com'
  })
});
```

## Monitoring & Maintenance

### Key Metrics to Monitor

1. **Version Creation Rate**
   ```sql
   SELECT DATE(created_at), COUNT(*) as versions_created
   FROM content_versions
   WHERE created_at >= NOW() - INTERVAL '7 days'
   GROUP BY DATE(created_at);
   ```

2. **Cache Hit Rate**
   ```sql
   SELECT 
     content_id,
     cache_hits,
     cache_misses,
     ROUND(cache_hits::numeric / NULLIF(cache_hits + cache_misses, 0) * 100, 2) as hit_rate_pct
   FROM content_delivery_optimization
   WHERE cache_hits + cache_misses > 0;
   ```

3. **Content Change Frequency**
   ```sql
   SELECT 
     action_type,
     COUNT(*) as count,
     DATE(created_at) as date
   FROM content_change_log
   WHERE created_at >= NOW() - INTERVAL '30 days'
   GROUP BY action_type, DATE(created_at)
   ORDER BY date DESC;
   ```

### Maintenance Tasks

#### Weekly
- Review version creation patterns
- Check cache hit rates
- Monitor storage usage for versions table

#### Monthly
- Clean up old versions (keep last 10 per content)
- Review change log for patterns
- Update cache control strategies

#### Cleanup Script (Run Monthly)
```sql
-- Keep only last 10 versions per content
DELETE FROM content_versions cv1
WHERE cv1.id NOT IN (
  SELECT cv2.id 
  FROM content_versions cv2
  WHERE cv2.content_id = cv1.content_id
  ORDER BY cv2.version_number DESC
  LIMIT 10
);
```

## Troubleshooting

### Common Issues

#### 1. Migration Fails
```bash
# Check current database state
psql $DATABASE_URL -c "\dt public.*"

# Verify no conflicts with existing tables
psql $DATABASE_URL -c "SELECT tablename FROM pg_tables WHERE schemaname = 'public';"
```

#### 2. Service Returns 500 Errors
```bash
# Check Cloud Run logs
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=today-feed-generator" --limit=50

# Test database connectivity
curl "$SERVICE_URL/health" -v
```

#### 3. Versions Not Creating
```sql
-- Check trigger status
SELECT trigger_name, event_manipulation, action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'daily_feed_content';

-- Test manual version creation
SELECT create_content_version(1, 'test', 'Manual test', 'debug');
```

#### 4. Cache Headers Missing
```bash
# Verify CORS and caching headers
curl -I "$SERVICE_URL/content/cached"

# Should include:
# Access-Control-Allow-Origin: *
# Cache-Control: public, max-age=86400
# ETag: "..."
```

## Rollback Plan

If issues occur, you can rollback:

### 1. Revert Service
```bash
# Deploy previous version without versioning endpoints
git checkout previous-commit
gcloud run deploy today-feed-generator --source .
```

### 2. Remove Database Changes (If Necessary)
```sql
-- CAUTION: This removes all versioning data
DROP TABLE IF EXISTS content_versions CASCADE;
DROP TABLE IF EXISTS content_change_log CASCADE;
DROP TABLE IF EXISTS content_delivery_optimization CASCADE;
DROP VIEW IF EXISTS content_with_versions;
-- Remove triggers and functions as needed
```

### 3. Restore from Backup
```sql
-- If data issues occur
DELETE FROM daily_feed_content;
INSERT INTO daily_feed_content SELECT * FROM daily_feed_content_backup;
```

## Success Criteria

✅ **Migration Complete**
- All new tables created successfully
- Triggers functioning correctly
- Existing content has initial versions

✅ **Service Deployed**
- All new endpoints responding correctly
- Health check passes
- No errors in Cloud Run logs

✅ **Functionality Verified**
- Version history retrieval works
- Content caching with ETags works
- Delivery stats reporting works
- Manual version creation works
- Rollback functionality works

✅ **Performance Maintained**
- Response times < 2 seconds
- Cache hit rate > 80%
- No memory leaks or errors

---

**Deployment Guide Complete**  
**Next Task**: T1.3.1.8 - Content moderation and approval workflow

For support or issues, refer to the VERSIONING_SYSTEM.md documentation or run the test suite to identify specific problems. 