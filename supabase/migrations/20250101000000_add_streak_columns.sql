-- Migration: Add Streak Tracking Columns to user_meta
-- Purpose: Support gamification streak features for chat engagement
-- Epic: M1.3.8 – Gamification & Rewards
-- 
-- Features:
--   - Add streak_start column for tracking when streak began
--   - Add current_streak column for current consecutive day count
--   - Ensure backward compatibility with existing user_meta records
--
-- Created: 2025-01-01
-- Author: BEE Development Team

-- Add streak tracking columns to user_meta table
ALTER TABLE user_meta 
ADD COLUMN IF NOT EXISTS streak_start TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS current_streak INTEGER DEFAULT 0;

-- Create index for efficient streak queries
CREATE INDEX IF NOT EXISTS idx_user_meta_streak 
ON user_meta(user_id, current_streak) 
WHERE current_streak > 0;

-- Update existing records to have default streak values
UPDATE user_meta 
SET current_streak = 0 
WHERE current_streak IS NULL;

-- Ensure current_streak cannot be negative
ALTER TABLE user_meta 
ADD CONSTRAINT check_current_streak_non_negative 
CHECK (current_streak >= 0);

-- Add comments for documentation
COMMENT ON COLUMN user_meta.streak_start IS 'Timestamp when current chat streak began';
COMMENT ON COLUMN user_meta.current_streak IS 'Current consecutive days with assistant replies';

-- Grant necessary permissions
GRANT SELECT, UPDATE ON user_meta TO authenticated;
GRANT ALL ON user_meta TO service_role; 