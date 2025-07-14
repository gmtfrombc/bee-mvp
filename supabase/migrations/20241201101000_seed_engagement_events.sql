-- Seed Script: Engagement Events Test Data
-- Purpose: Generate realistic test data for engagement events testing
-- Module: Core Engagement
-- Milestone: 1 · Data Backbone
--
-- Usage: Run this script after the main migration to populate test data
-- Note: This script creates test users and events for development/testing only
--
-- Created: 2024-12-01
-- Author: BEE Development Team

-- Create test users in auth.users table
-- Note: In production, users are created through Supabase Auth
-- These are for testing purposes only
INSERT INTO auth.users (
    id,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    raw_app_meta_data,
    raw_user_meta_data
) VALUES 
    (
        '11111111-1111-1111-1111-111111111111',
        'test.user1@example.com',
        '$2a$10$dummy.encrypted.password.hash.for.testing.purposes.only',
        NOW(),
        NOW(),
        NOW(),
        '{"provider": "email", "providers": ["email"]}',
        '{"name": "Test User 1"}'
    ),
    (
        '22222222-2222-2222-2222-222222222222',
        'test.user2@example.com',
        '$2a$10$dummy.encrypted.password.hash.for.testing.purposes.only',
        NOW(),
        NOW(),
        NOW(),
        '{"provider": "email", "providers": ["email"]}',
        '{"name": "Test User 2"}'
    ),
    (
        '33333333-3333-3333-3333-333333333333',
        'test.user3@example.com',
        '$2a$10$dummy.encrypted.password.hash.for.testing.purposes.only',
        NOW(),
        NOW(),
        NOW(),
        '{"provider": "email", "providers": ["email"]}',
        '{"name": "Test User 3"}'
    )
ON CONFLICT (id) DO NOTHING;

-- Generate realistic engagement events across multiple users and date ranges
-- Event types: app_open, goal_complete, steps_import, coach_message_sent, mood_log, sleep_log

-- User 1 Events (Active user with diverse event types)
INSERT INTO engagement_events (user_id, timestamp, event_type, value) VALUES
    -- App opens over the last 7 days
    ('11111111-1111-1111-1111-111111111111', NOW() - INTERVAL '1 day', 'app_open', '{"session_duration": 300, "screen": "dashboard"}'),
    ('11111111-1111-1111-1111-111111111111', NOW() - INTERVAL '2 days', 'app_open', '{"session_duration": 180, "screen": "goals"}'),
    ('11111111-1111-1111-1111-111111111111', NOW() - INTERVAL '3 days', 'app_open', '{"session_duration": 420, "screen": "dashboard"}'),
    ('11111111-1111-1111-1111-111111111111', NOW() - INTERVAL '5 days', 'app_open', '{"session_duration": 150, "screen": "profile"}'),
    ('11111111-1111-1111-1111-111111111111', NOW() - INTERVAL '7 days', 'app_open', '{"session_duration": 240, "screen": "dashboard"}'),
    
    -- Goal completions
    ('11111111-1111-1111-1111-111111111111', NOW() - INTERVAL '1 day', 'goal_complete', '{"goal_id": "goal_001", "goal_type": "steps", "target": 10000, "achieved": 12500, "streak": 3}'),
    ('11111111-1111-1111-1111-111111111111', NOW() - INTERVAL '3 days', 'goal_complete', '{"goal_id": "goal_002", "goal_type": "exercise", "target": 30, "achieved": 45, "streak": 1}'),
    ('11111111-1111-1111-1111-111111111111', NOW() - INTERVAL '5 days', 'goal_complete', '{"goal_id": "goal_001", "goal_type": "steps", "target": 10000, "achieved": 11200, "streak": 2}'),
    
    -- Steps imports from wearable devices
    ('11111111-1111-1111-1111-111111111111', NOW() - INTERVAL '1 day', 'steps_import', '{"source": "fitbit", "steps": 12500, "calories": 2100, "distance": 8.2, "active_minutes": 85}'),
    ('11111111-1111-1111-1111-111111111111', NOW() - INTERVAL '2 days', 'steps_import', '{"source": "fitbit", "steps": 9800, "calories": 1950, "distance": 6.8, "active_minutes": 72}'),
    ('11111111-1111-1111-1111-111111111111', NOW() - INTERVAL '3 days', 'steps_import', '{"source": "fitbit", "steps": 11200, "calories": 2050, "distance": 7.5, "active_minutes": 78}'),
    
    -- Coach messages and interactions
    ('11111111-1111-1111-1111-111111111111', NOW() - INTERVAL '2 days', 'coach_message_sent', '{"message_id": "msg_001", "type": "encouragement", "trigger": "goal_achievement", "content_length": 120}'),
    ('11111111-1111-1111-1111-111111111111', NOW() - INTERVAL '4 days', 'coach_message_sent', '{"message_id": "msg_002", "type": "reminder", "trigger": "inactivity", "content_length": 85}'),
    
    -- Mood and wellness logs
    ('11111111-1111-1111-1111-111111111111', NOW() - INTERVAL '1 day', 'mood_log', '{"mood_score": 8, "energy_level": 7, "stress_level": 3, "notes": "Feeling great after workout"}'),
    ('11111111-1111-1111-1111-111111111111', NOW() - INTERVAL '3 days', 'mood_log', '{"mood_score": 6, "energy_level": 5, "stress_level": 6, "notes": "Busy day at work"}'),
    ('11111111-1111-1111-1111-111111111111', NOW() - INTERVAL '2 days', 'sleep_log', '{"hours_slept": 7.5, "sleep_quality": 8, "bedtime": "22:30", "wake_time": "06:00", "interruptions": 1}');

-- User 2 Events (Moderate user with some gaps)
INSERT INTO engagement_events (user_id, timestamp, event_type, value) VALUES
    -- App opens with some gaps
    ('22222222-2222-2222-2222-222222222222', NOW() - INTERVAL '1 day', 'app_open', '{"session_duration": 200, "screen": "dashboard"}'),
    ('22222222-2222-2222-2222-222222222222', NOW() - INTERVAL '4 days', 'app_open', '{"session_duration": 120, "screen": "goals"}'),
    ('22222222-2222-2222-2222-222222222222', NOW() - INTERVAL '7 days', 'app_open', '{"session_duration": 300, "screen": "dashboard"}'),
    
    -- Fewer goal completions
    ('22222222-2222-2222-2222-222222222222', NOW() - INTERVAL '2 days', 'goal_complete', '{"goal_id": "goal_003", "goal_type": "steps", "target": 8000, "achieved": 8500, "streak": 1}'),
    ('22222222-2222-2222-2222-222222222222', NOW() - INTERVAL '6 days', 'goal_complete', '{"goal_id": "goal_004", "goal_type": "water", "target": 8, "achieved": 10, "streak": 2}'),
    
    -- Steps imports
    ('22222222-2222-2222-2222-222222222222', NOW() - INTERVAL '1 day', 'steps_import', '{"source": "apple_watch", "steps": 8500, "calories": 1800, "distance": 5.2, "active_minutes": 45}'),
    ('22222222-2222-2222-2222-222222222222', NOW() - INTERVAL '4 days', 'steps_import', '{"source": "apple_watch", "steps": 6200, "calories": 1650, "distance": 3.8, "active_minutes": 32}'),
    
    -- Mood logs
    ('22222222-2222-2222-2222-222222222222', NOW() - INTERVAL '3 days', 'mood_log', '{"mood_score": 7, "energy_level": 6, "stress_level": 4, "notes": "Good day overall"}');

-- User 3 Events (Less active user, testing edge cases)
INSERT INTO engagement_events (user_id, timestamp, event_type, value) VALUES
    -- Minimal app usage
    ('33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '3 days', 'app_open', '{"session_duration": 60, "screen": "dashboard"}'),
    ('33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '10 days', 'app_open', '{"session_duration": 90, "screen": "onboarding"}'),
    
    -- Single goal completion
    ('33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '5 days', 'goal_complete', '{"goal_id": "goal_005", "goal_type": "meditation", "target": 10, "achieved": 15, "streak": 1}'),
    
    -- Minimal data import
    ('33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '4 days', 'steps_import', '{"source": "manual", "steps": 3500, "calories": 1200, "distance": 2.1, "active_minutes": 15}'),
    
    -- Coach message for inactive user
    ('33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '1 day', 'coach_message_sent', '{"message_id": "msg_003", "type": "re_engagement", "trigger": "long_inactivity", "content_length": 150}');

-- Add some historical data (30 days back) for performance testing
INSERT INTO engagement_events (user_id, timestamp, event_type, value) VALUES
    -- User 1 historical data
    ('11111111-1111-1111-1111-111111111111', NOW() - INTERVAL '15 days', 'app_open', '{"session_duration": 250, "screen": "dashboard"}'),
    ('11111111-1111-1111-1111-111111111111', NOW() - INTERVAL '20 days', 'goal_complete', '{"goal_id": "goal_001", "goal_type": "steps", "target": 10000, "achieved": 10500, "streak": 5}'),
    ('11111111-1111-1111-1111-111111111111', NOW() - INTERVAL '25 days', 'steps_import', '{"source": "fitbit", "steps": 9500, "calories": 1900, "distance": 6.2, "active_minutes": 65}'),
    ('11111111-1111-1111-1111-111111111111', NOW() - INTERVAL '30 days', 'mood_log', '{"mood_score": 7, "energy_level": 8, "stress_level": 2, "notes": "Starting my wellness journey"}'),
    
    -- User 2 historical data
    ('22222222-2222-2222-2222-222222222222', NOW() - INTERVAL '18 days', 'app_open', '{"session_duration": 180, "screen": "goals"}'),
    ('22222222-2222-2222-2222-222222222222', NOW() - INTERVAL '22 days', 'steps_import', '{"source": "apple_watch", "steps": 7200, "calories": 1700, "distance": 4.5, "active_minutes": 38}'),
    
    -- User 3 historical data (sparse)
    ('33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '28 days', 'app_open', '{"session_duration": 45, "screen": "onboarding"}');

-- Add some test events with edge case JSONB payloads
INSERT INTO engagement_events (user_id, timestamp, event_type, value) VALUES
    -- Empty JSONB (should use default)
    ('11111111-1111-1111-1111-111111111111', NOW() - INTERVAL '1 hour', 'test_event', '{}'),
    
    -- Complex nested JSONB
    ('11111111-1111-1111-1111-111111111111', NOW() - INTERVAL '2 hours', 'complex_event', '{
        "metadata": {
            "version": "1.0",
            "source": "mobile_app",
            "platform": "ios"
        },
        "data": {
            "measurements": [
                {"type": "heart_rate", "value": 72, "unit": "bpm"},
                {"type": "blood_pressure", "value": {"systolic": 120, "diastolic": 80}, "unit": "mmHg"}
            ],
            "tags": ["health", "vitals", "routine_check"]
        }
    }'),
    
    -- Large JSONB payload
    ('22222222-2222-2222-2222-222222222222', NOW() - INTERVAL '3 hours', 'data_sync', '{
        "sync_id": "sync_12345",
        "records_processed": 1500,
        "data_sources": ["fitbit", "apple_health", "manual_entry"],
        "processing_time_ms": 2500,
        "errors": [],
        "summary": {
            "steps": {"total": 45000, "avg_daily": 9000},
            "sleep": {"total_hours": 52.5, "avg_nightly": 7.5},
            "workouts": {"count": 8, "total_minutes": 240}
        }
    }');

-- Create a test event that should be soft-deleted
INSERT INTO engagement_events (user_id, timestamp, event_type, value, is_deleted) VALUES
    ('11111111-1111-1111-1111-111111111111', NOW() - INTERVAL '6 hours', 'deleted_event', '{"reason": "user_requested_deletion"}', true);

-- Summary comment for verification
-- Total events created:
-- User 1: ~25 events (active user)
-- User 2: ~12 events (moderate user)  
-- User 3: ~7 events (inactive user)
-- Test events: 4 events (edge cases)
-- Total: ~48 events across 3 test users with varied patterns and date ranges 