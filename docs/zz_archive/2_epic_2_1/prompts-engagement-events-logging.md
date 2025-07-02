# Developer Prompts – Engagement Events Logging

**Source:** `tasks-prd-engagement-events-logging.md`  
**Module:** Core Engagement  
**Milestone:** 1 · Data Backbone

---

## Database Schema & Migration

### 1.1 Create Migration File Structure
Generate a Supabase migration file with timestamp `20241201000000_engagement_events.sql`. Include header comments describing the purpose (engagement events logging for BEE core module) and dependencies (requires auth.users table). Reference the migration patterns from `bee_mvp_architecture.md` for Supabase setup.

### 1.2 Define Core Table Schema
Write the `CREATE TABLE engagement_events` SQL statement with all required columns: UUID primary key with auto-generation, user_id foreign key to auth.users with CASCADE delete, timezone-aware timestamp defaulting to NOW(), event_type as TEXT, JSONB value column with empty object default, and is_deleted boolean flag. Follow the schema specifications from `prd-engagement-events-logging.md` section 4.1.

### 1.3 Add Performance Indexes
Create three indexes: composite index on (user_id, timestamp DESC) for user timeline queries, GIN index on the JSONB value column for payload searches, and standard index on event_type for filtering. Use the naming convention `idx_engagement_events_<purpose>` for consistency.

### 1.4 Add Table Constraints
Add check constraints to validate event_type format (non-empty string) and ensure timestamps are not in the future. Verify the foreign key cascade behavior will properly clean up events when users are deleted. Document any business rules for valid event_type values.

## Row-Level Security Implementation

### 2.1 Enable RLS on Table
Enable Row Level Security on the engagement_events table using `ALTER TABLE` statement. Verify RLS is active by checking the table definition. This ensures all data access goes through security policies as required by the HIPAA compliance pathway in `bee_mvp_architecture.md`.

### 2.2 Create SELECT Policy
Write an RLS policy named "Users can view own events" that allows SELECT operations only when `auth.uid()` matches the row's `user_id`. Test the policy by attempting to query with different user contexts to ensure proper isolation.

### 2.3 Create INSERT Policy
Create two INSERT policies: "Users can insert own events" with CHECK condition `auth.uid() = user_id` for regular users, and "Service role can insert any events" with CHECK true for the service_role. This supports both user-generated events and bulk imports from Cloud Functions.

### 2.4 RLS Testing
Create test users in the auth.users table and verify complete data isolation: user A cannot access user B's events, anonymous users have no access, and the service role can insert events for any user. Document the test results to satisfy the RLS audit requirement from the PRD success metrics.

## API Configuration

### 3.1 Supabase REST API Setup
Verify the engagement_events table appears in Supabase's auto-generated REST API documentation. Test GET and POST operations to `/rest/v1/engagement_events` using user JWT tokens. Configure rate limiting if needed based on expected event volume from the PRD.

### 3.2 GraphQL API Setup
Confirm the table is available in Supabase's GraphQL schema. Test both query and mutation operations with proper user authentication. This provides an alternative API interface for Flutter clients as outlined in the technical architecture.

### 3.3 Realtime Configuration
Enable Supabase Realtime on the engagement_events table through the dashboard. Configure Realtime policies to respect RLS so users only receive notifications for their own events. Test subscription functionality with a mock Flutter client to verify the <500ms latency target.

### 3.4 Service Role Access
Generate a service role API key in the Supabase dashboard for Cloud Function authentication. Test bulk insert operations using the service role to ensure it bypasses RLS appropriately. Document the service role usage patterns for the batch import endpoint.

## Cloud Function Integration

### 4.1 Service Role Authentication Setup
Store the Supabase service role key as an environment variable in Cloud Functions. Create a Supabase client instance using the service role credentials. Test the authentication connection from Cloud Function to Supabase database to ensure proper access.

### 4.2 Batch Import Endpoint Design
Define a JSON schema for batch event payloads that accepts arrays of engagement events. Implement batch operations using native Supabase client `.from('engagement_events').insert(events)` for bulk inserts with automatic transaction handling. Include comprehensive error handling and validation in the Flutter client as specified in the PRD.

### 4.3 UTC Timestamp Handling
Implement timestamp conversion logic to ensure all incoming timestamps are converted to UTC before database insertion. Add validation to reject invalid timezone data. Test with various timezone inputs to ensure consistent UTC storage as required by the technical considerations.

### 4.4 pgjwt Extension Setup
Verify the pgjwt extension is available in your Supabase instance for JWT operations. Create any necessary helper functions for service role JWT validation. Test JWT generation and validation flows to support the service role authentication pattern.

## Testing & Validation

### 5.1 Mock Data Generation
Create a seed script `seed_engagement_events.sql` that generates realistic test data with event types like `app_open`, `goal_complete`, and `steps_import`. Include multiple test users with events across various date ranges and diverse JSONB payloads to support comprehensive testing.

### 5.2 RLS Audit Tests
Write automated test scripts that verify complete cross-user data isolation by attempting unauthorized access patterns. Test with multiple concurrent user sessions to ensure RLS policies hold under load. Verify service role access works correctly. Document all test results to meet the "zero cross-user leakage" success metric.

### 5.3 Performance Testing
Measure Realtime notification latency from event insertion to client notification, targeting the <500ms requirement. Test database performance with 100+ concurrent inserts and use EXPLAIN ANALYZE to verify index effectiveness. Benchmark query performance with large datasets to ensure scalability.

### 5.4 API Validation Tests
Test all CRUD operations through both REST and GraphQL APIs with proper authentication. Validate that unauthorized access attempts return appropriate error responses. Test API rate limiting behavior to ensure system stability under load.

## Documentation & Deployment

### 6.1 Data Retention Documentation
Document the soft delete strategy using the `is_deleted` flag, including procedures for data archival and permanent deletion. Define data retention policies and timelines. Document GDPR compliance procedures for user data deletion requests as required by the privacy considerations in the architecture.

### 6.2 Deployment Procedures
Create a comprehensive migration deployment checklist including pre-deployment verification, migration execution steps, and post-deployment validation. Document rollback procedures for schema changes. Set up monitoring alerts for table health and document backup/recovery procedures.

### 6.3 API Usage Documentation
Create Flutter client integration examples showing how to subscribe to engagement events and perform CRUD operations. Document Realtime subscription patterns and create an API reference for event_type conventions. Document JSONB payload schemas for common event types to guide consistent usage.

### 6.4 Operational Readiness
Set up monitoring dashboards for table size, query performance, and Realtime latency. Create alerts for RLS policy violations and unusual access patterns. Document troubleshooting procedures for common issues and create an operational runbook for database maintenance tasks. 