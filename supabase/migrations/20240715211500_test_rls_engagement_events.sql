-- RLS Test Script for engagement_events table
-- Purpose: Verify complete data isolation between users
-- Run this script after the main migration to validate RLS policies
--
-- WARNING: This is a test script - do not run in production
-- Use only in development/staging environments

-- Create test users for RLS validation
-- Note: In real Supabase, users are created through auth.signup()
-- This is for testing purposes only
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at)
VALUES 
  ('11111111-1111-1111-1111-111111111111', 'test-user-a@example.com', 'encrypted', NOW(), NOW(), NOW()),
  ('22222222-2222-2222-2222-222222222222', 'test-user-b@example.com', 'encrypted', NOW(), NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- Insert test events for each user
INSERT INTO engagement_events (user_id, event_type, value) VALUES
  ('11111111-1111-1111-1111-111111111111', 'app_open', '{"source": "test_user_a"}'),
  ('11111111-1111-1111-1111-111111111111', 'goal_complete', '{"goal_id": "test_goal_a"}'),
  ('22222222-2222-2222-2222-222222222222', 'app_open', '{"source": "test_user_b"}'),
  ('22222222-2222-2222-2222-222222222222', 'steps_import', '{"steps": 5000}');

-- Test queries to verify RLS isolation
-- These should be run with different user contexts to verify policies

-- Query 1: User A should only see their own events (2 rows)
-- SET LOCAL "request.jwt.claims" = '{"sub": "11111111-1111-1111-1111-111111111111"}';
-- SELECT COUNT(*) FROM engagement_events; -- Should return 2

-- Query 2: User B should only see their own events (2 rows)  
-- SET LOCAL "request.jwt.claims" = '{"sub": "22222222-2222-2222-2222-222222222222"}';
-- SELECT COUNT(*) FROM engagement_events; -- Should return 2

-- Query 3: Anonymous user should see no events (0 rows)
-- RESET "request.jwt.claims";
-- SELECT COUNT(*) FROM engagement_events; -- Should return 0

-- Query 4: Service role should see all events (4 rows)
-- This requires service_role connection, not user JWT

-- Cleanup test data (uncomment to clean up after testing)
-- DELETE FROM engagement_events WHERE user_id IN (
--   '11111111-1111-1111-1111-111111111111',
--   '22222222-2222-2222-2222-222222222222'
-- );
-- DELETE FROM auth.users WHERE id IN (
--   '11111111-1111-1111-1111-111111111111', 
--   '22222222-2222-2222-2222-222222222222'
-- ); 