-- Migration: Create daily_momentum_scores view
-- Epic 1.8 ▸ Milestone M1.8.1 ▸ Task T3
-- Description: Provide backward-compatibility for legacy consumers by mapping
--              public.daily_engagement_scores → view daily_momentum_scores
--              with columns (user_id, score, score_date, pillar_breakdown)
-- Reversible: DROP VIEW on down

-- Up -----------------------------------------------------------------------
CREATE OR REPLACE VIEW public.daily_momentum_scores AS
SELECT
    user_id,
    final_score AS score,
    score_date,
    breakdown AS pillar_breakdown
FROM public.daily_engagement_scores;

-- Down ---------------------------------------------------------------------
DROP VIEW IF EXISTS public.daily_momentum_scores;
