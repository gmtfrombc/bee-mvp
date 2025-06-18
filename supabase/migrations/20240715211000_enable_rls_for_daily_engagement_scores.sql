-- =================================================================
-- Enable RLS and Add Policies for Daily Engagement Scores
-- =================================================================
-- This migration secures the daily_engagement_scores table by
-- enabling Row Level Security and adding policies that ensure
-- users can only access their own data.
-- =================================================================

ALTER TABLE public.daily_engagement_scores ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow individual read access on daily_engagement_scores"
ON public.daily_engagement_scores
FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Allow individual insert access on daily_engagement_scores"
ON public.daily_engagement_scores
FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow individual update access on daily_engagement_scores"
ON public.daily_engagement_scores
FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Allow individual delete access on daily_engagement_scores"
ON public.daily_engagement_scores
FOR DELETE
USING (auth.uid() = user_id); 