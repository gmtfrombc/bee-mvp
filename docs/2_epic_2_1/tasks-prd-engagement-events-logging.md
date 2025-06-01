# Tasks – Engagement Events Logging (Core Engagement Module)

**Source PRD:** `prd-engagement-events-logging.md`  
**Module:** Core Engagement  
**Milestone:** 1 · Data Backbone

---

## Detailed Implementation Tasks

### 1. Database Schema & Migration
#### 1.1 Create Migration File Structure
- [x] Generate timestamp for migration: `20241201000000_engagement_events.sql`
- [x] Create migration file in Supabase migrations directory
- [x] Add migration header comments with purpose and dependencies

#### 1.2 Define Core Table Schema
- [x] Write `CREATE TABLE engagement_events` SQL with:
  - `id UUID PRIMARY KEY DEFAULT gen_random_uuid()`
  - `user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE`
  - `timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()`
  - `event_type TEXT NOT NULL`
  - `value JSONB DEFAULT '{}'::jsonb`
  - `is_deleted BOOLEAN DEFAULT FALSE`

#### 1.3 Add Performance Indexes
- [x] Create composite index: `CREATE INDEX idx_engagement_events_user_timestamp ON engagement_events(user_id, timestamp DESC);`
- [x] Create GIN index: `CREATE INDEX idx_engagement_events_value ON engagement_events USING GIN(value);`
- [x] Create index on event_type: `CREATE INDEX idx_engagement_events_type ON engagement_events(event_type);`

#### 1.4 Add Table Constraints
- [x] Add check constraint for valid event_type format
- [x] Add check constraint for timestamp not in future
- [x] Verify foreign key cascade behavior

### 2. Row-Level Security Implementation
#### 2.1 Enable RLS on Table
- [x] Add `ALTER TABLE engagement_events ENABLE ROW LEVEL SECURITY;`
- [x] Verify RLS is enabled with `\d+ engagement_events`

#### 2.2 Create SELECT Policy
- [x] Write policy: `CREATE POLICY "Users can view own events" ON engagement_events FOR SELECT USING (auth.uid() = user_id);`
- [x] Test policy with different user contexts

#### 2.3 Create INSERT Policy
- [x] Write policy: `CREATE POLICY "Users can insert own events" ON engagement_events FOR INSERT WITH CHECK (auth.uid() = user_id);`
- [x] Add service role bypass: `CREATE POLICY "Service role can insert any events" ON engagement_events FOR INSERT TO service_role WITH CHECK (true);`

#### 2.4 RLS Testing
- [x] Create test users in auth.users
- [x] Verify user A cannot see user B's events
- [x] Verify anon role has no access
- [x] Test service role can insert for any user

### 3. API Configuration
#### 3.1 Supabase REST API Setup
- [x] Verify table appears in auto-generated API docs
- [x] Test GET `/rest/v1/engagement_events` with user JWT
- [x] Test POST `/rest/v1/engagement_events` with user JWT
- [x] Configure API rate limiting if needed

#### 3.2 GraphQL API Setup
- [x] Verify table appears in GraphQL schema
- [x] Test GraphQL query with user authentication
- [x] Test GraphQL mutation for inserting events

#### 3.3 Realtime Configuration
- [x] Enable Realtime on `engagement_events` table in Supabase dashboard
- [x] Configure Realtime policies to respect RLS
- [x] Test subscription with Flutter client mock

#### 3.4 Service Role Access
- [x] Create service role key in Supabase dashboard
- [x] Test bulk insert with service role authentication
- [x] Document service role usage patterns

### 4. Cloud Function Integration
#### 4.1 Service Role Authentication Setup
- [x] Store service role key in Cloud Function environment variables
- [x] Create Supabase client with service role in Cloud Function
- [x] Test authentication from Cloud Function to Supabase

#### 4.2 Batch Import Endpoint Design
- [x] Define JSON schema for batch event payload
- [x] Use native Supabase batch insert
- [x] Implement bulk insert logic with transaction handling (via native Supabase .insert())
- [x] Add error handling and validation

#### 4.3 UTC Timestamp Handling
- [x] Ensure all timestamps converted to UTC before insert
- [x] Add timezone validation in Cloud Function
- [x] Test with various timezone inputs

#### 4.4 pgjwt Extension Setup
- [x] Verify pgjwt extension is available in Supabase
- [x] Create helper functions for JWT validation if needed
- [x] Test service role JWT generation and validation

### 5. Testing & Validation
#### 5.1 Mock Data Generation
- [x] Create seed script `seed_engagement_events.sql`
- [x] Generate realistic event types: `app_open`, `goal_complete`, `steps_import`
- [x] Create events for multiple test users across date ranges
- [x] Include varied JSONB payloads for testing

#### 5.2 RLS Audit Tests
- [x] Write test script to verify cross-user data isolation
- [x] Test with multiple concurrent user sessions
- [x] Verify service role can access all data
- [x] Document RLS test results

#### 5.3 Performance Testing
- [x] Measure Realtime latency from insert to client notification
- [x] Test with 100+ concurrent inserts
- [x] Verify index performance with EXPLAIN ANALYZE
- [x] Benchmark query performance with large datasets

#### 5.4 API Validation Tests
- [x] Test all CRUD operations via REST API
- [x] Test GraphQL queries and mutations
- [x] Validate error responses for unauthorized access
- [x] Test API rate limiting behavior

### 6. Documentation & Deployment
#### 6.1 Data Retention Documentation
- [x] Document soft delete strategy using `is_deleted` flag
- [x] Create procedures for data archival
- [x] Define data retention policies and timelines
- [x] Document GDPR compliance for user data deletion

#### 6.2 Deployment Procedures
- [x] Create migration deployment checklist
- [x] Document rollback procedures for schema changes
- [x] Create monitoring alerts for table health
- [x] Document backup and recovery procedures

#### 6.3 API Usage Documentation
- [x] Create Flutter client integration examples
- [x] Document Realtime subscription patterns
- [x] Create API reference for event_type conventions
- [x] Document JSONB payload schemas for common events

#### 6.4 Operational Readiness
- [x] Set up monitoring for table size and performance
- [x] Create alerts for RLS policy violations
- [x] Document troubleshooting procedures
- [x] Create runbook for common operational tasks

### 7. Write minimal DB & RLS tests
#### 7.1 Create Python RLS Test Script
- [x] Create `tests/db/test_rls.py` – a tiny Python + psycopg2 script:
      * Connect to local Postgres (host=localhost, user=postgres, db=test).
      * Insert an `engagement_events` row with user_id A.
      * Attempt to read it as user_id B; expect 0 rows.

#### 7.2 Update CI Workflow
- [x] Update `.github/workflows/ci.yml`:
      * After Terraform validate, install `psycopg2-binary` + `pytest`.
      * Run `pytest tests/db/test_rls.py`.

#### 7.3 Document Test Commands
- [x] Document the test command in README:  
      `pytest tests/db/test_rls.py`

---

**Status:** Ready for implementation  
**Dependencies:** Supabase project setup, authentication system  
**Estimated Effort:** 1 week (Milestone 1 timeline) 