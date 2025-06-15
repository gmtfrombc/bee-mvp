-- Migration: Add steps_total and hrv_avg columns to wearable_daily_summary
-- Epic: 2.2 – Enhanced Wearable Integration Layer
-- Related Task: Back-fill summarizer columns for Phase-3 JITAI (ref docs/1_3_Epic_Adaptive_Coach/tasks-adaptive-coach.md T1.3.9.13)
-- Date: 2025-06-15

-- Create wearable_daily_summary table if it does not exist
CREATE TABLE IF NOT EXISTS public.wearable_daily_summary (
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    summary_date DATE NOT NULL,
    sleep_score INTEGER,
    sleep_hours NUMERIC(4,2),
    avg_hr INTEGER,
    steps_total INTEGER,
    hrv_avg INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, summary_date)
);

-- Enable Row Level Security (protects user data; service_role bypasses)
ALTER TABLE public.wearable_daily_summary ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own summaries" ON public.wearable_daily_summary
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can upsert their own summaries" ON public.wearable_daily_summary
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Add columns if they do not already exist
ALTER TABLE IF EXISTS public.wearable_daily_summary
    ADD COLUMN IF NOT EXISTS steps_total INTEGER,
    ADD COLUMN IF NOT EXISTS hrv_avg INTEGER;

-- Optional: update column comments for clarity
COMMENT ON COLUMN public.wearable_daily_summary.steps_total IS 'Total steps counted for the day';
COMMENT ON COLUMN public.wearable_daily_summary.hrv_avg IS 'Average heart-rate variability (ms) for the day';

-- No change to RLS policies required (row-level policies already use user_id). 