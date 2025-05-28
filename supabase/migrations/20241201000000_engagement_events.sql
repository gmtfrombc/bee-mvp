-- Migration: Engagement Events Logging (Core Engagement Module)
-- Purpose: Create engagement_events table for BEE behavioral tracking system
-- Module: Core Engagement
-- Milestone: 1 · Data Backbone
-- 
-- Dependencies:
--   - Requires auth.users table (provided by Supabase Auth)
--   - Requires uuid-ossp extension for UUID generation
--   - Part of BEE MVP architecture using Supabase as managed DB layer
--
-- References:
--   - bee_mvp_architecture.md: Supabase setup in Data & API Layer
--   - prd-engagement-events-logging.md: Functional requirements section 4.1
--
-- Created: 2024-12-01
-- Author: BEE Development Team

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create engagement_events table with all required columns
-- Following schema specifications from prd-engagement-events-logging.md section 4.1
CREATE TABLE engagement_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    event_type TEXT NOT NULL,
    value JSONB DEFAULT '{}'::jsonb,
    is_deleted BOOLEAN DEFAULT FALSE
);

-- Create performance indexes for optimal query patterns
-- Composite index for user timeline queries (most common access pattern)
CREATE INDEX idx_engagement_events_user_timestamp 
ON engagement_events(user_id, timestamp DESC);

-- GIN index for JSONB payload searches
CREATE INDEX idx_engagement_events_value 
ON engagement_events USING GIN(value);

-- Standard index for event_type filtering
CREATE INDEX idx_engagement_events_type 
ON engagement_events(event_type);

-- Add table constraints for data validation
-- Ensure event_type is not empty
ALTER TABLE engagement_events 
ADD CONSTRAINT check_event_type_not_empty 
CHECK (event_type != '' AND LENGTH(TRIM(event_type)) > 0);

-- Ensure timestamps are not in the future (with 1 minute tolerance for clock skew)
ALTER TABLE engagement_events 
ADD CONSTRAINT check_timestamp_not_future 
CHECK (timestamp <= NOW() + INTERVAL '1 minute');

-- Business rules for valid event_type values (can be extended as needed)
-- Common event types: app_open, goal_complete, steps_import, coach_message_sent, etc.
-- Note: This constraint can be modified to use an enum table in the future if needed

-- Enable Row Level Security (RLS) for HIPAA compliance
-- This ensures all data access goes through security policies
ALTER TABLE engagement_events ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can view only their own events
-- Ensures complete data isolation between users
CREATE POLICY "Users can view own events" 
ON engagement_events 
FOR SELECT 
USING (auth.uid() = user_id);

-- RLS Policy: Users can insert only their own events
-- Prevents users from creating events for other users
CREATE POLICY "Users can insert own events" 
ON engagement_events 
FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- RLS Policy: Service role can insert events for any user
-- Supports bulk imports from Cloud Functions and EHR integrations
CREATE POLICY "Service role can insert any events" 
ON engagement_events 
FOR INSERT 
TO service_role 
WITH CHECK (true); 