# Data Retention Policy - Engagement Events

**Module:** Core Engagement  
**Milestone:** 1 · Data Backbone  
**Purpose:** Define data lifecycle management for engagement_events table

---

## Overview

This document outlines the data retention strategy for the BEE engagement events logging system, ensuring compliance with HIPAA, GDPR, and other privacy regulations while maintaining system performance and user data integrity.

## Soft Delete Strategy

### Implementation
The `engagement_events` table uses a soft delete approach via the `is_deleted` boolean flag:

```sql
-- Soft delete an event
UPDATE engagement_events 
SET is_deleted = true, 
    updated_at = NOW() 
WHERE id = $1 AND user_id = auth.uid();

-- Query active events (default behavior)
SELECT * FROM engagement_events 
WHERE is_deleted = false 
AND user_id = auth.uid();
```

### Benefits
- **Data Recovery**: Accidentally deleted events can be restored
- **Audit Trail**: Maintains record of user actions for compliance
- **Performance**: Avoids expensive DELETE operations on large tables
- **Referential Integrity**: Preserves relationships with other tables

### RLS Policy Updates
```sql
-- Update existing policies to exclude soft-deleted events
CREATE POLICY "Users can view own active events" ON engagement_events 
FOR SELECT USING (auth.uid() = user_id AND is_deleted = false);

-- Allow users to soft-delete their own events
CREATE POLICY "Users can soft delete own events" ON engagement_events 
FOR UPDATE USING (auth.uid() = user_id) 
WITH CHECK (auth.uid() = user_id);
```

## Data Archival Procedures

### Automated Archival Process

#### 1. Archive Trigger Function
```sql
-- Function to archive old soft-deleted events
CREATE OR REPLACE FUNCTION archive_old_deleted_events()
RETURNS void AS $$
BEGIN
    -- Move events deleted >90 days ago to archive table
    INSERT INTO engagement_events_archive 
    SELECT * FROM engagement_events 
    WHERE is_deleted = true 
    AND updated_at < NOW() - INTERVAL '90 days';
    
    -- Remove archived events from main table
    DELETE FROM engagement_events 
    WHERE is_deleted = true 
    AND updated_at < NOW() - INTERVAL '90 days';
    
    -- Log archival activity
    INSERT INTO system_logs (action, details, timestamp)
    VALUES ('archive_events', 
            jsonb_build_object('archived_count', ROW_COUNT),
            NOW());
END;
$$ LANGUAGE plpgsql;
```

#### 2. Archive Table Schema
```sql
-- Create archive table with same structure
CREATE TABLE engagement_events_archive (
    LIKE engagement_events INCLUDING ALL
);

-- Add archival metadata
ALTER TABLE engagement_events_archive 
ADD COLUMN archived_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Create index for archive queries
CREATE INDEX idx_engagement_events_archive_user_archived 
ON engagement_events_archive(user_id, archived_at DESC);
```

#### 3. Scheduled Archival Job
```sql
-- Create scheduled job (using pg_cron extension)
SELECT cron.schedule('archive-deleted-events', '0 2 * * 0', 
    'SELECT archive_old_deleted_events();');
```

### Manual Archival Commands

```bash
# Archive specific user's data (GDPR deletion request)
psql -c "CALL archive_user_data('user-uuid-here');"

# Archive events older than specific date
psql -c "CALL archive_events_before('2024-01-01');"

# Verify archival completed successfully
psql -c "SELECT COUNT(*) FROM engagement_events WHERE is_deleted = true AND updated_at < NOW() - INTERVAL '90 days';"
```

## Data Retention Policies

### Retention Timeline

| Data State | Retention Period | Action |
|------------|------------------|---------|
| **Active Events** | Indefinite | Remain in main table |
| **Soft Deleted** | 90 days | Move to archive table |
| **Archived Events** | 7 years | Stored in archive table |
| **Expired Archive** | After 7 years | Permanent deletion |

### Retention Rules by Event Type

#### Standard Events
- **app_open, goal_complete, steps_import**: 7 years
- **mood_log, sleep_log**: 7 years (health data)
- **coach_message_sent**: 3 years (communication records)

#### Sensitive Events
- **health_data_import**: 7 years (HIPAA requirement)
- **payment_events**: 7 years (financial records)
- **location_events**: 1 year (privacy consideration)

### Implementation
```sql
-- Function to apply retention rules by event type
CREATE OR REPLACE FUNCTION apply_retention_rules()
RETURNS void AS $$
BEGIN
    -- Permanently delete location events >1 year old
    DELETE FROM engagement_events_archive 
    WHERE event_type = 'location_events' 
    AND archived_at < NOW() - INTERVAL '1 year';
    
    -- Permanently delete communication events >3 years old
    DELETE FROM engagement_events_archive 
    WHERE event_type = 'coach_message_sent' 
    AND archived_at < NOW() - INTERVAL '3 years';
    
    -- Permanently delete all other events >7 years old
    DELETE FROM engagement_events_archive 
    WHERE archived_at < NOW() - INTERVAL '7 years';
END;
$$ LANGUAGE plpgsql;
```

## GDPR Compliance Procedures

### Right to Erasure (Article 17)

#### User Data Deletion Request
```sql
-- Complete user data deletion procedure
CREATE OR REPLACE FUNCTION delete_user_data(target_user_id UUID)
RETURNS jsonb AS $$
DECLARE
    deleted_count INTEGER;
    archived_count INTEGER;
BEGIN
    -- Count events to be deleted
    SELECT COUNT(*) INTO deleted_count 
    FROM engagement_events 
    WHERE user_id = target_user_id;
    
    SELECT COUNT(*) INTO archived_count 
    FROM engagement_events_archive 
    WHERE user_id = target_user_id;
    
    -- Permanently delete from main table
    DELETE FROM engagement_events 
    WHERE user_id = target_user_id;
    
    -- Permanently delete from archive
    DELETE FROM engagement_events_archive 
    WHERE user_id = target_user_id;
    
    -- Log deletion for compliance audit
    INSERT INTO gdpr_deletion_log (
        user_id, 
        deleted_events_count, 
        archived_events_count, 
        deletion_timestamp,
        requested_by
    ) VALUES (
        target_user_id, 
        deleted_count, 
        archived_count, 
        NOW(),
        auth.uid()
    );
    
    RETURN jsonb_build_object(
        'user_id', target_user_id,
        'deleted_events', deleted_count,
        'deleted_archived', archived_count,
        'status', 'completed'
    );
END;
$$ LANGUAGE plpgsql;
```

#### GDPR Deletion API Endpoint
```javascript
// Cloud Function for GDPR deletion requests
exports.deleteUserData = functions.https.onCall(async (data, context) => {
    // Verify admin authentication
    if (!context.auth || !context.auth.token.admin) {
        throw new functions.https.HttpsError('permission-denied', 
            'Only admins can process deletion requests');
    }
    
    const { userId, requestId } = data;
    
    try {
        // Execute deletion procedure
        const result = await supabase.rpc('delete_user_data', {
            target_user_id: userId
        });
        
        // Update deletion request status
        await supabase
            .from('gdpr_requests')
            .update({ 
                status: 'completed',
                completed_at: new Date().toISOString(),
                result: result.data
            })
            .eq('id', requestId);
            
        return { success: true, result: result.data };
    } catch (error) {
        console.error('GDPR deletion failed:', error);
        throw new functions.https.HttpsError('internal', 
            'Deletion process failed');
    }
});
```

### Right to Data Portability (Article 20)

#### User Data Export
```sql
-- Export user's engagement events
CREATE OR REPLACE FUNCTION export_user_data(target_user_id UUID)
RETURNS jsonb AS $$
DECLARE
    user_events jsonb;
    archived_events jsonb;
BEGIN
    -- Export active events
    SELECT jsonb_agg(
        jsonb_build_object(
            'id', id,
            'timestamp', timestamp,
            'event_type', event_type,
            'value', value,
            'created_at', created_at
        )
    ) INTO user_events
    FROM engagement_events 
    WHERE user_id = target_user_id 
    AND is_deleted = false;
    
    -- Export archived events
    SELECT jsonb_agg(
        jsonb_build_object(
            'id', id,
            'timestamp', timestamp,
            'event_type', event_type,
            'value', value,
            'archived_at', archived_at
        )
    ) INTO archived_events
    FROM engagement_events_archive 
    WHERE user_id = target_user_id;
    
    RETURN jsonb_build_object(
        'user_id', target_user_id,
        'export_timestamp', NOW(),
        'active_events', COALESCE(user_events, '[]'::jsonb),
        'archived_events', COALESCE(archived_events, '[]'::jsonb)
    );
END;
$$ LANGUAGE plpgsql;
```

### Compliance Monitoring

#### Audit Tables
```sql
-- GDPR compliance audit log
CREATE TABLE gdpr_deletion_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    deleted_events_count INTEGER NOT NULL,
    archived_events_count INTEGER NOT NULL,
    deletion_timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    requested_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Data retention audit log
CREATE TABLE retention_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    action TEXT NOT NULL, -- 'archive', 'delete', 'export'
    affected_records INTEGER NOT NULL,
    execution_timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    details JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## Operational Procedures

### Daily Operations
```bash
#!/bin/bash
# Daily data retention check
echo "$(date): Starting daily retention check"

# Check for soft-deleted events ready for archival
psql -c "SELECT COUNT(*) as ready_for_archive FROM engagement_events WHERE is_deleted = true AND updated_at < NOW() - INTERVAL '90 days';"

# Check archive table size
psql -c "SELECT pg_size_pretty(pg_total_relation_size('engagement_events_archive')) as archive_size;"

# Verify no orphaned events
psql -c "SELECT COUNT(*) as orphaned_events FROM engagement_events WHERE user_id NOT IN (SELECT id FROM auth.users);"
```

### Weekly Operations
```bash
#!/bin/bash
# Weekly archival and cleanup
echo "$(date): Starting weekly archival process"

# Run archival procedure
psql -c "SELECT archive_old_deleted_events();"

# Apply retention rules
psql -c "SELECT apply_retention_rules();"

# Generate retention report
psql -c "SELECT event_type, COUNT(*) as count, MIN(timestamp) as oldest, MAX(timestamp) as newest FROM engagement_events GROUP BY event_type;"
```

### Emergency Procedures

#### Immediate Data Deletion (Legal Hold)
```sql
-- Emergency deletion procedure (bypasses normal retention)
CREATE OR REPLACE FUNCTION emergency_delete_user_data(
    target_user_id UUID,
    reason TEXT,
    authorized_by UUID
)
RETURNS void AS $$
BEGIN
    -- Log emergency deletion
    INSERT INTO emergency_deletion_log (
        user_id, reason, authorized_by, timestamp
    ) VALUES (target_user_id, reason, authorized_by, NOW());
    
    -- Immediate permanent deletion
    DELETE FROM engagement_events WHERE user_id = target_user_id;
    DELETE FROM engagement_events_archive WHERE user_id = target_user_id;
    
    -- Notify compliance team
    PERFORM pg_notify('emergency_deletion', 
        jsonb_build_object(
            'user_id', target_user_id,
            'reason', reason,
            'timestamp', NOW()
        )::text
    );
END;
$$ LANGUAGE plpgsql;
```

## Monitoring and Alerts

### Key Metrics
- Archive table growth rate
- Retention policy compliance rate
- GDPR request processing time
- Data export/deletion success rate

### Alert Conditions
- Archive table >80% of main table size
- Retention policy violations detected
- GDPR request >72 hour processing time
- Failed archival/deletion operations

---

**Implementation Status:** Ready for deployment  
**Review Required:** Legal and compliance team approval  
**Next Steps:** Implement monitoring dashboards and alert systems 