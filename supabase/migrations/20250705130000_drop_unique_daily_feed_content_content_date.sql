-- Migration: Drop obsolete unique constraint on content_date in daily_feed_content
-- Allows multiple rows per day after June-22 schema change

ALTER TABLE public.daily_feed_content
DROP CONSTRAINT IF EXISTS daily_feed_content_content_date_key; 