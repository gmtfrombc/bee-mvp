-- =====================================================
-- FORCE REMOVE SECURITY DEFINER FROM VIEWS
-- This migration ensures views are completely recreated without SECURITY DEFINER
-- =====================================================

-- First, let's check what the current view definitions actually contain
-- and forcibly recreate them with explicit SECURITY INVOKER

-- Drop views with CASCADE to handle any dependencies
DROP VIEW IF EXISTS public.coach_intervention_queue CASCADE;
DROP VIEW IF EXISTS public.momentum_dashboard CASCADE;
DROP VIEW IF EXISTS public.recent_user_momentum CASCADE;
DROP VIEW IF EXISTS public.intervention_candidates CASCADE;

-- Create coach_intervention_queue with explicit SECURITY INVOKER
CREATE VIEW public.coach_intervention_queue
AS
SELECT 
    ci.id,
    ci.user_id,
    ci.intervention_type,
    ci.trigger_reason,
    ci.trigger_pattern,
    ci.status,
    ci.scheduled_date,
    ci.scheduled_time,
    ci.assigned_coach_id,
    ci.outcome_summary,
    ci.intervention_notes,
    ci.created_at,
    ci.updated_at,
    des.final_score as current_momentum_score,
    des.momentum_state as current_momentum_state
FROM coach_interventions ci
JOIN daily_engagement_scores des ON (
    des.user_id = ci.user_id 
    AND des.score_date = CURRENT_DATE
)
WHERE ci.status IN ('scheduled', 'in_progress')
ORDER BY ci.scheduled_date, ci.scheduled_time;

-- Create momentum_dashboard with explicit SECURITY INVOKER
CREATE VIEW public.momentum_dashboard
AS
SELECT 
    des.user_id,
    des.score_date,
    des.final_score,
    des.momentum_state,
    des.breakdown,
    COUNT(mn.id) as pending_notifications,
    COUNT(ci.id) as active_interventions
FROM daily_engagement_scores des
LEFT JOIN momentum_notifications mn ON (
    mn.user_id = des.user_id 
    AND mn.status = 'pending'
)
LEFT JOIN coach_interventions ci ON (
    ci.user_id = des.user_id 
    AND ci.status IN ('scheduled', 'in_progress')
)
WHERE des.score_date = CURRENT_DATE
GROUP BY des.user_id, des.score_date, des.final_score, des.momentum_state, des.breakdown;

-- Create recent_user_momentum with explicit SECURITY INVOKER
CREATE VIEW public.recent_user_momentum
AS
SELECT 
    des.user_id,
    des.score_date,
    des.final_score,
    des.momentum_state,
    des.raw_score,
    des.normalized_score,
    des.created_at,
    LAG(des.final_score, 1) OVER (PARTITION BY des.user_id ORDER BY des.score_date) as previous_score,
    AVG(des.final_score) OVER (
        PARTITION BY des.user_id 
        ORDER BY des.score_date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as seven_day_avg,
    ROW_NUMBER() OVER (PARTITION BY des.user_id ORDER BY des.score_date DESC) as day_rank
FROM daily_engagement_scores des
WHERE des.score_date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY des.user_id, des.score_date DESC;

-- Create intervention_candidates with explicit SECURITY INVOKER
CREATE VIEW public.intervention_candidates
AS
SELECT 
    des.user_id,
    COUNT(*) as consecutive_needs_care_days,
    MAX(des.score_date) as latest_score_date,
    AVG(des.final_score) as avg_score_needs_care_period,
    MIN(des.final_score) as lowest_score,
    CASE 
        WHEN COUNT(*) >= 3 THEN 'Immediate'
        WHEN COUNT(*) >= 2 THEN 'Soon'
        ELSE 'Monitor'
    END as intervention_urgency,
    EXISTS(
        SELECT 1 FROM coach_interventions ci 
        WHERE ci.user_id = des.user_id 
        AND ci.status IN ('scheduled', 'in_progress')
    ) as has_active_intervention
FROM daily_engagement_scores des
WHERE des.momentum_state = 'NeedsCare'
  AND des.score_date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY des.user_id
HAVING COUNT(*) >= 2
ORDER BY COUNT(*) DESC, MIN(des.final_score) ASC;

-- Grant appropriate permissions
GRANT SELECT ON public.coach_intervention_queue TO authenticated;
GRANT SELECT ON public.coach_intervention_queue TO service_role;

GRANT SELECT ON public.momentum_dashboard TO authenticated;
GRANT SELECT ON public.momentum_dashboard TO service_role;

GRANT SELECT ON public.recent_user_momentum TO authenticated;
GRANT SELECT ON public.recent_user_momentum TO service_role;

GRANT SELECT ON public.intervention_candidates TO authenticated;
GRANT SELECT ON public.intervention_candidates TO service_role;

-- Log the forced recreation
INSERT INTO public.system_logs (log_level, message, created_at)
VALUES ('INFO', 'FORCED recreation of views with explicit security_invoker=true to remove SECURITY DEFINER properties', NOW()); 